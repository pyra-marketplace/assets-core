// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ISubscribeModule {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function initializeSubscribeModule(bytes32 assetId, bytes calldata data) external returns (bytes memory);

    function processSubscribe(bytes32 assetId, address subscriber, bytes memory data)
        external
        returns (uint256, uint256);
}
