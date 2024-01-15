// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IShareSetting} from "./IShareSetting.sol";
import {ShareAction} from "../ShareAction.sol";

abstract contract ShareSettingBase is IShareSetting, ERC165 {
    ShareAction public immutable SHARE_ACTION;

    constructor(address shareAction) {
        SHARE_ACTION = ShareAction(shareAction);
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IShareSetting).interfaceId || super.supportsInterface(interfaceId);
    }
}
