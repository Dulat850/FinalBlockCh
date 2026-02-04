// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ShoeNFT is ERC721, Ownable {
    uint256 public nextTokenId;

    // Конструктор
    constructor() ERC721("ShoeNFT", "SHOE") Ownable(msg.sender) {}

    // Минт нового NFT
    function mint(address to) external onlyOwner {
        _safeMint(to, nextTokenId);
        nextTokenId++;
    }

    // Сжигание NFT (потратить NFT на покупку обуви)
    function burn(uint256 tokenId) external {
        // Проверяем, что NFT принадлежит отправителю
        require(ownerOf(tokenId) == msg.sender, "Вы не владелец этого NFT");
        _burn(tokenId);
    }
}
