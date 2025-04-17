// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Define an interface for TLToken so the contract can interact with an external TL token contract
interface ITLToken {
    // Allows the contract to call transferFrom to move tokens from another account
    function transferFrom(
        address from,
        address to,
        uint amount
    ) external returns (bool);
    // Allows the contract to call transfer to move tokens from this contract to another account
    function transfer(address to, uint amount) external returns (bool);
    // Allows the contract to check the balance of TL tokens for a specific account
    function balanceOf(address account) external view returns (uint);
}

// Inheriting from ERC20 so that our contract provides the standard ERC20 functionalities
contract MyGov is ERC20, Ownable {
    ITLToken public tlToken;
    // The maximum supply of MyGov tokens
    uint public constant MAX_SUPPLY = 10_000_000 * 1e18;
    mapping(address => bool) public faucetClaimed;

    struct Survey {
        string weburl;
        uint surveydeadline;
        uint numchoices;
        uint atmostchoices;
        address owner;
        uint[] results;
        uint takerCount;
    }

    struct Proposal {
        string weburl;
        uint votedeadline;
        uint[] paymentAmounts;
        uint[] paySchedule;
        address owner;
        uint yesVotes;
        bool funded;
        uint reservedTime;
        uint lastPaidIndex;
    }

    Survey[] public surveys;
    Proposal[] public proposals;
    // Tracks whether a specific address has voted for a specific project proposal
    mapping(uint => mapping(address => bool)) public hasVoted; //projectID => (user => has voted for project proposal)
    // Tracks how many *extra* votes an address has received through vote delegation
    mapping(uint => mapping(address => uint)) public extraVotes;
    mapping(uint => mapping(address => bool)) public hasDelegated; // Prevents multiple delegations
    // Tracks the number of YES votes received for a specific project proposal (used for funding threshol
    mapping(uint => uint) public paymentVotes; //projectID => number of YES votes

    // Tracks whether a user has voted for the *payment approval* of a specific project
    mapping(uint => mapping(address => bool)) public hasVotedForPayment; //projectID => user => has voted for payment

    mapping(address => bool) public isMember;

    // Initial owner is the contract deployer, so Ownable(msg.sender) is used
    constructor(address _tlToken) ERC20("MyGov", "MGOV") Ownable(msg.sender) {
        tlToken = ITLToken(_tlToken);
        _mint(address(this), MAX_SUPPLY);
    }

    // Checks if transferring a certain amount of tokens will violate voting restrictions.
    // A user cannot reduce their MyGov balance to 0 if they have:
    // - Voted for any proposal that is still active
    // - Delegated their vote to someone else for an active proposal
    // This function helps enforce that rule before allowing token transfers.

    function willViolateProposal(
        address user,
        uint amountTransferring
    ) internal view returns (bool) {
        bool hasVotedNonExpired = false;
        bool hasDelegatedNonExpired = false;
        // Check if user has voted in any still-active proposals
        for (uint i = 0; i < proposals.length; i++) {
            if (
                block.timestamp < proposals[i].votedeadline && hasVoted[i][user]
            ) {
                hasVotedNonExpired = true;
                break;
            }
        }
        // Check if user has delegated their vote in any still-active proposals
        for (uint i = 0; i < proposals.length; i++) {
            if (
                block.timestamp < proposals[i].votedeadline &&
                hasDelegated[i][user]
            ) {
                hasDelegatedNonExpired = true;
                break;
            }
        }
        // If transfer would reduce balance to zero while the user is still involved in active voting,
        // it is considered a violation
        uint userBalance = balanceOf(user);
        uint userBalanceAfterTransfer = userBalance - amountTransferring;
        if (
            userBalanceAfterTransfer <= 0 &&
            (hasVotedNonExpired || hasDelegatedNonExpired)
        ) {
            return true;
        }
        return false;
    }

    // Override ERC20 transfer to enforce voting rules and manage membership status
    function transfer(address to, uint amount) public override returns (bool) {
        require(
            !willViolateProposal(msg.sender, amount),
            "Since this transfer ends your membership due to balance and you have unfinished voting, process is cancelled."
        );
        // Update membership if recipient gains enough tokens
        if (amount > 1e18) {
            isMember[to] = true;
        }
        // Revoke membership if sender drops below threshold
        if (balanceOf(msg.sender) - amount < 1e18) {
            isMember[msg.sender] = false;
        }
        return super.transfer(to, amount);
    }
    // Returns true if the given address is a member (owns at least 1 token)
    function isContractMember(address user) public view returns (bool) {
        return isMember[user];
    }

    // Distributes 1 MyGov token to an address if it hasn't claimed before
    function faucet() external {
        require(!faucetClaimed[msg.sender], "Already claimed");
        _transfer(address(this), msg.sender, 1e18);
        isMember[msg.sender] = true;
        faucetClaimed[msg.sender] = true;
    }
    // Accepts TL token donations by transferring from sender to contract
    function donateTLToken(uint amount) external {
        require(
            tlToken.transferFrom(msg.sender, address(this), amount),
            "Not enough TL tokens for donation"
        );
    }
    // Allows members to donate MGOV tokens to the contract
    function donateMyGovToken(uint amount) external {
        require(
            balanceOf(msg.sender) >= amount,
            "Not enough MGOV tokens for donation"
        );
        // Prevent donation if it would violate active voting restrictions
        require(
            !willViolateProposal(msg.sender, amount),
            "Since this transfer ends your membership due to balance and you have unfinished voting, process is cancelled."
        );
        // Update membership status if sender's balance drops below 1 token
        if (balanceOf(msg.sender) - amount < 1e18) {
            isMember[msg.sender] = false;
        }
        _transfer(msg.sender, address(this), amount);
    }
    // Creates a new survey by a member after collecting required MGOV and TL tokens
    function submitSurvey(
        string calldata weburl,
        uint surveydeadline,
        uint numchoices,
        uint atmostchoices
    ) external returns (uint) {
        uint MGOV_COST = 2e18;
        uint TL_COST = 1000e18;

        // Sender should be a member for survey creation
        require(
            isContractMember(msg.sender),
            "Only members can submit surveys"
        );

        // Ensuring sender has enough MyGov tokens
        require(
            balanceOf(msg.sender) >= MGOV_COST,
            "At least 2 MGOV tokens required"
        );
        require(
            !willViolateProposal(msg.sender, MGOV_COST),
            "Since this transfer ends your membership due to balance and you have unfinished voting, process is cancelled."
        );
        // Ensuring sender has enough TL tokens
        require(
            tlToken.transferFrom(msg.sender, address(this), TL_COST),
            "At least 1000 TL tokens required."
        );

        if (balanceOf(msg.sender) - MGOV_COST < 1e18) {
            isMember[msg.sender] = false;
        }
        // 3. Transfer MyGov tokens from sender to contract
        _transfer(msg.sender, address(this), MGOV_COST);

        // 4. Add survey to storage
        surveys.push(
            Survey(
                weburl,
                surveydeadline,
                numchoices,
                atmostchoices,
                msg.sender,
                new uint[](numchoices),
                0
            )
        );

        // Return the index of the newly created survey, which is the id of the survey
        return surveys.length - 1;
    }

    // Allows members to participate in an active survey by submitting their choices
    function takeSurvey(uint surveyid, uint[] calldata choices) external {
        require(isContractMember(msg.sender), "Only members can take surveys");
        Survey storage s = surveys[surveyid];
        require(block.timestamp < s.surveydeadline, "Expired");
        require(choices.length <= s.atmostchoices, "Too many choices");
        for (uint i = 0; i < choices.length; i++) {
            require(choices[i] < s.numchoices, "Invalid choice");
            s.results[choices[i]]++;
        }
        s.takerCount++;
    }
    // Submits a new project proposal with required MGOV and TL tokens
    function submitProjectProposal(
        string calldata weburl,
        uint votedeadline,
        uint[] calldata paymentamounts,
        uint[] calldata payschedule
    ) external returns (uint) {
        // Sender should be a member for project proposal creation
        require(
            isContractMember(msg.sender),
            "Only members can submit project proposals"
        );
        // Ensuring sender has enough MyGov tokens
        require(balanceOf(msg.sender) >= 5e18, "5 MGOV tokens required");
        // Ensuring sender has enough TL tokens
        require(
            !willViolateProposal(msg.sender, 5e18),
            "Since this transfer ends your membership due to balance and you have unfinished voting, process is cancelled."
        );
        require(
            tlToken.transferFrom(msg.sender, address(this), 4000e18),
            "4000 TL tokens required."
        );
        if (balanceOf(msg.sender) - 5e18 < 1e18) {
            isMember[msg.sender] = false;
        }
        _transfer(msg.sender, address(this), 5e18);
        proposals.push(
            Proposal(
                weburl,
                votedeadline,
                paymentamounts,
                payschedule,
                msg.sender,
                0,
                false,
                0,
                0
            )
        );
        // Returning project id.
        return proposals.length - 1;
    }
    // Allows members to vote for a project proposal before the deadline
    function voteForProjectProposal(uint projectid, bool choice) external {
        require(isContractMember(msg.sender), "Only members can vote");
        // Allow voting if it's the user's first vote or they have delegated votes
        require(
            !hasVoted[projectid][msg.sender] ||
                extraVotes[projectid][msg.sender] > 0,
            "You have no votes left."
        );

        require(!proposals[projectid].funded, "Already funded");
        require(block.timestamp < proposals[projectid].votedeadline, "Expired");
        // If using an extra delegated vote, decrement the counter
        if (hasVoted[projectid][msg.sender]) {
            extraVotes[projectid][msg.sender] =
                extraVotes[projectid][msg.sender] -
                1;
        }
        if (choice) proposals[projectid].yesVotes++;

        hasVoted[projectid][msg.sender] = true;
    }
    // Allows members to vote for the next scheduled payment of a funded project
    function voteForProjectPayment(uint projectid, bool choice) public {
        require(isContractMember(msg.sender), "Only members can vote");
        require(
            !hasVotedForPayment[projectid][msg.sender],
            "Already voted for this payment"
        );
        require(block.timestamp < proposals[projectid].votedeadline, "Expired");
        require(proposals[projectid].funded, "Project not funded");
        require(
            proposals[projectid].lastPaidIndex <
                proposals[projectid].paySchedule.length,
            "All payments made"
        );
        hasVotedForPayment[projectid][msg.sender] = true;

        if (choice) {
            paymentVotes[projectid]++;
        }
    }
    // Delegates sender's vote to a member for a specific project
    function delegateVoteTo(address memberaddr, uint projectid) external {
        require(!hasVoted[projectid][msg.sender], "Already voted");
        require(!hasDelegated[projectid][msg.sender], "Already delegated");
        require(
            isContractMember(memberaddr),
            "You cannot delegate to non-member"
        );
        hasDelegated[projectid][msg.sender] = true;
        // Increasing the extra votes of the member to whom the vote is delegated
        extraVotes[projectid][memberaddr]++;
    }
    // Reserves TL funds for a project if voting and funding conditions are met
    function reserveProjectGrant(uint projectid) external {
        Proposal storage p = proposals[projectid];
        require(msg.sender == p.owner, "Not owner");
        require(block.timestamp < p.votedeadline, "Expired");
        require(!p.funded, "Already funded");
        // Requires at least 1/10 of members to vote yes
        require(p.yesVotes * 10 >= getMemberCount(), "Not enough votes");
        uint total;
        for (uint i = 0; i < p.paymentAmounts.length; i++) {
            total += p.paymentAmounts[i];
        }
        require(tlToken.balanceOf(address(this)) >= total, "Not enough TL");
        p.funded = true;
        p.reservedTime = block.timestamp;
    }
    // Transfers scheduled TL payment to project owner if conditions are met
    function withdrawProjectTLPayment(uint projectid) external {
        Proposal storage p = proposals[projectid];
        require(p.funded && msg.sender == p.owner, "Unauthorized");
        require(p.lastPaidIndex < p.paySchedule.length, "All paid");
        // Check if the current payment is due
        require(
            block.timestamp >= p.reservedTime + p.paySchedule[p.lastPaidIndex],
            "Not due yet"
        );
        // At least 1/100 of members must vote yes for payment
        require(
            paymentVotes[projectid] * 100 >= getMemberCount(),
            "Not enough votes for payment"
        );
        tlToken.transfer(p.owner, p.paymentAmounts[p.lastPaidIndex]);
        p.lastPaidIndex++;
        paymentVotes[projectid] = 0;
        // Reset all payment votes for the project
        for (uint i = 0; i < proposals.length; i++) {
            if (hasVotedForPayment[projectid][msg.sender]) {
                hasVotedForPayment[projectid][msg.sender] = false;
            }
        }
    }
    // Returns number of participants and result counts for a given survey
    function getSurveyResults(
        uint surveyid
    ) external view returns (uint, uint[] memory) {
        return (surveys[surveyid].takerCount, surveys[surveyid].results);
    }
    // Returns metadata of a survey: URL, deadline, number of choices, and max choices per user
    function getSurveyInfo(
        uint surveyid
    ) external view returns (string memory, uint, uint, uint) {
        Survey memory s = surveys[surveyid];
        return (s.weburl, s.surveydeadline, s.numchoices, s.atmostchoices);
    }
    // Returns the creator address of the specified survey
    function getSurveyOwner(uint surveyid) external view returns (address) {
        return surveys[surveyid].owner;
    }
    // Returns true if the project has been funded
    function getIsProjectFunded(uint projectid) external view returns (bool) {
        return proposals[projectid].funded;
    }
    // Returns the timestamp offset of the next scheduled TL payment, or -1 if all are paid
    function getProjectNextTLPayment(
        uint projectid
    ) external view returns (int) {
        Proposal storage p = proposals[projectid];
        if (p.lastPaidIndex >= p.paySchedule.length) return -1;
        return int(p.paySchedule[p.lastPaidIndex]);
    }
    // Returns the owner address of the specified project
    function getProjectOwner(uint projectid) external view returns (address) {
        return proposals[projectid].owner;
    }
    // Returns project metadata: URL, vote deadline, payment amounts, and schedule
    function getProjectInfo(
        uint activityid
    )
        external
        view
        returns (string memory, uint, uint[] memory, uint[] memory)
    {
        Proposal memory p = proposals[activityid];
        return (p.weburl, p.votedeadline, p.paymentAmounts, p.paySchedule);
    }
    // Returns the total number of submitted project proposals
    function getNoOfProjectProposals() external view returns (uint) {
        return proposals.length;
    }
    // Returns the number of funded projects
    function getNoOfFundedProjects() external view returns (uint count) {
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].funded) count++;
        }
    }
    // Returns total TL amount paid to the project so far
    function getTLReceivedByProject(
        uint projectid
    ) external view returns (uint total) {
        Proposal storage p = proposals[projectid];
        for (uint i = 0; i < p.lastPaidIndex; i++) {
            total += p.paymentAmounts[i];
        }
    }
    // Returns the total number of submitted surveys
    function getNoOfSurveys() external view returns (uint) {
        return surveys.length;
    }
    // Returns the number of members who have created surveys
    function getMemberCount() internal view returns (uint) {
        uint count = 0;
        for (uint i = 0; i < surveys.length; i++) {
            if (isContractMember(surveys[i].owner)) count++;
        }
        return count;
    }
}
