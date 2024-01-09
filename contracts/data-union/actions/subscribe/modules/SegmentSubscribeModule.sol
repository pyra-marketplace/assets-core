// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SubscribeModuleBase} from "./base/SubscribeModuleBase.sol";
import {IDataUnion} from "../../../IDataUnion.sol";

struct AssetSubscribeDetail {
    address currency;
    uint256 amount;
    uint256 segment;
}

contract SegmentSubscribeModule is SubscribeModuleBase {
    error InvalidInitParams();
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
        (address currency, uint256 amount, uint256 segment) = abi.decode(data, (address, uint256, uint256));

        _assetSubscribeDetailById[assetId].currency = currency;
        _assetSubscribeDetailById[assetId].amount = amount;
        _assetSubscribeDetailById[assetId].segment = segment;

        return data;
    }

    function processSubscribe(bytes32 assetId, address subscriber, bytes memory data)
        external
        onlySubscribeAction
        returns (uint256, uint256)
    {
        AssetSubscribeDetail storage _subscribeDetail = _assetSubscribeDetailById[assetId];

        (uint256 startAt, uint256 endAt, bytes memory validateData) = abi.decode(data, (uint256, uint256, bytes));

        _validateDataIsExpected(validateData, _subscribeDetail.currency, _subscribeDetail.amount);

        IDataUnion.UnionAsset memory unionAsset = IDataUnion(SUBSCRIBE_ACTION.monetizer()).getUnionAsset(assetId);

        if (
            startAt > block.number || startAt < endAt || endAt > unionAsset.closeAt
                || endAt - startAt + 1 < _subscribeDetail.segment
        ) {
            revert InvalidSubscriptionDuration();
        }

        uint256 segmentsCount = (endAt - startAt + 1) / _subscribeDetail.segment;

        uint256 totalAmount = segmentsCount * _subscribeDetail.amount;

        uint256 remainingAmount;
        {
            uint256 dataverseFeeAmount = _payDataverseFee(subscriber, _subscribeDetail.currency, totalAmount);
            uint256 dappFeeAmount = _payDappFee(assetId, subscriber, _subscribeDetail.currency, totalAmount);

            remainingAmount = totalAmount - dataverseFeeAmount - dappFeeAmount;
        }

        if (remainingAmount > 0) {
            IERC20(_subscribeDetail.currency).safeTransferFrom(subscriber, _assetOwner(assetId), remainingAmount);
        }

        return (startAt, startAt + segmentsCount * _subscribeDetail.segment - 1);
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
