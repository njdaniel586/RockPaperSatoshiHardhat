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

    struct RareItemAttributes{//Struct to contain the individual attributed of each of the ERC721 rare item tokens.
        uint256 tokenId;//Id of the token which will be the same as what's stored in the contract. This increments numerically as more get minted
        uint256 lossAbsorb;//Attribute of the rare item that provides single use loss prevention to the user.
        uint256 incomeForWinBonus;//Attribute of the rare item that provides a income buff to the user when they win.
        uint256 maxHealthIncreaseModifier;//Attribute of the rare item that provides a max health buff to the user.
        uint256 healthCostToUse;//Attribute of the rare item that costs the user health for each use.
        bool equipped;//This is used to track whether or not the rare item is equipped for the user.
    }

    mapping(uint256 => RareItemAttributes) private rareItemAttributes;//Rare item attributes mapped by token id.

    event emitRareItemAttributes(RareItemAttributes rareItemAttributes_);//Event for emitting the rare item attributes.

    constructor() ERC721("RPSRareItems", "RPR") {}//Nothing to do in the constructor.

    function safeMint(address to, uint256 winStreak) public onlyOwner {//ERC721 inherent function for minting tokens + logic for rare item attributes.
        uint256 tokenId_ = _tokenIdCounter.current();//ERC721 inherent
        _tokenIdCounter.increment();//ERC721 inherent
        _safeMint(to, tokenId_);//ERC721 inherent
//Next I think I want to emit that a rare item got minted
        rareItemAttributes[tokenId_].tokenId = tokenId_;//Set the token Id in the rare item attributes to the token Id assigned by the inherent ERC721 enumerable function.

        uint256 lossAbsorbRoll = ((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId_,"1")))) % 100) + 1 + winStreak; // roll a random number from 1 to 100 + bonus for players winstreak.
        if(lossAbsorbRoll >= 90) {  // 10% chance to get loss absorb
            rareItemAttributes[tokenId_].lossAbsorb = 1;        
        }

        uint256 incomeBonusRoll = ((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId_,"2")))) % 100) + 1 + winStreak; // roll a random number from 1 to 100 + bonus for players winstreak.
        if(incomeBonusRoll <= 50) {  // 50% chance of bonus amount 5
            rareItemAttributes[tokenId_].incomeForWinBonus = 5;
        } else if(incomeBonusRoll <= 75) {  // 25% chance of bonus amount 10
            rareItemAttributes[tokenId_].incomeForWinBonus = 10;
        } else if(incomeBonusRoll <= 88) {  // 13% chance of bonus amount 15
            rareItemAttributes[tokenId_].incomeForWinBonus = 15;
        } else if(incomeBonusRoll <= 95) {  // 7% chance of bonus amount 20
            rareItemAttributes[tokenId_].incomeForWinBonus = 20;
        } else{  // 5% chance of bonus amount 25
            rareItemAttributes[tokenId_].incomeForWinBonus = 25;
        }

        uint256 maxHealthBonusRoll = ((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId_,"3")))) % 100) + 1 + winStreak; // roll a random number from 1 to 100 + bonus for players winstreak.
        if(maxHealthBonusRoll <= 50) {  // 50% chance of max health bonus amount 10
            rareItemAttributes[tokenId_].maxHealthIncreaseModifier = 10;
        } else if(maxHealthBonusRoll <= 75) {  // 25% chance of max health bonus amount 20
            rareItemAttributes[tokenId_].maxHealthIncreaseModifier = 20;
        } else if(maxHealthBonusRoll <= 88) {  // 13% chance of max health bonus amount 30
            rareItemAttributes[tokenId_].maxHealthIncreaseModifier = 30;
        } else if(maxHealthBonusRoll <= 95) {  // 7% chance of max health bonus amount 40
            rareItemAttributes[tokenId_].maxHealthIncreaseModifier = 40;
        } else{  // 5% chance of max health bonus amount 50
            rareItemAttributes[tokenId_].maxHealthIncreaseModifier = 50;
        }

        uint256 healthCostToUseRoll = ((uint256(keccak256(abi.encodePacked(block.timestamp,to,tokenId_,"4")))) % 100) + 1 + winStreak; // roll a random number from 1 to 100 + bonus for players winstreak.
        if(healthCostToUseRoll <= 50) {  // 50% chance of health cost to use amount 10
            rareItemAttributes[tokenId_].healthCostToUse = 10;
        } else if(healthCostToUseRoll <= 75) {  // 25% chance of health cost to use amount 8
            rareItemAttributes[tokenId_].healthCostToUse = 8;
        } else if(healthCostToUseRoll <= 88) {  // 13% chance of health cost to use amount 7
            rareItemAttributes[tokenId_].healthCostToUse = 7;
        } else if(healthCostToUseRoll <= 95) {  // 7% chance of health cost to use amount 6
            rareItemAttributes[tokenId_].healthCostToUse = 6;
        } else{  // 5% chance of health cost to use 5
            rareItemAttributes[tokenId_].healthCostToUse = 5;
        }
    }

    function readAttributesByTokenId(uint256 tokenId) public view returns(RareItemAttributes memory){//Function that returns the attributes of the token Id provided.
        //emit emitRareItemAttributes(rareItemAttributes[tokenId]);
        return rareItemAttributes[tokenId];
    }

    function equipToken(uint256 tokenId) public onlyOwner{//Function that equips the rare item. This is called by the main rockPaperSatoshi contract.
        require(rareItemAttributes[tokenId].equipped == false, "Rare item is already equipped.");//Require that the rare item is not already equipped.
        rareItemAttributes[tokenId].equipped = true;//Mark the rare item as equipped.
    }

    function unequipToken(uint256 tokenId) public onlyOwner{
        //Should I also take in the msg.sender from the main contract and then confirm they are the owner of the tokenId as a double check?
        require(rareItemAttributes[tokenId].equipped == true);
        rareItemAttributes[tokenId].equipped = false;
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
