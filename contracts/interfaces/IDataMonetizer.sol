// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IDataMonetizer {
    struct Asset {
        // string contentURI; // published data
        bytes data;
        uint256 publishAt; // timestamp
        uint256 publicationId; // publicationNFT tokenId
        address[] actions; // action addresses
    }

    struct PublishParams {
        bytes data;
        address[] actions;
        bytes[] actionInitDatas;
    }

    struct ActParams {
        bytes32 assetId;
        address[] actions;
        bytes[] actionProcessDatas;
    }

    struct AddActionsParams {
        bytes32 assetId;
        address[] actions;
        bytes[] actionInitDatas;
    }

    struct EIP712Signature {
        address signer;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    event AssetPublished(
        bytes32 indexed assetId,
        address indexed publisher,
        uint256 indexed publicationId,
        // string contentURI,
        bytes data,
        address[] actions,
        bytes[] actionInitDatas
    );

    event AssetActed(
        bytes32 indexed assetId,
        address indexed actor,
        address[] actions,
        bytes[] actionProcessDatas,
        bytes[] actionReturnDatas
    );

    event AssetActionsAdded(bytes32 indexed assetId, address[] actions, bytes[] actionInitDatas);

    error NotAssetOwner();
    error SignatureExpired();
    error SignatureMismatch();
    error ResourceNotExists();
    error ArrayLengthNotEqual();
    error ActionNotExists();
    error ActionAlreadyExists();
    error ActionInvalid();
    error InitializeActionFailed();
    error ProcessActionFailed();

    /**
     * @notice Returns the current signature nonce of the given signer.
     * @param signer The address for which to query the nonce.
     * @return uint256 The current nonce of the given signer.
     */
    function getSigNonce(address signer) external view returns (uint256);

    /**
     * @notice Returns the EIP-712 domain separator for this contract.
     * @return bytes32 The domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);

    /**
     * @notice Returns the asset of given asset ID.
     * @param assetId The asset ID to query asset for.
     * @return Asset A struct containing asset informations.
     */
    function getAsset(bytes32 assetId) external view returns (Asset memory);

    /**
     * @notice Returns the owner of an asset.
     * @param assetId The asset ID to query asset owner for.
     * @return address The owner of asset ID.
     */
    function getAssetOwner(bytes32 assetId) external returns (address);

    /**
     * @notice Publish an asset.
     * @param publishParams A PublishParams struct containing the needed params.
     * @return bytes32 Returns the asset ID generated.
     */
    function publish(PublishParams calldata publishParams) external payable returns (bytes32);

    /**
     * @notice Publish an asset with publisher's signature.
     * @param publishParams A PublishParams struct containing the needed params to publish off-chain resource.
     * @param signature An EIP712Signature struct containing the needed params to recover signer address.
     * @return bytes32 Returns the asset ID generated.
     */
    function publishWithSig(PublishParams calldata publishParams, EIP712Signature calldata signature)
        external
        payable
        returns (bytes32);

    /**
     * @notice Act on an asset.
     * @param actParams An ActParams struct containing the needed params to do action for an asset.
     * @return bytes[] Returns data after initializing action.
     */
    function act(ActParams calldata actParams) external payable returns (bytes[] memory);

    /**
     * @notice Act on an asset with actor's signature.
     * @param actParams An ActParams struct containing the needed params to do action for an asset.
     * @param signature An EIP712Signature struct containing the needed params to recover signer address.
     * @return bytes[] Returns data after initializing action.
     */
    function actWithSig(ActParams calldata actParams, EIP712Signature calldata signature)
        external
        payable
        returns (bytes[] memory);

    function addActions(AddActionsParams calldata addActionsParams) external;

    function addActionsWithSig(AddActionsParams calldata addActionsParams, EIP712Signature calldata signature)
        external;
}
