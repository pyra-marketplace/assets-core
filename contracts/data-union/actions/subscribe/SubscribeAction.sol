// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {ActionBase} from "dataverse-contracts-test/contracts/monetizer/base/ActionBase.sol";
import {ISubscribeModule} from "./modules/interface/ISubscribeModule.sol";
import {CollectAction} from "../collect/CollectAction.sol";
import {CollectNFT} from "../collect/token/CollectNFT.sol";

contract SubscribeAction is ActionBase {
    error NotCollected();
    error CollectTokenNotEnumberable();
    error CollectTokenNotOwned();

    using SafeERC20 for IERC20;

    CollectAction public immutable COLLECT_ACTION;
    mapping(bytes32 => mapping(uint256 => uint256[2][])) _assetSubscribeData;

    constructor(address actionConfig, address collectAction, address monetizer) ActionBase(actionConfig, monetizer) {
        COLLECT_ACTION = CollectAction(collectAction);
    }

    function initializeAction(bytes32 assetId, bytes calldata data)
        external
        override
        monetizerRestricted
        returns (bytes memory)
    {
        (address subscribeModule, bytes memory subscribeInitData) = abi.decode(data, (address, bytes));

        return ISubscribeModule(subscribeModule).initializeSubscribeModule(assetId, subscribeInitData);
    }

    function processAction(bytes32 assetId, address subscriber, bytes calldata data)
        external
        override
        monetizerRestricted
        returns (bytes memory)
    {
        if (COLLECT_ACTION.isCollected(assetId, subscriber)) {
            revert NotCollected();
        }

        address collectNFT = COLLECT_ACTION.getAssetCollectData(assetId).collectNFT;
        (uint256 collectTokenId, address subscribeModule, bytes memory subscribeProcessData) =
            abi.decode(data, (uint256, address, bytes));

        if (CollectNFT(collectNFT).ownerOf(collectTokenId) != subscriber) {
            revert CollectTokenNotOwned();
        }

        (uint256 startAt, uint256 endAt) =
            ISubscribeModule(subscribeModule).processSubscribe(assetId, subscriber, subscribeProcessData);
        _assetSubscribeData[assetId][collectTokenId].push([startAt, endAt]);

        return abi.encode(startAt, endAt);
    }

    function isAccessible(bytes32 assetId, address account, uint256 timestamp) external view returns (bool) {
        if (!COLLECT_ACTION.isCollected(assetId, account)) {
            return false;
        }
        address collectNFT = COLLECT_ACTION.getAssetCollectData(assetId).collectNFT;
        uint256 balance = CollectNFT(collectNFT).balanceOf(account);
        for (uint256 i = 0; i < balance; ++i) {
            uint256 collectTokenId = CollectNFT(collectNFT).tokenOfOwnerByIndex(account, i);
            if (isAccessible(assetId, collectTokenId, timestamp)) {
                return true;
            }
        }
        return false;
    }

    function isAccessible(bytes32 assetId, uint256 collectTokenId, uint256 timestamp) public view returns (bool) {
        if (timestamp > block.timestamp) {
            return false;
        }

        uint256[2][] memory targetSubscribeData = _assetSubscribeData[assetId][collectTokenId];
        for (uint256 i = 0; i < targetSubscribeData.length; ++i) {
            if (timestamp >= targetSubscribeData[i][0] && timestamp <= targetSubscribeData[i][1]) {
                return true;
            }
        }

        return false;
    }
}
