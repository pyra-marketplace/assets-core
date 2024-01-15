// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ICollectModule {
    // function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function initializeCollectModule(bytes32 assetId, bytes calldata data) external;

    function processCollect(bytes32 assetId, address collector, bytes calldata data) external returns (bytes memory);
}
