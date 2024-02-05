// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DateTime} from "../libraries/DateTime.sol";
import {SharesPool} from "./SharesPool.sol";
import {ShareToken} from "./ShareToken.sol";

contract RevenuePool is Ownable, ERC20 {
    error InsufficientShares();
    error InsufficientRewards();
    error DistributeUnavailable();
    error DistributeDaysExpired();

    struct StakeInfo {
        uint256 timestamp;
        uint256 shares;
    }

    struct DistributeInfo {
        bool triggered;
        uint256 totalRevenue;
        uint256 distributedRevenue;
    }

    using SafeERC20 for IERC20;

    uint256 internal _feePoint;
    SharesPool public immutable SHARES_POOL;

    /**
     * @notice share holder => stake info
     */
    mapping(address => StakeInfo) public shareholdersStakeInfo;

    /**
     * @notice year => month => distribute info
     */
    mapping(uint256 => mapping(uint256 => DistributeInfo)) public monthlyDistributeInfo;

    constructor(
        address initialOwner,
        address sharePool
    ) Ownable(initialOwner) ERC20("Staking Reward Token", "SRT") {
        SHARES_POOL = SharesPool(sharePool);
    }

    function getFeePoint() external view returns (uint256) {
        return _feePoint;
    }

    function setFeePoint(uint256 feePoint) external onlyOwner {
        _feePoint = feePoint;
    }

    function getShareToken() public view returns (address) {
        return SHARES_POOL.getShareInfo(owner()).shareToken;
    }

    function stake(uint256 sharesAmount) external {
        ShareToken shareToken = ShareToken(getShareToken());
        if (shareToken.balanceOf(msg.sender) < sharesAmount) {
            revert InsufficientShares();
        }

        shareholdersStakeInfo[msg.sender].timestamp = block.timestamp;
        shareholdersStakeInfo[msg.sender].shares += sharesAmount;

        shareToken.transfer(address(this), sharesAmount);
    }

    function unstake(uint256 sharesAmount) external {
        if (shareholdersStakeInfo[msg.sender].shares < sharesAmount) {
            revert InsufficientShares();
        }

        shareholdersStakeInfo[msg.sender].shares -= sharesAmount;
        ShareToken(getShareToken()).transfer(msg.sender, sharesAmount);

        claim(msg.sender);
    }

    function claim(address shareholder) public {
        uint256 rewards = getStakingRewards(shareholder);
        _mint(shareholder, rewards);
        shareholdersStakeInfo[shareholder].timestamp = block.timestamp;
    }

    function distribute(uint256 rewards) external {
        (
            uint256 currentYear,
            uint256 currentMonth,
            uint256 currentDay
        ) = DateTime.timestampToDate(block.timestamp);

        /*
            Only the first 5 days of each month are eligible to participate in the distribution.
        */
        if (currentDay > 4) {
            revert DistributeDaysExpired();
        }

        /*
            The share holders who staking shares in this month will not be able to participate in
            this month's distribution, and will have to wait until next month.
        */
        (uint256 stakeYear, uint256 stakeMonth, ) = DateTime
            .timestampToDate(shareholdersStakeInfo[msg.sender].timestamp);
        if (
            stakeYear == currentYear &&
            stakeMonth == currentMonth
        ) {
            revert DistributeUnavailable();
        }

        if (balanceOf(msg.sender) < rewards) {
            revert InsufficientRewards();
        }

        /*
            The "total revenue" is written in contract by the first caller in this month,
            and the same "total revenue" is used when other shareholders calc their distributed revenue.
        */
        if(!monthlyDistributeInfo[currentYear][currentMonth].triggered) {
            monthlyDistributeInfo[currentYear][currentMonth].totalRevenue = address(this).balance;
        }
        uint256 revenue = (monthlyDistributeInfo[currentYear][currentMonth].totalRevenue * rewards) / totalSupply();
        monthlyDistributeInfo[currentYear][currentMonth].distributedRevenue += revenue;

        _burn(msg.sender, rewards);
        payable(msg.sender).transfer(revenue);
    }

    function getStakingRewards(
        address shareholder
    ) public view returns (uint256) {
        return
            shareholdersStakeInfo[shareholder].shares *
            (block.timestamp - shareholdersStakeInfo[shareholder].timestamp);
    }
}
