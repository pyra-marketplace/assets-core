// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ActionConfig} from "../contracts/ActionConfig.sol";
import {IDataMonetizer} from "contracts/interfaces/IDataMonetizer.sol";
import {EIP712Encoder} from "contracts/libraries/EIP712Encoder.sol";
import "forge-std/Test.sol";

contract ERC20Mock is ERC20 {
    constructor() ERC20("Test ERC20", "TE") {}

    function mint(address receiver, uint256 amount) external {
        _mint(receiver, amount);
    }
}

contract BaseTest is Test {
    bytes32 constant PUBLISH_WITH_SIG_TYPEHASH = keccak256(
        bytes(
            "PublishWithSig(bytes data,address[] actions,bytes[] actionInitDatas,uint256 nonce,uint256 deadline)"
        )
    );

    bytes32 constant ACT_WITH_SIG_TYPEHASH = keccak256(
        bytes("ActWithSig(bytes32 assetId,address[] actions,bytes[] actionProcessDatas,uint256 nonce,uint256 deadline)")
    );

    bytes32 constant ADD_ACTIONS_WITH_SIG_TYPEHASH = keccak256(
        bytes(
            "AddActionsWithSig(bytes32 assetId,address[] actions,bytes[] actionInitDatas,uint256 nonce,uint256 deadline)"
        )
    );

    ActionConfig actionConfig;
    ERC20Mock erc20Mock;

    address protocolTreasury;
    uint256 protocolFeePoint;

    string testResourceId = "testResourceId";

    function _baseSetup() internal {
        protocolTreasury = makeAddr("protocolTreasury");
        protocolFeePoint = 50;

        erc20Mock = new ERC20Mock();
        actionConfig = new ActionConfig(address(this), protocolTreasury, protocolFeePoint);
    }

    function _buildPublishSignature(address monetizer, IDataMonetizer.PublishParams memory publishParams, address signer, uint256 signerPK) internal view returns (IDataMonetizer.EIP712Signature memory) {
        uint256 nonce = IDataMonetizer(monetizer).getSigNonce(signer);
        bytes32 domainSeparator = IDataMonetizer(monetizer).getDomainSeparator();
        uint256 deadline = block.timestamp + 1 days;
        bytes32 digest;
        {
            bytes32 hashedMessage = keccak256(
                abi.encode(
                    PUBLISH_WITH_SIG_TYPEHASH,
                    EIP712Encoder.encodeUsingEIP712Rules(publishParams.data),
                    EIP712Encoder.encodeUsingEIP712Rules(publishParams.actions),
                    EIP712Encoder.encodeUsingEIP712Rules(publishParams.actionInitDatas),
                    nonce,
                    deadline
                )
            );

            digest = _calculateDigest(domainSeparator, hashedMessage);
        }
        IDataMonetizer.EIP712Signature memory signature;
        {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPK, digest);
            signature.v = v;
            signature.r = r;
            signature.s = s;
            signature.deadline = deadline;
            signature.signer = signer;
        }
        return signature;
    }

    function _buildActSignature(address monetizer, IDataMonetizer.ActParams memory actParams, address signer, uint256 signerPK) internal view returns (IDataMonetizer.EIP712Signature memory) {
        uint256 nonce = IDataMonetizer(monetizer).getSigNonce(signer);
        bytes32 domainSeparator = IDataMonetizer(monetizer).getDomainSeparator();
        uint256 deadline = block.timestamp + 1 days;
        bytes32 digest;
        {
            bytes32 hashedMessage = keccak256(
                abi.encode(
                    ACT_WITH_SIG_TYPEHASH,
                    actParams.assetId,
                    EIP712Encoder.encodeUsingEIP712Rules(actParams.actions),
                    EIP712Encoder.encodeUsingEIP712Rules(actParams.actionProcessDatas),
                    nonce,
                    deadline
                )
            );

            digest = _calculateDigest(domainSeparator, hashedMessage);
        }
        IDataMonetizer.EIP712Signature memory signature;
        {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPK, digest);
            signature.v = v;
            signature.r = r;
            signature.s = s;
            signature.deadline = deadline;
            signature.signer = signer;
        }
        return signature;
    }

    function _buildAddActionsSignature(address monetizer, IDataMonetizer.AddActionsParams memory addActionsParams, address signer, uint256 signerPK) internal view returns (IDataMonetizer.EIP712Signature memory) {
        uint256 nonce = IDataMonetizer(monetizer).getSigNonce(signer);
        bytes32 domainSeparator = IDataMonetizer(monetizer).getDomainSeparator();
        uint256 deadline = block.timestamp + 1 days;
        bytes32 digest;
        {
            bytes32 hashedMessage = keccak256(
                abi.encode(
                    ADD_ACTIONS_WITH_SIG_TYPEHASH,
                    addActionsParams.assetId,
                    EIP712Encoder.encodeUsingEIP712Rules(addActionsParams.actions),
                    EIP712Encoder.encodeUsingEIP712Rules(addActionsParams.actionInitDatas),
                    nonce,
                    deadline
                )
            );

            digest = _calculateDigest(domainSeparator, hashedMessage);
        }
        IDataMonetizer.EIP712Signature memory signature;
        {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPK, digest);
            signature.v = v;
            signature.r = r;
            signature.s = s;
            signature.deadline = deadline;
            signature.signer = signer;
        }
        return signature;
    }

    function _calculateDigest(bytes32 domainSeparator, bytes32 hashedMessage) internal pure returns (bytes32) {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hashedMessage));
        return digest;
    }
}
