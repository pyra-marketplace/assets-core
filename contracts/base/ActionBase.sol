// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ActionConfig} from "../ActionConfig.sol";
import {IAction} from "../interfaces/IAction.sol";
import {IDataMonetizer} from "../interfaces/IDataMonetizer.sol";

abstract contract ActionBase is ERC165, IAction {
    uint256 constant BASE_FEE_POINT = 10000;
    ActionConfig public ACTION_CONFIG;
    address public monetizer;

    constructor(address actionConfig, address monetizer_) {
        ACTION_CONFIG = ActionConfig(actionConfig);
        monetizer = monetizer_;
    }

    modifier monetizerRestricted() {
        if (msg.sender != monetizer) {
            revert InvalidMonetizer();
        }
        _;
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAction).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IAction
     */
    function getDataverseTreasuryData() public view returns (address, uint256) {
        return ACTION_CONFIG.getDataverseTreasuryData();
    }
}
