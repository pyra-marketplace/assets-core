// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IDataMonetizer} from "../../../../interfaces/IDataMonetizer.sol";
import {SubscribeAction} from "../SubscribeAction.sol";
import {ISubscribeModule} from "./ISubscribeModule.sol";

abstract contract SubscribeModuleBase is ERC165 {
    error NotSubscribeAction();

    using SafeERC20 for IERC20;

    uint256 internal constant BASE_FEE_POINT = 10000;

    SubscribeAction public immutable SUBSCRIBE_ACTION;

    constructor(address subscribeAction) {
        SUBSCRIBE_ACTION = SubscribeAction(subscribeAction);
    }

    modifier onlySubscribeAction() {
        if (msg.sender != address(SUBSCRIBE_ACTION)) {
            revert NotSubscribeAction();
        }
        _;
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ISubscribeModule).interfaceId || super.supportsInterface(interfaceId);
    }

    function _assetOwner(bytes32 assetId) internal view returns (address) {
        return IDataMonetizer(SUBSCRIBE_ACTION.monetizer()).getAssetOwner(assetId);
    }

    function _payProtocolFee(address payer, address currency, uint256 amount) internal returns (uint256) {
        (address treasury, uint256 feePoint) = SUBSCRIBE_ACTION.getProtocolTreasuryData();
        uint256 protocolFee = (amount * feePoint) / BASE_FEE_POINT;
        if (protocolFee > 0) {
            IERC20(currency).safeTransferFrom(payer, treasury, protocolFee);
        }
        return protocolFee;
    }

    function _payDappFee(bytes32 assetId, address payer, address currency, uint256 amount) internal returns (uint256) {
        (address treasury, uint256 feePoint) = SUBSCRIBE_ACTION.getDappTreasuryData(assetId);
        uint256 dappFee = (amount * feePoint) / BASE_FEE_POINT;
        if (dappFee > 0) {
            IERC20(currency).safeTransferFrom(payer, treasury, dappFee);
        }
        return dappFee;
    }
}