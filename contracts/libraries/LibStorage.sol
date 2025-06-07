// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITLToken} from "../interfaces/ITLToken.sol";

library LibStorage {
    bytes32 constant STORAGE_POSITION = keccak256("mygov.standard.storage");

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

    struct AppStorage {
        address contractOwner;
        bool initialized;
        bool erc20Initialized;
        ITLToken tlToken;
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;

        // Membership
        address[] memberList;
        mapping(address => bool) isMember;

        // Faucet tracking
        mapping(address => bool) faucetClaimed;

        // Surveys
        Survey[] surveys;

        // Proposals
        Proposal[] proposals;

        // Voting
        mapping(uint => mapping(address => bool)) hasVoted;
        mapping(uint => mapping(address => uint)) extraVotes;
        mapping(uint => mapping(address => bool)) hasDelegated;

        // Payment voting
        mapping(uint => uint) paymentVotes;
        mapping(uint => mapping(address => bool)) hasVotedForPayment;
    }

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
