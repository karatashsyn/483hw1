// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TLToken is ERC20, Ownable {
    constructor() ERC20("Turkish Lira Token", "TL") Ownable(msg.sender) {}

    function faucet(address to, uint amount) external onlyOwner {
        _mint(to, amount);
    }
}