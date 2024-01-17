// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IDataMonetizer} from "dataverse-contracts-test/contracts/monetizer/interfaces/IDataMonetizer.sol";
import {CollectModuleBase} from "./CollectModuleBase.sol";
import {ICollectModule} from "./ICollectModule.sol";

struct AssetCollectDetail {
    uint256 totalSupply;
    uint256 currentCollects;
    uint256 amount;
    address currency;
}

contract FeeCollectModule is CollectModuleBase {
    error InitParamsInvalid();
    error ExceedTotalSupply();
    error ModuleDataMismatch();

    using SafeERC20 for IERC20;

    mapping(bytes32 => AssetCollectDetail) internal _assetCollectDetailById;

    constructor(address collectAction) CollectModuleBase(collectAction) {}

    /**
     * @inheritdoc ICollectModule
     */
    function initializeCollectModule(bytes32 assetId, bytes calldata data) external onlyCollectAction {
        (uint256 totalSupply, address currency, uint256 amount) = abi.decode(data, (uint256, address, uint256));
        if (totalSupply == 0 || amount == 0) {
            revert InitParamsInvalid();
        }

        AssetCollectDetail memory _publicationData =
            AssetCollectDetail({totalSupply: totalSupply, currentCollects: 0, amount: amount, currency: currency});

        _assetCollectDetailById[assetId] = _publicationData;
    }

    /**
     * @inheritdoc ICollectModule
     */
    function processCollect(bytes32 assetId, address collector, bytes calldata data)
        external
        onlyCollectAction
        returns (bytes memory)
    {
        AssetCollectDetail storage targetCollectDetail = _assetCollectDetailById[assetId];
        if (targetCollectDetail.currentCollects >= targetCollectDetail.totalSupply) {
            revert ExceedTotalSupply();
        }
        _validateDataIsExpected(data, targetCollectDetail.currency, targetCollectDetail.amount);

        ++targetCollectDetail.currentCollects;

        uint256 dataverseFeeAmount =
            _payDataverseFee(collector, targetCollectDetail.currency, targetCollectDetail.amount);
        uint256 dappFeeAmount =
            _payDappFee(assetId, collector, targetCollectDetail.currency, targetCollectDetail.amount);

        uint256 remainingAmount = targetCollectDetail.amount - dataverseFeeAmount - dappFeeAmount;

        if (remainingAmount > 0) {
            IERC20(targetCollectDetail.currency).safeTransferFrom(collector, _assetOwner(assetId), remainingAmount);
        }

        return new bytes(0);
    }

    function getAssetCollectDetail(bytes32 assetId) external view returns (AssetCollectDetail memory) {
        return _assetCollectDetailById[assetId];
    }

    function _validateDataIsExpected(bytes calldata data, address currency, uint256 amount) internal pure {
        (address decodedCurrency, uint256 decodedAmount) = abi.decode(data, (address, uint256));
        if (decodedAmount != amount || decodedCurrency != currency) {
            revert ModuleDataMismatch();
        }
    }
}
