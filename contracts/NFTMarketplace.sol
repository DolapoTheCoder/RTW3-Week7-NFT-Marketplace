//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

//import the ERC721 contract

contract NFTMarketPlace is ERC721URIStorage {
    using Counters for Counters.Counter;
    address payable owner;
    Counters.Counter private nftId;
    Counters.Counter private nftSold;
    uint256 listPrice = 0.01 ether;
    struct ListedToken {
        uint256 nftId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }
    event TokenListedSuccess(
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint256 price,
        bool currentlyListed
    );
    mapping(uint256 => ListedToken) public idToNft;

    constructor() ERC721("DolaNFT", "DNFT") {
        owner = payable(msg.sender);
    }

    //updateListPrice, getListPrice, getLatestIdToListedToken, getListedTokenForId
    //getCurrentToken, createToken, createListedToken, getAllNFTs
    //getMyNFTs, executeSale

    function updateListPrice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "Only owner can update listing price");
        listPrice = _listPrice;
    }

    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    function getListedTokenForId(uint256 _tokenId)
        public
        view
        returns (ListedToken memory)
    {
        require(
            idToNft[_tokenId].nftId == _tokenId,
            "No Token is associated to this Token ID."
        );
        return idToNft[_tokenId];
    }

    function getCurrentToken() public view returns (uint256) {
        return nftId.current();
    }

    function getLatestIdToListedToken()
        public
        view
        returns (ListedToken memory)
    {
        return idToNft[getCurrentToken()];
    }

    function createToken(string memory tokenURI, uint256 price)
        public
        payable
        returns (uint256)
    {
        nftId.increment();
        uint256 newTokenId = nftId.current();
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createListedToken(newTokenId, price);
        return newTokenId;
    }

    function createListedToken(uint256 _newTokenId, uint256 price) private {
        require(price > 0, "Price must be be greater than 0.");
        require(
            msg.value >= price,
            "Please send minimum the price you set Ether."
        );

        idToNft[_newTokenId] = ListedToken(
            _newTokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            true
        );

        emit TokenListedSuccess(
            _newTokenId,
            idToNft[_newTokenId].owner,
            idToNft[_newTokenId].seller,
            price,
            true
        );
    }

    function getAllNfts() public view returns (ListedToken[] memory) {
        uint256 nftCount = nftId.current();
        ListedToken[] memory tokens = new ListedToken[](nftCount);
        uint256 currentIndex = 0;
        uint256 currentId;
        for (uint256 i = 0; i < nftCount; i++) {
            currentId = i + 1;
            if (idToNft[currentId].currentlyListed == true) {
                ListedToken storage currentItem = idToNft[currentId];
                tokens[currentIndex] = currentItem;
            }
            currentIndex += 1;
        }
        return tokens;
    }

    function getMyNFTs() public view returns (ListedToken[] memory) {
        uint256 totalItemCount = nftId.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        uint256 currentId;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                idToNft[i + 1].owner == msg.sender ||
                idToNft[i + 1].seller == msg.sender
            ) {
                itemCount += 1;
            }
        }

        ListedToken[] memory items = new ListedToken[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                idToNft[i + 1].owner == msg.sender ||
                idToNft[i + 1].seller == msg.sender
            ) {
                currentId = i + 1;
                ListedToken storage currentItem = idToNft[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function executeSale(uint256 tokenId) public payable {
        uint256 price = idToNft[tokenId].price;
        address seller = idToNft[tokenId].seller;
        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );

        idToNft[tokenId].currentlyListed = true;
        idToNft[tokenId].seller = payable(msg.sender);
        nftSold.increment();

        _transfer(address(this), msg.sender, tokenId);

        approve(address(this), tokenId);

        payable(owner).transfer(listPrice);
        payable(seller).transfer(msg.value);
    }
}
