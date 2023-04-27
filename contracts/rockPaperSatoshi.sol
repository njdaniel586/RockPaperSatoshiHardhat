// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

//import "hardhat/console.sol";

import "./RPSatoshiToken.sol";
import "./RPSHashHealToken.sol";
import "./RPSRareItemsToken.sol";

contract rockPaperSatoshi {
    string public contractName = "rockPaperSatoshi";
    RPSatoshiToken private RPSatoshi;
    RPSHashHealToken private RPSHashHeal;
    RPSRareItemsToken private RPSRareItems;

    struct player {
        string name;
        bool registered;
        address playerAddress;
        uint256 health;
        uint256 healthMax;
        bool inPvEBattle;
        uint256 winStreak;
        uint256 currentLossAbsorb;
        uint256 currentIncomeForWinOverride;
        uint256 currentHealthModifier;
        uint256 currentRPSatoshiCostToUse;
        uint256 currentHealthCostToUse;
        //Need to write a function for disabling these that resets stats back to default.
        //Max win streak obtained??
        //Global that containes the current king of the hill in terms of win streak.
    }

    address public owner;
    address public contractAddress;

    mapping(address => player) public players;

    uint256 totalPlayers = 0;

    event botBattled(
        address _currentPlayer,
        bool _roundWin,
        string _outcome,
        int8 _healthChange,
        uint256 _winStreak
    );

    event emitRareItemAttributesFromMainContract(
        string _message,
        uint256 _lossAbsorb,
        uint256 _incomeForWinOverride,
        uint256 _healthModifier,
        uint256 _RPSatoshiCostToUse,
        uint256 _healthCostToUse,
        bool _enabled
    );

    event emitUint256(string message, uint256 value);

    constructor() {
        owner = msg.sender;
        contractAddress = address(this);
        RPSatoshi = new RPSatoshiToken();
        RPSHashHeal = new RPSHashHealToken();
        RPSRareItems = new RPSRareItemsToken();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this.");
        _;
    }

    modifier onlyRegistered() {
        require(
            players[msg.sender].registered == true,
            "Only registered players of Rock Paper Satoshi can perform this. Please register at www.RPSatoshi.com"
        );
        _;
    }

    modifier onlyUnregisterd() {
        require(
            players[msg.sender].registered == false,
            "Only Unregistered players of Rock Paper Satoshi can perform this."
        );
        _;
    }

    function getTokenAddress()
        public
        view
        returns (
            address,
            address,
            address
        )
    {
        return (
            address(RPSatoshi),
            address(RPSHashHeal),
            address(RPSRareItems)
        );
    }

    function register(string memory name_) public onlyUnregisterd {
        players[msg.sender].playerAddress = msg.sender;
        players[msg.sender].name = name_;
        players[msg.sender].registered = true;
        players[msg.sender].healthMax = 100;
        players[msg.sender].health = 100;
    }

    function initPvE() public onlyRegistered {
        require(players[msg.sender].inPvEBattle == false);
        require(players[msg.sender].health > 0 && players[msg.sender].health > players[msg.sender].currentHealthCostToUse);
        require(players[msg.sender].health <= 300);
        require(RPSatoshi.balanceOf(msg.sender) >= players[msg.sender].currentRPSatoshiCostToUse * 10**RPSatoshi.decimals());
        players[msg.sender].inPvEBattle = true;
    }

    function battlePvE(uint256 move_) public onlyRegistered {
        require(players[msg.sender].inPvEBattle == true);
        if(players[msg.sender].health == 0 || players[msg.sender].health < players[msg.sender].currentHealthCostToUse){
            emit emitUint256("Player health is too low. They only have: ", players[msg.sender].health);
            emit emitUint256("players[msg.sender].currentHealthCostToUse", players[msg.sender].currentHealthCostToUse);
            players[msg.sender].inPvEBattle = false;//This happens if player runs out of health due to Rare item health loss.
            return();//Need to return here otherwise reverting will reset the state change we made of inPvEBattle = false.
        }else if(players[msg.sender].health > 300){
            emit emitUint256("Player health overflowed. They have: ", players[msg.sender].health);
            players[msg.sender].inPvEBattle = false;//
            return();//Need to return here otherwise reverting will reset the state change we made of inPvEBattle = false.
        }else if(RPSatoshi.balanceOf(msg.sender) < players[msg.sender].currentRPSatoshiCostToUse * 10**RPSatoshi.decimals()){
            emit emitUint256("Player is too low on RPSatoshis. They have only: ", RPSatoshi.balanceOf(msg.sender));
            emit emitUint256("players[msg.sender].currentRPSatoshiCostToUse * 10**RPSatoshi.decimals()", players[msg.sender].currentRPSatoshiCostToUse * 10**RPSatoshi.decimals());
            players[msg.sender].inPvEBattle = false;//This happens if player runs out of health due to Rare item health loss.
            return();//Need to return here otherwise reverting will reset the state change we made of inPvEBattle = false.
        }
        RPSatoshi.burnFromUser(msg.sender, players[msg.sender].currentRPSatoshiCostToUse * 10**RPSatoshi.decimals());//This should never revert.
        players[msg.sender].health -= players[msg.sender].currentHealthCostToUse;

        //We use block time since our game will be too small of a fish to manipulate (likely) and charging $3 in gas for every PvE battle is too much.
        //But maybe I can use a real oracle once someone's win streak reaches 15 or something.
        uint256 botMove = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 3;

        if ((botMove == 0 && move_ == 1) ||(botMove == 1 && move_ == 2) ||(botMove == 2 && move_ == 0)) {
            //Player wins
            players[msg.sender].inPvEBattle = false;

            if(players[msg.sender].currentIncomeForWinOverride != 0){
                RPSatoshi.mint(msg.sender, players[msg.sender].currentIncomeForWinOverride * 10**RPSatoshi.decimals());
            } else {
                RPSatoshi.mint(msg.sender, 1 * 10**RPSatoshi.decimals());
            }

            players[msg.sender].winStreak += 1;
            if (((uint256(keccak256(abi.encodePacked(block.timestamp,msg.sender,botMove,move_)))) % 2) == 1) {
                //50% chance of getting a hash heal
                RPSHashHeal.mint(msg.sender, 1 * 10**RPSHashHeal.decimals());
            }
            emit botBattled(
                msg.sender,
                true,
                "Player Wins!",
                0,
                players[msg.sender].winStreak
            );
        } else if (botMove == move_) {
            //Draw
            emit botBattled(
                msg.sender,
                false,
                "Draw",
                0,
                players[msg.sender].winStreak
            );
            //Player is still in battle since inPvEBattle still = true
        } else {
            //Bot wins
           if(players[msg.sender].currentLossAbsorb > 0){//Should I limit check somewhere to see if lossAbsorb ever gets above 2?
                players[msg.sender].currentLossAbsorb--;
                emit botBattled(
                    msg.sender,
                    false,
                    "Loss absorbed!",
                    0,
                    players[msg.sender].winStreak
                );
           } else{
                players[msg.sender].winStreak = 0;
                if(players[msg.sender].health < 10){
                    players[msg.sender].health = 0;
                } else {
                    players[msg.sender].health -= 10;
                }
                
                players[msg.sender].inPvEBattle = false;
                players[msg.sender].currentLossAbsorb = 0;
                emit botBattled(
                    msg.sender,
                    false,
                    "Bot Wins",
                    -10,
                    players[msg.sender].winStreak
                );
            }
        }
        if(players[msg.sender].health == 0){
            emit emitUint256("2nd Check: Player health is too low. They only have: ", players[msg.sender].health);
            players[msg.sender].inPvEBattle = false;
            return();//Need to return here otherwise reverting will reset the state change we made of inPvEBattle = false.
        }
    }

    function useHashHeal() public onlyRegistered {
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

    function enableRareItem(uint256 tokenId_) public onlyRegistered {
        require(RPSRareItems.ownerOf(tokenId_) == msg.sender);
        uint256 enabledCounter;
        //Get ids of rare items owned by the msg.sender
        for (uint256 i; i < RPSRareItems.balanceOf(msg.sender); i++) {
            uint256 tokenIdToCheck = RPSRareItems.tokenOfOwnerByIndex(msg.sender,i);
            RPSRareItemsToken.RareItemAttributes memory rareItemAttributesFromToken = RPSRareItems.readAttributesByTokenId(tokenIdToCheck);
            if(rareItemAttributesFromToken.enabled){
                enabledCounter++;
                require(enabledCounter < 2, "User has 2 or more tokens already enabled");
            }
        }
        RPSRareItems.enableToken(tokenId_);
        //If there is trading, need to make sure tokens are disabeled before they can be traded (or make it automatic).
        //Make is so they cannot trade during combat.

            uint256 lossAbsorbSum_;
            uint256 incomeForWinOverrideSum_;
            uint256 healthModifierSum_;
            uint256 RPSatoshiCostToUseSum_;
            uint256 healthCostToUseSum_;

            for (uint256 i; i < RPSRareItems.balanceOf(msg.sender); i++) {
                uint256 tokenIdToCheck = RPSRareItems.tokenOfOwnerByIndex(msg.sender,i);
                RPSRareItemsToken.RareItemAttributes memory rareItemAttributesFromToken = RPSRareItems.readAttributesByTokenId(tokenIdToCheck);
                bool enabled_ = rareItemAttributesFromToken.enabled;
                if(enabled_){
                    lossAbsorbSum_ += rareItemAttributesFromToken.lossAbsorb;
                    incomeForWinOverrideSum_ += rareItemAttributesFromToken.incomeForWinOverride;
                    healthModifierSum_ += rareItemAttributesFromToken.healthModifier;
                    RPSatoshiCostToUseSum_ += rareItemAttributesFromToken.RPSatoshiCostToUse;
                    healthCostToUseSum_ += rareItemAttributesFromToken.healthCostToUse;
                }

            }
            players[msg.sender].currentLossAbsorb = lossAbsorbSum_;
            players[msg.sender].currentIncomeForWinOverride = incomeForWinOverrideSum_;
            players[msg.sender].currentHealthModifier = healthModifierSum_;
            players[msg.sender].healthMax = 100 + healthModifierSum_;
            players[msg.sender].currentRPSatoshiCostToUse = RPSatoshiCostToUseSum_;
            players[msg.sender].currentHealthCostToUse = healthCostToUseSum_;

            emit emitRareItemAttributesFromMainContract(
                "Emit the sum of attributes of the enabled NFTs owned by the user",
                lossAbsorbSum_,
                incomeForWinOverrideSum_,
                healthModifierSum_,
                RPSatoshiCostToUseSum_,
                healthCostToUseSum_,
                true
            );

    }
}
