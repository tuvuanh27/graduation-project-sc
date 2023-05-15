// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract NFT is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC721BurnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    mapping(uint256 => address[]) private _tokenViewers;
    mapping(uint => bool) private tokenPublic;
    mapping(uint => uint) public salePrice;
    uint256 public mintingFee;

    event TokenMinted(address indexed minter, uint256 indexed tokenId, string uri, uint256 price, bool isPublic);
    event ChangeTokenPublic(uint256 indexed tokenId, bool isPublic);
    event AddViewer(uint256 indexed tokenId, address viewer);
    event RemoveViewer(uint256 indexed tokenId, address viewer);
    event SaleToken(uint256 indexed tokenId, uint256 price);
    event BuyToken(uint256 indexed tokenId, address buyer, uint256 price);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev fallback function
     */
    fallback() external {
        revert();
    }

    /**
     * @dev fallback function
     */
    receive() external payable {
        revert();
    }

    function initialize(string memory name, string memory symbol) external initializer {
        __ERC721_init(name, symbol);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __ReentrancyGuard_init();

        mintingFee = 0.1 ether;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMintingFee(uint256 _mintingFee) external onlyOwner {
        mintingFee = _mintingFee;
    }

    function setSalePrice(uint256 tokenId, uint256 price) external {
        require(_exists(tokenId), "Token does not exist");
        require(msg.sender == owner() || msg.sender == ownerOf(tokenId), "Not authorized to set sale price");

        salePrice[tokenId] = price;
        emit SaleToken(tokenId, price);
    }

    function buyToken(uint256 tokenId) external payable nonReentrant {
        require(_exists(tokenId), "Token does not exist");
        require(salePrice[tokenId] > 0, "Token is not for sale");
        require(msg.value >= salePrice[tokenId], "Insufficient payment");

        address tokenOwner = ownerOf(tokenId);
        address payable payableTokenOwner = payable(tokenOwner);
        payableTokenOwner.transfer(msg.value);

        _transfer(tokenOwner, msg.sender, tokenId);
        salePrice[tokenId] = 0;
        emit BuyToken(tokenId, msg.sender, msg.value);
    }

    function isNftPublic(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        return tokenPublic[tokenId];
    }

    // function check address in in viewers list of token
    function isViewer(uint256 tokenId, address viewer) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        if (tokenPublic[tokenId] || msg.sender == ownerOf(tokenId) || msg.sender == owner()) {
            return true;
        }

        address[] memory viewers = _tokenViewers[tokenId];
        for (uint256 i = 0; i < viewers.length; i++) {
            if (viewers[i] == viewer) {
                return true;
            }
        }
        return false;
    }

    // get viewers of token
    function getTokenViewers(uint256 tokenId) public view returns (address[] memory) {
        require(_exists(tokenId), "Token does not exist");
        if (
            tokenPublic[tokenId] ||
            msg.sender == ownerOf(tokenId) ||
            msg.sender == owner() ||
            isApprovedForAll(ownerOf(tokenId), msg.sender)
        ) {
            return _tokenViewers[tokenId];
        } else {
            revert("Not authorized to view token viewers");
        }
    }

    function addTokenViewer(uint256 tokenId, address viewer) public {
        require(_exists(tokenId), "Token does not exist");
        require(msg.sender == owner() || msg.sender == ownerOf(tokenId), "Not authorized to add viewer");

        _tokenViewers[tokenId].push(viewer);
        emit AddViewer(tokenId, viewer);
    }

    function removeTokenViewer(uint256 tokenId, address viewer) public {
        require(_exists(tokenId), "Token does not exist");
        require(msg.sender == owner() || msg.sender == ownerOf(tokenId), "Not authorized to remove viewer");

        address[] storage viewers = _tokenViewers[tokenId];
        for (uint256 i = 0; i < viewers.length; i++) {
            if (viewers[i] == viewer) {
                viewers[i] = viewers[viewers.length - 1];
                viewers.pop();
                break;
            }
        }
        emit RemoveViewer(tokenId, viewer);
    }

    function changeTokenPublic(uint256 tokenId, bool isPublic) public {
        require(_exists(tokenId), "Token does not exist");
        require(msg.sender == owner() || msg.sender == ownerOf(tokenId), "Not authorized to change token public");

        tokenPublic[tokenId] = isPublic;
        emit ChangeTokenPublic(tokenId, isPublic);
    }

    function mint(string memory _uri, bool _isTokenPublic) external payable nonReentrant returns (uint256) {
        require(msg.value >= mintingFee, "Insufficient payment");

        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _uri);
        _tokenIdCounter.increment();
        tokenPublic[newTokenId] = _isTokenPublic;
        emit TokenMinted(msg.sender, newTokenId, _uri, msg.value, _isTokenPublic);

        return newTokenId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // add function add to view after approve
    function approve(address to, uint256 tokenId) public override {
        super.approve(to, tokenId);
        if (to != address(0)) {
            addTokenViewer(tokenId, to);
        }
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        if (
            tokenPublic[tokenId] == true ||
            isViewer(tokenId, msg.sender) ||
            msg.sender == ownerOf(tokenId) ||
            msg.sender == owner() ||
            isApprovedForAll(ownerOf(tokenId), msg.sender)
        ) {
            return super.tokenURI(tokenId);
        } else {
            return "Not authorized to view token URI";
        }
    }

    function getAllNFTIdsOfAddress(address account) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(account);
        uint256[] memory tokenIds = new uint256[](balance);

        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(account, i);
        }

        return tokenIds;
    }

    // withdraw all funds from the contract
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
