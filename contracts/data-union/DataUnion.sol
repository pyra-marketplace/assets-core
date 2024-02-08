// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {DataMonetizerBase} from "../base/DataMonetizerBase.sol";
import {IAction} from "../interfaces/IAction.sol";
import {IDataUnion} from "./IDataUnion.sol";

contract DataUnion is DataMonetizerBase, IDataUnion {
    bytes32 constant CLOSE_WITH_SIG_TYPEHASH =
        keccak256(bytes("CloseWithSig(bytes32 assetId,uint256 nonce,uint256 deadline)"));

    mapping(bytes32 => uint256) _unionCloseAt;

    constructor() DataMonetizerBase("DataUnion", "1") {}

    /**
     * @inheritdoc IDataUnion
     */
    function getUnionAsset(bytes32 assetId) external view returns (UnionAsset memory) {
        (string memory resourceId, string memory folderId) = abi.decode(_assetById[assetId].data, (string, string));
        return UnionAsset({
            resourceId: resourceId,
            folderId: folderId,
            publishAt: _assetById[assetId].publishAt,
            closeAt: _unionCloseAt[assetId],
            publicationId: _assetById[assetId].publicationId,
            actions: _assetById[assetId].actions
        });
    }

    /**
     * @inheritdoc IDataUnion
     */
    function close(bytes32 assetId) external returns (uint256) {
        return _close(assetId, msg.sender);
    }

    /**
     * @inheritdoc IDataUnion
     */
    function closeWithSig(bytes32 assetId, EIP712Signature calldata signature) external returns (uint256) {
        address recoveredAddr = _recoverSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(CLOSE_WITH_SIG_TYPEHASH, assetId, _sigNonces[signature.signer]++, signature.deadline)
                )
            ),
            signature
        );

        if (signature.signer != recoveredAddr) {
            revert SignatureMismatch();
        }

        return _close(assetId, signature.signer);
    }

    /**
     * @inheritdoc DataMonetizerBase
     */
    function _afterPublish(PublishParams calldata, address, uint256, bytes32 assetId) internal virtual override {
        _unionCloseAt[assetId] = type(uint256).max;
    }

    function _close(bytes32 assetId, address signer) internal returns (uint256) {
        if (block.timestamp >= _unionCloseAt[assetId]) {
            revert UnionAlreadyClosed();
        }

        address assetOwner = getAssetOwner(assetId);
        if (signer != assetOwner) {
            revert NotUnionOwner();
        }

        _unionCloseAt[assetId] = block.timestamp;

        emit UnionClosed(assetId, signer, block.timestamp);

        return block.timestamp;
    }
}