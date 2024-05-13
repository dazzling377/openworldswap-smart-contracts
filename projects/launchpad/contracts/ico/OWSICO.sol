pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../libs/UniversalERC20.sol";

contract OWSICO is Ownable {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using UniversalERC20 for IERC20;

    struct ContributeData {
        uint256 amount;
        bool claimed;
    }

    IERC20 private immutable _icoToken;
    address payable private immutable _icoOwner; // ICO owner wallet address
    address payable private immutable _icoTreasury; // ICO treasury wallet address
    uint16 private immutable _treasuryFee; // ICO treasury fee

    uint256 private _startDate = 1715561976; //
    uint256 private _endDate = 1715561976; //
    uint256 private _claimDate = 1715563176; //

    uint256 private _hardcap = 2000000 ether; // hard cap
    uint256 private _softcap = 500000 ether; // softcap
    uint256 private _icoPrice = 1 ether; // token price
    uint256 private _minPerUser = 0 ether; // min amount per user
    uint256 private _maxPerUser = 2000000 ether; // max amount per user

    bool private _fundsWithdrawn;
    uint256 private _totalContributed; // Total contributed amount in buy token
    uint256 private _totalClaimed; // Total claimed amount in buy token
    mapping(address => ContributeData) private _contributedPerUser; // User contributed amount in buy token

    constructor(
        IERC20 icoToken_,
        address payable icoTreasury_,
        address payable icoOwner_,
        uint16 treasuryFee_,
        uint256 startDate_,
        uint256 endDate_
    ) Ownable(msg.sender) {
        icoToken_.balanceOf(address(this)); // To check the IERC20 contract
        _icoToken = icoToken_;

        require(icoOwner_ != address(0) && icoTreasury_ != address(0), "Invalid owner / treasury");

        require(startDate_ < endDate_, "Operations: invalid ico duration");
        require(startDate_ > block.timestamp, "Operations: start must be greater than current time");

        _endDate = endDate_;
        _startDate = startDate_;

        _icoOwner = icoOwner_;
        _icoTreasury = icoTreasury_;
        _treasuryFee = treasuryFee_;
    }

    /**
     * @dev Contribute ICO
     *
     * Only available when ICO is opened
     */
    function contribute() external payable {
        require(block.timestamp >= _startDate && block.timestamp < _endDate, "ICO not opened");

        uint256 contributeAmount = msg.value;
        ContributeData storage userContributeData = _contributedPerUser[_msgSender()];

        uint256 contributedSoFar = userContributeData.amount + contributeAmount;
        require(contributedSoFar >= _minPerUser && contributedSoFar <= _maxPerUser, "Out of limit");

        userContributeData.amount = contributedSoFar;
        _totalContributed += contributeAmount;

        require(_totalContributed <= _hardcap, "Reached hardcap");
    }

    /**
     * @dev Claim tokens from his contributed amount
     *
     * Only available after claim date
     */
    function claimTokens() external {
        require(block.timestamp > _claimDate, "Wait more");
        ContributeData storage userContributedData = _contributedPerUser[_msgSender()];
        require(!userContributedData.claimed, "Already claimed");
        uint256 userContributedAmount = userContributedData.amount;
        require(userContributedAmount > 0, "Not contributed");

        uint256 userRequiredAmount = (userContributedAmount * 10 ** (_icoToken.universalDecimals())) / _icoPrice;

        if (userRequiredAmount > 0) {
            _icoToken.safeTransfer(_msgSender(), userRequiredAmount);
        }
        userContributedData.claimed = true;
        _totalClaimed += userContributedAmount;
    }

    /**
     * @dev Finalize ICO when it was filled or by some reasons
     *
     * It should indicate claim date
     * Only ICO owner is allowed to call this function
     */
    function finalizeIco(uint256 claimDate_) external {
        require(_msgSender() == _icoOwner, "Unpermitted");
        require(block.timestamp < _endDate, "Already finished");
        require(block.timestamp < claimDate_, "Invalid claim date");
        if (_startDate > block.timestamp) {
            _startDate = block.timestamp;
        }
        _endDate = block.timestamp;
        _claimDate = claimDate_;
    }

    /**
     * @dev Withdraw remained tokens
     *
     * Only ICO owner is allowed to call this function
     */
    function withdrawRemainedTokens() external {
        require(_msgSender() == _icoOwner, "Unpermitted");
        require(block.timestamp >= _endDate, "ICO not finished");
        uint256 contractTokens = _icoToken.balanceOf(address(this));
        uint256 unclaimedTokens = ((_totalContributed - _totalClaimed) * 10 ** (_icoToken.universalDecimals())) /
            _icoPrice;

        _icoToken.safeTransfer(_msgSender(), contractTokens - unclaimedTokens);
    }

    /**
     * @dev Withdraw contributed funds
     *
     * Only ICO owner is allowed to call this function
     */
    function withdrawFunds() external {
        require(_msgSender() == _icoOwner, "Unpermitted");
        require(block.timestamp >= _endDate, "ICO not finished");
        require(!_fundsWithdrawn, "Already withdrawn");

        // Transfer treasury funds first
        uint256 treasuryFunds = (_totalContributed * _treasuryFee) / 10000;
        _icoTreasury.sendValue(treasuryFunds);

        // Transfer redundant funds
        _icoOwner.sendValue(_totalContributed - treasuryFunds);

        _fundsWithdrawn = true;
    }

    function viewIcoToken() external view returns (address) {
        return address(_icoToken);
    }

    function viewIcoOwner() external view returns (address payable) {
        return _icoOwner;
    }

    function viewIcoTreasury() external view returns (address payable) {
        return _icoTreasury;
    }

    function viewTreasuryFee() external view returns (uint16) {
        return _treasuryFee;
    }

    function viewTotalContributed() external view returns (uint256) {
        return _totalContributed;
    }

    function viewTotalClaimed() external view returns (uint256) {
        return _totalClaimed;
    }

    function viewUserContributed(address account_) external view returns (uint256, bool) {
        return (_contributedPerUser[account_].amount, _contributedPerUser[account_].claimed);
    }

    /**
     * @dev Update ICO start / end / claim date
     *
     * Only owner is allowed to call this function
     */
    function updateIcoDates(uint256 startDate_, uint256 endDate_, uint256 claimDate_) external onlyOwner {
        require(block.timestamp < _startDate, "ICO already started");
        require(block.timestamp < startDate_, "Must be future time");
        require(startDate_ < endDate_, "startDate must before endDate");
        require(endDate_ < claimDate_, "endDate must before claimDate");

        _startDate = startDate_;
        _endDate = endDate_;
        _claimDate = claimDate_;
    }

    function viewIcoDates() external view returns (uint256, uint256, uint256) {
        return (_startDate, _endDate, _claimDate);
    }

    /**
     * @dev Update ICO hardcap / softcap
     *
     * Only owner is allowed to call this function
     */
    function updateCap(uint256 softcap_, uint256 hardcap_) external onlyOwner {
        require(block.timestamp < _startDate, "ICO already started");
        require(hardcap_ > 0 && softcap_ > 0, "Non zero values");
        require(softcap_ <= hardcap_, "Invalid values");
        _hardcap = hardcap_;
        _softcap = softcap_;
    }

    function viewCap() external view returns (uint256, uint256) {
        return (_softcap, _hardcap);
    }

    /**
     * @dev Update user contribute min / max limitation
     *
     * Only owner is allowed to call this function
     */
    function updateLimitation(uint256 minPerUser_, uint256 maxPerUser_) external onlyOwner {
        require(minPerUser_ <= maxPerUser_, "Invalid values");
        require(maxPerUser_ > 0, "Invalid max value");
        _minPerUser = minPerUser_;
        _maxPerUser = maxPerUser_;
    }

    function viewLimitation() external view returns (uint256, uint256) {
        return (_minPerUser, _maxPerUser);
    }

    /**
     * @dev Update ICO price
     *
     * Only owner is allowed to call this function
     */
    function updateIcoPrice(uint256 icoPrice_) external onlyOwner {
        require(block.timestamp < _startDate, "ICO already started");
        require(icoPrice_ > 0, "Invalid price");
        _icoPrice = icoPrice_;
    }

    function viewIcoPrice() external view returns (uint256) {
        return _icoPrice;
    }

    /**
     * @dev Recover ETH sent to the contract
     *
     * Only owner allowed to call this function
     */
    function recoverETH() external onlyOwner {
        require(_fundsWithdrawn, "Not available until withdraw funds");
        uint256 etherBalance = address(this).balance;
        require(etherBalance > 0, "No ETH");
        payable(_msgSender()).transfer(etherBalance);
    }

    /**
     * @dev It allows the admin to recover tokens sent to the contract
     * @param token_: the address of the token to withdraw
     * @param amount_: the number of tokens to withdraw
     *
     * This function is only callable by owner
     */
    function recoverToken(address token_, uint256 amount_) external onlyOwner {
        require(token_ != address(_icoToken), "Not allowed token");
        require(amount_ > 0, "Non zero value");
        IERC20(token_).safeTransfer(_msgSender(), amount_);
    }

    /**
     * @dev To receive ETH in the ICO contract
     */
    receive() external payable {}
}
