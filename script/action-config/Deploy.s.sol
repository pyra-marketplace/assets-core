// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ActionConfig} from "../../contracts/ActionConfig.sol";
import "forge-std/Script.sol";

contract DeployDataToken is Script {
    address protocolTreasury = 0x3F3786B67DC1874C3Bd8e8CD61F5eea87604470F;
    uint256 protocolFeePoint = 500;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        ActionConfig actionConfig = new ActionConfig(vm.addr(deployerPrivateKey), protocolTreasury, protocolFeePoint);
        vm.stopBroadcast();

        console.log('"ActionConfig: "%s"', address(actionConfig));
    }
}
