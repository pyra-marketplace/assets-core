// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ShareToken} from "./ShareToken.sol";
import {RevenuePool} from "./RevenuePool.sol";

contract SharesPool is Ownable {
    error AlreadyCreated();
    error InsufficientPayment();

    event SharesBought(address trader, uint256 amount);
    event SharesSelled(address trader, uint256 amount);

    uint256 public constant BASE_FEE_POINT = 10000;

    uint256 public immutable TREASURY_FEE_POINT;
    address public immutable TREASURY;

    struct ShareInfo {
        address shareToken;
        uint256 feePoint;
        uint256 totalValue;
        address revenuePool;
    }

    mapping(address => ShareInfo) internal _shares;

    constructor(address initialOwner, address payable treasury) Ownable(initialOwner) {
        TREASURY = treasury;
        // CURVE = curve;
    }

    // pyra contract
    // pyra market

    function getShareInfo(address account) external view returns (ShareInfo memory) {
        return _shares[account];
    }

    function create(string memory name, string memory symbol, uint256 feePoint) external {
        if (_shares[msg.sender].shareToken == address(0)) {
            revert AlreadyCreated();
        }
        ShareToken share = new ShareToken(name, symbol);
        RevenuePool revenuePool = new RevenuePool(msg.sender, address(this));
        _shares[msg.sender].shareToken = address(share);
        _shares[msg.sender].feePoint = feePoint;
        _shares[msg.sender].revenuePool = address(revenuePool);
    }

    function buyShares(address publisher, uint256 amount) external payable {
        uint256 sharesPrice = getBuyPrice(publisher, amount);
        uint256 personalFee = (sharesPrice * _shares[publisher].feePoint) / BASE_FEE_POINT;
        uint256 protocolFee = (sharesPrice * TREASURY_FEE_POINT) / BASE_FEE_POINT;

        if (msg.value < sharesPrice + personalFee + protocolFee) {
            revert InsufficientPayment();
        }

        ShareToken(_shares[publisher].shareToken).mint(msg.sender, amount);

        payable(publisher).transfer(personalFee);
        payable(TREASURY).transfer(protocolFee);

        emit SharesBought(msg.sender, amount);
    }

    function sellShares(address publisher, uint256 amount) external payable {
        uint256 sharesPrice = getSellPrice(publisher, amount);
        uint256 personalFee = (sharesPrice * _shares[publisher].feePoint) / BASE_FEE_POINT;
        uint256 protocolFee = (sharesPrice * TREASURY_FEE_POINT) / BASE_FEE_POINT;

        if (msg.value < sharesPrice + personalFee + protocolFee) {
            revert InsufficientPayment();
        }

        ShareToken(_shares[publisher].shareToken).burn(msg.sender, amount);

        payable(publisher).transfer(personalFee);
        payable(TREASURY).transfer(protocolFee);
        payable(msg.sender).transfer(sharesPrice - personalFee - protocolFee);

        emit SharesSelled(msg.sender, amount);
    }

    function getBuyPrice(address account, uint256 amount) public view returns (uint256) {
        return getPrice(ShareToken(_shares[account].shareToken).totalSupply() - amount, amount);
    }

    function getBuyPriceAfterFee(address account, uint256 amount) public view returns (uint256) {
        uint256 sharesPrice = getBuyPrice(account, amount);
        uint256 personalFee = (sharesPrice * _shares[account].feePoint) / BASE_FEE_POINT;
        uint256 protocolFee = (sharesPrice * TREASURY_FEE_POINT) / BASE_FEE_POINT;

        return sharesPrice + personalFee + protocolFee;
    }

    function getSellPrice(address account, uint256 amount) public view returns (uint256) {
        return getPrice(ShareToken(_shares[account].shareToken).totalSupply() - amount, amount);
    }

    function getSellPriceAfterFee(address account, uint256 amount) public view returns (uint256) {
        uint256 sharesPrice = getSellPrice(account, amount);
        uint256 personalFee = (sharesPrice * _shares[account].feePoint) / BASE_FEE_POINT;
        uint256 protocolFee = (sharesPrice * TREASURY_FEE_POINT) / BASE_FEE_POINT;

        return sharesPrice - personalFee - protocolFee;
    }

    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : ((supply - 1) * (supply) * (2 * (supply - 1) + 1)) / 6;
        uint256 sum2 = supply == 0 && amount == 1
            ? 0
            : ((supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1)) / 6;
        uint256 summation = sum2 - sum1;
        return (summation * 1 ether) / 16000;
    }
}
