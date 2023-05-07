// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract RPSatoshiToken is ERC20, Ownable, ERC20Burnable {
    constructor() ERC20("RPSatoshi", "RPS") {
        _mint(msg.sender, 10 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

        function burnFromUser(address user, uint256 amount) public onlyOwner {
        _burn(user, amount);
    }
}
