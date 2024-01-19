// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DataUnion} from "../../contracts/data-union/DataUnion.sol";
import {CollectAction} from "../../contracts/data-union/actions/collect/CollectAction.sol";
import {FeeCollectModule} from "../../contracts/data-union/actions/collect/modules/FeeCollectModule.sol";
import {SubscribeAction} from "../../contracts/data-union/actions/subscribe/SubscribeAction.sol";
import {MonthlySubscribeModule} from "../../contracts/data-union/actions/subscribe/modules/MonthlySubscribeModule.sol";
import "forge-std/Script.sol";

contract DeployDataUnion is Script {
    address dappTableRegistry = 0x228538B514b674978553F0dE9f272Bc01EeE2788;
    address actionConfig = 0xC721c6c0D9DAA7130d1b20d0B0f876278770EB03;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DataUnion dataUnion = new DataUnion(dappTableRegistry);
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
