// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IDataMonetizer} from "../../../../interfaces/IDataMonetizer.sol";
import {CollectAction} from "../CollectAction.sol";
import {ICollectModule} from "./ICollectModule.sol";

abstract contract CollectModuleBase is ICollectModule, ERC165 {
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

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(ICollectModule).interfaceId || super.supportsInterface(interfaceId);
    }

    function _assetOwner(bytes32 assetId) internal view returns (address) {
        return IDataMonetizer(COLLECT_ACTION.monetizer()).getAssetOwner(assetId);
    }

    function _payProtocolFee(address payer, address currency, uint256 amount) internal returns (uint256) {
        (address treasury, uint256 feePoint) = COLLECT_ACTION.getProtocolTreasuryData();
        uint256 protocolFee = (amount * feePoint) / BASE_FEE_POINT;
        if (protocolFee > 0) {
            IERC20(currency).safeTransferFrom(payer, treasury, protocolFee);
        }
        return protocolFee;
    }

    function _payDappFee(bytes32 assetId, address payer, address currency, uint256 amount) internal returns (uint256) {
        (address treasury, uint256 feePoint) = COLLECT_ACTION.getDappTreasuryData(assetId);
        uint256 dappFee = (amount * feePoint) / BASE_FEE_POINT;
        if (dappFee > 0) {
            IERC20(currency).safeTransferFrom(payer, treasury, dappFee);
        }
        return dappFee;
    }
}
