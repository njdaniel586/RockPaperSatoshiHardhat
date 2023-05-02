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
        bool inPvEBattle;//Wether or not the player is in a PvE battle.
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
        //bool _roundWin,
        string _outcome//,
        //int8 _healthChange,
        //uint256 _winStreak
    );

    event emitRareItemAttributesFromMainContract(//Event emitted to report out the attributes of a rare item such as when the rare item is earned/minted.
        string _message,
        uint256 _lossAbsorb,//Loss absorbe attribute of rare item.
        uint256 _incomeForWinBonus,//Income for win bonus attribute from rare item.
        uint256 _healthIncreaseModifier,//Health increase modifier attribute from rare item.
        //uint256 _RPSatoshiCostToUse,
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
        require(
            players[msg.sender].registered == true,
            "Only registered players of Rock Paper Satoshi can perform this. Please register at www.RPSatoshi.com"
        );
        _;
    }

    modifier onlyUnregisterd() {//Function modifier for actions only unregistered players can perform. Only used for register function.
        require(
            players[msg.sender].registered == false,
            "Only Unregistered players of Rock Paper Satoshi can perform this."
        );
        _;
    }

    function getTokenAddress() public view returns (address, address, address){//Function that returns the addresses of the token contracts deployed.
        return (address(RPSatoshi), address(RPSHashHeal), address(RPSRareItems));
    }

    function register(string memory name_) public onlyUnregisterd {//Function for unregistered players to register.
        //players[msg.sender].playerAddress = msg.sender;
        players[msg.sender].name = name_;//Store the registering player's name in the "players" mapping.
        players[msg.sender].registered = true;//Mark the player as registered.
        players[msg.sender].healthMax = 100;//Initialize the players max health to 100.
        players[msg.sender].health = 100;//Initialize the playerd health to 100. AKA start them off with full health.
        totalPlayers ++;//Increment the count of the total registered players for the contract.
    }

    function initPvE() public onlyRegistered {//Function to initialize a PvE encounter. Players battle a bot until they win, lose, or run out of health due to a rare item costing health to use.
        require(players[msg.sender].inPvEBattle == false);//Require the player to not already be in a battle.
        require(players[msg.sender].health > 0 && players[msg.sender].health > players[msg.sender].currentHealthCostToUse);//Require that the player has enough health to pay their rare item health cost.
        require(players[msg.sender].health <= 300);//Health should never be above 300 so this is a bug/exploit catch.
        //require(RPSatoshi.balanceOf(msg.sender) >= players[msg.sender].currentRPSatoshiCostToUse * 10**RPSatoshi.decimals());
        players[msg.sender].inPvEBattle = true;//Set the player's status to in battle.
        players[msg.sender].currentLossAbsorb = players[msg.sender].currentLossAbsorbMax;//Since it's the start of an encounter, set the players loss absorb to the max allowed by their rare item(s) (max of 2).
        
    }

    function battlePvE(uint256 move_) public onlyRegistered {//Function for the player to battle the bot encountered with either a rock, paper, or scissors. Possibly outcomes are draw, win, lose, and loss absorbed.
        require(players[msg.sender].inPvEBattle == true);//Require the player to be in a PvE encounter.
        //if(players[msg.sender].health == 0 || players[msg.sender].health < players[msg.sender].currentHealthCostToUse){//If the players
        //    emit emitUint256("Player health is too low. They only have: ", players[msg.sender].health);
        //    emit emitUint256("players[msg.sender].currentHealthCostToUse", players[msg.sender].currentHealthCostToUse);
        //    players[msg.sender].inPvEBattle = false;//This happens if player runs out of health due to Rare item health loss.
        //    return();//Need to return here otherwise reverting will reset the state change we made of inPvEBattle = false.
        require(players[msg.sender].health > 0 || players[msg.sender].health > players[msg.sender].currentHealthCostToUse, "Player's health is too low");//Require the player to have more than 0 health and also enough health to pay the health cost of their rare item(s).
        //}else if(players[msg.sender].health > 300){
        //    emit emitUint256("Player health overflowed. They have: ", players[msg.sender].health);
        //    players[msg.sender].inPvEBattle = false;//
        //    return();//Need to return here otherwise reverting will reset the state change we made of inPvEBattle = false.
        //}
        require(players[msg.sender].health <= 300, "Players health is too high. What happened??");//Require the players health to be less than or equal to 300 which is the max possibly health in the game.
        //else if(RPSatoshi.balanceOf(msg.sender) < players[msg.sender].currentRPSatoshiCostToUse * 10**RPSatoshi.decimals()){
        //    emit emitUint256("Player is too low on RPSatoshis. They have only: ", RPSatoshi.balanceOf(msg.sender));
        //    emit emitUint256("players[msg.sender].currentRPSatoshiCostToUse * 10**RPSatoshi.decimals()", players[msg.sender].currentRPSatoshiCostToUse * 10**RPSatoshi.decimals());
        //    players[msg.sender].inPvEBattle = false;//This happens if player runs out of health due to Rare item health loss.
        //    return();//Need to return here otherwise reverting will reset the state change we made of inPvEBattle = false.
        //}
        //RPSatoshi.burnFromUser(msg.sender, players[msg.sender].currentRPSatoshiCostToUse * 10**RPSatoshi.decimals());//This should never revert.
        players[msg.sender].health -= players[msg.sender].currentHealthCostToUse;//Player pays the health cost of their rare items.


        uint256 botMove = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 3;//This psudo-random-number generator takes the block time and the players address to come up with the bots move.
        //We use block time since our game will be too small of a fish to manipulate (likely) and charging $3 in gas for every PvE battle is too much.
        //But maybe I can use a real oracle once someone's win streak reaches 15 or something.

        //Time to compare the player's move vs the bot's move. 0 = rock, 1 = paper, 2 = scissors. So 1 beats 0, 2 beats 1, and 0 beats 2.
        if ((botMove == 0 && move_ == 1) || (botMove == 1 && move_ == 2) || (botMove == 2 && move_ == 0)) {//All scenarios where the player beats the bot.
            players[msg.sender].inPvEBattle = false;//Since the player won, they are no longer in battle.

            //if(players[msg.sender].currentIncomeForWinBonus != 0){
            //    RPSatoshi.mint(msg.sender, 10 + (players[msg.sender].currentIncomeForWinBonus * 10**RPSatoshi.decimals()));
            //} else {
            //    RPSatoshi.mint(msg.sender, 10 * 10**RPSatoshi.decimals());
            //}
            RPSatoshi.mint(msg.sender, 10 + (players[msg.sender].currentIncomeForWinBonus * 10**RPSatoshi.decimals()));//Give player their reward for winning. Base of 10 RPSatoshis + any bonuses from rare item(s).
            players[msg.sender].winStreak += 1;//Increment player win streak.
            if(players[msg.sender].winStreak > RPSKingStreak){//If player's new win streak makes them the new record holder.
                RPSKingStreak = players[msg.sender].winStreak;//Update the global win streak to that of the current player.
                RPSKingAddress = msg.sender;//Update the address of the highest win streak holder to the current player's address.
                RPSKingName = players[msg.sender].name;//Update the name of the highest win streak holder to the current player's name.
            }
            if (((uint256(keccak256(abi.encodePacked(block.timestamp,msg.sender,botMove,move_)))) % 2) == 1) {//psudo-random-number generator for if player receives a hash heal for their win. (50% chance of getting a hash heal).
                RPSHashHeal.mint(msg.sender, 1 * 10**RPSHashHeal.decimals());
            }
            emit botBattled(//Emit the outcome of the battle (Player wins)
                msg.sender,
                //true,
                "Player Wins!"//,
                //0,
                //players[msg.sender].winStreak
            );
        } else if (botMove == move_) {//If the player and bot chose the same move (Draw)
            //Draw
            emit botBattled(//Emit the outcome of the battle (Draw)
                msg.sender,
                //false,
                "Draw"//,
                //0,
                //players[msg.sender].winStreak
            );
            //Player is still in battle since inPvEBattle still = true
        } else {//This leaves the only remaining scenarios to be that the bot won. However we will take into account loss absorb below.
           if(players[msg.sender].currentLossAbsorb > 0 && players[msg.sender].currentLossAbsorb < 3){//If the player has loss absorb of 1 or 2. We make sure it's less than 3 because 2 should be the highest acheivable.
                players[msg.sender].currentLossAbsorb--;//Decrement the player's loss absorb.
                emit botBattled(//Emit the outcome of the battle (Loss absorbed).
                    msg.sender,
                    //false,
                    "Loss absorbed!"//,
                    //0,
                    //players[msg.sender].winStreak
                );
           } else{//If the player did not have loss absorb then the player has lost the encounter.
                players[msg.sender].winStreak = 0;//Reset the players win streak back to 0.
                if(players[msg.sender].health < 10){//Before we reduce the player's health by 10 for the loss, we check if it's less than 10 to prevent underflow of the uint256.
                    players[msg.sender].health = 0;//If they had less than 10 health, they they get reduced to 0;
                } else {
                    players[msg.sender].health -= 10;//Otherwise, they had 10 or more health and it can be reduced by 10.
                }
                
                players[msg.sender].inPvEBattle = false;//The player is lo longer in a PvE encounter.
                //players[msg.sender].currentLossAbsorb = 0;//I don't think I need this since I always set this when we init PvE.
                emit botBattled(//Emit the outcome of the battle (bot wins).
                    msg.sender,
                    //false,
                    "Bot Wins"//,
                    //-10,
                    //players[msg.sender].winStreak
                );
            }
        }
        if(players[msg.sender].health == 0){//I need to look into if I make the player's streak end when their health reaches 0.
            emit emitUint256("2nd Check: Player health is too low. They only have: ", players[msg.sender].health);
            players[msg.sender].inPvEBattle = false;
            return();//Need to return here otherwise reverting will reset the state change we made of inPvEBattle = false.
        }
    }

    function useHashHeal() public onlyRegistered {//not in battle. make a modifier??
        RPSHashHeal.burnFromUser(msg.sender, 1 * 10**RPSHashHeal.decimals());
        if(players[msg.sender].health + 50 >= players[msg.sender].healthMax){
            players[msg.sender].health = players[msg.sender].healthMax;
        } else{
            players[msg.sender].health += 50;
        }

    }

    function getHashHeal() public onlyRegistered {
        RPSHashHeal.mint(msg.sender, 1*10**RPSHashHeal.decimals());
    }

    function getMoney() public onlyRegistered {
        RPSatoshi.mint(msg.sender, 10*10**RPSatoshi.decimals());
    }

    function mintRareItem() public onlyRegistered {
        RPSRareItems.safeMint(msg.sender);
        //Probably should emit what they get.
    }

    function equippedRareItem(uint256 tokenId_) public onlyRegistered {
        require(RPSRareItems.ownerOf(tokenId_) == msg.sender);
        uint256 equippedCounter;
        //Make sure user has less than 2 rare items enabeled.
        for (uint256 i; i < RPSRareItems.balanceOf(msg.sender); i++) {
            uint256 tokenIdToCheck = RPSRareItems.tokenOfOwnerByIndex(msg.sender,i);
            RPSRareItemsToken.RareItemAttributes memory rareItemAttributesFromToken = RPSRareItems.readAttributesByTokenId(tokenIdToCheck);
            if(rareItemAttributesFromToken.equipped){
                equippedCounter++;
                require(equippedCounter < 2, "User has 2 or more tokens already equipped");
            }
        }
        RPSRareItems.equippedToken(tokenId_);
        //If there is trading, need to make sure tokens are disabeled before they can be traded (or make it automatic).
        //Make is so they cannot trade during combat.
            uint256 currentLossAbsorbMaxSum;
            uint256 incomeForWinBonusSum_;
            uint256 healthIncreaseModifierSum_;
            //uint256 RPSatoshiCostToUseSum_;
            uint256 healthCostToUseSum_;

            for (uint256 i; i < RPSRareItems.balanceOf(msg.sender); i++) {
                uint256 tokenIdToCheck = RPSRareItems.tokenOfOwnerByIndex(msg.sender,i);
                RPSRareItemsToken.RareItemAttributes memory rareItemAttributesFromToken = RPSRareItems.readAttributesByTokenId(tokenIdToCheck);
                bool equipped_ = rareItemAttributesFromToken.equipped;
                if(equipped_){
                    currentLossAbsorbMaxSum += rareItemAttributesFromToken.lossAbsorb;
                    incomeForWinBonusSum_ += rareItemAttributesFromToken.incomeForWinBonus;
                    healthIncreaseModifierSum_ += rareItemAttributesFromToken.healthIncreaseModifier;
                    //RPSatoshiCostToUseSum_ += rareItemAttributesFromToken.RPSatoshiCostToUse;
                    healthCostToUseSum_ += rareItemAttributesFromToken.healthCostToUse;
                }

            }
            players[msg.sender].currentLossAbsorbMax = currentLossAbsorbMaxSum;
            players[msg.sender].currentIncomeForWinBonus = incomeForWinBonusSum_;
            //players[msg.sender].currenthealthIncreaseModifier = healthIncreaseModifierSum_;//To delete if no issues.
            players[msg.sender].healthMax = 100 + healthIncreaseModifierSum_;
            //players[msg.sender].currentRPSatoshiCostToUse = RPSatoshiCostToUseSum_;
            players[msg.sender].currentHealthCostToUse = healthCostToUseSum_;

            emit emitRareItemAttributesFromMainContract(
                "Emit the sum of attributes of the equipped NFTs owned by the user",
                currentLossAbsorbMaxSum,
                incomeForWinBonusSum_,
                healthIncreaseModifierSum_,
                //RPSatoshiCostToUseSum_,
                healthCostToUseSum_,
                true
            );

    }

    function disableRareItem(uint256 tokenId_) public onlyRegistered{
        require(RPSRareItems.ownerOf(tokenId_) == msg.sender);
        RPSRareItemsToken.RareItemAttributes memory rareItemAttributesFromToken = RPSRareItems.readAttributesByTokenId(tokenId_);
        require(rareItemAttributesFromToken.equipped);
        players[msg.sender].currentLossAbsorbMax -= rareItemAttributesFromToken.lossAbsorb;
        players[msg.sender].currentIncomeForWinBonus -= rareItemAttributesFromToken.incomeForWinBonus;
        players[msg.sender].healthMax -= rareItemAttributesFromToken.healthIncreaseModifier;
        //players[msg.sender].currentRPSatoshiCostToUse -= rareItemAttributesFromToken.RPSatoshiCostToUse;
        players[msg.sender].currentHealthCostToUse -= rareItemAttributesFromToken.healthCostToUse;
        if(players[msg.sender].healthMax < players[msg.sender].health){
            players[msg.sender].health = players[msg.sender].healthMax;
        }
        RPSRareItems.disableToken(tokenId_);
    }
}
