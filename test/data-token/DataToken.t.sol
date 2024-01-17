// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DataToken} from "../../contracts/data-token/DataToken.sol";
import {IDataToken} from "../../contracts/data-token/IDataToken.sol";
import {IDataMonetizer} from "dataverse-contracts-test/contracts/monetizer/interfaces/IDataMonetizer.sol";
import {CollectAction} from "../../contracts/data-token/actions/collect/CollectAction.sol";
import {FeeCollectModule} from "../../contracts/data-token/actions/collect/modules/FeeCollectModule.sol";
import {ShareAction} from "../../contracts/data-token/actions/share/ShareAction.sol";
import {DefaultShareSetting} from "../../contracts/data-token/actions/share/setting/DefaultShareSetting.sol";
import {BaseTest} from "../Base.t.sol";

contract DataTokenTest is BaseTest {
    DataToken dataToken;
    CollectAction collectAction;
    FeeCollectModule feeCollectModule;
    ShareAction shareAction;
    DefaultShareSetting shareSetting;

    address publisher;
    address actor;

    string testFileId = "testFileId";

    // CollectAction: initialize
    uint256 totalSupply = 100;
    uint256 amount = 1e6;

    // ShareAction: initialize
    string shareTokenName = "testShareTokenName";
    string shareTokenSymbol = "TEST";
    uint256 assetOwnerFeePoint = 50;
    uint256 initialSupply = 500;
    // ShareAction: process
    uint256 buyShareAmount = 100;
    uint256 sellShareAmount = 50;

    function setUp() public {
        _baseSetup();
        publisher = makeAddr("publisher");
        actor = makeAddr("actor");

        erc20Mock.mint(actor, 1e30);

        dataToken = new DataToken(address(dappTableRegistry));
        collectAction = new CollectAction(address(actionConfig), address(dataToken));
        feeCollectModule = new FeeCollectModule(address(collectAction));
        shareAction = new ShareAction(address(actionConfig), address(dataToken));
        shareSetting = new DefaultShareSetting(address(shareAction));

        collectAction.registerCollectModule(address(feeCollectModule));
    }

    function test_Publish_WhenCollectAction() public {
        bytes memory data = abi.encode(testFileId);
        address[] memory actions = new address[](1);
        bytes[] memory actionInitDatas = new bytes[](1);
        bytes32[] memory images = new bytes32[](0);

        actions[0] = address(collectAction);
        actionInitDatas[0] = abi.encode(address(feeCollectModule), abi.encode(totalSupply, address(erc20Mock), amount));
        IDataMonetizer.PublishParams memory publishParams = IDataMonetizer.PublishParams({
            resourceId: testResourceId,
            data: data,
            actions: actions,
            actionInitDatas: actionInitDatas,
            images: images
        });

        vm.prank(publisher);
        bytes32 assetId = dataToken.publish(publishParams);

        IDataToken.TokenAsset memory tokenAsset = dataToken.getTokenAsset(assetId);
        assertEq(tokenAsset.resourceId, testResourceId);
        assertEq(tokenAsset.fileId, testFileId);
        assertEq(tokenAsset.publishAt, block.timestamp);
        assertEq(tokenAsset.actions, actions);
        assertEq(tokenAsset.images.length, 0);
    }

    function test_Act_WhenCollectAction() public {
        bytes memory data = abi.encode(testFileId);
        address[] memory actions = new address[](1);
        bytes[] memory actionInitDatas = new bytes[](1);
        bytes32[] memory images = new bytes32[](0);

        actions[0] = address(collectAction);
        actionInitDatas[0] = abi.encode(address(feeCollectModule), abi.encode(totalSupply, address(erc20Mock), amount));
        IDataMonetizer.PublishParams memory publishParams = IDataMonetizer.PublishParams({
            resourceId: testResourceId,
            data: data,
            actions: actions,
            actionInitDatas: actionInitDatas,
            images: images
        });

        vm.prank(publisher);
        bytes32 assetId = dataToken.publish(publishParams);

        bytes[] memory actionProcessDatas = new bytes[](1);
        actionProcessDatas[0] = abi.encode(address(erc20Mock), amount);

        IDataMonetizer.ActParams memory actParams = IDataMonetizer.ActParams({
            assetId: assetId,
            actions: actions,
            actionProcessDatas: actionProcessDatas
        });

        vm.startPrank(actor);
        erc20Mock.approve(address(feeCollectModule), amount);
        dataToken.act(actParams);
        vm.stopPrank();
    }

    function test_Publish_WhenShareAction() public {
        bytes memory data = abi.encode(testFileId);
        address[] memory actions = new address[](1);
        bytes[] memory actionInitDatas = new bytes[](1);
        bytes32[] memory images = new bytes32[](0);

        actions[0] = address(shareAction);
        actionInitDatas[0] = abi.encode(
            publisher,
            shareTokenName,
            shareTokenSymbol,
            address(erc20Mock),
            assetOwnerFeePoint,
            initialSupply,
            address(shareSetting)
        );
        IDataMonetizer.PublishParams memory publishParams = IDataMonetizer.PublishParams({
            resourceId: testResourceId,
            data: data,
            actions: actions,
            actionInitDatas: actionInitDatas,
            images: images
        });

        vm.prank(publisher);
        bytes32 assetId = dataToken.publish(publishParams);

        IDataToken.TokenAsset memory tokenAsset = dataToken.getTokenAsset(assetId);
        assertEq(tokenAsset.resourceId, testResourceId);
        assertEq(tokenAsset.fileId, testFileId);
        assertEq(tokenAsset.publishAt, block.timestamp);
        assertEq(tokenAsset.actions, actions);
        assertEq(tokenAsset.images.length, 0);
    }

    function test_Act_WhenShareAction() public {
        bytes memory data = abi.encode(testFileId);
        address[] memory actions = new address[](1);
        bytes[] memory actionInitDatas = new bytes[](1);
        bytes32[] memory images = new bytes32[](0);

        actions[0] = address(shareAction);
        actionInitDatas[0] = abi.encode(
            publisher,
            shareTokenName,
            shareTokenSymbol,
            address(erc20Mock),
            assetOwnerFeePoint,
            initialSupply,
            address(shareSetting)
        );
        IDataMonetizer.PublishParams memory publishParams = IDataMonetizer.PublishParams({
            resourceId: testResourceId,
            data: data,
            actions: actions,
            actionInitDatas: actionInitDatas,
            images: images
        });

        vm.prank(publisher);
        bytes32 assetId = dataToken.publish(publishParams);

        bytes[] memory actionProcessDatas = new bytes[](1);
        actionProcessDatas[0] = abi.encode(ShareAction.TradeType.Buy, buyShareAmount);

        IDataMonetizer.ActParams memory actParams =
            IDataMonetizer.ActParams({assetId: assetId, actions: actions, actionProcessDatas: actionProcessDatas});

        vm.startPrank(actor);
        erc20Mock.approve(address(shareAction), shareAction.getBuyPrice(assetId, buyShareAmount));
        dataToken.act(actParams);
        vm.stopPrank();
    }
}
