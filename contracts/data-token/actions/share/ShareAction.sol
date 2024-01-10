// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ActionBase} from "dataverse-contracts-test/contracts/monetizer/base/ActionBase.sol";
import {IActionConfig} from "dataverse-contracts-test/contracts/monetizer/interfaces/IActionConfig.sol";
import {IDataMonetizer} from "dataverse-contracts-test/contracts/monetizer/interfaces/IDataMonetizer.sol";
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
        uint256 feePoint;
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
            uint256 feePoint,
            uint256 initialSupply,
            address creator
        ) = abi.decode(data, (string, string, address, uint256, uint256, address));
        ShareToken shareToken = new ShareToken(name, symbol);
        assetShareData[assetId].monetizer = msg.sender;
        assetShareData[assetId].currency = currency;
        assetShareData[assetId].feePoint = feePoint;
        assetShareData[assetId].shareToken = address(shareToken);
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
        uint256 ownerFeeAmount = (price * assetShareData[assetId].feePoint) / BASE_FEE_POINT;
        uint256 dappFeeAmount = _payDappFee(assetId, trader, assetShareData[assetId].currency, price);
        uint256 dataverseFeeAmount = _payDataverseFee(trader, assetShareData[assetId].currency, price);
        IERC20(assetShareData[assetId].currency).safeTransferFrom(trader, _assetOwner(assetId), ownerFeeAmount);
        IERC20(assetShareData[assetId].currency).safeTransferFrom(trader, address(this), price - dappFeeAmount - dataverseFeeAmount - ownerFeeAmount);

        ShareToken(assetShareData[assetId].shareToken).mint(trader, amount);
        assetShareData[assetId].totalSupply += amount;
        assetShareData[assetId].totalValue += price;
    }

    function _sellShare(bytes32 assetId, address trader, uint256 amount) internal {
        uint256 price = getSellPrice(assetId, amount);
        uint256 ownerFeeAmount = (price * assetShareData[assetId].feePoint) / BASE_FEE_POINT;
        uint256 dappFeeAmount = _payDappFee(assetId, trader, assetShareData[assetId].currency, price);
        uint256 dataverseFeeAmount = _payDataverseFee(trader, assetShareData[assetId].currency, price);
        IERC20(assetShareData[assetId].currency).safeTransferFrom(trader, _assetOwner(assetId), ownerFeeAmount);
        IERC20(assetShareData[assetId].currency).transfer(trader, price - dappFeeAmount - dataverseFeeAmount - ownerFeeAmount);

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

    function _payDataverseFee(address payer, address currency, uint256 amount) internal returns (uint256) {
        (address treasury, uint256 feePoint) = getDataverseTreasuryData();
        uint256 dataverseFeeAmount = (amount * feePoint) / BASE_FEE_POINT;
        if (dataverseFeeAmount > 0) {
            IERC20(currency).safeTransferFrom(payer, treasury, dataverseFeeAmount);
        }
        return dataverseFeeAmount;
    }

    function _payDappFee(bytes32 assetId, address payer, address currency, uint256 amount) internal returns (uint256) {
        IDataMonetizer.Asset memory asset = IDataMonetizer(monetizer).getAsset(assetId);
        (address treasury, uint256 feePoint) = getDappTreasuryData(asset.resourceId);
        uint256 dappFeeAmount = (amount * feePoint) / BASE_FEE_POINT;
        if (dappFeeAmount > 0) {
            IERC20(currency).safeTransferFrom(payer, treasury, dappFeeAmount);
        }
        return dappFeeAmount;
    }

    function _assetOwner(bytes32 assetId) internal returns (address) {
        return IDataMonetizer(monetizer).getAssetOwner(assetId);
    }
}
