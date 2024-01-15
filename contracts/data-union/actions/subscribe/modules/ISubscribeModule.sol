// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ISubscribeModule {
    function initializeSubscribeModule(bytes32 assetId, bytes calldata data) external;

    function processSubscribe(bytes32 assetId, address subscriber, bytes memory data)
        external
        returns (uint256, uint256);
}
