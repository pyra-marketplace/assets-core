// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IShareSetting {
    function isAccessible(bytes32 assetId, address account) external view returns (bool);

    function getPrice(uint256 supply, uint256 amount) external pure returns (uint256);
}
