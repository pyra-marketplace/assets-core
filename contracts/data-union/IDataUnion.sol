// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IDataMonetizer} from "../interfaces/IDataMonetizer.sol";

interface IDataUnion is IDataMonetizer {
    struct UnionAsset {
        string resourceId;
        string folderId;
        uint256 publishAt;
        uint256 closeAt;
        uint256 publicationId;
        address[] actions;
    }

    error NotUnionOwner();
    error UnionAlreadyClosed();

    event UnionClosed(bytes32 assetId, address operator, uint256 closeAt);

    /**
     * @notice Returns UnionAsset of given asset ID.
     * @param assetId The asset ID to query.
     * @return UnionAsset A struct containing DataUnion info.
     */
    function getUnionAsset(bytes32 assetId) external view returns (UnionAsset memory);

    /**
     * @notice Close a DataUnion.
     * @param assetId The asset ID to close.
     * @return uint256 The timestamp of closing.
     */
    function close(bytes32 assetId) external returns (uint256);

    /**
     * @notice Close a DataUnion with signature.
     * @param assetId The asset ID to close.
     * @param signature An EIP712Signature struct containing the needed params to recover signer address.
     * @return uint256 The timestamp of closing.
     */
    function closeWithSig(bytes32 assetId, EIP712Signature calldata signature) external returns (uint256);
}
