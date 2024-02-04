// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {DataMonetizerBase} from "../base/DataMonetizerBase.sol";
import {IAction} from "../interfaces/IAction.sol";
import {IPyraMarketplace} from "./IPyraMarketplace.sol";

contract PyraMarketplace is DataMonetizerBase, IPyraMarketplace {
    constructor() DataMonetizerBase("PyraMarketplace", "1") {}

    /**
     * @inheritdoc IPyraMarketplace
     */
    function getMarketAsset(bytes32 assetId) external view returns (MarketAsset memory) {
        return MarketAsset({
            publishAt: _assetById[assetId].publishAt,
            publicationId: _assetById[assetId].publicationId,
            actions: _assetById[assetId].actions
        });
    }

    /**
     * @inheritdoc DataMonetizerBase
     */
    function _afterPublish(PublishParams calldata, address publisher, uint256, bytes32) internal virtual override {}
}
