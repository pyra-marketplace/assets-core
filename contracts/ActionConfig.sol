// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDappTableRegistry} from "dataverse-contracts-test/contracts/dapp-table-registry/IDappTableRegistry.sol";
import {IActionConfig} from "./interfaces/IActionConfig.sol";

contract ActionConfig is Ownable, IActionConfig {
    uint256 public constant BASE_FEE_POINT = 10000;
    IDappTableRegistry public immutable DAPP_TABLE_REGISTRY;

    address internal _protocolTreasury;
    uint256 internal _protocolFeePoint;

    constructor(address initialOwner, address dappTableRegistry, address protocolTreasury, uint256 protocolFeePoint)
        Ownable(initialOwner)
    {
        DAPP_TABLE_REGISTRY = IDappTableRegistry(dappTableRegistry);
        _protocolTreasury = protocolTreasury;
        _protocolFeePoint = protocolFeePoint;
        emit TreasurySet(msg.sender, protocolTreasury);
        emit TreasuryFeeSet(msg.sender, protocolFeePoint);
    }

    /**
     * @inheritdoc IActionConfig
     */
    function getDappTreasuryData(string memory resourceId, uint256 timestamp)
        external
        view
        returns (address, uint256)
    {
        return DAPP_TABLE_REGISTRY.getResourceFeeData(resourceId, timestamp);
    }

    /**
     * @inheritdoc IActionConfig
     */
    function getProtocolTreasuryData() external view returns (address, uint256) {
        return (_protocolTreasury, _protocolFeePoint);
    }

    /**
     * @inheritdoc IActionConfig
     */
    function setProtocolTreasury(address protocolTreasury) external onlyOwner {
        _protocolTreasury = protocolTreasury;
        emit TreasurySet(msg.sender, protocolTreasury);
    }

    /**
     * @inheritdoc IActionConfig
     */
    function setProtocolFeePoint(uint256 protocolFeePoint) external onlyOwner {
        if (protocolFeePoint > BASE_FEE_POINT) {
            revert InvalidFeePoint();
        }
        _protocolFeePoint = protocolFeePoint;
        emit TreasuryFeeSet(msg.sender, protocolFeePoint);
    }
}
