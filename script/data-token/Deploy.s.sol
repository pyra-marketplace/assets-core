// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DataToken} from "../../contracts/data-token/DataToken.sol";
import {CollectAction} from "../../contracts/data-token/actions/collect/CollectAction.sol";
import {FeeCollectModule} from "../../contracts/data-token/actions/collect/modules/FeeCollectModule.sol";
import {ShareAction} from "../../contracts/data-token/actions/share/ShareAction.sol";
import {DefaultCurve} from "../../contracts/data-token/actions/share/curve/DefaultCurve.sol";
import "forge-std/Script.sol";

contract DeployDataToken is Script {
    address dappTableRegistry = 0x2fA7e6bE1B348384d42dd8890F1EF936326487bF;
    address actionConfig = 0x4dE5f5D64e5Dc5c10a34dfb88b71642B9E9F0D07;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DataToken dataToken = new DataToken(dappTableRegistry);
        CollectAction collectAction = new CollectAction(actionConfig, address(dataToken));
        FeeCollectModule feeCollectModule = new FeeCollectModule(address(collectAction));
        collectAction.registerCollectModule(address(feeCollectModule));
        ShareAction shareAction = new ShareAction(actionConfig, address(dataToken));
        DefaultCurve defaultCurve = new DefaultCurve();
        vm.stopBroadcast();

        console.log("DataToken:", address(dataToken));
        console.log("CollectAction:", address(collectAction));
        console.log("FeeCollectModule:", address(feeCollectModule));
        console.log("ShareAction:", address(shareAction));
        console.log("DefaultCurve:", address(defaultCurve));
    }
}
