// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IActionConfig {
    error InvalidFeePoint();

    event TreasurySet(address operator, address treasury);
    event TreasuryFeeSet(address operator, uint256 feePoint);

    /**
     * @notice Returns dapp developer's treasury address and fee point.
     * @param resourceId The resource ID query for.
     * @param publishAt The blocknumber publishing at.
     * @return address Treasury address.
     * @return uint256 Fee point value.
     */
    function getDappTreasuryData(string memory resourceId, uint256 publishAt)
        external
        view
        returns (address, uint256);

    /**
     * @notice Returns dataverse treasury address and fee point.
     * @return address Treasury address.
     * @return uint256 Fee point value.
     */
    function getDataverseTreasuryData() external view returns (address, uint256);

    /**
     * @notice Sets the treasury address for the dataverse foundation.
     * @param treasury The address of the treasury.
     */
    function setDataverseTreasury(address treasury) external;

    /**
     * @notice Sets the fee point value for the dataverse foundation.
     * @param feePoint The fee point value to be set.
     */
    function setDataverseFeePoint(uint256 feePoint) external;
}
