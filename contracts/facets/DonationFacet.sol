// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibStorage} from "../libraries/LibStorage.sol";

/**
 * @title DonationFacet
 * @notice Handles TL token and MGOV token donations sent to the Diamond contract.
 */
contract DonationFacet {
    using LibStorage for LibStorage.AppStorage;

    /// @notice Donate TL tokens to the DAO treasury
    /// @param amount The amount of TL tokens to donate
    function donateTLToken(uint256 amount) external {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        require(amount > 0, "Amount must be greater than 0");
        require(
            s.tlToken.transferFrom(msg.sender, address(this), amount),
            "Not enough TL tokens for donation"
        );
    }

    /// @notice Donate MGOV tokens to the DAO treasury
    /// @dev Respects voting constraints and membership downgrade
    /// @param amount The amount of MGOV to donate
    function donateMyGovToken(uint256 amount) external {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        require(amount > 0, "Amount must be greater than 0");

        uint256 balance = ERC20Facet(address(this)).balanceOf(msg.sender);
        require(balance >= amount, "Insufficient MGOV balance");

        require(
            !_willViolateProposal(msg.sender, amount),
            "Donation violates voting constraint"
        );

        // Update membership if balance drops below 1 MGOV
        if (balance - amount < 1e18) {
            s.isMember[msg.sender] = false;
        }

        require(
            ERC20Facet(address(this)).transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
    }

    // ============================
    // Internal Voting Guard Logic
    // ============================

    function _willViolateProposal(address user, uint256 amount) internal view returns (bool) {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        bool voted = false;
        bool delegated = false;

        for (uint256 i = 0; i < s.proposals.length; i++) {
            if (block.timestamp < s.proposals[i].votedeadline && s.hasVoted[i][user]) {
                voted = true;
                break;
            }
        }

        for (uint256 i = 0; i < s.proposals.length; i++) {
            if (block.timestamp < s.proposals[i].votedeadline && s.hasDelegated[i][user]) {
                delegated = true;
                break;
            }
        }

        uint256 balance = ERC20Facet(address(this)).balanceOf(user);
        if (amount > balance || balance - amount < 1e18) {
            if (voted || delegated) return true;
        }

        return false;
    }
}

interface ERC20Facet {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
