// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibStorage} from "../libraries/LibStorage.sol";

/**
 * @title MembershipFacet
 * @notice Handles membership verification, transfer eligibility, and membership status changes.
 */
contract MembershipFacet {
    using LibStorage for LibStorage.AppStorage;



    /// @notice Checks if an address is an active contract member
    /// @param user Address to check
    /// @return True if user is a member
    function isContractMember(address user) external view returns (bool) {
        return LibStorage.diamondStorage().isMember[user];
    }

    /// @notice Computes how many members are active
    /// @dev This is a proxy for tracking active members
    /// @return count of active survey owners who are members
    function getMemberCount() external view returns (uint256 count) {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        for (uint256 i = 0; i < s.memberList.length; i++) {
            address user = s.memberList[i];
            if (s.balances[user] >= 1e18) {
                count++;
            }
        }
    }

    /// @notice Internal view to determine whether transferring tokens would violate an ongoing proposal
    /// @param user Sender of tokens
    /// @param amountTransferring Amount attempting to transfer
    /// @return True if transfer would drop user below 1 MGOV while they have open votes or delegations
    function willViolateProposal(address user, uint256 amountTransferring) public view returns (bool) {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        bool hasVotedNonExpired = false;
        bool hasDelegatedNonExpired = false;

        for (uint256 i = 0; i < s.proposals.length; i++) {
            if (block.timestamp < s.proposals[i].votedeadline && s.hasVoted[i][user]) {
                hasVotedNonExpired = true;
                break;
            }
        }

        for (uint256 i = 0; i < s.proposals.length; i++) {
            if (block.timestamp < s.proposals[i].votedeadline && s.hasDelegated[i][user]) {
                hasDelegatedNonExpired = true;
                break;
            }
        }

        uint256 currentBalance = address(this).balance; // Stubbed — replace with actual balanceOf(msg.sender)

        if (amountTransferring > currentBalance && (hasVotedNonExpired || hasDelegatedNonExpired)) {
            return true;
        }
        return false;
    }

    /// @notice Updates membership status based on token balance after transfer
    /// @dev This is called after a token transfer to update member state
    /// @param sender The address sending tokens
    /// @param recipient The address receiving tokens
    /// @param amount The amount transferred
    function updateMembershipOnTransfer(address sender, address recipient, uint256 amount) external {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        // If amount > 1 MGOV, recipient becomes member
        if (amount >= 1e18) {
            s.isMember[recipient] = true;
        }

        // If balance < 1 MGOV, sender loses membership
        uint256 newSenderBalance = address(this).balance; // Replace with actual balanceOf(sender)
        if (newSenderBalance < 1e18) {
            s.isMember[sender] = false;
        }
    }
}
