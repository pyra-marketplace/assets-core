// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {DataUnion} from "../../contracts/data-union/DataUnion.sol";
import {CollectAction} from "../../contracts/data-union/actions/collect/CollectAction.sol";
import {FeeCollectModule} from "../../contracts/data-union/actions/collect/modules/FeeCollectModule.sol";
import {SubscribeAction} from "../../contracts/data-union/actions/subscribe/SubscribeAction.sol";
import {MonthlySubscribeModule} from "../../contracts/data-union/actions/subscribe/modules/MonthlySubscribeModule.sol";
import "forge-std/Script.sol";

contract DeployDataUnion is Script {
    address actionConfig = 0x4dE5f5D64e5Dc5c10a34dfb88b71642B9E9F0D07;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DataUnion dataUnion = new DataUnion();
        CollectAction collectAction = new CollectAction(actionConfig, address(dataUnion));
        FeeCollectModule feeCollectModule = new FeeCollectModule(address(collectAction));
        collectAction.registerCollectModule(address(feeCollectModule));
        SubscribeAction subscribeAction = new SubscribeAction(actionConfig, address(collectAction), address(dataUnion));
        MonthlySubscribeModule monthlySubscribeModule = new MonthlySubscribeModule(address(subscribeAction));
        subscribeAction.registerSubscribeModule(address(monthlySubscribeModule));
        vm.stopBroadcast();

        console.log("DataUnion:", address(dataUnion));
        console.log("CollectAction:", address(collectAction));
        console.log("FeeCollectModule:", address(feeCollectModule));
        console.log("SubscribeAction:", address(subscribeAction));
        console.log("MonthlySubscribeModule:", address(monthlySubscribeModule));
    }
}
