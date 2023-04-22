// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.8.3/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.8.3/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.8.3/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts@4.8.3/access/Ownable.sol";
import "@openzeppelin/contracts@4.8.3/utils/Counters.sol";

contract RPSRareItemsToken is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    struct RareItemAttributes{
        uint256 lossAbsorb;
        uint256 incomeForWinOverride;
        uint256 healthChangeFromLossOverride;
        uint256 RPSatoshiCostToUse;
        uint256 healthCostToUse;
        bool enabled;
    }

    mapping(uint256 => RareItemAttributes) private rareItemAttributes;

    event emitRareItemAttributes(RareItemAttributes rareItemAttributes_);


    constructor() ERC721("RPSRareItems", "RPR") {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        if(((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId,"1")))) % 2) == 1){//50% chance to provide lossAbsorb
            rareItemAttributes[tokenId].lossAbsorb = 1;
        }
        if(((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId,"2")))) % 2) == 1){
            rareItemAttributes[tokenId].incomeForWinOverride = (((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId,"2")))) % 5 + 1)*5);//Equal chance of a 5,10,15,20, or 25 income override for a win.
        }
        if(((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId,"3")))) % 2) == 1){
            rareItemAttributes[tokenId].healthChangeFromLossOverride = (((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId,"3")))) % 5 + 1)*5);//Equal chance of a 5,10,15,20, or 25 health loss override for a loss.
        }
        if(((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId,"4")))) % 2) == 1){
            rareItemAttributes[tokenId].RPSatoshiCostToUse = (((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId,"4")))) % 5 + 1)*5);//Equal chance of a 5,10,15,20, or 25 RPSatoshi cost for each battle used.
        }
        if(((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId,"5")))) % 2) == 1){
            rareItemAttributes[tokenId].healthCostToUse = (((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId,"5")))) % 5 + 1)*5);//Equal chance of a 5,10,15,20, or 25 health cost for each battle used.
        }
    }


    function readAttributesByTokenId(uint256 tokenId) public returns(RareItemAttributes memory){//Should this be onlyOwner?
        emit emitRareItemAttributes(rareItemAttributes[tokenId]);
        return rareItemAttributes[tokenId];
    }

    function enableToken(uint256 tokenId) public onlyOwner{
        //Should I also take in the msg.sender from the main contract and then confirm they are the owner of the tokenId as a double check?
        rareItemAttributes[tokenId].enabled = true;
    }


    //I should write gas free function that emits all the RareItems owned by the caller*****

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
