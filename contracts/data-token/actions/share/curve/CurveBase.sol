// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {ICurve} from "./ICurve.sol";

abstract contract CurveBase is ICurve, ERC165 {
    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(ICurve).interfaceId || super.supportsInterface(interfaceId);
    }
}
