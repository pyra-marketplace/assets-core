// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {ActionBase} from "../../../base/ActionBase.sol";
import {ISubscribeModule} from "./modules/ISubscribeModule.sol";
import {IDataUnion} from "../../IDataUnion.sol";
import {CollectAction} from "../collect/CollectAction.sol";
import {CollectNFT} from "../collect/token/CollectNFT.sol";

contract SubscribeAction is ActionBase {
    error SubscribeModuleAlreadyRegistered();
    error SubscribeModuleNotRegistered();
    error NotSubscribeModule();
    error NotCollected();
    error CollectTokenNotEnumberable();
    error CollectTokenNotOwned();

    using SafeERC20 for IERC20;

    CollectAction public immutable COLLECT_ACTION;

    mapping(address => bool) public isSubscribeModuleRegistered;
    mapping(bytes32 => mapping(uint256 => uint256[2][])) _assetSubscribeData;

    constructor(address actionConfig, address collectAction, address monetizer) ActionBase(actionConfig, monetizer) {
        COLLECT_ACTION = CollectAction(collectAction);
    }

    function initializeAction(bytes32 assetId, bytes calldata data) external payable override monetizerRestricted {
        (address subscribeModule, bytes memory subscribeInitData) = abi.decode(data, (address, bytes));
        if (!isSubscribeModuleRegistered[subscribeModule]) {
            revert SubscribeModuleNotRegistered();
        }
        ISubscribeModule(subscribeModule).initializeSubscribeModule(assetId, subscribeInitData);
    }

    function processAction(bytes32 assetId, address subscriber, bytes calldata data)
        external
        payable
        override
        monetizerRestricted
        returns (bytes memory)
    {
        if (!COLLECT_ACTION.isCollected(assetId, subscriber)) {
            revert NotCollected();
        }

        address collectNFT = COLLECT_ACTION.getAssetCollectData(assetId).collectNFT;
        (uint256 collectionId, address subscribeModule, bytes memory subscribeProcessData) =
            abi.decode(data, (uint256, address, bytes));

        if (CollectNFT(collectNFT).ownerOf(collectionId) != subscriber) {
            revert CollectTokenNotOwned();
        }

        (uint256 startAt, uint256 endAt) =
            ISubscribeModule(subscribeModule).processSubscribe(assetId, subscriber, subscribeProcessData);
        _assetSubscribeData[assetId][collectionId].push([startAt, endAt]);

        return abi.encode(startAt, endAt);
    }

    function isAccessible(bytes32 assetId, address account, uint256 timestamp) external view returns (bool) {
        if (!COLLECT_ACTION.isCollected(assetId, account)) {
            return false;
        }
        if(account == IDataUnion(monetizer).getAssetOwner(assetId)) {
            return true;
        }
        address collectNFT = COLLECT_ACTION.getAssetCollectData(assetId).collectNFT;
        uint256 balance = CollectNFT(collectNFT).balanceOf(account);
        for (uint256 i = 0; i < balance; ++i) {
            uint256 collectionId = CollectNFT(collectNFT).tokenOfOwnerByIndex(account, i);
            if (isAccessible(assetId, collectionId, timestamp)) {
                return true;
            }
        }
        return false;
    }

    function isAccessible(bytes32 assetId, uint256 collectionId, uint256 timestamp) public view returns (bool) {
        if (timestamp > block.timestamp) {
            return false;
        }

        uint256[2][] memory targetSubscribeData = _assetSubscribeData[assetId][collectionId];
        for (uint256 i = 0; i < targetSubscribeData.length; ++i) {
            if (timestamp >= targetSubscribeData[i][0] && timestamp <= targetSubscribeData[i][1]) {
                return true;
            }
        }

        return false;
    }

    function getSubscribeData(bytes32 assetId, uint256 collectionId) external view returns (uint256[2][] memory) {
        return _assetSubscribeData[assetId][collectionId];
    }

    function registerSubscribeModule(address subscribeModule) external {
        if (isSubscribeModuleRegistered[subscribeModule]) {
            revert SubscribeModuleAlreadyRegistered();
        }
        if (!IERC165(subscribeModule).supportsInterface(type(ISubscribeModule).interfaceId)) {
            revert NotSubscribeModule();
        }
        isSubscribeModuleRegistered[subscribeModule] = true;
    }

    function getDappTreasuryData(bytes32 assetId) public view returns (address, uint256) {
        IDataUnion.UnionAsset memory unionAsset = IDataUnion(monetizer).getUnionAsset(assetId);
        return ACTION_CONFIG.getDappTreasuryData(unionAsset.resourceId, unionAsset.publishAt);
    }
}
