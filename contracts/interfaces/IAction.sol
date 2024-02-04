// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAction {
    error InvalidMonetizer();

    /**
     * @notice Returns dataverse treasury address and fee point.
     * @return address Treasury address.
     * @return uint256 Fee point value.
     */
    function getDataverseTreasuryData() external view returns (address, uint256);

    // /**
    //  * @notice Returns dapp developer's treasury address and fee point.
    //  * @param assetId The asset ID to query.
    //  * @return address Treasury address.
    //  * @return uint256 Fee point value.
    //  */
    // function getDappTreasuryData(bytes32 assetId) external view returns (address, uint256);

    /**
     * @notice Initialize action for a given asset.
     * @param assetId The asset ID act for.
     * @param data Custom data bytes for initializing.
     */
    function initializeAction(bytes32 assetId, bytes calldata data) external payable;

    /**
     * @notice Process action for a given asset.
     * @param assetId The asset ID act for.
     * @param actor The actor.
     * @param data Custom process data bytes.
     * @return bytes Custome returned data bytes.
     */
    function processAction(bytes32 assetId, address actor, bytes calldata data)
        external
        payable
        returns (bytes memory);
}
