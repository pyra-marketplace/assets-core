// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IDataMonetizer} from "dataverse-contracts-test/contracts/monetizer/interfaces/IDataMonetizer.sol";

interface IDataToken is IDataMonetizer {
    struct TokenAsset {
        string resourceId;
        string fileId;
        uint256 publishAt;
        uint256 publicationId;
        address[] actions;
        bytes32[] images;
    }

    error CollectParamsMismatch();
    error DuplicatePublish();

    /**
     * @notice Returns TokenAsset of given asset ID.
     * @param assetId The asset ID to query.
     * @return TokenAsset A struct containing DataToken info.
     */
    function getTokenAsset(bytes32 assetId) external view returns (TokenAsset memory);
}
