// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibStorage} from "../libraries/LibStorage.sol";

/**
 * @title ERC20Facet
 * @notice ERC20 implementation using OpenZeppelin, adapted for Diamond.
 */
contract ERC20Facet is ERC20 {
    using LibStorage for LibStorage.AppStorage;

    uint256 public constant MAX_SUPPLY = 10_000_000 * 1e18;

    constructor() ERC20("MyGov", "MGOV") {
        // This constructor won’t run when used in a Diamond
    }

    /// @notice Should be called via DiamondInit
    function initializeERC20Facet() external {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();
        require(!s.erc20Initialized, "Already initialized");
        _mint(address(this), MAX_SUPPLY);
        s.erc20Initialized = true;
    }
    
    /// @dev ERC20 transfer with voting rule enforcement
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(!_willViolateProposal(msg.sender, amount), "Voting constraint: balance too low");
        return super.transfer(to, amount);
    }

    /// @dev ERC20 transferFrom with voting rule enforcement
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(!_willViolateProposal(from, amount), "Voting constraint: balance too low");
        return super.transferFrom(from, to, amount);
    }

    /// @notice Transfers from contract balance (used by faucet)
    function transferFaucetToken(address to, uint256 amount) external {
        require(msg.sender == address(this), "Only callable via delegatecall");

        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance >= amount, "Insufficient faucet balance");

        _transfer(address(this), to, amount);
    }

    /// @dev Voting balance rule
    function _willViolateProposal(address user, uint256 amount) internal view returns (bool) {
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

        uint256 balance = balanceOf(user);
        if (amount > balance || balance - amount < 1e18) {
            if (hasVotedNonExpired || hasDelegatedNonExpired) {
                return true;
            }
        }

        return false;
    }
}
