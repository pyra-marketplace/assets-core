// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IDataMonetizer} from "dataverse-contracts-test/contracts/monetizer/interfaces/IDataMonetizer.sol";
import {CollectAction} from "../CollectAction.sol";
import {ICollectModule} from "./ICollectModule.sol";

abstract contract CollectModuleBase is ICollectModule {
    error NotCollectAction();

    using SafeERC20 for IERC20;

    uint256 internal constant BASE_FEE_POINT = 10000;

    CollectAction public immutable COLLECT_ACTION;

    constructor(address collectAction) {
        COLLECT_ACTION = CollectAction(collectAction);
    }

    modifier onlyCollectAction() {
        if (msg.sender != address(COLLECT_ACTION)) {
            revert NotCollectAction();
        }
        _;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(ICollectModule).interfaceId;
    }

    function _assetOwner(bytes32 assetId) internal returns (address) {
        return IDataMonetizer(COLLECT_ACTION.monetizer()).getAssetOwner(assetId);
    }

    function _payDataverseFee(address payer, address currency, uint256 amount) internal returns (uint256) {
        (address treasury, uint256 feePoint) = COLLECT_ACTION.getDataverseTreasuryData();
        uint256 dataverseFeeAmount = (amount * feePoint) / BASE_FEE_POINT;
        if (dataverseFeeAmount > 0) {
            IERC20(currency).safeTransferFrom(payer, treasury, dataverseFeeAmount);
        }
        return dataverseFeeAmount;
    }

    function _payDappFee(bytes32 assetId, address payer, address currency, uint256 amount) internal returns (uint256) {
        (address treasury, uint256 feePoint) = COLLECT_ACTION.getDappTreasuryData(assetId);
        uint256 dappFeeAmount = (amount * feePoint) / BASE_FEE_POINT;
        if (dappFeeAmount > 0) {
            IERC20(currency).safeTransferFrom(payer, treasury, dappFeeAmount);
        }
        return dappFeeAmount;
    }
}
