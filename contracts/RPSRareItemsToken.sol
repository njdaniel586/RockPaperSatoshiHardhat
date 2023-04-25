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
        uint256 tokenId;
        uint256 lossAbsorb;
        uint256 incomeForWinOverride;
        uint256 healthModifier;
        uint256 RPSatoshiCostToUse;
        uint256 healthCostToUse;
        bool enabled;
    }

    mapping(uint256 => RareItemAttributes) private rareItemAttributes;//Rare item attributes mapped by token id.

    event emitRareItemAttributes(RareItemAttributes rareItemAttributes_);


    constructor() ERC721("RPSRareItems", "RPR") {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId_ = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId_);

        rareItemAttributes[tokenId_].tokenId = tokenId_;

        if(((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId_,"1")))) % 2) == 1){//50% chance to provide lossAbsorb
            rareItemAttributes[tokenId_].lossAbsorb = 1;
        }
        if(((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId_,"2")))) % 2) == 1){
            rareItemAttributes[tokenId_].incomeForWinOverride = (((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId_,"2")))) % 5 + 1)*5);//Equal chance of a 5,10,15,20, or 25 income override for a win.
        }
        if(((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId_,"3")))) % 2) == 1){
            rareItemAttributes[tokenId_].healthModifier = (((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId_,"3")))) % 5 + 1)*10);//Equal chance of a 10,20,30,40, or 50 increase to max health (when equipped).
        }
        if(((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId_,"4")))) % 2) == 1){
            rareItemAttributes[tokenId_].RPSatoshiCostToUse = (((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId_,"4")))) % 5 + 1)*5);//Equal chance of a 5,10,15,20, or 25 RPSatoshi cost for each battle used.
        }
        if(((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId_,"5")))) % 2) == 1){//Probably should make it a garunteeed health loss if lossAbsorb is enabled.
            rareItemAttributes[tokenId_].healthCostToUse = (((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId_,"5")))) % 5 + 1)*5);//Equal chance of a 5,10,15,20, or 25 health cost for each battle used.
        }
    }


    function readAttributesByTokenId(uint256 tokenId) public returns(RareItemAttributes memory){//Should this be onlyOwner?
        emit emitRareItemAttributes(rareItemAttributes[tokenId]);
        return rareItemAttributes[tokenId];
    }

    function enableToken(uint256 tokenId) public onlyOwner{
        //Should I also take in the msg.sender from the main contract and then confirm they are the owner of the tokenId as a double check?
        require(rareItemAttributes[tokenId].enabled == false);
        rareItemAttributes[tokenId].enabled = true;
    }


    function getAllTokensOwnedByAddress(address address_) public view returns(RareItemAttributes[] memory rareItemAttributes_){//Gass free return of all tokens owned by the given address.
        RareItemAttributes[] memory _rareItemAttributes = new RareItemAttributes[](balanceOf(address_));
        for(uint256 i; i < balanceOf(address_); i++){
            uint256 tokenId_ = tokenOfOwnerByIndex(address_, i);
            _rareItemAttributes[i] = rareItemAttributes[tokenId_];
        }
        return _rareItemAttributes;
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
