pragma solidity ^0.8.0;

contract RockPaperScissors {
    enum Move { None, Rock, Paper, Scissors }

    struct Player {
        bytes32 commitment;
        Move move;
        bool hasRevealed;
    }

    address public player1;
    address public player2;
    mapping(address => Player) public players;

    constructor(address _player1, address _player2) {
        player1 = _player1;
        player2 = _player2;
    }

    function commitMove(bytes32 _commitment) public {
        require(msg.sender == player1 || msg.sender == player2, "Invalid player");
        require(players[msg.sender].commitment == 0, "Move already committed");

        players[msg.sender].commitment = _commitment;
    }

    function revealMove(Move _move, uint256 _nonce) public {
        require(msg.sender == player1 || msg.sender == player2, "Invalid player");
        require(uint256(_move) >= 1 && uint256(_move) <= 3, "Invalid move");
        require(!players[msg.sender].hasRevealed, "Move already revealed");

        bytes32 commitment = keccak256(abi.encodePacked(uint256(_move), _nonce));
        require(commitment == players[msg.sender].commitment, "Move and nonce do not match commitment");

        players[msg.sender].move = _move;
        players[msg.sender].hasRevealed = true;
    }

    function determineWinner() public view returns (address) {
        if (!players[player1].hasRevealed || !players[player2].hasRevealed) {
            return address(0); // No winner yet, as both moves have not been revealed
        }

        Move move1 = players[player1].move;
        Move move2 = players[player2].move;

        if (move1 == move2) {
            return address(0); // It's a tie, no winner
        }

        if ((move1 == Move.Rock && move2 == Move.Scissors) ||
            (move1 == Move.Paper && move2 == Move.Rock) ||
            (move1 == Move.Scissors && move2 == Move.Paper)) {
            return player1;
        } else {
            return player2;
        }
    }
}