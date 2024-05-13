// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./OWSICO.sol";

contract ICODeployer is Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_BUFFER_BLOCKS = 200000; // 200,000 blocks (6-7 days on BSC)

    event AdminTokenRecovery(address indexed tokenRecovered, uint256 amount);
    event NewICOContract(address indexed ifoAddress);

    constructor() Ownable(msg.sender) {}

    /**
     * @notice It creates the ICO contract 
     * @param _icoToken: the ico token used
     * @param _icoTreasury: the ico treasury address
     * @param _icoOwner: the ico owner
     * @param _treasuryFee: the fee
     */
    function createICO(
        address _icoToken,
        address payable _icoTreasury,
        address payable _icoOwner,
        uint16 _treasuryFee,
        uint256 startDate_,
        uint256 endDate_
    ) external onlyOwner {
        require(IERC20(_icoToken).totalSupply() >= 0);

        address icoAddress = address(new OWSICO(IERC20(_icoToken), _icoTreasury, _icoOwner, _treasuryFee,startDate_,endDate_));

        emit NewICOContract(icoAddress);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress) external onlyOwner {
        uint256 balanceToRecover = IERC20(_tokenAddress).balanceOf(address(this));
        require(balanceToRecover > 0, "Operations: Balance must be > 0");
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), balanceToRecover);

        emit AdminTokenRecovery(_tokenAddress, balanceToRecover);
    }
}
