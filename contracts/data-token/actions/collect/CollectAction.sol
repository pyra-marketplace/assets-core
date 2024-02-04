// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ActionBase} from "../../../base/ActionBase.sol";
import {ICollectModule} from "./modules/ICollectModule.sol";
import {CollectNFT} from "./token/CollectNFT.sol";
import {IDataToken} from "../../IDataToken.sol";

contract CollectAction is ActionBase {
    struct CollectData {
        address collectModule;
        address collectNFT;
    }

    error CollectModuleAlreadyRegistered();
    error CollectModuleNotRegistered();
    error NotCollectModule();

    mapping(address => bool) public isCollectModuleRegistered;
    mapping(bytes32 => CollectData) internal _assetCollectData;

    constructor(address actionConfig, address monetizer) ActionBase(actionConfig, monetizer) {}

    /**
     * @inheritdoc ActionBase
     */
    function initializeAction(bytes32 assetId, bytes calldata data) external payable monetizerRestricted {
        (address collectModule, bytes memory collectModuleInitData) = abi.decode(data, (address, bytes));
        if (!isCollectModuleRegistered[collectModule]) {
            revert CollectModuleNotRegistered();
        }

        _assetCollectData[assetId].collectModule = collectModule;

        ICollectModule(collectModule).initializeCollectModule(assetId, collectModuleInitData);
    }

    /**
     * @inheritdoc ActionBase
     */
    function processAction(bytes32 assetId, address collector, bytes calldata data)
        external
        payable
        monetizerRestricted
        returns (bytes memory)
    {
        if (_assetCollectData[assetId].collectNFT == address(0)) {
            _assetCollectData[assetId].collectNFT = address(new CollectNFT());
        }
        uint256 collectionId = CollectNFT(_assetCollectData[assetId].collectNFT).mintCollection(collector);

        bytes memory collectModuleReturnData =
            ICollectModule(_assetCollectData[assetId].collectModule).processCollect(assetId, collector, data);

        return abi.encode(collectionId, collectModuleReturnData);
    }

    function isCollected(bytes32 assetId, address account) external view returns (bool) {
        if (_assetCollectData[assetId].collectNFT == address(0)) {
            return false;
        } else {
            if (CollectNFT(_assetCollectData[assetId].collectNFT).balanceOf(account) == 0) {
                return false;
            } else {
                return true;
            }
        }
    }

    function getAssetCollectData(bytes32 assetId) external view returns (CollectData memory) {
        return _assetCollectData[assetId];
    }

    function registerCollectModule(address collectModule) external {
        if (isCollectModuleRegistered[collectModule]) {
            revert CollectModuleAlreadyRegistered();
        }
        if (!IERC165(collectModule).supportsInterface(type(ICollectModule).interfaceId)) {
            revert NotCollectModule();
        }
        isCollectModuleRegistered[collectModule] = true;
    }

    function getDappTreasuryData(bytes32 assetId) public view returns (address, uint256) {
        IDataToken.TokenAsset memory tokenAsset = IDataToken(monetizer).getTokenAsset(assetId);
        return ACTION_CONFIG.getDappTreasuryData(tokenAsset.resourceId, tokenAsset.publishAt);
    }
}
