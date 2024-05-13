pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./OWSERC20Template.sol";
import "./IBase.sol";

contract OWSTokenFactory is Ownable {
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    address private _payToken;
    address private _treasury;
    uint256 private _launchFee;
    uint256 public totalDeployedCount;

    /// @dev account => owned tokens
    mapping(address => EnumerableSet.AddressSet) private _ownedTokens;

    event NewTokenCreated(address token);

    constructor(address payToken_, address treasury_) Ownable(msg.sender) {
        require(treasury_ != address(0), "invalid treasury");
        // validate if the given address is ERC20 standard
        IERC20(payToken_).balanceOf(address(this));
        _payToken = payToken_;
        _treasury = treasury_;
    }

    function createToken(IBase.TokenCreationProps memory props) external returns (address) {
        address caller = _msgSender();

        // charge token launch fee
        uint256 fee = _launchFee;
        if (fee > 0) IERC20(_payToken).safeTransferFrom(caller, _treasury, fee);

        bytes memory bytecode = type(OWSERC20Template).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(props.name, props.symbol, props.decimals, caller, block.timestamp));

        address payable tokenAddress;

        assembly {
            tokenAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        OWSERC20Template(tokenAddress).initialize(caller, props);
        _ownedTokens[caller].add(tokenAddress);
        ++totalDeployedCount;

        emit NewTokenCreated(tokenAddress);

        return tokenAddress;
    }

    /**
     * @notice When token ownership is transferred, it updates structure as well in the factory
     */
    function transferTokenOwnership(address from, address to) external {
        address token = _msgSender();

        EnumerableSet.AddressSet storage fromOwnedTokens = _ownedTokens[from];
        EnumerableSet.AddressSet storage toOwnedTokens = _ownedTokens[to];
        require(fromOwnedTokens.contains(token), "not involving");

        fromOwnedTokens.remove(token);
        toOwnedTokens.add(token);
    }

    /**
     * @notice Get the owned token count of the given account
     */
    function ownedTokenCount(address account) external view returns (uint256) {
        return _ownedTokens[account].length();
    }

    /**
     * @notice Get the owned tokens' addresses of the given account
     * @dev paginated function
     */
    function ownedTokens(address account, uint256 offset, uint256 limit) external view returns (address[] memory) {
        EnumerableSet.AddressSet storage tokens = _ownedTokens[account];
        uint256 totalCount = tokens.length();
        if (offset > totalCount) return new address[](0);
        if (offset + limit > totalCount) limit = totalCount - offset;
        address[] memory paginatedTokens = new address[](limit);
        for (uint256 i; i < limit; ) {
            paginatedTokens[i] = tokens.at(offset + i);
            unchecked {
                ++i;
            }
        }
        return paginatedTokens;
    }

    function setTreasury(address account) external onlyOwner {
        require(account != address(0), "invalid account");

        _treasury = account;
    }

    function treasury() external view returns (address) {
        return _treasury;
    }

    function setToken(address token) external onlyOwner {
        // validate if the given address is ERC20 standard
        IERC20(token).balanceOf(address(this));
        _payToken = token;
    }

    function payToken() external view returns (address) {
        return _payToken;
    }

    /**
     * @notice Set token creation fee
     */
    function setLaunchFee(uint256 fee) external onlyOwner {
        _launchFee = fee;
    }

    function launchFee() external view returns (uint256) {
        return _launchFee;
    }

    /**
     * @notice Recover tokens in the token contract
     * @param token address of token to recover
     * @param amount recover amount
     */
    function recoverTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(_msgSender(), amount);
    }

    /**
     * @notice Recover ETH in the token contract
     * @param amount recover amount
     */
    function recoverETH(uint256 amount) external onlyOwner {
        payable(_msgSender()).sendValue(amount);
    }
}
