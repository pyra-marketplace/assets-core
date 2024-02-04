// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract TierKey is Ownable, ERC721Enumerable {
    error TokenIdNotOwned();

    uint256 private _tokenIdCount = 0;

    constructor(string memory name, string memory symbol) Ownable(msg.sender) ERC721(name, symbol) {}

    function mint(address account) external onlyOwner returns (uint256 tokenId) {
        tokenId = _tokenIdCount;
        _safeMint(account, _tokenIdCount++);
    }

    function burn(address account, uint256 tokenId) external onlyOwner {
        if (ownerOf(tokenId) != account) {
            revert TokenIdNotOwned();
        }
        _burn(tokenId);
    }
}
