// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EIP712Encoder} from "../libraries/EIP712Encoder.sol";
import {IDataMonetizer} from "../interfaces/IDataMonetizer.sol";
import {IAction} from "../interfaces/IAction.sol";

abstract contract DataMonetizerBase is ERC721Enumerable, EIP712, ReentrancyGuard, IDataMonetizer {
    bytes32 constant PUBLISH_WITH_SIG_TYPEHASH = keccak256(
        bytes(
            "PublishWithSig(string resourceId,bytes data,address[] actions,bytes[] actionInitDatas,bytes32[] images,uint256 nonce,uint256 deadline)"
        )
    );

    bytes32 constant ACT_WITH_SIG_TYPEHASH = keccak256(
        bytes("ActWithSig(bytes32 assetId,address[] actions,bytes[] actionProcessDatas,uint256 nonce,uint256 deadline)")
    );

    bytes32 constant ADD_ACTIONS_WITH_SIG_TYPEHASH = keccak256(
        bytes(
            "AddActionsWithSig(bytes32 assetId,address[] actions,bytes[] actionInitDatas,uint256 nonce,uint256 deadline)"
        )
    );

    uint256 internal _tokenIdCount = 0;

    mapping(address => uint256) internal _sigNonces;

    mapping(bytes32 => Asset) internal _assetById;

    constructor(string memory eip712Name, string memory eip712Version)
        ERC721("Publication NFT", "PN")
        EIP712(eip712Name, eip712Version)
    {}

    /**
     * @inheritdoc ERC721Enumerable
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return interfaceId == type(IDataMonetizer).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IDataMonetizer
     */
    function getDomainSeparator() public view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @inheritdoc IDataMonetizer
     */
    function getSigNonce(address signer) public view returns (uint256) {
        return _sigNonces[signer];
    }

    /**
     * @inheritdoc IDataMonetizer
     */
    function getAsset(bytes32 assetId) public view returns (Asset memory) {
        return _assetById[assetId];
    }

    /**
     * @inheritdoc IDataMonetizer
     */
    function getAssetOwner(bytes32 assetId) public view returns (address) {
        return ownerOf(_assetById[assetId].publicationId);
    }

    /**
     * @inheritdoc IDataMonetizer
     */
    function publish(PublishParams calldata publishParams) public payable nonReentrant returns (bytes32) {
        return _publish(publishParams, msg.sender);
    }

    /**
     * @inheritdoc IDataMonetizer
     */
    function publishWithSig(PublishParams calldata publishParams, EIP712Signature calldata signature)
        public
        payable
        nonReentrant
        returns (bytes32)
    {
        address recoveredAddr = _recoverSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        PUBLISH_WITH_SIG_TYPEHASH,
                        EIP712Encoder.encodeUsingEIP712Rules(publishParams.data),
                        EIP712Encoder.encodeUsingEIP712Rules(publishParams.actions),
                        EIP712Encoder.encodeUsingEIP712Rules(publishParams.actionInitDatas),
                        _sigNonces[signature.signer]++,
                        signature.deadline
                    )
                )
            ),
            signature
        );

        if (signature.signer != recoveredAddr) {
            revert SignatureMismatch();
        }

        return _publish(publishParams, signature.signer);
    }

    /**
     * @inheritdoc IDataMonetizer
     */
    function act(ActParams calldata actParams) public payable nonReentrant returns (bytes[] memory) {
        return _act(actParams, msg.sender);
    }

    /**
     * @inheritdoc IDataMonetizer
     */
    function actWithSig(ActParams calldata actParams, EIP712Signature calldata signature)
        public
        payable
        nonReentrant
        returns (bytes[] memory)
    {
        address recoveredAddr = _recoverSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        ACT_WITH_SIG_TYPEHASH,
                        actParams.assetId,
                        EIP712Encoder.encodeUsingEIP712Rules(actParams.actions),
                        EIP712Encoder.encodeUsingEIP712Rules(actParams.actionProcessDatas),
                        _sigNonces[signature.signer]++,
                        signature.deadline
                    )
                )
            ),
            signature
        );

        if (signature.signer != recoveredAddr) {
            revert SignatureMismatch();
        }

        return _act(actParams, signature.signer);
    }

    function addActions(AddActionsParams calldata addActionsParams) external nonReentrant {
        _addActions(addActionsParams, msg.sender);
    }

    function addActionsWithSig(AddActionsParams calldata addActionsParams, EIP712Signature calldata signature)
        external
        nonReentrant
    {
        address recoveredAddr = _recoverSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        ADD_ACTIONS_WITH_SIG_TYPEHASH,
                        addActionsParams.assetId,
                        EIP712Encoder.encodeUsingEIP712Rules(addActionsParams.actions),
                        EIP712Encoder.encodeUsingEIP712Rules(addActionsParams.actionInitDatas),
                        _sigNonces[signature.signer]++,
                        signature.deadline
                    )
                )
            ),
            signature
        );

        if (signature.signer != recoveredAddr) {
            revert SignatureMismatch();
        }

        return _addActions(addActionsParams, signature.signer);
    }

    function _publish(PublishParams calldata publishParams, address publisher) internal returns (bytes32) {
        _checkActionsValidity(publishParams.actions);

        bytes32 assetId = _calcAssetId(publishParams, publisher);

        uint256 publicationId = _mintPublication(publisher);

        _assetById[assetId] = Asset({
            data: publishParams.data,
            publishAt: block.timestamp,
            publicationId: publicationId,
            actions: publishParams.actions
        });

        for (uint256 i = 0; i < publishParams.actions.length; ++i) {
            (bool success,) = publishParams.actions[i].call{value: msg.value}(
                abi.encodeWithSelector(IAction.initializeAction.selector, assetId, publishParams.actionInitDatas[i])
            );
            if (!success) {
                revert InitializeActionFailed();
            }
        }

        _afterPublish(publishParams, publisher, publicationId, assetId);

        emit AssetPublished(
            assetId, publisher, publicationId, publishParams.data, publishParams.actions, publishParams.actionInitDatas
        );

        return assetId;
    }

    /**
     * @dev virtual function
     * @notice Custom logic to be executed after publish.
     */
    function _afterPublish(
        PublishParams calldata publishParams,
        address publisher,
        uint256 publicationId,
        bytes32 assetId
    ) internal virtual;

    function _act(ActParams calldata actParams, address actor) internal returns (bytes[] memory actionReturnDatas) {
        if (actParams.actions.length != actParams.actionProcessDatas.length) {
            revert ArrayLengthNotEqual();
        }
        for (uint256 i = 0; i < actParams.actions.length; ++i) {
            bool flag;
            for (uint256 j = 0; j < _assetById[actParams.assetId].actions.length; ++j) {
                if (actParams.actions[i] == _assetById[actParams.assetId].actions[j]) {
                    flag = true;
                }
            }
            if (!flag) {
                revert ActionNotExists();
            }
        }

        actionReturnDatas = new bytes[](actParams.actions.length);

        for (uint256 i = 0; i < actParams.actions.length; ++i) {
            (bool success, bytes memory returnData) = actParams.actions[i].call{value: msg.value}(
                abi.encodeWithSelector(
                    IAction.processAction.selector, actParams.assetId, actor, actParams.actionProcessDatas[i]
                )
            );
            if (!success) {
                revert ProcessActionFailed();
            }
            actionReturnDatas[i] = abi.decode(returnData, (bytes));
        }

        emit AssetActed(actParams.assetId, actor, actParams.actions, actParams.actionProcessDatas, actionReturnDatas);
    }

    function _addActions(AddActionsParams memory addActionsParams, address signer) internal {
        _checkAssetOwner(addActionsParams.assetId, signer);
        _checkActionsValidity(addActionsParams.actions);
        if (addActionsParams.actions.length != addActionsParams.actionInitDatas.length) {
            revert ArrayLengthNotEqual();
        }
        for (uint256 i = 0; i < addActionsParams.actions.length; ++i) {
            _assetById[addActionsParams.assetId].actions.push(addActionsParams.actions[i]);
            (bool success,) = addActionsParams.actions[i].call{value: msg.value}(
                abi.encodeWithSelector(
                    IAction.initializeAction.selector, addActionsParams.assetId, addActionsParams.actionInitDatas[i]
                )
            );
            if (!success) {
                revert InitializeActionFailed();
            }
        }
        emit AssetActionsAdded(addActionsParams.assetId, addActionsParams.actions, addActionsParams.actionInitDatas);
    }

    function _mintPublication(address to) private returns (uint256 tokenId) {
        tokenId = _tokenIdCount;
        _safeMint(to, _tokenIdCount++);
    }

    function _recoverSigner(bytes32 digest, EIP712Signature memory signature) internal view returns (address) {
        if (signature.deadline < block.timestamp) revert SignatureExpired();
        address recoveredAddress = ecrecover(digest, signature.v, signature.r, signature.s);
        return recoveredAddress;
    }

    function _calcAssetId(PublishParams memory publishParams, address publisher) internal view returns (bytes32) {
        return keccak256(abi.encode(publishParams, publisher, address(this), block.timestamp));
    }

    function _checkActionsValidity(address[] memory actions) internal view {
        for (uint256 i = 0; i < actions.length; ++i) {
            if (!IERC165(actions[i]).supportsInterface(type(IAction).interfaceId)) {
                revert ActionInvalid();
            }
        }
    }

    function _checkAssetOwner(bytes32 assetId, address account) internal view {
        if (getAssetOwner(assetId) != account) {
            revert NotAssetOwner();
        }
    }

    function _checkActionsExsitence(bytes32 assetId, address[] memory actions) internal view {
        Asset storage targetAsset = _assetById[assetId];
        for (uint256 i = 0; i < actions.length; ++i) {
            for (uint256 j = 0; j < targetAsset.actions.length; ++j) {
                if (actions[i] == targetAsset.actions[j]) {
                    revert ActionAlreadyExists();
                }
            }
        }
    }
}
