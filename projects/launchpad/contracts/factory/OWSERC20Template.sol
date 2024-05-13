pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./OWSERC20.sol";
import "./IBase.sol";
import "./IOWSTokenFactory.sol";

contract OWSERC20Template is Ownable, OWSERC20 {
    using Address for address payable;
    using SafeERC20 for IERC20;

    uint16 private constant DENOMINATOR = 10000;
    /// @dev buy/sell/transfer tax cannot be more than 30%
    uint16 private constant MAX_TAX = 3000;
    /// @dev max tx amount should be more than 0.01% always
    uint16 private constant MAX_TX_AMOUNT_MIN_LIMIT = 1;
    /// @dev max hold amount should be more than 0.02% always
    uint16 private constant MAX_HOLD_AMOUNT_MIN_LIMIT = 2;

    address _factory;
    address _marketingWallet;

    bool _initialized;

    uint16 _buyTax;
    uint16 _sellTax;
    uint16 _transferTax;

    uint256 _txLimit;
    uint256 _holdLimit;

    mapping(address => bool) _excludedFromTxLimit;
    mapping(address => bool) _excludedFromHoldLimit;
    mapping(address => bool) _excludedFromTax;
    mapping(address => bool) _isAmmPair;

    event ExcludedFromHoldLimit(address account, bool flag);
    event ExcludedFromTax(address account, bool flag);
    event ExcludedFromTxLimit(address account, bool flag);
    event MarketingWalletUpdated(address wallet);
    event NewAmmPair(address lp, bool flag);

    constructor() Ownable(msg.sender) {
        _factory = _msgSender();
    }

    function initialize(
        address owner_,
        IBase.TokenCreationProps calldata props_
    ) external {
        require(_msgSender() == _factory, "only factory");
        require(!_initialized, "already initialized");
        super._initialize(props_.name, props_.symbol, props_.decimals);

        _excludedFromTxLimit[owner_] = true;
        _excludedFromTxLimit[address(0xdead)] = true;
        _excludedFromTxLimit[address(0)] = true;
        _excludedFromTxLimit[address(this)] = true;

        _excludedFromHoldLimit[owner_] = true;
        _excludedFromHoldLimit[address(0xdead)] = true;
        _excludedFromHoldLimit[address(0)] = true;
        _excludedFromHoldLimit[address(this)] = true;

        _excludedFromTax[owner_] = true;
        _excludedFromTax[address(0xdead)] = true;
        _excludedFromTax[address(0)] = true;
        _excludedFromTax[address(this)] = true;

        super._mint(owner_, props_.totalSupply);

        _setLimit(props_.txLimit, props_.holdLimit);
        _setTax(props_.buyTax, props_.sellTax, props_.transferTax);
        _marketingWallet = props_.marketingWallet;

        transferOwnership(owner_);
        _initialized = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint16 txFee;
        if (!_excludedFromTax[from] && !_excludedFromTax[to]) {
            if (_isAmmPair[from]) txFee = _buyTax;
            else if (_isAmmPair[to]) txFee = _sellTax;
            else txFee = _transferTax;
        }

        uint256 feeAmount = (amount * txFee) / DENOMINATOR;
        amount -= feeAmount;
        if (feeAmount > 0) super._transfer(from, _marketingWallet, feeAmount);
        if (amount > 0) {
            super._transfer(from, to, amount);
            _afterTokenTransfer(from, to, amount);
        }
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // Check max tx limit
        require(
            _excludedFromTxLimit[from] ||
                _excludedFromTxLimit[to] ||
                amount <= _txLimit,
            "tx amount limited"
        );

        // Check max wallet amount limit
        require(
            _excludedFromHoldLimit[to] || balanceOf(to) <= _holdLimit,
            "hold amount limited"
        );
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        if (_initialized)
            IOWSTokenFactory(_factory).transferTokenOwnership(
                owner(),
                newOwner
            );
        super._transferOwnership(newOwner);
    }

    /**
     * @notice Set new marketing wallet
     * @param account new marketing wallet
     */
    function setMarketingWallet(address account) external onlyOwner {
        require(account != address(0), "invalid wallet");
        _marketingWallet = account;

        emit MarketingWalletUpdated(account);
    }

    /**
     * @notice Return marketing wallet
     */
    function marketingWallet() external view returns (address) {
        return _marketingWallet;
    }

    /**
     * @notice Exclude / Include the account from max tx limit
     * @dev Only callable by owner
     */
    function excludeFromTxLimit(address account, bool flag) external onlyOwner {
        _excludedFromTxLimit[account] = flag;

        emit ExcludedFromTxLimit(account, flag);
    }

    /**
     * @notice Exclude / Include the accounts from max tx limit
     * @dev Only callable by owner
     */
    function batchExcludeFromTxLimit(
        address[] calldata accounts,
        bool flag
    ) external onlyOwner {
        uint256 count = accounts.length;
        for (uint256 i; i < count; ) {
            _excludedFromTxLimit[accounts[i]] = flag;
            emit ExcludedFromTxLimit(accounts[i], flag);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Check if the account is excluded from max tx limit
     * @param account: the account to be checked
     */
    function isExcludedFromTxLimit(
        address account
    ) external view returns (bool) {
        return _excludedFromTxLimit[account];
    }

    /**
     * @notice Exclude / Include the account from max wallet limit
     * @dev Only callable by owner
     */
    function excludeFromHoldLimit(
        address account,
        bool flag
    ) external onlyOwner {
        _excludedFromHoldLimit[account] = flag;

        emit ExcludedFromHoldLimit(account, flag);
    }

    /**
     * @notice Exclude / Include the accounts from max wallet limit
     * @dev Only callable by owner
     */
    function batchExcludeFromHoldLimit(
        address[] calldata accounts,
        bool flag
    ) external onlyOwner {
        uint256 count = accounts.length;
        for (uint256 i; i < count; ) {
            _excludedFromHoldLimit[accounts[i]] = flag;
            emit ExcludedFromHoldLimit(accounts[i], flag);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Check if the account is excluded from max wallet limit
     * @param account: the account to be checked
     */
    function isExcludedFromHoldLimit(
        address account
    ) external view returns (bool) {
        return _excludedFromHoldLimit[account];
    }

    /**
     * @notice Exclude / Include the account from tax
     * @dev Only callable by owner
     */
    function excludeFromTax(address account, bool flag) external onlyOwner {
        _excludedFromTax[account] = flag;

        emit ExcludedFromTax(account, flag);
    }

    /**
     * @notice Exclude / Include the accounts from tax
     * @dev Only callable by owner
     */
    function batchExcludeFromTax(
        address[] calldata accounts,
        bool flag
    ) external onlyOwner {
        uint256 count = accounts.length;
        for (uint256 i; i < count; ) {
            _excludedFromTax[accounts[i]] = flag;
            emit ExcludedFromTax(accounts[i], flag);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Check if the account is excluded from the tax
     * @param account: the account to be checked
     */
    function isExcludedFromTax(address account) external view returns (bool) {
        return _excludedFromTax[account];
    }

    /**
     * @notice Include / Exclude lp address in AMM pairs
     */
    function includeInAmmPair(address lpAddress, bool flag) external onlyOwner {
        // for the amm pair, exclude from hold limit automatically
        _excludedFromHoldLimit[lpAddress] = flag;
        _isAmmPair[lpAddress] = flag;

        emit NewAmmPair(lpAddress, flag);
    }

    /**
     * @notice Check if the lp address is AMM pair
     */
    function isAmmPair(address lpAddress) external view returns (bool) {
        return _isAmmPair[lpAddress];
    }

    function _setLimit(uint256 txLimit, uint256 holdLimit) private {
        require(
            txLimit >= (totalSupply() * MAX_TX_AMOUNT_MIN_LIMIT) / DENOMINATOR,
            "tx limit too small"
        );
        require(
            holdLimit >=
                (totalSupply() * MAX_HOLD_AMOUNT_MIN_LIMIT) / DENOMINATOR,
            "hold limit too small"
        );
        _txLimit = txLimit;
        _holdLimit = holdLimit;
    }

    /**
     * @notice Set tx limit & hold limit
     * @dev Only callable by owner
     */
    function setLimit(uint256 txLimit, uint256 holdLimit) external onlyOwner {
        _setLimit(txLimit, holdLimit);
    }

    function limit() external view returns (uint256, uint256) {
        return (_txLimit, _holdLimit);
    }

    function _setTax(
        uint16 buyTax,
        uint16 sellTax,
        uint16 transferTax
    ) private {
        require(buyTax <= MAX_TAX, "too much buy tax");
        require(sellTax <= MAX_TAX, "too much sell tax");
        require(transferTax <= MAX_TAX, "too much transfer tax");
        _buyTax = buyTax;
        _sellTax = sellTax;
        _transferTax = transferTax;
    }

    /**
     * @notice Set buy, sell, transfer tax
     */
    function setTax(
        uint16 buyTax,
        uint16 sellTax,
        uint16 transferTax
    ) external onlyOwner {
        _setTax(buyTax, sellTax, transferTax);
    }

    /**
     * @notice Return current buy tax, sell tax, transfer tax
     */
    function tax() external view returns (uint16, uint16, uint16) {
        return (_buyTax, _sellTax, _transferTax);
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