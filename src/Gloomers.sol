// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {WhitelistVerifier} from "../src/WhitelistVerifier.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract Gloomers is ERC721A, Ownable, WhitelistVerifier, ERC721Royalty {
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant PRICE_PER_TOKEN = 0.03 ether;
    uint256 public constant MAX_MINT_PER_WALLET = 3;
    uint256 public constant START_TOKEN_ID = 3334;
    bytes32 public constant PROVENANCE_HASH = 0x5158cf3ac201d8d9dfe63ac7c7d1e7aa58b7c33426665c9bf643e0003e095e2f;
    uint256 public constant MINT_START_TIMESTAMP = 1714838400; // Sat May 04 2024 16:00:00 GMT
    uint256 public constant WHITELIST_MINT_DURATION = 3 hours;

    bool public revealed = false;
    MintState public mintState = MintState.DISABLED;

    enum MintState {
        DISABLED,
        WHITELIST,
        PUBLIC
    }

    string private _baseTokenURI =
        "https://ipfs.gloomtoken.xyz/ipfs/bafybeidnrgagzrjvavrsjtnz6qhqvnlbkz3vh5q35gfgkj236ylsxwpmsy";
    mapping(address => uint256) private _mintedPerWallet;

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event GloomerMinted(address indexed _to, uint256 _quantity);
    event WhitelistClaimed(address indexed _to, uint256 _quantity);
    event MintStateUpdated(MintState _mintState);

    error MintingDisabled();
    error PublicSaleNotActive();
    error WhitelistError();
    error ExceedsMaxMintPerWallet();
    error ExceedsMaxSupply();
    error InsufficientFunds();

    modifier publicSaleActive() {
        if (mintState != MintState.PUBLIC) {
            revert PublicSaleNotActive();
        }
        _;
    }

    modifier notDisabled() {
        if (mintState == MintState.DISABLED) {
            revert MintingDisabled();
        }
        _;
    }

    modifier mintsAvailable(uint256 quantity) {
        if (quantity + _nextTokenId() > MAX_SUPPLY) {
            revert ExceedsMaxSupply();
        }
        _;
    }

    modifier fundsAttached(uint256 quantity) {
        if (msg.value < PRICE_PER_TOKEN * quantity) {
            revert InsufficientFunds();
        }
        _;
    }

    modifier validatedWhitelistRequest(bytes32 hash, bytes memory signature) {
        if (!isValidWhitelistRequest(hash, signature)) {
            revert WhitelistError();
        }
        _;
    }

    modifier notOverWalletLimit(uint256 quantity) {
        if (_mintedPerWallet[msg.sender] + quantity > MAX_MINT_PER_WALLET && msg.sender != owner()) {
            revert ExceedsMaxMintPerWallet();
        }
        _;
    }

    constructor() ERC721A("Gloomers", "GLOOMERS") Ownable(msg.sender) {
        _setDefaultRoyalty(msg.sender, 500);
    }

    function mint(uint256 quantity)
        external
        payable
        publicSaleActive
        notDisabled
        mintsAvailable(quantity)
        fundsAttached(quantity)
        notOverWalletLimit(quantity)
    {
        _mintedPerWallet[msg.sender] += quantity;
        _mint(msg.sender, quantity);

        emit GloomerMinted(msg.sender, quantity);
    }

    function whitelistMint(uint256 quantity, bytes32 hash, bytes memory signature)
        external
        publicSaleActive
        notDisabled
        mintsAvailable(quantity)
        fundsAttached(quantity)
        notOverWalletLimit(quantity)
        validatedWhitelistRequest(hash, signature)
    {
        _mintedPerWallet[msg.sender] += quantity;
        _mint(msg.sender, quantity);

        emit WhitelistClaimed(msg.sender, quantity);
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

    function triggerMintState() external {
        uint256 timestamp = block.timestamp;
        if (timestamp <= MINT_START_TIMESTAMP) {
            revert MintingDisabled();
        }
        if (timestamp < MINT_START_TIMESTAMP + WHITELIST_MINT_DURATION) {
            mintState = MintState.WHITELIST;
        } else {
            mintState = MintState.PUBLIC;
        }
        emit MintStateUpdated(mintState_);
    }

    function setTokenUri(string calldata baseTokenURI_) external onlyOwner {
        revealed = true;
        _baseTokenURI = baseTokenURI_;
        emit BatchMetadataUpdate(START_TOKEN_ID, (type(uint256).max));
    }

    function setDefaultRoyalty(address receiver, uinit96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return START_TOKEN_ID;
    }

    function _sequentialUpTo() internal view override returns (uint256) {
        return START_TOKEN_ID + MAX_SUPPLY;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // Required overrides
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}
