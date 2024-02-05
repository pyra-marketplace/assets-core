// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ActionBase} from "../../../base/ActionBase.sol";
import {IActionConfig} from "../../../interfaces/IActionConfig.sol";
import {IDataMonetizer} from "../../../interfaces/IDataMonetizer.sol";
import {TierKey} from "./token/TierKey.sol";
import {SharesPool} from "../../personal/SharesPool.sol";

contract TradeAction is ActionBase {
    using SafeERC20 for IERC20;
    using Math for uint256;

    enum TradeType {
        Buy,
        Sell
    }

    struct TierKeyData {
        address[4] tierKeys;
        uint256[4] expiredPeriods;
        uint256[4] totalValues;
        uint256 feePoint;
    }

    error InvalidTier();
    error InsufficientPayment();

    SharesPool public immutable SHARES_POOL;

    uint256 internal constant REVENUE_POOL_FEE_POINT = 1000;

    mapping(bytes32 => TierKeyData) internal _assetTierkeyData;

    /**
     * @notice tier => keyId => manufacture time
     */
    mapping(uint256 => mapping(uint256 => uint256)) _tierKeyMintSnapshot;

    constructor(
        address actionConfig,
        address monetizer,
        address personalShares
    ) ActionBase(actionConfig, monetizer) {
        SHARES_POOL = SharesPool(personalShares);
    }

    function initializeAction(
        bytes32 assetId,
        bytes calldata data
    ) external payable monetizerRestricted {
        (
            string memory name,
            string memory symbol,
            uint256 feePoint,
            uint256[4] memory expiredPeriods
        ) = abi.decode(data, (string, string, uint256, uint256[4]));

        for (uint256 i = 0; i < 4; ++i) {
            TierKey tierKey = new TierKey(name, symbol);
            _assetTierkeyData[assetId].tierKeys[i] = address(tierKey);
            tierKey.mint(_assetOwner(assetId));
        }
        _assetTierkeyData[assetId].feePoint = feePoint;
        _assetTierkeyData[assetId].expiredPeriods = expiredPeriods;
    }

    function processAction(
        bytes32 assetId,
        address trader,
        bytes calldata data
    ) external payable monetizerRestricted returns (bytes memory) {
        (TradeType tradeType, bytes memory extra) = abi.decode(
            data,
            (TradeType, bytes)
        );

        uint256 tier;
        uint256 keyId;
        uint256 keyPrice;
        if (tradeType == TradeType.Buy) {
            (tier) = abi.decode(extra, (uint256));
            (keyId, keyPrice) = _buyTierKey(assetId, trader, tier);
        }
        if (tradeType == TradeType.Sell) {
            (tier, keyId) = abi.decode(extra, (uint256, uint256));
            (keyPrice) = _sellTierKey(assetId, trader, tier, keyId);
        }

        return abi.encode(tier, keyId, keyPrice);
    }

    function _buyTierKey(
        bytes32 assetId,
        address trader,
        uint256 tier
    ) internal returns (uint256, uint256) {
        if (tier >= 4) {
            revert InvalidTier();
        }
        uint256 keyPrice = getTierKeyPrice(assetId, tier, TradeType.Buy);
        uint256 ownerFee = (keyPrice * _assetTierkeyData[assetId].feePoint) /
            BASE_FEE_POINT;
        uint256 revenuePoolFee = (keyPrice * REVENUE_POOL_FEE_POINT) /
            BASE_FEE_POINT;

        if (msg.value < keyPrice + ownerFee + revenuePoolFee) {
            revert InsufficientPayment();
        }

        _assetTierkeyData[assetId].totalValues[tier] += keyPrice;

        payable(_assetOwner(assetId)).transfer(ownerFee);
        payable(SHARES_POOL.getShareInfo(trader).revenuePool).transfer(
            revenuePoolFee
        );

        TierKey targetTierKey = TierKey(
            _assetTierkeyData[assetId].tierKeys[tier]
        );
        uint256 keyId = targetTierKey.mint(trader);
        _tierKeyMintSnapshot[tier][keyId] =
            block.timestamp;

        return (keyId, keyPrice);
    }

    function _sellTierKey(
        bytes32 assetId,
        address trader,
        uint256 tier,
        uint256 keyId
    ) internal returns (uint256) {
        if (tier >= 4) {
            revert InvalidTier();
        }
        uint256 keyPrice = getTierKeyPrice(assetId, tier, TradeType.Sell);
        uint256 depreciatedKeyPrice = (keyPrice *
            (block.timestamp - _tierKeyMintSnapshot[tier][keyId])) /
            _assetTierkeyData[assetId].expiredPeriods[tier];

        uint256 ownerFee = (keyPrice * _assetTierkeyData[assetId].feePoint) /
            BASE_FEE_POINT;
        uint256 revenuePoolFee = (keyPrice * REVENUE_POOL_FEE_POINT) /
            BASE_FEE_POINT;

        _assetTierkeyData[assetId].totalValues[tier] -= keyPrice;

        payable(_assetOwner(assetId)).transfer(ownerFee);
        payable(SHARES_POOL.getShareInfo(_assetOwner(assetId)).revenuePool)
            .transfer(revenuePoolFee + depreciatedKeyPrice);

        TierKey(_assetTierkeyData[assetId].tierKeys[tier]).burn(trader, keyId);
        return keyPrice - depreciatedKeyPrice;
    }

    function getTierKeyPrice(
        bytes32 assetId,
        uint256 tier,
        TradeType tradeType
    ) public view returns (uint256) {
        uint256 totalSupply;
        if (tradeType == TradeType.Buy) {
            totalSupply = TierKey(_assetTierkeyData[assetId].tierKeys[tier])
                .totalSupply();
        } else {
            totalSupply =
                TierKey(_assetTierkeyData[assetId].tierKeys[tier])
                    .totalSupply() -
                1;
        }
        uint256 x = tier *
            (TierKey(_assetTierkeyData[assetId].tierKeys[tier]).totalSupply() +
                1) *
            1 ether;
        return x.log2();
    }

    function getTierKeyPriceAfterFee(
        bytes32 assetId,
        uint256 tier,
        TradeType tradeType
    ) public view returns (uint256) {
        uint256 keyPrice = getTierKeyPrice(assetId, tier, tradeType);
        uint256 ownerFee = (keyPrice * _assetTierkeyData[assetId].feePoint) /
            BASE_FEE_POINT;
        uint256 revenuePoolFee = (keyPrice * REVENUE_POOL_FEE_POINT) /
            BASE_FEE_POINT;

        if (tradeType == TradeType.Buy) {
            return keyPrice + ownerFee + revenuePoolFee;
        } else {
            return keyPrice - ownerFee - revenuePoolFee;
        }
    }

    function getAssetTierKeyData(
        bytes32 assetId
    ) external view returns (TierKeyData memory) {
        return _assetTierkeyData[assetId];
    }

    function _payDataverseFee(
        address payer,
        address currency,
        uint256 amount
    ) internal returns (uint256) {
        (address treasury, uint256 feePoint) = getDataverseTreasuryData();
        uint256 dataverseFeeAmount = (amount * feePoint) / BASE_FEE_POINT;
        if (dataverseFeeAmount > 0) {
            IERC20(currency).safeTransferFrom(
                payer,
                treasury,
                dataverseFeeAmount
            );
        }
        return dataverseFeeAmount;
    }

    function _assetOwner(bytes32 assetId) internal returns (address) {
        return IDataMonetizer(monetizer).getAssetOwner(assetId);
    }
}
