// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CollectNFT is ERC721Enumerable, Ownable {
    error ZeroAddress();
    error NotOwner();

    uint256 private _tokenIdCount = 0;

    constructor() ERC721("Collect NFT", "CN") {}

    function mintCollection(address to) external onlyOwner returns (uint256 tokenId) {
        tokenId = _tokenIdCount;
        _safeMint(to, _tokenIdCount++);
    }
}
