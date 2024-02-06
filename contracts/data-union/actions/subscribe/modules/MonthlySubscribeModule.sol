// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SubscribeModuleBase} from "./SubscribeModuleBase.sol";
import {DateTime} from "../../../../libraries/DateTime.sol";
import {IDataUnion} from "../../../IDataUnion.sol";

struct AssetSubscribeDetail {
    address currency;
    uint256 amount;
}

contract MonthlySubscribeModule is SubscribeModuleBase {
    error InvalidInitParams();
    error InvalidDate();
    error InvalidSubscriptionDuration();
    error ModuleDataMismatch();

    using SafeERC20 for IERC20;

    mapping(bytes32 => AssetSubscribeDetail) internal _assetSubscribeDetailById;

    constructor(address subscribeAction) SubscribeModuleBase(subscribeAction) {}

    function initializeSubscribeModule(bytes32 assetId, bytes calldata data)
        external
        onlySubscribeAction
        returns (bytes memory)
    {
        (address currency, uint256 amount) = abi.decode(data, (address, uint256));

        _assetSubscribeDetailById[assetId].currency = currency;
        _assetSubscribeDetailById[assetId].amount = amount;

        return data;
    }

    function processSubscribe(bytes32 assetId, address subscriber, bytes memory data)
        external
        onlySubscribeAction
        returns (uint256, uint256)
    {
        AssetSubscribeDetail storage _subscribeDetail = _assetSubscribeDetailById[assetId];

        (uint256 year, uint256 month, uint256 count) = abi.decode(data, (uint256, uint256, uint256));

        if (!DateTime.isValidDate(year, month, 1)) {
            revert InvalidDate();
        }
        uint256 startAt = DateTime.timestampFromDate(year, month, 1);
        uint256 endAt = DateTime.addMonths(startAt, count);

        IDataUnion.UnionAsset memory unionAsset = IDataUnion(SUBSCRIBE_ACTION.monetizer()).getUnionAsset(assetId);

        if (
            startAt > block.timestamp || endAt < unionAsset.publishAt
                || DateTime.addMonths(startAt, 1) <= unionAsset.publishAt
                || DateTime.subMonths(endAt, 1) >= unionAsset.closeAt
        ) {
            revert InvalidSubscriptionDuration();
        }

        uint256 remainingAmount;
        {
            uint256 dataverseFeeAmount =
                _payDataverseFee(subscriber, _subscribeDetail.currency, _subscribeDetail.amount * count);
            uint256 dappFeeAmount =
                _payDappFee(assetId, subscriber, _subscribeDetail.currency, _subscribeDetail.amount * count);

            remainingAmount = _subscribeDetail.amount * count - dataverseFeeAmount - dappFeeAmount;
        }

        if (remainingAmount > 0) {
            IERC20(_subscribeDetail.currency).safeTransferFrom(subscriber, _assetOwner(assetId), remainingAmount);
        }

        return (startAt, endAt);
    }

    function getAssetSubscribeDetail(bytes32 assetId) external view returns (AssetSubscribeDetail memory) {
        return _assetSubscribeDetailById[assetId];
    }

    function _validateDataIsExpected(bytes memory data, address currency, uint256 amount) internal pure {
        (address decodedCurrency, uint256 decodedAmount) = abi.decode(data, (address, uint256));
        if (decodedAmount != amount || decodedCurrency != currency) {
            revert ModuleDataMismatch();
        }
    }
}
