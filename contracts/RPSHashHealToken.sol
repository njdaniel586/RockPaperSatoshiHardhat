// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts@4.8.3/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.8.3/access/Ownable.sol";
import "@openzeppelin/contracts@4.8.3/token/ERC20/extensions/ERC20Burnable.sol";

contract RPSHashHealToken is ERC20, Ownable, ERC20Burnable {
    constructor() ERC20("RPSHashHeal", "RHH") {
        _mint(msg.sender, 10 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

        function burnFromUser(address user, uint256 amount) public onlyOwner {
        _burn(user, amount);
    }
}
