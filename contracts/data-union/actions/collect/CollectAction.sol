// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ActionBase} from "dataverse-contracts-test/contracts/monetizer/base/ActionBase.sol";
import {ICollectModule} from "./modules/interface/ICollectModule.sol";
import {CollectNFT} from "./token/CollectNFT.sol";

contract CollectAction is ActionBase {
    struct CollectData {
        address collectModule;
        address collectNFT;
    }

    error CollectModuleAlreadyRegistered();
    error NotCollectModule();

    mapping(address => bool) public isCollectModuleRegistered;
    mapping(bytes32 => CollectData) internal _assetCollectData;

    constructor(address actionConfig, address monetizer) ActionBase(actionConfig, monetizer) {}

    function initializeAction(bytes32 assetId, bytes calldata data)
        external
        monetizerRestricted
        returns (bytes memory)
    {
        (address collectModule, bytes memory collectModuleInitData) = abi.decode(data, (address, bytes));
        _checkCollectModule(collectModule);

        CollectNFT collectNFT = new CollectNFT();
        _assetCollectData[assetId].collectNFT = address(collectNFT);
        _assetCollectData[assetId].collectModule = collectModule;

        return ICollectModule(collectModule).initializeCollectModule(assetId, collectModuleInitData);
    }

    function processAction(bytes32 assetId, address collector, bytes calldata data)
        external
        monetizerRestricted
        returns (bytes memory)
    {
        CollectNFT(_assetCollectData[assetId].collectNFT).mintCollection(collector);

        return ICollectModule(_assetCollectData[assetId].collectModule).processCollect(assetId, collector, data);
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
        _checkCollectModule(collectModule);
        isCollectModuleRegistered[collectModule] = true;
    }

    function _checkCollectModule(address collectModule) internal view {
        if (isCollectModuleRegistered[collectModule]) {
            revert CollectModuleAlreadyRegistered();
        }
        if (!ICollectModule(collectModule).supportsInterface(type(ICollectModule).interfaceId)) {
            revert NotCollectModule();
        }
    }
}
