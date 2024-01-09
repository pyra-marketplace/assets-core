// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DataMonetizerBase} from "dataverse-contracts-test/contracts/monetizer/base/DataMonetizerBase.sol";
import {IAction} from "dataverse-contracts-test/contracts/monetizer/interfaces/IAction.sol";
import {IDataToken} from "./IDataToken.sol";

contract DataToken is DataMonetizerBase, IDataToken {
    constructor(address dappTableRegistry) DataMonetizerBase("DataToken", "1", dappTableRegistry) {}

    function getTokenAsset(bytes32 assetId) external view returns (TokenAsset memory) {
        string memory fileId = abi.decode(_assetById[assetId].data, (string));
        return TokenAsset({
            resourceId: _assetById[assetId].resourceId,
            fileId: fileId,
            publishAt: _assetById[assetId].publishAt,
            publicationId: _assetById[assetId].publicationId,
            actions: _assetById[assetId].actions,
            images: _assetById[assetId].images
        });
    }

    function _afterPublish(PublishParams calldata publishParams, bytes32 assetId) internal virtual override {}
}
