// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ActionBase} from "dataverse-contracts-test/contracts/monetizer/base/ActionBase.sol";
import {IActionConfig} from "dataverse-contracts-test/contracts/monetizer/interfaces/IActionConfig.sol";
import {ShareToken} from "./token/ShareToken.sol";

contract ShareAction is ActionBase {
    using SafeERC20 for IERC20;

    enum TradeType {
        Buy,
        Sell
    }

    struct ShareData {
        address monetizer;
        address shareToken;
        uint256 totalValue;
        uint256 totalSupply;
        address currency;
        uint256 creatorFeePoint;
        address creator;
    }

    mapping(bytes32 => ShareData) public assetShareData;

    constructor(address actionConfig, address monetizer) ActionBase(actionConfig, monetizer) {}

    function initializeAction(bytes32 assetId, bytes calldata data)
        external
        monetizerRestricted
        returns (bytes memory)
    {
        (
            string memory name,
            string memory symbol,
            address currency,
            uint256 creatorFeePoint,
            uint256 initialSupply,
            address creator
        ) = abi.decode(data, (string, string, address, uint256, uint256, address));
        ShareToken shareToken = new ShareToken(name, symbol);
        assetShareData[assetId].monetizer = msg.sender;
        assetShareData[assetId].currency = currency;
        assetShareData[assetId].creatorFeePoint = creatorFeePoint;
        assetShareData[assetId].shareToken = address(shareToken);
        assetShareData[assetId].creator = creator;
        _buyShare(assetId, creator, initialSupply);

        return data;
    }

    function processAction(bytes32 assetId, address trader, bytes calldata data)
        external
        monetizerRestricted
        returns (bytes memory)
    {
        (TradeType tradeType, uint256 amount) = abi.decode(data, (TradeType, uint256));
        if (tradeType == TradeType.Buy) {
            _buyShare(assetId, trader, amount);
        }
        if (tradeType == TradeType.Sell) {
            _sellShare(assetId, trader, amount);
        }
        return data;
    }

    function _buyShare(bytes32 assetId, address trader, uint256 amount) internal {
        uint256 price = getBuyPrice(assetId, amount);
        uint256 creatorFee = (price * assetShareData[assetId].creatorFeePoint) / BASE_FEE_POINT;
        IERC20(assetShareData[assetId].currency).safeTransferFrom(trader, assetShareData[assetId].creator, creatorFee);
        IERC20(assetShareData[assetId].currency).safeTransferFrom(trader, address(this), price - creatorFee);

        ShareToken(assetShareData[assetId].shareToken).mint(trader, amount);
        assetShareData[assetId].totalSupply += amount;
        assetShareData[assetId].totalValue += price;
    }

    function _sellShare(bytes32 assetId, address trader, uint256 amount) internal {
        uint256 price = getSellPrice(assetId, amount);
        uint256 creatorFee = (price * assetShareData[assetId].creatorFeePoint) / BASE_FEE_POINT;
        IERC20(assetShareData[assetId].currency).safeTransferFrom(trader, assetShareData[assetId].creator, creatorFee);
        IERC20(assetShareData[assetId].currency).transfer(trader, price - creatorFee);

        ShareToken(assetShareData[assetId].shareToken).burn(trader, amount);
        assetShareData[assetId].totalSupply -= amount;
        assetShareData[assetId].totalValue -= price;
    }

    function getBuyPrice(bytes32 assetId, uint256 amount) public view returns (uint256) {
        return getPrice(assetShareData[assetId].totalSupply, amount);
    }

    function getSellPrice(bytes32 assetId, uint256 amount) public view returns (uint256) {
        return getPrice(assetShareData[assetId].totalSupply - amount, amount);
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
