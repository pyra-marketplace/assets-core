// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ShareSettingBase} from "./ShareSettingBase.sol";
import {ShareAction} from "../ShareAction.sol";

contract ShareSetting is ShareSettingBase {
    constructor(address shareAction) ShareSettingBase(shareAction) {}

    function isAccessible(bytes32 assetId, address account) external view returns (bool) {
        address shareToken = SHARE_ACTION.getAssetShareData(assetId).shareToken;
        return IERC20(shareToken).balanceOf(account) > 0;
    }

    function getPrice(uint256 supply, uint256 amount) external pure returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : ((supply - 1) * (supply) * (2 * (supply - 1) + 1)) / 6;
        uint256 sum2 = supply == 0 && amount == 1
            ? 0
            : ((supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1)) / 6;
        uint256 summation = sum2 - sum1;
        return (summation * 1 ether) / 16000;
    }
}
