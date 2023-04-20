// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "./RPSatoshiToken.sol";
import "./RPSHashHealToken.sol";
import "./RPSRareItemsToken.sol";

contract rockPaperSatoshi{
    string public contractName = "rockPaperSatoshi";
    RPSatoshiToken private RPSatoshi;
    RPSHashHealToken private RPSHashHeal;
    RPSRareItemsToken private RPSRareItems;

    struct player{
        string name;
        bool registered;
        address playerAddress;
        int8 health;
        int8 healthMax;
        bool inPvEBattle;
        uint256 chosenMove;
        uint256 winStreak;
    }

    address public owner;
    address public contractAddress;

    mapping (address => player) public players;

    uint256 totalPlayers = 0;

    event botBattled(address currentPlayer, bool roundWin, string outcome, int8 healthChange, uint256 winStreak);

    constructor(){
        owner = msg.sender;
        contractAddress = address(this);
        RPSatoshi = new RPSatoshiToken();
        RPSHashHeal = new RPSHashHealToken();
        RPSRareItems = new RPSRareItemsToken();
    }

    modifier onlyOwner{
        require(msg.sender == owner, "Only the owner can perform this.");
        _;
    }

    modifier onlyRegistered{
        require(players[msg.sender].registered == true, "Only registered players of Rock Paper Satoshi can perform this. Please register at www.RPSatoshi.com");
        _;
    }

    modifier onlyUnregisterd{
        require(players[msg.sender].registered == false, "Only Unregistered players of Rock Paper Satoshi can perform this.");
        _;
    }

    function getTokenAddress() public view returns (address,address,address){
        return (address(RPSatoshi),address(RPSHashHeal),address(RPSRareItems));
    }

    function register(string memory name_) public onlyUnregisterd{
        players[msg.sender].playerAddress = msg.sender;
        players[msg.sender].name = name_;
        players[msg.sender].registered = true;
    }

    function initPvE() public onlyRegistered{
        require(players[msg.sender].inPvEBattle == false);
        players[msg.sender].inPvEBattle = true;
    }

    function battlePvE(uint256 move_) public onlyRegistered{
        require(players[msg.sender].inPvEBattle == true);
        players[msg.sender].chosenMove = move_;
        //We use block time since our game will be too small of a fish to manipulate (likely) and charging $3 in gas for every PvE battle is too much.
        uint256 botMove = uint256(keccak256(abi.encodePacked(block.timestamp,msg.sender))) % 3;

        if((botMove == 0 && move_ == 1) || (botMove == 1 && move_ == 2) || (botMove == 2 && move_ == 0)){//Player wins
            players[msg.sender].inPvEBattle = false;
            RPSatoshi.mint(msg.sender,1 * 10 ** RPSatoshi.decimals());
            players[msg.sender].winStreak += 1;
            if(((uint256(keccak256(abi.encodePacked(block.timestamp,msg.sender,botMove,move_)))) % 2) == 1){//50% chance of getting a hash heal
                RPSHashHeal.mint(msg.sender,1 * 10 ** RPSHashHeal.decimals());
            }
            emit botBattled(msg.sender,true,"Player Wins!",0,players[msg.sender].winStreak);
        } else if(botMove == move_){//Draw
            emit botBattled(msg.sender,false,"Draw",0,players[msg.sender].winStreak);
            //Player is still in battle since inPvEBattle still = true
        } else {//Bot wins

            //uint256 totalRPSRareItemSupply = RPSRareItems.totalSupply();
            for (uint256 i; i < RPSRareItems.balanceOf(msg.sender); i++) 
            {
                uint256 tokenIdToCheck = RPSRareItems.tokenOfOwnerByIndex(msg.sender,i);
                RPSRareItems.readAttributesByTokenId(tokenIdToCheck);
                
            }

            players[msg.sender].winStreak = 0;
            players[msg.sender].health -= 10;
            players[msg.sender].inPvEBattle = false;
            emit botBattled(msg.sender,false,"Bot Wins",-10,players[msg.sender].winStreak);
        }

    }

    function useHashHeal() public onlyRegistered{
        RPSHashHeal.burnFromUser(msg.sender,1 * 10 ** RPSHashHeal.decimals());
        players[msg.sender].health += 50;
    }

    function mintRareItem() public onlyRegistered{
        RPSRareItems.safeMint(msg.sender);
    }
}