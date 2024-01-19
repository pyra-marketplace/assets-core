// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DataToken} from "../../contracts/data-token/DataToken.sol";
import {CollectAction} from "../../contracts/data-token/actions/collect/CollectAction.sol";
import {FeeCollectModule} from "../../contracts/data-token/actions/collect/modules/FeeCollectModule.sol";
import {ShareAction} from "../../contracts/data-token/actions/share/ShareAction.sol";
import {DefaultCurve} from "../../contracts/data-token/actions/share/curve/DefaultCurve.sol";
import "forge-std/Script.sol";

contract DeployDataToken is Script {
    address dappTableRegistry = 0x228538B514b674978553F0dE9f272Bc01EeE2788;
    address actionConfig = 0xC721c6c0D9DAA7130d1b20d0B0f876278770EB03;

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
