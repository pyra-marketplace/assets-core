// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {DappTableRegistry} from "dataverse-contracts-test/contracts/dapp-table-registry/DappTableRegistry.sol";
import {ActionConfig} from "../contracts/ActionConfig.sol";
import "forge-std/Test.sol";

contract ERC20Mock is ERC20 {
    constructor() ERC20("Test ERC20", "TE") {}

    function mint(address receiver, uint256 amount) external {
        _mint(receiver, amount);
    }
}

contract BaseTest is Test {
    address systemGovernor;
    address systemAdmin;
    address systemTreasury;

    DappTableRegistry dappTableRegistry;
    ActionConfig actionConfig;
    ERC20Mock erc20Mock;

    address dataverseTreasury;
    uint256 dataverseFeePoint;

    address dappDeployer;
    address dappTreasury;
    bytes16 testDappId;
    string testResourceId;
    uint256 testResourceFeePoint;
    string[] testResources;
    uint256[] testFeePoints;

    function _baseSetup() internal {
        systemGovernor = makeAddr("systemGovernor");
        systemAdmin = makeAddr("systemAdmin");
        systemTreasury = makeAddr("systemTreasury");

        dappDeployer = makeAddr("dappDeployer");
        dappTreasury = makeAddr("dappTreasury");
        testDappId = bytes16("testDappId");
        testResourceId = "testResourceId";
        testResourceFeePoint = 100;

        dataverseTreasury = makeAddr("dataverseTreasury");
        dataverseFeePoint = 50;

        testResources.push(testResourceId);
        testFeePoints.push(testResourceFeePoint);

        erc20Mock = new ERC20Mock();

        dappTableRegistry = new DappTableRegistry();
        dappTableRegistry.initialize(systemGovernor, systemTreasury);

        actionConfig = new ActionConfig(address(this), address(dappTableRegistry), dataverseTreasury, dataverseFeePoint);

        vm.startPrank(systemGovernor);
        dappTableRegistry.whitelistSystemAdmin(systemAdmin, true);
        dappTableRegistry.whitelistRegisterCurrency(address(erc20Mock), true);
        vm.stopPrank();

        vm.prank(systemAdmin);
        dappTableRegistry.registerDapp(
            testDappId, dappDeployer, address(erc20Mock), dappTreasury, testResources, testFeePoints
        );
    }
}
