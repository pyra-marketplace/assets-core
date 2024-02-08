// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {DataToken} from "contracts/data-token/DataToken.sol";
import {IDataToken} from "contracts/data-token/IDataToken.sol";
import {IDataMonetizer} from "contracts/interfaces/IDataMonetizer.sol";
import {CollectAction} from "contracts/data-token/actions/collect/CollectAction.sol";
import {FeeCollectModule} from "contracts/data-token/actions/collect/modules/FeeCollectModule.sol";
import {BaseTest} from "../Base.t.sol";

contract DataTokenTest is BaseTest {
    DataToken dataToken;
    CollectAction collectAction;
    FeeCollectModule feeCollectModule;

    address publisher;
    uint256 publisherPK;
    address actor;
    uint256 actorPK;

    string testFileId = "testFileId";

    // CollectAction: initialize
    uint256 totalSupply = 100;
    uint256 amount = 1e6;

    function setUp() public {
        _baseSetup();
        (publisher, publisherPK) = makeAddrAndKey("publisher");
        (actor, actorPK) = makeAddrAndKey("actor");

        erc20Mock.mint(actor, 1e30);

        dataToken = new DataToken();
        collectAction = new CollectAction(address(actionConfig), address(dataToken));
        feeCollectModule = new FeeCollectModule(address(collectAction));

        collectAction.registerCollectModule(address(feeCollectModule));
    }

    function test_Publish() public {
        bytes memory data = abi.encode(testResourceId, testFileId);
        address[] memory actions = new address[](1);
        bytes[] memory actionInitDatas = new bytes[](1);

        actions[0] = address(collectAction);
        actionInitDatas[0] = abi.encode(address(feeCollectModule), abi.encode(totalSupply, address(erc20Mock), amount));
        IDataMonetizer.PublishParams memory publishParams =
            IDataMonetizer.PublishParams({data: data, actions: actions, actionInitDatas: actionInitDatas});

        vm.prank(publisher);
        bytes32 assetId = dataToken.publish(publishParams);

        IDataToken.TokenAsset memory tokenAsset = dataToken.getTokenAsset(assetId);
        assertEq(tokenAsset.resourceId, testResourceId);
        assertEq(tokenAsset.fileId, testFileId);
        assertEq(tokenAsset.publishAt, block.timestamp);
        assertEq(tokenAsset.actions, actions);
    }

    function test_PublishWithSig() public {
        bytes memory data = abi.encode(testResourceId, testFileId);
        address[] memory actions = new address[](1);
        bytes[] memory actionInitDatas = new bytes[](1);

        actions[0] = address(collectAction);
        actionInitDatas[0] = abi.encode(address(feeCollectModule), abi.encode(totalSupply, address(erc20Mock), amount));
        IDataMonetizer.PublishParams memory publishParams =
            IDataMonetizer.PublishParams({data: data, actions: actions, actionInitDatas: actionInitDatas});

        IDataMonetizer.EIP712Signature memory signature = _buildPublishSignature(address(dataToken), publishParams, publisher, publisherPK);

        vm.prank(publisher);
        bytes32 assetId = dataToken.publishWithSig(publishParams, signature);

        IDataToken.TokenAsset memory tokenAsset = dataToken.getTokenAsset(assetId);
        assertEq(tokenAsset.resourceId, testResourceId);
        assertEq(tokenAsset.fileId, testFileId);
        assertEq(tokenAsset.publishAt, block.timestamp);
        assertEq(tokenAsset.actions, actions);
    }

    function test_Act() public {
        bytes memory data = abi.encode(testResourceId, testFileId);
        address[] memory actions = new address[](1);
        bytes[] memory actionInitDatas = new bytes[](1);

        actions[0] = address(collectAction);
        actionInitDatas[0] = abi.encode(address(feeCollectModule), abi.encode(totalSupply, address(erc20Mock), amount));
        IDataMonetizer.PublishParams memory publishParams =
            IDataMonetizer.PublishParams({data: data, actions: actions, actionInitDatas: actionInitDatas});
        vm.prank(publisher);
        bytes32 assetId = dataToken.publish(publishParams);

        bytes[] memory actionProcessDatas = new bytes[](1);
        actionProcessDatas[0] = abi.encode(address(erc20Mock), amount);

        IDataMonetizer.ActParams memory actParams =
            IDataMonetizer.ActParams({assetId: assetId, actions: actions, actionProcessDatas: actionProcessDatas});

        vm.startPrank(actor);
        erc20Mock.approve(address(feeCollectModule), amount);
        dataToken.act(actParams);
        vm.stopPrank();
    }

    function test_ActWithSig() public {
        bytes memory data = abi.encode(testResourceId, testFileId);
        address[] memory actions = new address[](1);
        bytes[] memory actionInitDatas = new bytes[](1);

        actions[0] = address(collectAction);
        actionInitDatas[0] = abi.encode(address(feeCollectModule), abi.encode(totalSupply, address(erc20Mock), amount));
        IDataMonetizer.PublishParams memory publishParams =
            IDataMonetizer.PublishParams({data: data, actions: actions, actionInitDatas: actionInitDatas});
        vm.prank(publisher);
        bytes32 assetId = dataToken.publish(publishParams);

        bytes[] memory actionProcessDatas = new bytes[](1);
        actionProcessDatas[0] = abi.encode(address(erc20Mock), amount);

        IDataMonetizer.ActParams memory actParams =
            IDataMonetizer.ActParams({assetId: assetId, actions: actions, actionProcessDatas: actionProcessDatas});

        IDataMonetizer.EIP712Signature memory signature = _buildActSignature(address(dataToken), actParams, actor, actorPK);

        vm.startPrank(actor);
        erc20Mock.approve(address(feeCollectModule), amount);
        dataToken.actWithSig(actParams, signature);
        vm.stopPrank();
    }

    function test_AddActions() public {
        bytes memory data = abi.encode(testResourceId, testFileId);
        address[] memory actions = new address[](0);
        bytes[] memory actionInitDatas = new bytes[](0);

        IDataMonetizer.PublishParams memory publishParams =
            IDataMonetizer.PublishParams({data: data, actions: actions, actionInitDatas: actionInitDatas});

        vm.prank(publisher);
        bytes32 assetId = dataToken.publish(publishParams);

        actions = new address[](1);
        actionInitDatas = new bytes[](1);
        actions[0] = address(collectAction);
        actionInitDatas[0] = abi.encode(address(feeCollectModule), abi.encode(totalSupply, address(erc20Mock), amount));
        IDataMonetizer.AddActionsParams memory addActionsParams = IDataMonetizer.AddActionsParams({
            assetId: assetId,
            actions: actions,
            actionInitDatas: actionInitDatas
        });

        vm.prank(publisher);
        dataToken.addActions(addActionsParams);

        IDataToken.TokenAsset memory tokenAsset = dataToken.getTokenAsset(assetId);
        assertEq(tokenAsset.actions, actions);
    }

    function test_AddActionsWithSig() public {
        bytes memory data = abi.encode(testResourceId, testFileId);
        address[] memory actions = new address[](0);
        bytes[] memory actionInitDatas = new bytes[](0);

        IDataMonetizer.PublishParams memory publishParams =
            IDataMonetizer.PublishParams({data: data, actions: actions, actionInitDatas: actionInitDatas});

        vm.prank(publisher);
        bytes32 assetId = dataToken.publish(publishParams);

        actions = new address[](1);
        actionInitDatas = new bytes[](1);
        actions[0] = address(collectAction);
        actionInitDatas[0] = abi.encode(address(feeCollectModule), abi.encode(totalSupply, address(erc20Mock), amount));
        IDataMonetizer.AddActionsParams memory addActionsParams = IDataMonetizer.AddActionsParams({
            assetId: assetId,
            actions: actions,
            actionInitDatas: actionInitDatas
        });

        IDataMonetizer.EIP712Signature memory signature = _buildAddActionsSignature(address(dataToken), addActionsParams, publisher, publisherPK);

        vm.prank(publisher);
        dataToken.addActionsWithSig(addActionsParams, signature);

        IDataToken.TokenAsset memory tokenAsset = dataToken.getTokenAsset(assetId);
        assertEq(tokenAsset.actions, actions);
    }
}
