// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "hardhat/console.sol";

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
        int8 health;
        int8 healthMax;
        bool inPvEBattle;
        uint256 chosenMove;
        uint256 winStreak;
        uint256 currentLossAbsorb;
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
        uint256 _healthChangeFromLossOverride,
        uint256 _RPSatoshiCostToUse,
        uint256 _healthCostToUse,
        bool _enabeled
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
    }

    function initPvE() public onlyRegistered {
        require(players[msg.sender].inPvEBattle == false);
        players[msg.sender].inPvEBattle = true;
    }

    function battlePvE(uint256 move_) public onlyRegistered {
        require(players[msg.sender].inPvEBattle == true);
        players[msg.sender].chosenMove = move_;
        //We use block time since our game will be too small of a fish to manipulate (likely) and charging $3 in gas for every PvE battle is too much.
        uint256 botMove = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 3;

        if ((botMove == 0 && move_ == 1) ||(botMove == 1 && move_ == 2) ||(botMove == 2 && move_ == 0)) {
            //Player wins
            players[msg.sender].inPvEBattle = false;
            RPSatoshi.mint(msg.sender, 1 * 10**RPSatoshi.decimals());
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
            uint256[] memory lossAbsorb_ = new uint256[](2);
            uint256[] memory incomeForWinOverride_= new uint256[](2);
            uint256[] memory healthChangeFromLossOverride_= new uint256[](2);
            uint256[] memory RPSatoshiCostToUse_= new uint256[](2);
            uint256[] memory healthCostToUse_= new uint256[](2);
            uint256 lossAbsorbSum_;
            uint256 incomeForWinOverrideSum_;
            uint256 healthChangeFromLossOverrideSum_;
            uint256 RPSatoshiCostToUseSum_;
            uint256 healthCostToUseSum_;

            uint256 enabledCounter;
            for (uint256 i; i < RPSRareItems.balanceOf(msg.sender); i++) {
                uint256 tokenIdToCheck = RPSRareItems.tokenOfOwnerByIndex(msg.sender,i);
                RPSRareItemsToken.RareItemAttributes memory rareItemAttributesFromToken = RPSRareItems.readAttributesByTokenId(tokenIdToCheck);
                bool enabled_ = rareItemAttributesFromToken.enabled;
                if(enabled_){
                    lossAbsorb_[enabledCounter] = rareItemAttributesFromToken.lossAbsorb;
                    incomeForWinOverride_[enabledCounter] = rareItemAttributesFromToken.incomeForWinOverride;
                    healthChangeFromLossOverride_[enabledCounter] = rareItemAttributesFromToken.healthChangeFromLossOverride;
                    RPSatoshiCostToUse_[enabledCounter] = rareItemAttributesFromToken.RPSatoshiCostToUse;
                    healthCostToUse_[enabledCounter] = rareItemAttributesFromToken.healthCostToUse;

                    lossAbsorbSum_ += lossAbsorb_[enabledCounter];
                    incomeForWinOverrideSum_ += incomeForWinOverride_[enabledCounter];
                    healthChangeFromLossOverrideSum_ += healthChangeFromLossOverride_[enabledCounter];
                    RPSatoshiCostToUseSum_ += RPSatoshiCostToUse_[enabledCounter];
                    healthCostToUseSum_ += healthCostToUse_[enabledCounter];
                    enabledCounter++;
                }
                //Time to implement code that saves players from losses, adjustes health from loss, etc
            }

            //Show the enabeled rareItems by the user.
            for(uint256 i; i < enabledCounter; i++){
                emit emitRareItemAttributesFromMainContract(
                    "Emit from for loop in main contract that's checking the attributes of the enabled NFTs owned by the user",
                    lossAbsorb_[i],
                    incomeForWinOverride_[i],
                    healthChangeFromLossOverride_[i],
                    RPSatoshiCostToUse_[i],
                    healthCostToUse_[i],
                    true
                );
            }
                emit emitRareItemAttributesFromMainContract(
                    "Emit the sum of attributes of the enabled NFTs owned by the user",
                    lossAbsorbSum_,
                    incomeForWinOverrideSum_,
                    healthChangeFromLossOverrideSum_,
                    RPSatoshiCostToUseSum_,
                    healthCostToUseSum_,
                    true
                );

            players[msg.sender].winStreak = 0;
            players[msg.sender].health -= 10;
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

    function useHashHeal() public onlyRegistered {
        RPSHashHeal.burnFromUser(msg.sender, 1 * 10**RPSHashHeal.decimals());
        players[msg.sender].health += 50;
    }

    function mintRareItem() public onlyRegistered {
        RPSRareItems.safeMint(msg.sender);
        //Probably should emit what they get.
    }

    function enableRareItem(uint256 tokenId_) public onlyRegistered {
        require(RPSRareItems.ownerOf(tokenId_) == msg.sender);
        uint256 enabeledCounter;
        //Need to get ids of rare items owned by the msg.sender
        for (uint256 i; i < RPSRareItems.balanceOf(msg.sender); i++) {
            uint256 tokenIdToCheck = RPSRareItems.tokenOfOwnerByIndex(msg.sender,i);
            RPSRareItemsToken.RareItemAttributes memory rareItemAttributesFromToken = RPSRareItems.readAttributesByTokenId(tokenIdToCheck);
            if(rareItemAttributesFromToken.enabled){
                enabeledCounter++;
                require(enabeledCounter < 2, "User has 2 or more tokens already enabeled");
            }
        }
        RPSRareItems.enableToken(tokenId_);
        //If there is trading, need to make sure tokens are disabeled before they can be traded (or make it automatic).
        //Make is so they cannot trade during combat.
    }
}
