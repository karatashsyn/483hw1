// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibStorage} from "../libraries/LibStorage.sol";

/**
 * @title FaucetFacet
 * @notice Allows new users to claim a one-time MGOV token grant and become members.
 */
contract FaucetFacet {
    using LibStorage for LibStorage.AppStorage;

    uint256 internal constant FAUCET_AMOUNT = 1e18;

    /// @notice One-time faucet claim that grants 1 MGOV token and activates membership
    function faucet() external {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        require(!s.faucetClaimed[msg.sender], "Faucet already claimed");

        // Mark faucet as claimed
        s.faucetClaimed[msg.sender] = true;

        // Set user as member
        s.isMember[msg.sender] = true;

        // Transfer MGOV tokens from contract to user
        ERC20Facet(address(this)).transferFaucetToken(msg.sender, FAUCET_AMOUNT);
    }

    /// @notice View if user has claimed the faucet
    function hasClaimedFaucet(address user) external view returns (bool) {
        return LibStorage.diamondStorage().faucetClaimed[user];
    }
}

interface ERC20Facet {
    function transferFaucetToken(address to, uint256 amount) external;
}
