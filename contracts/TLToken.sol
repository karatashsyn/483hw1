// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TLToken is ERC20 {
    constructor() ERC20("Turkish Lira Token", "TL") {
        _mint(msg.sender, 1_000_000_000 * 1e18);
    }

    function faucet(address to, uint amount) external {
        _mint(to, amount);
    }
}
