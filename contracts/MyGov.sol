// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ITLToken {
    function transferFrom(address from, address to, uint amount) external returns (bool);
    function transfer(address to, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
}

// Inheriting from ERC20 so that our contract provides the standard ERC20 functionalities
contract MyGov is ERC20, Ownable {
    ITLToken public tlToken;

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

    mapping(uint => mapping(address => bool)) public hasVoted; //projectID => (user => has voted for project proposal)
    // Extra vote rights from other members' delegations.
    mapping(uint => mapping(address => uint)) public extraVotes;
    mapping(uint => mapping(address => bool)) public hasDelegated;
    mapping(uint => uint) public paymentVotes; //projectID => number of YES votes
    mapping(uint => mapping(address => bool)) public hasVotedForPayment; //projectID => user => has voted for payment

    mapping(address => bool) public isMember;

    // Initial owner is the contract deployer, so Ownable(msg.sender) is used
    constructor(address _tlToken) ERC20("MyGov", "MGOV") Ownable(msg.sender) {
        tlToken = ITLToken(_tlToken);
        _mint(address(this), MAX_SUPPLY);
    }

    
  
  // A helper function for the 12th point of the project description  
  // Checking if user has voted a propoposal that is not expired yet.
  // If this is the case and the user is transferring an amount that will make their balance less than 1 MGOV,
  // then the function will return true, indicating that the transfer will violate the proposal.
  // create a variable boolean called hasVotedNonExpired
  function willViolateProposal(address user, uint amountTransferring) internal view returns (bool) {
    bool hasVotedNonExpired = false;
    bool hasDelegatedNonExpired = false;
    for (uint i = 0; i < proposals.length; i++) {
        if (block.timestamp < proposals[i].votedeadline && hasVoted[i][user]) {
            hasVotedNonExpired = true;
            break;
        }
    }
    for (uint i = 0; i < proposals.length; i++) {
        if (block.timestamp < proposals[i].votedeadline && hasDelegated[i][user]) {
            hasDelegatedNonExpired = true;
            break;
        }
    }
    uint userBalance = balanceOf(user);
    uint userBalanceAfterTransfer = userBalance - amountTransferring;
    if (userBalanceAfterTransfer <= 0 && (hasVotedNonExpired || hasDelegatedNonExpired)) {
        return true;
    }
    return false;
  }

  // We are overriding the transfer function of the ERC20 contract for checking if the transfers will violate the proposal.
  function transfer(address to, uint amount) public override returns (bool) {
    require(!willViolateProposal(msg.sender, amount), "Since this transfer ends your membership due to balance and you have unfinished voting, process is cancelled.");
    if(amount > 1e18) {
        isMember[to] = true;
    }
    if(balanceOf(msg.sender)- amount < 1e18) {
        isMember[msg.sender] = false;
    }
    return super.transfer(to, amount);
  }

  function isContractMember(address user) public view returns (bool) {
    return isMember[user];
  }
 
    // A faucet function to distribute MyGov tokens to members that have not claimed yet
    function faucet() external {
        require(!faucetClaimed[msg.sender], "Already claimed");
        _transfer(address(this), msg.sender, 1e18);
        isMember[msg.sender] = true;
        faucetClaimed[msg.sender] = true;
    }

    function donateTLToken(uint amount) external {
        require(tlToken.transferFrom(msg.sender, address(this), amount), "Not enough TL tokens for donation");
    }

    function donateMyGovToken(uint amount) external {
        require(balanceOf(msg.sender) >= amount, "Not enough MGOV tokens for donation");
        require(!willViolateProposal(msg.sender, amount), "Since this transfer ends your membership due to balance and you have unfinished voting, process is cancelled.");
        if(balanceOf(msg.sender) - amount < 1e18) {
            isMember[msg.sender] = false;
        }
        _transfer(msg.sender, address(this), amount);
    }

  function submitSurvey(string calldata weburl, uint surveydeadline, uint numchoices, uint atmostchoices)
    external returns (uint)
{
    uint MGOV_COST = 2e18;
    uint TL_COST = 1000e18;

    // Sender should be a member for survey creation
    require(isContractMember(msg.sender), "Only members can submit surveys");

    // Ensuring sender has enough MyGov tokens
    require(balanceOf(msg.sender) >= MGOV_COST, "At least 2 MGOV tokens required");
    require(!willViolateProposal(msg.sender, MGOV_COST), "Since this transfer ends your membership due to balance and you have unfinished voting, process is cancelled.");
    // Ensuring sender has enough TL tokens
    require(tlToken.transferFrom(msg.sender, address(this), TL_COST), "At least 1000 TL tokens required.");

    if(balanceOf(msg.sender)- MGOV_COST < 1e18) {
        isMember[msg.sender] = false;
    }
    // 3. Transfer MyGov tokens from sender to contract
    _transfer(msg.sender, address(this), MGOV_COST);

    // 4. Add survey to storage
    surveys.push(Survey(
        weburl,
        surveydeadline,
        numchoices,
        atmostchoices,
        msg.sender,
        new uint[](numchoices),
        0
    ));

    // Return the index of the newly created survey, which is the id of the survey
    return surveys.length - 1;
}
     
    // Function for allowing anyone to join a survey with given id
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

    function submitProjectProposal(string calldata weburl, uint votedeadline, uint[] calldata paymentamounts, uint[] calldata payschedule)
        external returns (uint)
    {
        // Sender should be a member for project proposal creation
        require(isContractMember(msg.sender), "Only members can submit project proposals");
        // Ensuring sender has enough MyGov tokens
        require(balanceOf(msg.sender) >= 5e18, "5 MGOV tokens required");
        // Ensuring sender has enough TL tokens
        require(!willViolateProposal(msg.sender, 5e18), "Since this transfer ends your membership due to balance and you have unfinished voting, process is cancelled.");
        require(tlToken.transferFrom(msg.sender, address(this), 4000e18), "4000 TL tokens required.");
        if(balanceOf(msg.sender) - 5e18 < 1e18) {
            isMember[msg.sender] = false;
        }
        _transfer(msg.sender, address(this), 5e18);
        proposals.push(Proposal(weburl, votedeadline, paymentamounts, payschedule, msg.sender, 0, false, 0, 0));
        // Returning project id.
        return proposals.length - 1;
    }

    function voteForProjectProposal(uint projectid, bool choice) external {
        require(isContractMember(msg.sender), "Only members can vote");
        require(!hasVoted[projectid][msg.sender] || extraVotes[projectid][msg.sender] > 0 , "You have no votes left.");
        // If already funded, no need to vote
        require(!proposals[projectid].funded, "Already funded");
        require(block.timestamp < proposals[projectid].votedeadline, "Expired");

        if(hasVoted[projectid][msg.sender]) {
            extraVotes[projectid][msg.sender] = extraVotes[projectid][msg.sender] - 1;
        }
        if (choice) proposals[projectid].yesVotes++;

        hasVoted[projectid][msg.sender] = true;
    }

    function voteForProjectPayment(uint projectid, bool choice) public {
    require(isContractMember(msg.sender), "Only members can vote");
    require(!hasVotedForPayment[projectid][msg.sender], "Already voted for this payment");
    require(block.timestamp < proposals[projectid].votedeadline, "Expired");
    require(proposals[projectid].funded, "Project not funded");
    require(proposals[projectid].lastPaidIndex < proposals[projectid].paySchedule.length, "All payments made");
    hasVotedForPayment[projectid][msg.sender] = true;

    if (choice) {
        paymentVotes[projectid]++;
    }
}

    function delegateVoteTo(address memberaddr, uint projectid) external {
        require(!hasVoted[projectid][msg.sender], "Already voted");
        require(!hasDelegated[projectid][msg.sender], "Already delegated");
        require(isContractMember(memberaddr), "You cannot delegate to non-member");
        hasDelegated[projectid][msg.sender] = true;
        // Increasing the extra votes of the member to whom the vote is delegated
        extraVotes[projectid][memberaddr]++;
    }

    function reserveProjectGrant(uint projectid) external {
        Proposal storage p = proposals[projectid];
        require(msg.sender == p.owner, "Not owner");
        require(block.timestamp < p.votedeadline, "Expired");
        require(!p.funded, "Already funded");
        require(p.yesVotes * 10 >= getMemberCount(), "Not enough votes");
        uint total;
        for (uint i = 0; i < p.paymentAmounts.length; i++) {
            total += p.paymentAmounts[i];
        }
        require(tlToken.balanceOf(address(this)) >= total, "Not enough TL");
        p.funded = true;
        p.reservedTime = block.timestamp;
    }

    function withdrawProjectTLPayment(uint projectid) external {
        Proposal storage p = proposals[projectid];
        require(p.funded && msg.sender == p.owner, "Unauthorized");
        require(p.lastPaidIndex < p.paySchedule.length, "All paid");
        require(block.timestamp >= p.reservedTime + p.paySchedule[p.lastPaidIndex], "Not due yet");
        require(paymentVotes[projectid] * 100 >= getMemberCount(), "Not enough votes for payment");
        tlToken.transfer(p.owner, p.paymentAmounts[p.lastPaidIndex]);
        p.lastPaidIndex++;
        paymentVotes[projectid] = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (hasVotedForPayment[projectid][msg.sender]) {
                hasVotedForPayment[projectid][msg.sender] = false;
            }
        }
    }

    function getSurveyResults(uint surveyid) external view returns (uint, uint[] memory) {
        return (surveys[surveyid].takerCount, surveys[surveyid].results);
    }

    function getSurveyInfo(uint surveyid) external view returns (string memory, uint, uint, uint) {
        Survey memory s = surveys[surveyid];
        return (s.weburl, s.surveydeadline, s.numchoices, s.atmostchoices);
    }

    function getSurveyOwner(uint surveyid) external view returns (address) {
        return surveys[surveyid].owner;
    }

    function getIsProjectFunded(uint projectid) external view returns (bool) {
        return proposals[projectid].funded;
    }

    function getProjectNextTLPayment(uint projectid) external view returns (int) {
        Proposal storage p = proposals[projectid];
        if (p.lastPaidIndex >= p.paySchedule.length) return -1;
        return int(p.paySchedule[p.lastPaidIndex]);
    }

    function getProjectOwner(uint projectid) external view returns (address) {
        return proposals[projectid].owner;
    }

    function getProjectInfo(uint activityid) external view returns (string memory, uint, uint[] memory, uint[] memory) {
        Proposal memory p = proposals[activityid];
        return (p.weburl, p.votedeadline, p.paymentAmounts, p.paySchedule);
    }

    function getNoOfProjectProposals() external view returns (uint) {
        return proposals.length;
    }

    function getNoOfFundedProjects() external view returns (uint count) {
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].funded) count++;
        }
    }

    function getTLReceivedByProject(uint projectid) external view returns (uint total) {
        Proposal storage p = proposals[projectid];
        for (uint i = 0; i < p.lastPaidIndex; i++) {
            total += p.paymentAmounts[i];
        }
    }

    function getNoOfSurveys() external view returns (uint) {
        return surveys.length;
    }

    function getMemberCount() internal view returns (uint) {
        uint count = 0;
        for (uint i = 0; i < surveys.length; i++) {
            if (isContractMember(surveys[i].owner)) count++;
        }
        return count;
    }

}
