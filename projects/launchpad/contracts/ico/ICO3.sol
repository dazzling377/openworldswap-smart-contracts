pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../libs/UniversalERC20.sol";

contract ICO3 is Ownable {
    using Address for address payable;
    using UniversalERC20 for IERC20;

    struct UserInfo {
        uint256 wlContributes;
        uint256 pubContributes;
        uint256 wlClaims;
        uint256 pubClaims;
    }

    struct VestingProp {
        uint64 interval; // Vesting segment interval
        uint16 percent; // Vesting percent in each segment
        uint16 beginPercent; // Vesting start percent
    }

    address public immutable icoToken;

    uint64 private _wlStartDate = 1715541916; //
    uint64 private _pubStartDate = 1715561916; //
    uint64 private _endDate = 1715561976; //
    uint64 private _claimDate = 1715563176; //

    uint256 private _hardcap = 1000000 ether; // hard cap
    uint256 private _softcap = 500000 ether; // softcap

    uint256 private _wlPrice = 0.6 ether; // Whitelisted ICO price
    uint256 private _pubPrice = 0.75 ether; // Public ICO price

    uint256 private _wlMaxPerUser = 600000 ether; // max amount per user

    uint256 public totalWlContributes;
    uint256 public totalPubContributes;
    uint256 public totalWlClaims;
    uint256 public totalPubClaims;

    VestingProp private _wlVestingProp;
    VestingProp private _pubVestingProp;

    mapping(address => UserInfo) private _userInfo; // User info structure

    event UserContributed(address account, uint256 contributes, bool isPub);
    event UserClaimed(address account, uint256 wlClaims, uint256 pubClaims);

    error HardcapReached();
    error IcoAlreadyFinished();
    error IcoAlreadyStarted();
    error IcoNotOpened();
    error IcoStillOpened();
    error InvalidParam();
    error NotClaimableYet();
    error NothingToClaim();
    error TooMuchWLSale();

    constructor(address icoToken_) Ownable(msg.sender) {
        IERC20(icoToken_).balanceOf(address(this)); // To check the IERC20 contract
        icoToken = icoToken_;

        _wlVestingProp = VestingProp({
            interval: 30 days, // claim every 30 days
            percent: 1250, // claim 12.5% at once
            beginPercent: 500 // claim 5% on the first day
        });
        _pubVestingProp = VestingProp({
            interval: 30 days, // claim every 30 days
            percent: 1250, // claim 12.5% at once
            beginPercent: 1000 // claim 10% on the first day
        });
    }

    /**
     * @dev Contribute ICO
     *
     * Only available when ICO is opened
     */
    function contribute() external payable {
        if (block.timestamp < _wlStartDate || _endDate < block.timestamp) revert IcoNotOpened();

        uint256 fundAmount = msg.value;
        bool isPubSale = _pubStartDate <= block.timestamp;
        uint256 totalPubContributes_ = totalPubContributes;
        uint256 totalWlContributes_ = totalWlContributes;

        if (totalPubContributes_ + totalWlContributes_ + fundAmount > _hardcap) revert HardcapReached();

        UserInfo storage userData = _userInfo[_msgSender()];

        if (isPubSale) {
            userData.pubContributes += fundAmount;
            totalPubContributes = totalPubContributes_ + fundAmount;
        } else {
            uint256 userWlContributes = userData.wlContributes + fundAmount;
            if (userWlContributes > _wlMaxPerUser) revert TooMuchWLSale();
            userData.wlContributes = userWlContributes;
            totalWlContributes = totalWlContributes_ + fundAmount;
        }
        emit UserContributed(_msgSender(), fundAmount, isPubSale);
    }

    /**
     * @dev Claim tokens from his contributed amount
     *
     * Only available after claim date
     */
    function claimTokens() external {
        if (block.timestamp < _claimDate) revert NotClaimableYet();

        UserInfo storage userData = _userInfo[_msgSender()];

        uint256 userWlClaims = userData.wlClaims;
        uint256 userPubClaims = userData.pubClaims;

        (uint256 wlSegAmount, uint256 wlSegTokenAmount) = _calculateVesting(
            userData.wlContributes,
            userWlClaims,
            false
        );
        (uint256 pubSegAmount, uint256 pubSegTokenAmount) = _calculateVesting(
            userData.pubContributes,
            userPubClaims,
            true
        );

        uint256 segTokenAmount = wlSegTokenAmount + pubSegTokenAmount;

        if (segTokenAmount == 0) revert NothingToClaim();

        IERC20(icoToken).universalTransfer(_msgSender(), segTokenAmount);

        userData.wlClaims = userWlClaims + wlSegAmount;
        userData.pubClaims = userPubClaims + pubSegAmount;
        totalWlClaims += wlSegAmount;
        totalPubClaims += pubSegAmount;

        emit UserClaimed(_msgSender(), wlSegTokenAmount, pubSegTokenAmount);
    }

    function _calculateVesting(
        uint256 contributes_,
        uint256 claims_,
        bool isPub_
    ) internal view returns (uint256 segAmount, uint256 segTokenAmount) {
        uint64 claimDate = _claimDate;
        if (block.timestamp < claimDate) return (0, 0);

        VestingProp memory prop = isPub_ ? _pubVestingProp : _wlVestingProp;
        uint256 price = isPub_ ? _pubPrice : _wlPrice;

        uint256 steps = (block.timestamp - claimDate) / prop.interval;
        uint256 percents = uint256(prop.percent) * steps + prop.beginPercent;
        if (percents > 10000) percents = 10000;

        uint256 userClaimableSoFar = (contributes_ * percents) / 10000;
        if (userClaimableSoFar > claims_) segAmount = userClaimableSoFar - claims_;
        segTokenAmount = (segAmount * 1 ether) / price;
    }

    /// @notice View available amounts to claim from the vested tokens
    /// @return - WL claimable token amount
    /// @return - Pub claimable token amount
    function viewAvailableClaims(address account_) external view returns (uint256, uint256) {
        UserInfo memory userData = _userInfo[account_];
        (, uint256 wlAmount) = _calculateVesting(userData.wlContributes, userData.wlClaims, false);
        (, uint256 pubAmount) = _calculateVesting(userData.pubContributes, userData.pubClaims, true);
        return (wlAmount, pubAmount);
    }

    /**
     * @dev Finalize ICO when it was filled or by some reasons
     *
     * It should indicate claim date
     * Only ICO owner is allowed to call this function
     */
    function finalizeIco(uint64 claimDate_) external onlyOwner {
        if (block.timestamp < _wlStartDate) revert IcoNotOpened();
        if (block.timestamp > claimDate_) revert InvalidParam();

        if (_pubStartDate > block.timestamp) _pubStartDate = uint64(block.timestamp);
        _endDate = uint64(block.timestamp);
        _claimDate = claimDate_;
    }

    /**
     * @dev Withdraw remained tokens
     *
     * Only ICO owner is allowed to call this function
     */
    function withdrawRemainedTokens() external onlyOwner {
        if (_endDate > block.timestamp) revert IcoStillOpened();

        // Calculate required token amount for the contributors to claim
        uint256 requiredWlAmount = ((totalWlContributes - totalWlClaims) * 1 ether) / _wlPrice;
        uint256 requiredPubAmount = ((totalPubContributes - totalPubClaims) * 1 ether) / _pubPrice;

        IERC20 icoToken_ = IERC20(icoToken);

        uint256 balanceInContract = icoToken_.balanceOf(address(this));
        uint256 extraAmount = balanceInContract - requiredWlAmount - requiredPubAmount;

        icoToken_.universalTransfer(_msgSender(), extraAmount);
    }

    /**
     * @dev Withdraw contributed funds
     *
     * Only ICO owner is allowed to call this function
     */
    function withdrawFunds() external onlyOwner {
        payable(_msgSender()).sendValue(address(this).balance);
    }

    function viewTotalContributed() external view returns (uint256, uint256) {
        return (totalWlContributes, totalPubContributes);
    }

    function viewTotalClaimed() external view returns (uint256, uint256) {
        return (totalWlClaims, totalPubClaims);
    }

    function viewUserInfo(address account_) external view returns (uint256, uint256, uint256, uint256) {
        return (
            _userInfo[account_].wlContributes,
            _userInfo[account_].pubContributes,
            _userInfo[account_].wlClaims,
            _userInfo[account_].pubClaims
        );
    }

    /**
     * @dev Update ICO dates
     *
     * Only owner is allowed to call this function
     */
    function updateIcoDates(
        uint64 wlStartDate_,
        uint64 pubStartDate_,
        uint64 endDate_,
        uint64 claimDate_
    ) external onlyOwner {
        if (_wlStartDate < block.timestamp) revert IcoAlreadyStarted();

        if (
            block.timestamp > wlStartDate_ ||
            wlStartDate_ > pubStartDate_ ||
            pubStartDate_ > endDate_ ||
            endDate_ > claimDate_
        ) revert InvalidParam();

        _wlStartDate = wlStartDate_;
        _pubStartDate = pubStartDate_;
        _endDate = endDate_;
        _claimDate = claimDate_;
    }

    /// @notice View ICO dates
    function viewIcoDates() external view returns (uint64, uint64, uint64, uint64) {
        return (_wlStartDate, _pubStartDate, _endDate, _claimDate);
    }

    /**
     * @dev Update ICO hardcap / softcap
     *
     * Only owner is allowed to call this function
     */
    function updateCap(uint256 softcap_, uint256 hardcap_) external onlyOwner {
        if (hardcap_ == 0 || softcap_ == 0 || hardcap_ < softcap_) revert InvalidParam();

        _hardcap = hardcap_;
        _softcap = softcap_;
    }

    function viewCap() external view returns (uint256, uint256) {
        return (_softcap, _hardcap);
    }

    function updateVestingProp(
        bool isPub_,
        uint64 interval_,
        uint16 percent_,
        uint16 beginPercent_
    ) external onlyOwner {
        if (percent_ == 0 || percent_ > 10000) revert InvalidParam();
        if (beginPercent_ == 0 || beginPercent_ > 10000) revert InvalidParam();
        if (interval_ == 0) revert InvalidParam();

        VestingProp memory prop = VestingProp({interval: interval_, percent: percent_, beginPercent: beginPercent_});
        if (isPub_) _pubVestingProp = prop;
        else _wlVestingProp = prop;
    }

    function viewVestingProp(bool isPub_) external view returns (uint64, uint16, uint16) {
        VestingProp memory prop = isPub_ ? _pubVestingProp : _wlVestingProp;
        return (prop.interval, prop.percent, prop.beginPercent);
    }

    /**
     * @dev Update user contribute min / max limitation
     *
     * Only owner is allowed to call this function
     */
    function updateWlLimitation(uint256 limit_) external onlyOwner {
        _wlMaxPerUser = limit_;
    }

    function wlMaxPerUser() external view returns (uint256) {
        return _wlMaxPerUser;
    }

    /**
     * @notice Update ICO price
     *
     * @param wlPrice_ ICO price in the whitelisted sale
     * @param pubPrice_ ICO price in the public sale
     *
     * Only owner is allowed to call this function
     */
    function updateIcoPrices(uint256 wlPrice_, uint256 pubPrice_) external onlyOwner {
        if (_wlStartDate < block.timestamp) revert IcoAlreadyStarted();

        if (wlPrice_ == 0 || pubPrice_ == 0) revert InvalidParam();

        _wlPrice = wlPrice_;
        _pubPrice = pubPrice_;
    }

    /**
     * @notice View ICO level1 / leve2 / level3 prices
     */
    function viewIcoPrices() external view returns (uint256, uint256) {
        return (_wlPrice, _pubPrice);
    }

    /**
     * @dev It allows the admin to recover tokens sent to the contract
     * @param token_: the address of the token to withdraw
     * @param amount_: the number of tokens to withdraw
     *
     * This function is only callable by owner
     */
    function recoverToken(address token_, uint256 amount_) external onlyOwner {
        require(token_ != icoToken, "Not allowed token");
        IERC20(token_).universalTransfer(_msgSender(), amount_);
    }

    /**
     * @dev To receive ETH in the ICO contract
     */
    receive() external payable {}
}
