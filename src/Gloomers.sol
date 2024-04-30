// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC721A, ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {StartTokenIdHelper} from "erc721a/contracts/extensions/StartTokenIdHelper.sol";
import {WhitelistVerifier} from "../src/WhitelistVerifier.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

contract Gloomers is ERC721A, ERC721AQueryable, StartTokenIdHelper, ERC2981, Ownable, WhitelistVerifier {
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant PRICE_PER_TOKEN = 0.03 ether;
    uint256 public constant MAX_MINT_PER_WALLET = 3;
    bytes32 public constant PROVENANCE_HASH = 0x5158cf3ac201d8d9dfe63ac7c7d1e7aa58b7c33426665c9bf643e0003e095e2f;
    uint256 public constant WHITELIST_START_TIMESTAMP = 1714838400; // Sat May 04 2024 16:00:00 GMT
    uint256 public constant PUBLIC_MINT_TIMESTAMP = WHITELIST_START_TIMESTAMP + 3 hours;

    enum DropStatus {
        DISABLED,
        PRESALE,
        WHITELIST,
        PUBLIC
    }

    DropStatus public dropStatus = DropStatus.DISABLED;

    mapping(address => uint256) private _mintedPerWallet;
    mapping(address => uint256) private _presaleAllocationsByWallet;
    mapping(uint256 => address) private _presaleWalletsById;
    uint256 private _presalesCount;
    uint256 private _presaleSupplyOffset;

    bool private revealed = false;
    string private _baseTokenURI =
        "https://ipfs.gloomtoken.xyz/ipfs/bafybeidnrgagzrjvavrsjtnz6qhqvnlbkz3vh5q35gfgkj236ylsxwpmsy";

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event GloomersMint(address indexed _to, uint256 _quantity);
    event MintWhitelist(address indexed _to, uint256 _quantity);
    event RegisterPresale(address indexed _to, uint256 _quantity);
    event ClaimPresale(address indexed _to, uint256 _quantity);
    event NewDropStatus(DropStatus _dropStatus);

    error MintingDisabled();
    error PublicMintNotActive();
    error WhitelistNotActive();
    error PresaleNotActive();
    error ClaimNotActive();
    error NotEligible();
    error ExceedsMaxMintPerWallet();
    error ExceedsMaxSupply();
    error InsufficientFunds();
    error NonEOACaller();

    modifier dropEnabled() {
        if (dropStatus == DropStatus.DISABLED) {
            revert MintingDisabled();
        }
        _;
    }

    modifier presaleActive() {
        if (block.timestamp > WHITELIST_START_TIMESTAMP || dropStatus != DropStatus.PRESALE) {
            revert PresaleNotActive();
        }
        _;
    }

    modifier whitelistActive() {
        if (
            block.timestamp > WHITELIST_START_TIMESTAMP || block.timestamp < PUBLIC_MINT_TIMESTAMP
                || dropStatus != DropStatus.WHITELIST
        ) {
            revert WhitelistNotActive();
        }
        _;
    }

    modifier publicMintActive() {
        if (block.timestamp < PUBLIC_MINT_TIMESTAMP || dropStatus != DropStatus.PUBLIC) {
            revert PublicMintNotActive();
        }
        _;
    }

    modifier claimEnabled() {
        if (block.timestamp < WHITELIST_START_TIMESTAMP) {
            revert ClaimNotActive();
        }
        _;
    }

    modifier eligibleForClaim() {
        if (_presaleAllocationsByWallet[msg.sender] == 0) {
            revert NotEligible();
        }
        _;
    }

    modifier supplyIsAvailable(uint256 quantity) {
        if (quantity + _nextTokenId() > MAX_SUPPLY - _presaleSupplyOffset) {
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

    modifier obeysWalletLimit(uint256 quantity) {
        if (
            _mintedPerWallet[msg.sender] + _presaleAllocationsByWallet[msg.sender] + quantity > MAX_MINT_PER_WALLET
                && msg.sender != owner()
        ) {
            revert ExceedsMaxMintPerWallet();
        }
        _;
    }

    modifier onlyEOA() {
        if (tx.origin != msg.sender) {
            revert NonEOACaller();
        }
        _;
    }

    constructor(address whitelistSigner_, uint256 startTokenId_)
        ERC721A("Gloomers", "GLOOMERS")
        Ownable(msg.sender)
        WhitelistVerifier(whitelistSigner_)
        StartTokenIdHelper(startTokenId_)
    {
        _setDefaultRoyalty(msg.sender, 500);
    }

    function mint(uint256 quantity)
        external
        payable
        dropEnabled
        publicMintActive
        fundsAttached(quantity)
        obeysWalletLimit(quantity)
        supplyIsAvailable(quantity)
        onlyEOA
    {
        _mintedPerWallet[msg.sender] += quantity;
        _mint(msg.sender, quantity);

        emit GloomersMint(msg.sender, quantity);
    }

    function mintWhitelist(uint256 quantity, bytes32 hash, bytes memory signature)
        external
        payable
        dropEnabled
        whitelistActive
        validatedWhitelistRequest(hash, signature)
        fundsAttached(quantity)
        obeysWalletLimit(quantity)
        supplyIsAvailable(quantity)
        onlyEOA
    {
        _mintedPerWallet[msg.sender] += quantity;
        _mint(msg.sender, quantity);

        emit MintWhitelist(msg.sender, quantity);
        (msg.sender, quantity);
    }

    function registerPresale(uint256 quantity, bytes32 hash, bytes memory signature)
        external
        payable
        dropEnabled
        presaleActive
        validatedWhitelistRequest(hash, signature)
        fundsAttached(quantity)
        obeysWalletLimit(quantity)
        supplyIsAvailable(quantity)
        onlyEOA
    {
        ++_presalesCount;
        _presaleSupplyOffset += quantity;
        _presaleAllocationsByWallet[msg.sender] = quantity;
        _presaleWalletsById[_presalesCount] = msg.sender;

        emit RegisterPresale(msg.sender, quantity);
        (msg.sender, quantity);
    }

    function claimPresale()
        external
        dropEnabled
        claimEnabled
        eligibleForClaim
        obeysWalletLimit(_presaleAllocationsByWallet[msg.sender])
        onlyEOA
    {
        uint256 quantity = _presaleAllocationsByWallet[msg.sender];
        _mintedPerWallet[msg.sender] += quantity;
        _presaleAllocationsByWallet[msg.sender] = 0;
        _presaleSupplyOffset -= quantity;
        _mint(msg.sender, quantity);

        emit GloomersMint(msg.sender, quantity);
    }

    function getPresaleAllocation(address wallet) public view returns (uint256) {
        return _presaleAllocationsByWallet[wallet];
    }

    function _startTokenId() internal view override returns (uint256) {
        return startTokenId();
    }

    function _sequentialUpTo() internal view override returns (uint256) {
        return _startTokenId() + MAX_SUPPLY;
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(IERC721A, ERC721A) returns (string memory) {
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }
        string memory baseURI = _baseURI();
        string memory metadataPointerId = !revealed ? "" : _toString(tokenId);
        string memory result = string(abi.encodePacked(baseURI, metadataPointerId));
        return bytes(baseURI).length != 0 ? result : "";
    }

    function setTokenUri(string calldata baseTokenURI_) external onlyOwner {
        revealed = true;
        _baseTokenURI = baseTokenURI_;
        emit BatchMetadataUpdate(_startTokenId(), (type(uint256).max));
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setWhitelistSigner(address whitelistSigner_) public onlyOwner {
        _setWhitelistSigner(whitelistSigner_);
    }

    function setDropStatus(DropStatus newDropStatus) public onlyOwner {
        dropStatus = newDropStatus;
        emit NewDropStatus(newDropStatus);
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}
