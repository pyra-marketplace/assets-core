// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {DataMonetizerBase} from "../base/DataMonetizerBase.sol";
import {IAction} from "../interfaces/IAction.sol";
import {IDataToken} from "./IDataToken.sol";

contract DataToken is DataMonetizerBase, IDataToken {
    constructor() DataMonetizerBase("DataToken", "1") {}

    /**
     * @inheritdoc IDataToken
     */
    function getTokenAsset(bytes32 assetId) external view returns (TokenAsset memory) {
        (string memory resourceId, string memory fileId) = abi.decode(_assetById[assetId].data, (string, string));
        return TokenAsset({
            resourceId: resourceId,
            fileId: fileId,
            publishAt: _assetById[assetId].publishAt,
            publicationId: _assetById[assetId].publicationId,
            actions: _assetById[assetId].actions
        });
    }

    /**
     * @inheritdoc DataMonetizerBase
     */
    function _afterPublish(
        PublishParams calldata publishParams,
        address publisher,
        uint256 publicationId,
        bytes32 assetId
    ) internal virtual override {}
}
