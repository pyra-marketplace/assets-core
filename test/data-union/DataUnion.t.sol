// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DataUnion} from "../../contracts/data-union/DataUnion.sol";
import {IDataUnion} from "../../contracts/data-union/IDataUnion.sol";
import {IDataMonetizer} from "dataverse-contracts-test/contracts/monetizer/interfaces/IDataMonetizer.sol";
import {CollectAction} from "../../contracts/data-union/actions/collect/CollectAction.sol";
import {FeeCollectModule} from "../../contracts/data-union/actions/collect/modules/FeeCollectModule.sol";
import {SubscribeAction} from "../../contracts/data-union/actions/subscribe/SubscribeAction.sol";
import {MonthlySubscribeModule} from "../../contracts/data-union/actions/subscribe/modules/MonthlySubscribeModule.sol";
import {BaseTest} from "../Base.t.sol";

contract DataUnionTest is BaseTest {
    DataUnion dataUnion;
    CollectAction collectAction;
    FeeCollectModule feeCollectModule;
    SubscribeAction subscribeAction;
    MonthlySubscribeModule monthlySubscribeModule;

    address publisher;
    address actor;

    string testFolderId = "testFolderId";

    // CollectAction: initialize
    uint256 totalSupply = 100;
    uint256 amount = 1e6;

    // SubscribeAction: initialize
    uint256 amountPerMonth = 1e3;

    function setUp() public {
        _baseSetup();
        publisher = makeAddr("publisher");
        actor = makeAddr("actor");

        erc20Mock.mint(actor, 1e30);

        dataUnion = new DataUnion(address(dappTableRegistry));
        collectAction = new CollectAction(
            address(actionConfig),
            address(dataUnion)
        );
        feeCollectModule = new FeeCollectModule(address(collectAction));
        subscribeAction = new SubscribeAction(
            address(actionConfig),
            address(collectAction),
            address(dataUnion)
        );
        monthlySubscribeModule = new MonthlySubscribeModule(
            address(subscribeAction)
        );

        collectAction.registerCollectModule(address(feeCollectModule));
        subscribeAction.registerSubscribeModule(
            address(monthlySubscribeModule)
        );
    }

    function test_Publish_WhenCollectAction() public {
        bytes memory data = abi.encode(testFolderId);
        address[] memory actions = new address[](1);
        bytes[] memory actionInitDatas = new bytes[](1);
        bytes32[] memory images = new bytes32[](0);

        actions[0] = address(collectAction);
        actionInitDatas[0] = abi.encode(
            address(feeCollectModule),
            abi.encode(totalSupply, address(erc20Mock), amount)
        );
        IDataMonetizer.PublishParams memory publishParams = IDataMonetizer
            .PublishParams({
                resourceId: testResourceId,
                data: data,
                actions: actions,
                actionInitDatas: actionInitDatas,
                images: images
            });

        vm.prank(publisher);
        bytes32 assetId = dataUnion.publish(publishParams);

        IDataUnion.UnionAsset memory unionAsset = dataUnion.getUnionAsset(
            assetId
        );
        assertEq(unionAsset.resourceId, testResourceId);
        assertEq(unionAsset.folderId, testFolderId);
        assertEq(unionAsset.publishAt, block.timestamp);
        assertEq(unionAsset.closeAt, type(uint256).max);
        assertEq(unionAsset.actions, actions);
        assertEq(unionAsset.images.length, 0);
    }

    function test_Act_WhenCollectAction() public {
        bytes memory data = abi.encode(testFolderId);
        address[] memory actions = new address[](1);
        bytes[] memory actionInitDatas = new bytes[](1);
        bytes32[] memory images = new bytes32[](0);

        actions[0] = address(collectAction);
        actionInitDatas[0] = abi.encode(
            address(feeCollectModule),
            abi.encode(totalSupply, address(erc20Mock), amount)
        );
        IDataMonetizer.PublishParams memory publishParams = IDataMonetizer
            .PublishParams({
                resourceId: testResourceId,
                data: data,
                actions: actions,
                actionInitDatas: actionInitDatas,
                images: images
            });

        vm.prank(publisher);
        bytes32 assetId = dataUnion.publish(publishParams);

        bytes[] memory actionProcessDatas = new bytes[](1);
        actionProcessDatas[0] = abi.encode(address(erc20Mock), amount);

        IDataMonetizer.ActParams memory actParams = IDataMonetizer.ActParams({
            assetId: assetId,
            actions: actions,
            actionProcessDatas: actionProcessDatas
        });

        vm.startPrank(actor);
        erc20Mock.approve(address(feeCollectModule), amount);
        dataUnion.act(actParams);
        vm.stopPrank();
    }

    function test_Publish_WhenSubscribeAction() public {
        bytes memory data = abi.encode(testFolderId);
        address[] memory actions = new address[](1);
        bytes[] memory actionInitDatas = new bytes[](1);
        bytes32[] memory images = new bytes32[](0);

        actions[0] = address(subscribeAction);
        actionInitDatas[0] = abi.encode(
            address(monthlySubscribeModule),
            abi.encode(address(erc20Mock), amount)
        );
        IDataMonetizer.PublishParams memory publishParams = IDataMonetizer
            .PublishParams({
                resourceId: testResourceId,
                data: data,
                actions: actions,
                actionInitDatas: actionInitDatas,
                images: images
            });

        vm.prank(publisher);
        bytes32 assetId = dataUnion.publish(publishParams);

        IDataUnion.UnionAsset memory unionAsset = dataUnion.getUnionAsset(
            assetId
        );
        assertEq(unionAsset.resourceId, testResourceId);
        assertEq(unionAsset.folderId, testFolderId);
        assertEq(unionAsset.publishAt, block.timestamp);
        assertEq(unionAsset.actions, actions);
        assertEq(unionAsset.images.length, 0);
    }

    function test_Act_WhenSubscribeAction() public {
        vm.warp(1705673480);    // 2024-1-19 10:11:20 PM GMT+08:00

        bytes32 assetId = _publish();
        uint256 collectionId = _collect(assetId);

        assertFalse(
            subscribeAction.isAccessible(assetId, actor, block.timestamp)
        );

        uint256 year = 2024;
        uint256 month = 1;
        uint256 count = 2;

        address[] memory actions = new address[](1);
        bytes[] memory actionProcessDatas = new bytes[](1);
        actions[0] = address(subscribeAction);
        actionProcessDatas[0] = abi.encode(
            collectionId,
            address(monthlySubscribeModule),
            abi.encode(year, month, count)
        );

        IDataMonetizer.ActParams memory actParams = IDataMonetizer.ActParams({
            assetId: assetId,
            actions: actions,
            actionProcessDatas: actionProcessDatas
        });

        vm.startPrank(actor);
        erc20Mock.approve(
            address(monthlySubscribeModule),
            amountPerMonth * count
        );
        dataUnion.act(actParams);
        vm.stopPrank();

        assertTrue(subscribeAction.isAccessible(assetId, actor, block.timestamp));
    }

    function _publish() internal returns (bytes32) {
        bytes memory data = abi.encode(testFolderId);
        address[] memory actions = new address[](2);
        bytes[] memory actionInitDatas = new bytes[](2);
        bytes32[] memory images = new bytes32[](0);

        actions[0] = address(collectAction);
        actions[1] = address(subscribeAction);
        actionInitDatas[0] = abi.encode(
            address(feeCollectModule),
            abi.encode(totalSupply, address(erc20Mock), amount)
        );
        actionInitDatas[1] = abi.encode(
            address(monthlySubscribeModule),
            abi.encode(address(erc20Mock), amountPerMonth)
        );
        IDataMonetizer.PublishParams memory publishParams = IDataMonetizer
            .PublishParams({
                resourceId: testResourceId,
                data: data,
                actions: actions,
                actionInitDatas: actionInitDatas,
                images: images
            });

        vm.prank(publisher);
        bytes32 assetId = dataUnion.publish(publishParams);

        return assetId;
    }

    function _collect(bytes32 assetId) internal returns (uint256) {
        address[] memory actions = new address[](1);
        bytes[] memory actionProcessDatas = new bytes[](1);
        
        actions[0] = address(collectAction);
        actionProcessDatas[0] = abi.encode(address(erc20Mock), amount);

        IDataMonetizer.ActParams memory actParams = IDataMonetizer.ActParams({
            assetId: assetId,
            actions: actions,
            actionProcessDatas: actionProcessDatas
        });

        vm.startPrank(actor);
        erc20Mock.approve(address(feeCollectModule), amount);
        bytes[] memory actReturnDatas = dataUnion.act(actParams);
        vm.stopPrank();

        (uint256 collectionId, ) = abi.decode(
            actReturnDatas[0],
            (uint256, bytes)
        );

        return collectionId;
    }
}
