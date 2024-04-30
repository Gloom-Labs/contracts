// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GloomersERC721 is ERC721, ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;

    constructor() ERC721("GloomersERC721", "GLOOMERS") Ownable(msg.sender) {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeidnrgagzrjvavrsjtnz6qhqvnlbkz3vh5q35gfgkj236ylsxwpmsy";
    }

    // function safeMint(address to, string memory uri) public {
    //     uint256 tokenId = _nextTokenId++;
    //     _safeMint(to, tokenId);
    //     _setTokenURI(tokenId, uri);
    // }

    function mint(address to, string memory uri) public {
        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
