// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library EIP712Encoder {
    function encodeUsingEIP712Rules(bytes[] memory bytesArray) public pure returns (bytes32) {
        bytes32[] memory bytesArrayEncodedElements = new bytes32[](bytesArray.length);
        uint256 i;
        while (i < bytesArray.length) {
            bytesArrayEncodedElements[i] = encodeUsingEIP712Rules(bytesArray[i]);
            unchecked {
                ++i;
            }
        }
        return encodeUsingEIP712Rules(bytesArrayEncodedElements);
    }

    function encodeUsingEIP712Rules(bool[] memory boolArray) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(boolArray));
    }

    function encodeUsingEIP712Rules(address[] memory addressArray) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(addressArray));
    }

    function encodeUsingEIP712Rules(uint256[] memory uint256Array) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(uint256Array));
    }

    function encodeUsingEIP712Rules(bytes32[] memory bytes32Array) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes32Array));
    }

    function encodeUsingEIP712Rules(string memory stringValue) public pure returns (bytes32) {
        return keccak256(bytes(stringValue));
    }

    function encodeUsingEIP712Rules(bytes memory bytesValue) public pure returns (bytes32) {
        return keccak256(bytesValue);
    }
}
