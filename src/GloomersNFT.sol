// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "erc721a/contracts/ERC721AOffsetable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Gloomers is ERC721AOffsetable, Ownable {
    event BaseURIUpdated(string baseURI);
    event Revealed();

    event Minted(address indexed to, uint256 indexed tokenId);

    error ExceedsMaxMintPerWallet();
    error ExceedsMaxSupply();
    error InsufficientFunds();
    error AlreadyRevealed();

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_MINT_PER_WALLET = 3;
    uint256 public constant MINT_PRICE = 0 ether; // 0.03 ether;
    string public constant PROVENANCE_HASH = "0x5158cf3ac201d8d9dfe63ac7c7d1e7aa58b7c33426665c9bf643e0003e095e2f";
    uint256 public immutable randomSeed = 1288; // temp while using foundry
    bool public revealed = false;
    string private _baseTokenURI = "ipfs://bafybeidnrgagzrjvavrsjtnz6qhqvnlbkz3vh5q35gfgkj236ylsxwpmsy";

    mapping(address => uint256) private _mintedPerWallet;

    constructor() ERC721AOffsetable("Gloomers", "GLOOMERS", 6667) Ownable(msg.sender) {
        // randomSeed = randomSeed_; //(uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % MAX_SUPPLY) + 1;
    }

    function mint(uint256 quantity) external payable {
        if (_mintedPerWallet[msg.sender] + quantity > MAX_MINT_PER_WALLET && msg.sender != owner()) {
            revert ExceedsMaxMintPerWallet();
        }

        if (msg.value < MINT_PRICE * quantity) {
            revert InsufficientFunds();
        }

        _mintedPerWallet[msg.sender] += quantity;

        uint256 sequentialMintQuantity = 0;
        uint256 spotMintQuantity = 0;

        uint256 totalWithQuantity = _totalMinted() + quantity;

        if (totalWithQuantity > MAX_SUPPLY) {
            revert ExceedsMaxSupply();
        }

        if (totalWithQuantity > randomSeed) {
            spotMintQuantity = totalWithQuantity - randomSeed;
            if (spotMintQuantity > 3) {
                spotMintQuantity = 3;
            }
            sequentialMintQuantity = quantity - spotMintQuantity;
        } else {
            sequentialMintQuantity = quantity;
        }

        // mint sequential
        if (sequentialMintQuantity > 0) {
            _mint(msg.sender, sequentialMintQuantity);
        }

        // mint spot
        if (spotMintQuantity > 0) {
            for (uint256 i = 0; i < spotMintQuantity; i++) {
                _mintSpot(msg.sender, nextTokenIdSpot());
                emit Revealed();
            }
        }
    }

    function nextTokenId() public view returns (uint256) {
        return (_nextTokenId() + _startTokenId() - 1) % (MAX_SUPPLY + 1);
    }

    function nextTokenIdSpot() public view returns (uint256) {
        return randomSeed + _totalSpotMinted() + 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }
        string memory baseURI = _baseURI();
        string memory metadataPointerId = !revealed ? "" : _toString(tokenId);
        string memory result = string(abi.encodePacked(baseURI, metadataPointerId));
        return bytes(baseURI).length != 0 ? result : "";
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 3333;
    }

    function _sequentialUpTo() internal view override returns (uint256) {
        return randomSeed;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function reveal(string calldata baseTokenURI_) public onlyOwner {
        if (revealed) {
            revert AlreadyRevealed();
        }
        _baseTokenURI = baseTokenURI_;
        revealed = true;
        emit BaseURIUpdated(baseTokenURI_);
        emit Revealed();
    }
}
