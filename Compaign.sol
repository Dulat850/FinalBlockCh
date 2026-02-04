// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ShoesNFT {
    string public name = "Exclusive Shoes";
    string public symbol = "SHOES";
    
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    uint256 public totalSupply;
    uint256 public nextTokenId;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    constructor() {
        nextTokenId = 0;
    }
    
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
    
    function mint(address to) public {
        uint256 tokenId = nextTokenId;
        balanceOf[to]++;
        ownerOf[tokenId] = to;
        totalSupply++;
        nextTokenId++;
        emit Transfer(address(0), to, tokenId);
    }
}
