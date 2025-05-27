// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibStorage} from "../libraries/LibStorage.sol";


/**
 * @title ProposalFacet
 * @notice Manages project proposals, voting, delegation, payment approval, and TL disbursements.
 */
contract ProposalFacet {
    using LibStorage for LibStorage.AppStorage;

    uint256 internal constant MGOV_PROPOSAL_COST = 5e18;
    uint256 internal constant TL_PROPOSAL_COST = 4000e18;
    uint256 internal constant ONE_MGOV = 1e18;

    // ============================
    // Proposal Lifecycle Functions
    // ============================

    /// @notice Submit a project proposal with payment schedule
    function submitProjectProposal(
        string calldata weburl,
        uint256 votedeadline,
        uint256[] calldata paymentAmounts,
        uint256[] calldata paySchedule
    ) external returns (uint256) {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        require(s.isMember[msg.sender], "Only members can submit project proposals");

        // Balance checks
        uint256 balance = ERC20Facet(address(this)).balanceOf(msg.sender);
        require(balance >= MGOV_PROPOSAL_COST, "5 MGOV tokens required");
        require(!_willViolateProposal(msg.sender, MGOV_PROPOSAL_COST), "Transfer violates voting lock");

        // TL token transfer
        require(s.tlToken.transferFrom(msg.sender, address(this), TL_PROPOSAL_COST), "4000 TL tokens required");

        // MGOV deduction
        require(
            ERC20Facet(address(this)).transferFrom(msg.sender, address(this), MGOV_PROPOSAL_COST),
            "Transfer failed"
        );
        

        if (balance - MGOV_PROPOSAL_COST < ONE_MGOV) {
            s.isMember[msg.sender] = false;
        }

        // Add proposal
        s.proposals.push(LibStorage.Proposal({
            weburl: weburl,
            votedeadline: votedeadline,
            paymentAmounts: paymentAmounts,
            paySchedule: paySchedule,
            owner: msg.sender,
            yesVotes: 0,
            funded: false,
            reservedTime: 0,
            lastPaidIndex: 0
        }));

        return s.proposals.length - 1;
    }

    /// @notice Vote for a project proposal
    function voteForProjectProposal(uint256 projectId, bool choice) external {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        require(s.isMember[msg.sender], "Only members can vote");
        require(projectId < s.proposals.length, "Invalid project ID");
        require(!s.proposals[projectId].funded, "Already funded");
        require(block.timestamp < s.proposals[projectId].votedeadline, "Expired");

        if (s.hasVoted[projectId][msg.sender]) {
            require(s.extraVotes[projectId][msg.sender] > 0, "No extra votes");
            s.extraVotes[projectId][msg.sender]--;
        } else {
            s.hasVoted[projectId][msg.sender] = true;
        }

        if (choice) {
            s.proposals[projectId].yesVotes++;
        }
    }

    /// @notice Delegate vote to another member for a proposal
    function delegateVoteTo(address memberaddr, uint256 projectId) external {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        require(projectId < s.proposals.length, "Invalid project ID");
        require(!s.hasVoted[projectId][msg.sender], "Already voted");
        require(!s.hasDelegated[projectId][msg.sender], "Already delegated");
        require(s.isMember[memberaddr], "Delegate must be a member");

        s.hasDelegated[projectId][msg.sender] = true;
        s.extraVotes[projectId][memberaddr]++;
    }

    /// @notice Reserves TLToken funding for a successful project
    function reserveProjectGrant(uint256 projectId) external {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();
        require(projectId < s.proposals.length, "Invalid project ID");

        LibStorage.Proposal storage p = s.proposals[projectId];
        require(msg.sender == p.owner, "Not project owner");
        require(block.timestamp < p.votedeadline, "Proposal expired");
        require(!p.funded, "Already funded");

        uint256 memberCount = MembershipFacet(address(this)).getMemberCount();
        require(p.yesVotes * 10 >= memberCount, "Insufficient votes");

        uint256 total;
        for (uint256 i = 0; i < p.paymentAmounts.length; i++) {
            total += p.paymentAmounts[i];
        }

        require(s.tlToken.balanceOf(address(this)) >= total, "Insufficient TLToken funds");

        p.funded = true;
        p.reservedTime = block.timestamp;
    }

    /// @notice Withdraw TL payment after scheduled time and vote approval
    function withdrawProjectTLPayment(uint256 projectId) external {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();
        require(projectId < s.proposals.length, "Invalid project ID");

        LibStorage.Proposal storage p = s.proposals[projectId];
        require(p.funded && msg.sender == p.owner, "Unauthorized or not funded");
        require(p.lastPaidIndex < p.paySchedule.length, "All payments made");

        uint256 dueTime = p.reservedTime + p.paySchedule[p.lastPaidIndex];
        require(block.timestamp >= dueTime, "Payment not due");

        uint256 memberCount = MembershipFacet(address(this)).getMemberCount();
        require(s.paymentVotes[projectId] * 100 >= memberCount, "Insufficient votes");

        s.tlToken.transfer(p.owner, p.paymentAmounts[p.lastPaidIndex]);
        p.lastPaidIndex++;

        // Reset payment votes for next round
        s.paymentVotes[projectId] = 0;

        // Reset per-user payment vote flags
        for (uint256 i = 0; i < s.proposals.length; i++) {
            if (s.hasVotedForPayment[projectId][msg.sender]) {
                s.hasVotedForPayment[projectId][msg.sender] = false;
            }
        }
    }

    /// @notice Vote to approve TL payment from reserved pool
    function voteForProjectPayment(uint256 projectId, bool choice) external {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        require(s.isMember[msg.sender], "Only members can vote");
        require(!s.hasVotedForPayment[projectId][msg.sender], "Already voted");
        require(block.timestamp < s.proposals[projectId].votedeadline, "Expired");
        require(s.proposals[projectId].funded, "Project not funded");
        require(s.proposals[projectId].lastPaidIndex < s.proposals[projectId].paySchedule.length, "All paid");

        s.hasVotedForPayment[projectId][msg.sender] = true;

        if (choice) {
            s.paymentVotes[projectId]++;
        }
    }

    // ============================
    // View Functions
    // ============================

    function getProjectOwner(uint256 projectId) external view returns (address) {
        return LibStorage.diamondStorage().proposals[projectId].owner;
    }

    function getProjectInfo(uint256 projectId)
        external
        view
        returns (string memory url, uint256 deadline, uint256[] memory amounts, uint256[] memory schedule)
    {
        LibStorage.Proposal storage p = LibStorage.diamondStorage().proposals[projectId];
        return (p.weburl, p.votedeadline, p.paymentAmounts, p.paySchedule);
    }

    function getIsProjectFunded(uint256 projectId) external view returns (bool) {
        return LibStorage.diamondStorage().proposals[projectId].funded;
    }

    function getProjectNextTLPayment(uint256 projectId) external view returns (int256) {
        LibStorage.Proposal storage p = LibStorage.diamondStorage().proposals[projectId];
        if (p.lastPaidIndex >= p.paySchedule.length) return -1;
        return int256(p.paySchedule[p.lastPaidIndex]);
    }

    function getNoOfProjectProposals() external view returns (uint256) {
        return LibStorage.diamondStorage().proposals.length;
    }

    function getNoOfFundedProjects() external view returns (uint256 count) {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();
        for (uint256 i = 0; i < s.proposals.length; i++) {
            if (s.proposals[i].funded) count++;
        }
    }

    function getTLReceivedByProject(uint256 projectId) external view returns (uint256 total) {
        LibStorage.Proposal storage p = LibStorage.diamondStorage().proposals[projectId];
        for (uint256 i = 0; i < p.lastPaidIndex; i++) {
            total += p.paymentAmounts[i];
        }
    }

    // ============================
    // Internal utilities
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
interface MembershipFacet {
    function getMemberCount() external view returns (uint256 count);
}
