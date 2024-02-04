// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDappTableRegistry} from "dataverse-contracts-test/contracts/dapp-table-registry/IDappTableRegistry.sol";
import {IActionConfig} from "./interfaces/IActionConfig.sol";

contract ActionConfig is Ownable, IActionConfig {
    uint256 public constant BASE_FEE_POINT = 10000;
    IDappTableRegistry public immutable DAPP_TABLE_REGISTRY;

    address internal _treasury;
    uint256 internal _feePoint;

    constructor(address initialOwner, address dappTableRegistry, address treasury, uint256 feePoint)
        Ownable(initialOwner)
    {
        DAPP_TABLE_REGISTRY = IDappTableRegistry(dappTableRegistry);
        _treasury = treasury;
        _feePoint = feePoint;
        emit TreasurySet(msg.sender, treasury);
        emit TreasuryFeeSet(msg.sender, feePoint);
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
    function getDataverseTreasuryData() external view returns (address, uint256) {
        return (_treasury, _feePoint);
    }

    /**
     * @inheritdoc IActionConfig
     */
    function setDataverseTreasury(address treasury) external onlyOwner {
        _treasury = treasury;
        emit TreasurySet(msg.sender, treasury);
    }

    /**
     * @inheritdoc IActionConfig
     */
    function setDataverseFeePoint(uint256 feePoint) external onlyOwner {
        if (feePoint > BASE_FEE_POINT) {
            revert InvalidFeePoint();
        }
        _feePoint = feePoint;
        emit TreasuryFeeSet(msg.sender, feePoint);
    }
}
