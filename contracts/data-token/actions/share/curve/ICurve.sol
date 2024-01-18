// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICurve {
    function getPrice(uint256 supply, uint256 decimals, uint256 amount) external pure returns (uint256);
}
