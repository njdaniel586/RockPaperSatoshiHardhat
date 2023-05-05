// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

//import "hardhat/console.sol";

import "./RPSatoshiToken.sol";
import "./RPSHashHealToken.sol";
import "./RPSRareItemsToken.sol";

contract rockPaperSatoshi {
    string public contractName = "rockPaperSatoshi";

    RPSatoshiToken private RPSatoshi;//This is our general currency token contract.
    RPSHashHealToken private RPSHashHeal;//This is our common healing item contract.
    RPSRareItemsToken private RPSRareItems;//This is our contract for minting and keeping track of unique/rare items the player can obtain.

    struct player {
        string name;//A store of the players name.
        bool registered;//Wether or not the player is registered
        uint256 health;//The current health of the player (changes with any healing/damage taken).
        bool inPvEEncounter;//Wether or not the player is in a PvE battle.
        uint256 winStreak;//The current win streak of the player.
        uint256 maxWinStreak;//The max win streak the player has acheived.
        uint256 currentLossAbsorbMax;//loss absorb is basically loss protection when the user loses a round. currentLossAbsorbMax is the maximum amount of loss absorbs they have (due to rare item modifiers) going into a battle.
        uint256 currentLossAbsorb;//loss absorb is basically loss protection when the user loses a round. currentLossAbsorb is the current ammount of loss absorbs they have left. Basically the max - # of losses so far in battle. This resets to max when a battle is initiated.
        uint256 currentIncomeForWinBonus;//The bonus in RPSatoshis the player will get for each win. This comes from rare items the user has equipt.
        uint256 healthMax;//The max health the player will have when fully healed. Default is 100 but can be increased with a rare item that has a health modifier.
        //uint256 currentRPSatoshiCostToUse;//Probably can remove. Unneeded complexity
        uint256 currentHealthCostToUse;//The health cost associated for each time the user battles (even if the user draws or has a loss absorb). Put another way, this is the health cost each time a user plays a rock, paper, or scissors regardless of the outcome.
    }

    address public owner;//Owner of the contract. Initialized in the constructor.

    address public RPSKingAddress;//Address of current win streak king of all time.
    string public RPSKingName;//Name of current win streak king of all time.
    uint256 public RPSKingStreak;//Highest win streak of all time.

    mapping(address => player) public players;//Mapping of all players (using the player struct).

    uint256 totalPlayers;//Keeps track of all the player that have registered since the launch of the contract.

    event botBattled(//Event emitted when a battle happens to report out the outcome.
        address _currentPlayer,
        string _outcome
    );

    event emitRareItemAttributesFromMainContract(//Event emitted to report out the attributes of a rare item such as when the rare item is earned/minted.
        string _message,
        uint256 _lossAbsorb,//Loss absorbe attribute of rare item.
        uint256 _incomeForWinBonus,//Income for win bonus attribute from rare item.
        uint256 _maxHealthIncreaseModifier,//Health increase modifier attribute from rare item.
        uint256 _healthCostToUse,//Health cost to use attribute from rare item.
        bool _equipped//Rare item equipped status.
    );

    event emitUint256(string message, uint256 value);//Used for debugging

    constructor() {
        owner = msg.sender;//Initialize owner address.
        RPSatoshi = new RPSatoshiToken();//Initialize RPSatoshiToken (ERC20) contract which is the main currency for Rock Paper Satoshi.
        RPSHashHeal = new RPSHashHealToken();//Initialize RPSHashHealToken (ERC20) contract which is the main heal item for Rock Paper Satoshi.
        RPSRareItems = new RPSRareItemsToken();//Initialize RPSRareItemsToken (ERC721) contract which handles all the rare items for Rock Paper Satoshi.
    }

    modifier onlyOwner() {//Function modifier for actions only the contract deployer/owner can perform.
        require(msg.sender == owner, "Only the owner can perform this.");
        _;
    }

    modifier onlyRegistered() {//Function modifier for actions only registered players can perform.
        require(players[msg.sender].registered, "Only registered players of Rock Paper Satoshi can perform this. Please register at www.RPSatoshi.com");
        _;
    }

    modifier onlyUnregisterd() {//Function modifier for actions only unregistered players can perform. Only used for register function.
        require(!players[msg.sender].registered,"Only unregistered players of Rock Paper Satoshi can perform this.");
        _;
    }

    modifier notInBattle() {
        require(!players[msg.sender].inPvEEncounter, "This cannot be performed while in battle.");
        _;
    }

    function getTokenAddress() public view returns (address, address, address){//Function that returns the addresses of the token contracts deployed.
        return (address(RPSatoshi), address(RPSHashHeal), address(RPSRareItems));
    }

    function register(string memory name_) public onlyUnregisterd {//Function for unregistered players to register.
        players[msg.sender].name = name_;//Store the registering player's name in the "players" mapping.
        players[msg.sender].registered = true;//Mark the player as registered.
        players[msg.sender].healthMax = 100;//Initialize the players max health to 100.
        players[msg.sender].health = 100;//Initialize the playerd health to 100. AKA start them off with full health.
        totalPlayers ++;//Increment the count of the total registered players for the contract.
    }

    function initPvE() public onlyRegistered notInBattle {//Function to initialize a PvE encounter. Players battle a bot until they win, lose, or run out of health due to a rare item costing health to use.
        require(players[msg.sender].health > 0 && players[msg.sender].health > players[msg.sender].currentHealthCostToUse, "Player does not have enough health to battle");//Require that the player has enough health to pay their rare item health cost.
        require(players[msg.sender].health <= 300, "Player's health is too high. What happened??");//Health should never be above 300 so this is a bug/exploit catch.
        players[msg.sender].inPvEEncounter = true;//Set the player's status to in battle.
        players[msg.sender].currentLossAbsorb = players[msg.sender].currentLossAbsorbMax;//Since it's the start of an encounter, set the players loss absorb to the max allowed by their rare item(s) (max of 2).
        
    }

    function battlePvE(uint256 move_) public onlyRegistered {//Function for the player to battle the bot encountered with either a rock, paper, or scissors. Possibly outcomes are draw, win, lose, and loss absorbed.
        require(players[msg.sender].inPvEEncounter == true, "The player must be in an encounter to perform this. Try initPvE");//Require the player to be in a PvE encounter.
        require(players[msg.sender].health > 0 || players[msg.sender].health > players[msg.sender].currentHealthCostToUse, "Player's health is too low");//Require the player to have more than 0 health and also enough health to pay the health cost of their rare item(s).
        require(players[msg.sender].health <= 300, "Players health is too high. What happened??");//Require the players health to be less than or equal to 300 which is the max possibly health in the game.
        players[msg.sender].health -= players[msg.sender].currentHealthCostToUse;//Player pays the health cost of their rare items.
        uint256 botMove = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 3;//This psudo-random-number generator takes the block time and the players address to come up with the bots move.
        //We use block time since our game will be too small of a fish to manipulate (likely) and charging $3 in gas for every PvE battle is too much.
        //But maybe I can use a real oracle once someone's win streak reaches 15 or something.

        //Time to compare the player's move vs the bot's move. 0 = rock, 1 = paper, 2 = scissors. So 1 beats 0, 2 beats 1, and 0 beats 2.
        if ((botMove == 0 && move_ == 1) || (botMove == 1 && move_ == 2) || (botMove == 2 && move_ == 0)) {//All scenarios where the player beats the bot.
            players[msg.sender].inPvEEncounter = false;//Since the player won, they are no longer in battle.

            RPSatoshi.mint(msg.sender, (10 + players[msg.sender].currentIncomeForWinBonus) * 10**RPSatoshi.decimals());//Give player their income reward for winning. Base of 10 RPSatoshis + any bonuses from rare item(s).
            uint256 rareItemRoll = ((uint256(keccak256(abi.encodePacked(block.timestamp,move_)))) % 100) + 1 + players[msg.sender].winStreak;//1-100 Roll + bonus for the current win streak for whether the player earns a rare item. Psudo-random generator using a keccak hash of the block time + player's chosen move.
            if(rareItemRoll > 95){//If the roll + win streak is greater than 95...
                RPSRareItems.safeMint(msg.sender,players[msg.sender].winStreak);//The player earns a rare item.
            }
            players[msg.sender].winStreak += 1;//Increment player win streak.
            if(players[msg.sender].winStreak > RPSKingStreak){//If player's new win streak makes them the new record holder.
                RPSKingStreak = players[msg.sender].winStreak;//Update the global win streak to that of the current player.
                RPSKingAddress = msg.sender;//Update the address of the highest win streak holder to the current player's address.
                RPSKingName = players[msg.sender].name;//Update the name of the highest win streak holder to the current player's name.
            }
            if (((uint256(keccak256(abi.encodePacked(block.timestamp,msg.sender,botMove,move_)))) % 2) == 1) {//psudo-random-number generator for if player receives a hash heal for their win. (50% chance of getting a hash heal).
                RPSHashHeal.mint(msg.sender, 1 * 10**RPSHashHeal.decimals());//Mint 1 hash heal to the palyer.
            }
            emit botBattled(//Emit the outcome of the battle (Player wins)
                msg.sender,
                "Player Wins!"
            );
        } else if (botMove == move_) {//If the player and bot chose the same move (Draw)
            //Draw
            emit botBattled(//Emit the outcome of the battle (Draw)
                msg.sender,
                "Draw"
            );
            //Player is still in battle since inPvEEncounter still = true
        } else {//This leaves the only remaining scenarios to be that the bot won. However we will take into account loss absorb below.
           if(players[msg.sender].currentLossAbsorb > 0 && players[msg.sender].currentLossAbsorb < 3){//If the player has loss absorb of 1 or 2. We make sure it's less than 3 because 2 should be the highest acheivable.
                players[msg.sender].currentLossAbsorb--;//Decrement the player's loss absorb.
                emit botBattled(//Emit the outcome of the battle (Loss absorbed).
                    msg.sender,
                    "Loss absorbed!"
                );
           } else{//If the player did not have loss absorb then the player has lost the encounter.
                players[msg.sender].winStreak = 0;//Reset the players win streak back to 0.
                if(players[msg.sender].health < 10){//Before we reduce the player's health by 10 for the loss, we check if it's less than 10 to prevent underflow of the uint256.
                    players[msg.sender].health = 0;//If they had less than 10 health, they they get reduced to 0;
                } else {
                    players[msg.sender].health -= 10;//Otherwise, they had 10 or more health and it can be reduced by 10.
                }
                
                players[msg.sender].inPvEEncounter = false;//Update so that the player is lo longer in a PvE encounter.
                emit botBattled(//Emit the outcome of the battle (bot wins).
                    msg.sender,
                    "Bot Wins"
                );
            }
        }
        if(players[msg.sender].health == 0){//If the players health reaches 0 from the previous battle,
            emit emitUint256("2nd Check: Player health is too low. They only have: ", players[msg.sender].health);
            players[msg.sender].winStreak = 0;//Reset the players win streak back to 0.
            players[msg.sender].inPvEEncounter = false;//Update so that the player is lo longer in a PvE encounter.
            return();//Need to return here otherwise reverting will reset the state change we made of inPvEEncounter = false.
        }
    }

    function useHashHeal() public onlyRegistered notInBattle {//Function for the player to use up a hash heal to heal their health.
        RPSHashHeal.burnFromUser(msg.sender, 1 * 10**RPSHashHeal.decimals());//Burn (use up) 1 hash heal from the user.
        if(players[msg.sender].health + 50 >= players[msg.sender].healthMax){//If the player would heal past max, then..
            players[msg.sender].health = players[msg.sender].healthMax;//Set the player's health to their max.
        } else{
            players[msg.sender].health += 50;//Otherwise, increase the players health by 50.
        }

    }

    function getHashHeal() public onlyRegistered {//Bug testing only. To be deleted.
        RPSHashHeal.mint(msg.sender, 1*10**RPSHashHeal.decimals());
    }

    function getMoney() public onlyRegistered {//Bug testing only. To be deleted.
        RPSatoshi.mint(msg.sender, 10*10**RPSatoshi.decimals());
    }

    function mintRareItem() public onlyRegistered {//Bug testing only. To be deleted. Needs to be incorporated into players playing/earning a win streak.
        RPSRareItems.safeMint(msg.sender,0);
        //Probably should emit what they get.
    }

    function equipRareItem(uint256 tokenId_) public onlyRegistered notInBattle {//Function for the player to equip rare items that they own.
        require(RPSRareItems.ownerOf(tokenId_) == msg.sender, "Player must be the owner of the rare item.");//Require that the player is the owner of the rare item.
        uint256 equippedCounter;//This counter will be used to ensure the player cannot equip more than 2 items.
        for (uint256 i; i < RPSRareItems.balanceOf(msg.sender); i++) {//Initialize the loop iterations to the banlanceOf (aka # of) rare items the player owns.
            uint256 tokenIdToCheck = RPSRareItems.tokenOfOwnerByIndex(msg.sender,i);//Use tokenOfOwnerByIndex to get the token ID of each rare item owned by the user.
            RPSRareItemsToken.RareItemAttributes memory rareItemAttributesFromToken = RPSRareItems.readAttributesByTokenId(tokenIdToCheck);//Use the readAttributesByTokenId function to fill the rareItemAttributesFromToken struct with the current rare item from the loop.
            if(rareItemAttributesFromToken.equipped){//Check if the rare item is equipped.
                equippedCounter++;//Increment the equipped counter.
                require(equippedCounter < 2, "User has 2 or more tokens already equipped");//Require the equipped counter to be less than 2 (aka 0 or 1) to ensure we have room to equip another rare item.
            }
        }
        RPSRareItems.equipToken(tokenId_);//Call the equipToken function from the RPSRareItems contract in order to make the item equipped.
        //If there is trading, need to make sure tokens are disabeled before they can be traded (or make it automatic).
        //Make is so they cannot trade during combat.
            uint256 currentLossAbsorbMaxSum;//Will be used to calculate/sum the loss absorb gained from the 1-2 rare items the player has equipped.
            uint256 incomeForWinBonusSum_;//Will be used to calculate the income from winning bonus gained from the 1-2 rare items the player has equipped.
            uint256 maxHealthIncreaseModifierSum_;//Will be used to calculate the max income from winning bonus gained from the 1-2 rare items the player has equipped.
            uint256 healthCostToUseSum_;//Will be used to calculate the rare item health cost from the 1-2 rare items the player has equipped.

            for (uint256 i; i < RPSRareItems.balanceOf(msg.sender); i++) {//Initialize the loop iterations to the banlanceOf (aka # of) rare items the player owns.
                uint256 tokenIdToCheck = RPSRareItems.tokenOfOwnerByIndex(msg.sender,i);//Use tokenOfOwnerByIndex to get the token ID of each rare item owned by the user.
                RPSRareItemsToken.RareItemAttributes memory rareItemAttributesFromToken = RPSRareItems.readAttributesByTokenId(tokenIdToCheck);//Use the readAttributesByTokenId function to fill the rareItemAttributesFromToken struct with the current rare item from the loop.
                if(rareItemAttributesFromToken.equipped){//Check if the rare item is equipped.
                    currentLossAbsorbMaxSum += rareItemAttributesFromToken.lossAbsorb;//Add the loss absorb for the current rare item to the sum.
                    incomeForWinBonusSum_ += rareItemAttributesFromToken.incomeForWinBonus;//Add the income for winning bonus for the current rare item to the sum.
                    maxHealthIncreaseModifierSum_ += rareItemAttributesFromToken.maxHealthIncreaseModifier;//Add the max health increase modifier for the current rare item to the sum.
                    healthCostToUseSum_ += rareItemAttributesFromToken.healthCostToUse;//Add the health cost to use modifier for the current rare item to the sum.
                }

            }
            players[msg.sender].currentLossAbsorbMax = currentLossAbsorbMaxSum;//Set the players loss absorb max to what we just summed up from the rare items they had enabled.
            players[msg.sender].currentIncomeForWinBonus = incomeForWinBonusSum_;//Set the players current income for win bonus to what we just summed up from the rare items they had enabled.
            players[msg.sender].healthMax = 100 + maxHealthIncreaseModifierSum_;//Set the players max health to 100 + the modifier we just summed up from the rare items they had enabled.
            players[msg.sender].currentHealthCostToUse = healthCostToUseSum_;//Set the players current health cost to use to what we just summed up from the rare items they had enabled.

            emit emitRareItemAttributesFromMainContract(
                "Emit the sum of attributes of the equipped NFTs owned by the user",
                currentLossAbsorbMaxSum,
                incomeForWinBonusSum_,
                maxHealthIncreaseModifierSum_,
                healthCostToUseSum_,
                true
            );

    }

    function unequipRareItem(uint256 tokenId_) public onlyRegistered notInBattle {//Function that registered players can use to unequip the rare items they previously had equipped.
        require(RPSRareItems.ownerOf(tokenId_) == msg.sender, "Player must be the owner of the rare item.");//Require that the player ownes the rare item they are attempting to unequip.
        RPSRareItemsToken.RareItemAttributes memory rareItemAttributesFromToken = RPSRareItems.readAttributesByTokenId(tokenId_);//Use the readAttributesByTokenId function to fill the rareItemAttributesFromToken struct with the rare item to be unequipped.
        require(rareItemAttributesFromToken.equipped,"The item is not equipped.");//Require that the rare item is equipped.
        players[msg.sender].currentLossAbsorbMax -= rareItemAttributesFromToken.lossAbsorb;//Substract the loss absorb max modifier that the rare item provided. Aka remove the buff.
        players[msg.sender].currentIncomeForWinBonus -= rareItemAttributesFromToken.incomeForWinBonus;//Substract the income for win bonus modifier that the rare item provided. Aka remove the buff.
        players[msg.sender].healthMax -= rareItemAttributesFromToken.maxHealthIncreaseModifier;//Substract the max health increase modifier that the rare item provided. Aka remove the buff.
        players[msg.sender].currentHealthCostToUse -= rareItemAttributesFromToken.healthCostToUse;//Substract the health cost to use modifier that the rare item provided. Aka remove the debuff.
        if(players[msg.sender].healthMax < players[msg.sender].health){//If the player's max health is lower than their current health...
            players[msg.sender].health = players[msg.sender].healthMax;//set their health to their max health.
        }
        RPSRareItems.unequipToken(tokenId_);//Finally, unequip the rare item by calling the function from the RPSRareItems REC721 contract.
    }
}
