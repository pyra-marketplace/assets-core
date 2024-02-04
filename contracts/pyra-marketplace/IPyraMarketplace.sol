// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IDataMonetizer} from "../interfaces/IDataMonetizer.sol";

interface IPyraMarketplace is IDataMonetizer {
    struct MarketAsset {
        uint256 publishAt;
        uint256 publicationId;
        address[] actions;
    }

    /**
     * @notice Returns TokenAsset of given asset ID.
     * @param assetId The asset ID to query.
     * @return TokenAsset A struct containing DataToken info.
     */
    function getMarketAsset(bytes32 assetId) external view returns (MarketAsset memory);
}
