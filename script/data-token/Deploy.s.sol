// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {DataToken} from "../../contracts/data-token/DataToken.sol";
import {CollectAction} from "../../contracts/data-token/actions/collect/CollectAction.sol";
import {FeeCollectModule} from "../../contracts/data-token/actions/collect/modules/FeeCollectModule.sol";
import "forge-std/Script.sol";

contract DeployDataToken is Script {
    address actionConfig = 0xcfBA10a0F2588e11E1Da7852888c6142D3Ad6B24;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DataToken dataToken = new DataToken();
        CollectAction collectAction = new CollectAction(actionConfig, address(dataToken));
        FeeCollectModule feeCollectModule = new FeeCollectModule(address(collectAction));
        collectAction.registerCollectModule(address(feeCollectModule));
        vm.stopBroadcast();

        console.log('"DataToken": {');
        console.log('   "DataToken": "%s",', address(dataToken));
        console.log('   "CollectAction": "%s",', address(collectAction));
        console.log('   "FeeCollectModule": "%s"', address(feeCollectModule));
        console.log('}');
    }
}
