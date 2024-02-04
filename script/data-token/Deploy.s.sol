// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {DataToken} from "../../contracts/data-token/DataToken.sol";
import {CollectAction} from "../../contracts/data-token/actions/collect/CollectAction.sol";
import {FeeCollectModule} from "../../contracts/data-token/actions/collect/modules/FeeCollectModule.sol";
import "forge-std/Script.sol";

contract DeployDataToken is Script {
    address actionConfig = 0x4dE5f5D64e5Dc5c10a34dfb88b71642B9E9F0D07;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DataToken dataToken = new DataToken();
        CollectAction collectAction = new CollectAction(actionConfig, address(dataToken));
        FeeCollectModule feeCollectModule = new FeeCollectModule(address(collectAction));
        collectAction.registerCollectModule(address(feeCollectModule));
        vm.stopBroadcast();

        console.log("DataToken:", address(dataToken));
        console.log("CollectAction:", address(collectAction));
        console.log("FeeCollectModule:", address(feeCollectModule));
    }
}
