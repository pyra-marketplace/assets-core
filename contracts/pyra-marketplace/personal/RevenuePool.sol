// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SharesPool} from "./SharesPool.sol";
import {ShareToken} from "./token/ShareToken.sol";

contract RevenuePool is Ownable, ERC20 {
    error NotOwner();
    error NotShareHolder();
    error LockPeriodNotOver();
    error InsufficientShares();
    error InsufficientTokens();

    struct LockPoint {
        uint256 timestamp;
        uint256 shares;
        uint256 balance; // WETH balance
            // uint256 expenses; // WETH expenses
            // uint256 claimed;
    }

    using SafeERC20 for IERC20;

    ShareToken public immutable S_SHARE_TOKEN;

    // IERC20 public immutable CURRENCY; // WETH

    uint256 internal _feePoint;
    // uint256 internal _expenses;
    SharesPool public immutable SHARES_POOL;
    uint256 public constant LOCK_PERIOD = 7 days;

    mapping(address => LockPoint) public lockPoints;

    constructor(address initialOwner, address sharePool) Ownable(initialOwner) ERC20("RevenuePool Token", "RPT") {
        SHARES_POOL = SharesPool(sharePool);
        // CURRENCY = IERC20(currency);
    }

    function getFeePoint() external view returns (uint256) {
        return _feePoint;
    }

    function setFeePoint(uint256 feePoint) external onlyOwner {
        _feePoint = feePoint;
    }

    function stake(uint256 sharesAmount) external {
        ShareToken shareToken = ShareToken(SHARES_POOL.getShareInfo(owner()).shareToken);
        if (shareToken.balanceOf(msg.sender) < sharesAmount) {
            revert InsufficientShares();
        }
        lockPoints[msg.sender] =
            LockPoint({timestamp: block.timestamp, shares: sharesAmount, balance: address(this).balance});
        // expenses: _expenses

        shareToken.transfer(address(this), sharesAmount);
    }

    function unstake(uint256 sharesAmount) external {
        if (block.number < lockPoints[msg.sender].timestamp + LOCK_PERIOD) {
            revert LockPeriodNotOver();
        }
        if (lockPoints[msg.sender].shares < sharesAmount) {
            revert InsufficientShares();
        }
        ShareToken shareToken = ShareToken(SHARES_POOL.getShareInfo(owner()).shareToken);

        lockPoints[msg.sender].shares -= sharesAmount;
        shareToken.transfer(msg.sender, sharesAmount);
    }

    function claim() external {
        uint256 rewards = getStakingRewards(msg.sender);
        _mint(msg.sender, rewards);
        // _expenses += rewards;
        // IERC20(currency).transfer(account, rewards);
    }

    function withdraw(uint256 renvenueTokenAmount) external {
        if (block.number < lockPoints[msg.sender].timestamp + LOCK_PERIOD) {
            revert LockPeriodNotOver();
        }
        if (balanceOf(msg.sender) < renvenueTokenAmount) {
            revert InsufficientTokens();
        }
        _burn(msg.sender, renvenueTokenAmount);

        uint256 revenue = address(this).balance * renvenueTokenAmount / totalSupply();
        payable(msg.sender).transfer(revenue);
        // CURRENCY.safeTransfer(msg.sender, revenue);
    }

    function getStakingRewards(address shareHolder) public view returns (uint256) {
        return lockPoints[shareHolder].shares * (block.timestamp - lockPoints[shareHolder].timestamp);
    }

    // function getRewards(address account) public view returns (uint256) {
    //     uint256 deltaIncome = IERC20(currency).balanceOf(address(this)) +
    //         _expenses -
    //         lockPoints[account].balance -
    //         lockPoints[account].expenses;

    //     uint256 revenue = (deltaIncome * lockPoints[account].shares) /
    //         SHARES_POOL.balanceOf(address(this));

    //     return revenue;
    // }
}
