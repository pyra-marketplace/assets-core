// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IDataMonetizer} from "dataverse-contracts-test/contracts/monetizer/interfaces/IDataMonetizer.sol";

interface IDataUnion is IDataMonetizer {
    struct UnionAsset {
        string resourceId;
        uint256 publishAt;
        uint256 closeAt;
        uint256 publicationId;
        address[] actions;
        bytes32[] images;
    }

    error DuplicatePublish();
    error NotUnionOwner();
    error UnionAlreadyClosed();

    function getUnionAsset(bytes32 assetId) external view returns (UnionAsset memory);

    function close(bytes32 assetId) external returns (uint256);

    function closeWithSig(bytes32 assetId, EIP712Signature calldata signature) external returns (uint256);
}
