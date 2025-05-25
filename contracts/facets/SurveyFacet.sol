// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibStorage} from "../libraries/LibStorage.sol";

/**
 * @title SurveyFacet
 * @notice Allows members to submit and participate in surveys using MGOV and TL tokens.
 */
contract SurveyFacet {
    using LibStorage for LibStorage.AppStorage;

    uint256 internal constant MGOV_COST = 2e18;
    uint256 internal constant TL_COST = 1000e18;
    uint256 internal constant ONE_MGOV = 1e18;

    /// @notice Submits a new survey proposal and deducts required token fees
    /// @param weburl The metadata or URL of the survey
    /// @param surveydeadline Deadline (UNIX timestamp) for survey participation
    /// @param numchoices Number of selectable options in the survey
    /// @param atmostchoices Max number of choices a participant can select
    /// @return surveyId The index of the newly added survey
    function submitSurvey(
        string calldata weburl,
        uint256 surveydeadline,
        uint256 numchoices,
        uint256 atmostchoices
    ) external returns (uint256 surveyId) {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        require(s.isMember[msg.sender], "Only members can submit surveys");

        // Check MGOV balance and proposal voting status
        uint256 senderBalance = _getBalance(msg.sender);
        require(senderBalance >= MGOV_COST, "At least 2 MGOV tokens required");
        require(!_willViolateProposal(msg.sender, MGOV_COST), "Transfer violates voting requirement");

        // Check TLToken balance and transfer
        require(s.tlToken.transferFrom(msg.sender, address(this), TL_COST), "TL token transfer failed");

        // Deduct MGOV cost
        _decreaseBalance(msg.sender, MGOV_COST);
        _increaseBalance(address(this), MGOV_COST);

        // Update membership if dropping below 1 MGOV
        if (_getBalance(msg.sender) < ONE_MGOV) {
            s.isMember[msg.sender] = false;
        }

        // Create new survey
        s.surveys.push(LibStorage.Survey({
            weburl: weburl,
            surveydeadline: surveydeadline,
            numchoices: numchoices,
            atmostchoices: atmostchoices,
            owner: msg.sender,
            results: new uint256[](numchoices),
            takerCount: 0
        }));

        return s.surveys.length - 1;
    }

    /// @notice Participate in a survey by selecting a subset of options
    /// @param surveyId ID of the survey
    /// @param choices Array of chosen option indices
    function takeSurvey(uint256 surveyId, uint256[] calldata choices) external {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        require(s.isMember[msg.sender], "Only members can take surveys");
        require(surveyId < s.surveys.length, "Invalid survey ID");

        LibStorage.Survey storage survey = s.surveys[surveyId];

        require(block.timestamp < survey.surveydeadline, "Survey expired");
        require(choices.length <= survey.atmostchoices, "Too many choices");

        for (uint256 i = 0; i < choices.length; i++) {
            uint256 choice = choices[i];
            require(choice < survey.numchoices, "Invalid choice index");
            survey.results[choice]++;
        }

        survey.takerCount++;
    }

    /// @notice Returns taker count and survey result tallies
    /// @param surveyId ID of the survey
    function getSurveyResults(uint256 surveyId) external view returns (uint256 takers, uint256[] memory results) {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();
        require(surveyId < s.surveys.length, "Invalid survey ID");

        LibStorage.Survey storage survey = s.surveys[surveyId];
        return (survey.takerCount, survey.results);
    }

    /// @notice Returns metadata for a given survey
    function getSurveyInfo(uint256 surveyId)
        external
        view
        returns (string memory url, uint256 deadline, uint256 numchoices, uint256 atmostchoices)
    {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();
        require(surveyId < s.surveys.length, "Invalid survey ID");

        LibStorage.Survey storage survey = s.surveys[surveyId];
        return (survey.weburl, survey.surveydeadline, survey.numchoices, survey.atmostchoices);
    }

    /// @notice Returns the survey creator
    function getSurveyOwner(uint256 surveyId) external view returns (address) {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();
        require(surveyId < s.surveys.length, "Invalid survey ID");

        return s.surveys[surveyId].owner;
    }

    /// @notice Returns the total number of surveys submitted
    function getNoOfSurveys() external view returns (uint256) {
        return LibStorage.diamondStorage().surveys.length;
    }

    // ========================
    // Internal utilities
    // ========================

    function _getBalance(address user) internal view returns (uint256) {
        // You can alternatively move this into LibToken if split further
        return ERC20Facet(address(this)).balanceOf(user);
    }

    function _increaseBalance(address user, uint256 amount) internal {
        ERC20Facet(address(this)).mint(user, amount);
    }

    function _decreaseBalance(address user, uint256 amount) internal {
        ERC20Facet(address(this)).burn(user, amount);
    }

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

        uint256 balance = _getBalance(user);
        if (amount > balance || balance - amount < 1e18) {
            if (voted || delegated) return true;
        }

        return false;
    }
}

interface ERC20Facet {
    function balanceOf(address account) external view returns (uint256);
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}
