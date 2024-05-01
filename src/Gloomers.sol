// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC721A, ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {StartTokenIdHelper} from "erc721a/contracts/extensions/StartTokenIdHelper.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @title Gloomers #6667 - #10000
 * @author soko.eth | Gloom Labs | https://www.gloomtoken.com
 * @dev ERC721A contract with presale, whitelist, and public minting periods.
 * @notice Gloomers is a 10k PFP collection launched across Base, Solana, and Optimism with teleburning to Bitcoin
 */
contract Gloomers is
    StartTokenIdHelper,
    ERC721A,
    ERC721AQueryable,
    ERC2981,
    Ownable
{
    uint256 public constant START_TOKEN_ID = 6667;
    uint256 public constant END_TOKEN_ID = 10000;
    uint256 public constant PRICE_PER_TOKEN = 0.03 ether;
    uint256 public constant MAX_MINT_PER_WALLET = 3;
    bytes32 public constant PROVENANCE_HASH =
        0x5158cf3ac201d8d9dfe63ac7c7d1e7aa58b7c33426665c9bf643e0003e095e2f;
    uint256 public constant WHITELIST_START_TIMESTAMP = 1714838400; // Sat May 04 2024 16:00:00 GMT
    uint256 public constant PUBLIC_MINT_TIMESTAMP =
        WHITELIST_START_TIMESTAMP + 3 hours;

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
    bytes32 private gloomerHash;

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
        if (block.timestamp > WHITELIST_START_TIMESTAMP) {
            revert PresaleNotActive();
        }
        _;
    }

    modifier whitelistActive() {
        if (
            block.timestamp < WHITELIST_START_TIMESTAMP ||
            block.timestamp > PUBLIC_MINT_TIMESTAMP
        ) {
            revert WhitelistNotActive();
        }
        _;
    }

    modifier publicMintActive() {
        if (block.timestamp < PUBLIC_MINT_TIMESTAMP) {
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
        if (
            quantity + _nextTokenId() - 1 > END_TOKEN_ID - _presaleSupplyOffset
        ) {
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
            _mintedPerWallet[msg.sender] +
                _presaleAllocationsByWallet[msg.sender] +
                quantity >
            MAX_MINT_PER_WALLET &&
            msg.sender != owner()
        ) {
            revert ExceedsMaxMintPerWallet();
        }
        _;
    }

    modifier gloomin(bytes32 gloomerHash_) {
        if (gloomerHash != gloomerHash_) {
            revert NotEligible();
        }
        _;
    }

    modifier onlyEOA() {
        if (tx.origin != msg.sender) {
            revert NonEOACaller();
        }
        _;
    }

    constructor()
        StartTokenIdHelper(START_TOKEN_ID)
        ERC721A("Gloomers", "GLOOMERS")
        Ownable(msg.sender)
    {
        _setDefaultRoyalty(msg.sender, 500);
    }

    function mint(
        uint256 quantity
    )
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

    function mintWhitelist(
        uint256 quantity,
        bytes32 gloomerHash_
    )
        external
        payable
        dropEnabled
        whitelistActive
        fundsAttached(quantity)
        obeysWalletLimit(quantity)
        supplyIsAvailable(quantity)
        gloomin(gloomerHash_)
        onlyEOA
    {
        if (gloomerHash != gloomerHash_) {
            revert NotEligible();
        }
        _mintedPerWallet[msg.sender] += quantity;
        _mint(msg.sender, quantity);

        emit MintWhitelist(msg.sender, quantity);
        (msg.sender, quantity);
    }

    function registerPresale(
        uint256 quantity,
        bytes32 gloomerHash_
    )
        external
        payable
        dropEnabled
        presaleActive
        fundsAttached(quantity)
        obeysWalletLimit(quantity)
        supplyIsAvailable(quantity)
        gloomin(gloomerHash_)
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

    function getPresaleAllocation(
        address wallet
    ) public view returns (uint256) {
        return _presaleAllocationsByWallet[wallet];
    }

    function _startTokenId() internal view override returns (uint256) {
        return startTokenId();
    }

    function _baseURI()
        internal
        view
        override(ERC721A)
        returns (string memory)
    {
        return _baseTokenURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(IERC721A, ERC721A) returns (string memory) {
        if (!revealed) {
            return _baseURI();
        }
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }
        string memory baseURI = _baseURI();
        string memory metadataPointerId = !revealed ? "" : _toString(tokenId);
        string memory result = string(
            abi.encodePacked(baseURI, metadataPointerId)
        );
        return bytes(baseURI).length != 0 ? result : "";
    }

    function setTokenUri(string calldata baseTokenURI_) external onlyOwner {
        revealed = true;
        _baseTokenURI = baseTokenURI_;
        emit BatchMetadataUpdate(_startTokenId(), (type(uint256).max));
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setDropStatus(DropStatus newDropStatus) public onlyOwner {
        dropStatus = newDropStatus;
        emit NewDropStatus(newDropStatus);
    }

    function setGloomerHash(bytes32 gloomerHash_) public onlyOwner {
        gloomerHash = gloomerHash_;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    fallback() external payable {}

    receive() external payable {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}
