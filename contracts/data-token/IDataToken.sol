// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IDataMonetizer} from "../interfaces/IDataMonetizer.sol";

interface IDataToken is IDataMonetizer {
    struct TokenAsset {
        string resourceId;
        string fileId;
        uint256 publishAt;
        uint256 publicationId;
        address[] actions;
    }

    /**
     * @notice Returns TokenAsset of given asset ID.
     * @param assetId The asset ID to query.
     * @return TokenAsset A struct containing DataToken info.
     */
    function getTokenAsset(bytes32 assetId) external view returns (TokenAsset memory);
}
