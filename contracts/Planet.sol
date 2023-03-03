// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// @title Planet NFT
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract Planet is Ownable, ERC721Enumerable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;
    

    uint256 public immutable maxSupply;
    address payable public payment;
    uint256 public saleStartTime;
    uint256 public salePrice;
    string public baseURI;
    Counters.Counter private _tokenIdCounter = Counters.Counter(1);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseuri,
        uint256 _salePrice,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) {
        salePrice = _salePrice * 10 ** 18;
        maxSupply = _maxSupply;
        baseURI = _baseuri;
    }

    function mint(uint256 _quantity)
        external
        payable
        nonReentrant
    {
        require(totalSupply() + _quantity <= maxSupply, "Max supply exceed");
        uint256 totalPrice = salePrice * _quantity;
        require(msg.value >= totalPrice, "Not enough funds");
        _batchMint(msg.sender, _quantity);
        refundIfOver(totalPrice);
    }



    function withdraw() external {
        uint256 amount = address(this).balance;
        if (amount > 0) {
            Address.sendValue(payable(owner()), amount);
        }
    }

    function withdraw(IERC20 token) external {
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "No tokens to withdraw");
        SafeERC20.safeTransfer(token, payable(owner()), amount);
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }


    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _batchMint(address _account, uint256 _quantity) internal {
        for(uint8 i = 0;i< _quantity;i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(_account, tokenId);
        }
    }

    
    function refundIfOver(uint256 price) private {
        if (msg.value > price) {
            Address.sendValue(payable(msg.sender), msg.value - price);
        }
    }

}
