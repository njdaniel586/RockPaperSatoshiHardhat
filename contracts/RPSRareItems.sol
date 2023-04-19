// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.8.3/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.8.3/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.8.3/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts@4.8.3/access/Ownable.sol";
import "@openzeppelin/contracts@4.8.3/utils/Counters.sol";

contract RPSRareItems is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    struct RareItemAttributes{
        uint256 lossAbsorb;
        uint256 incomeForWinOverride;
        uint256 healthChangeFromLossOverride;
        uint256 RPSatoshiCostToUse;
        uint256 healthCostToUse;
        bool enabeled;
    }

    mapping(uint256 => RareItemAttributes) private rareItemAttributes;

    constructor() ERC721("RPSRareItems", "RPR") {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        if(((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId,"1")))) % 2) == 1){
            rareItemAttributes[tokenId].lossAbsorb = 1;
        }
        if(((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId,"2")))) % 2) == 1){
            rareItemAttributes[tokenId].incomeForWinOverride = (((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId,"2")))) % 5 + 1)*5);
        }
        if(((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId,"3")))) % 2) == 1){
            rareItemAttributes[tokenId].healthChangeFromLossOverride = (((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId,"2")))) % 5 + 1)*5);
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
