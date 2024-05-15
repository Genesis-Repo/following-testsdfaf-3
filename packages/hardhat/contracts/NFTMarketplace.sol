// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC721Enumerable, Ownable {
    using Address for address payable;

    struct NFT {
        address owner;
        uint256 price;
        bool isListed;
    }

    mapping(uint256 => NFT) public nfts;
    mapping(address => uint256[]) public userNFTs;

    event NFTListed(uint256 indexed tokenId, address owner, uint256 price);
    event NFTUnlisted(uint256 indexed tokenId, address owner);
    event NFTSold(uint256 indexed tokenId, address seller, address buyer, uint256 price);

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function listNFT(uint256 tokenId, uint256 price) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Market: Caller is not owner nor approved");
        require(price > 0, "Market: Price must be greater than zero");

        nfts[tokenId] = NFT(_msgSender(), price, true);
        userNFTs[_msgSender()].push(tokenId);

        emit NFTListed(tokenId, _msgSender(), price);
    }

    function unlistNFT(uint256 tokenId) external {
        require(msg.sender == nfts[tokenId].owner, "Market: Caller is not the NFT owner");

        delete nfts[tokenId];

        emit NFTUnlisted(tokenId, msg.sender);
    }

    function buyNFT(uint256 tokenId) external payable {
        NFT memory nft = nfts[tokenId];
        require(nft.isListed, "Market: NFT is not listed");
        require(msg.value >= nft.price, "Market: Insufficient payment");

        address seller = nft.owner;

        _transfer(seller, _msgSender(), tokenId);
        nfts[tokenId].isListed = false;

        payable(seller).sendValue(msg.value);

        emit NFTSold(tokenId, seller, _msgSender(), nft.price);
    }

    function getUserNFTs() external view returns (uint256[] memory) {
        return userNFTs[_msgSender()];
    }

    function getNFT(uint256 tokenId) external view returns (address owner, uint256 price, bool isListed) {
        NFT memory nft = nfts[tokenId];
        return (nft.owner, nft.price, nft.isListed);
    }
}