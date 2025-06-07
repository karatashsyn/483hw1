// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibStorage} from "../libraries/LibStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import { ITLToken } from "../interfaces/ITLToken.sol";


/**
 * @title ERC20Facet
 * @notice Diamond-compatible ERC20 token logic for MGOV with voting constraints.
 */
contract ERC20Facet {
    using LibStorage for LibStorage.AppStorage;

    // Constants
    string public constant name = "MyGov";
    string public constant symbol = "MGOV";
    uint8 public constant decimals = 18;
    uint256 public constant MAX_SUPPLY = 10_000_000 * 1e18;

    // ------------------------------------------------------------------------
    // ERC20 View Functions
    // ------------------------------------------------------------------------

    function totalSupply() external view returns (uint256) {
        return LibStorage.diamondStorage().totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return LibStorage.diamondStorage().balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return LibStorage.diamondStorage().allowances[owner][spender];
    }

    // ------------------------------------------------------------------------
    // ERC20 External Functions
    // ------------------------------------------------------------------------

    function transfer(address to, uint256 amount) external returns (bool) {
        require(!_willViolateProposal(msg.sender, amount), "Voting constraint violated");
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();
        s.allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        uint256 currentAllowance = s.allowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: insufficient allowance");

        s.allowances[from][msg.sender] = currentAllowance - amount;
        require(!_willViolateProposal(from, amount), "Voting constraint violated");

        _transfer(from, to, amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Admin Minting and Burning
    // ------------------------------------------------------------------------

    /// @notice Mints tokens to the given address. Only Diamond owner may call.
    function mint(address to, uint256 amount) external {
        require(msg.sender == LibDiamond.contractOwner(), "Only owner");
        _mint(to, amount);
    }

    /// @notice Mints full supply to Diamond contract (for init)
    function initializeERC20Facet() external {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();
        require(!s.erc20Initialized, "Already initialized");

        _mint(address(this), MAX_SUPPLY);
        s.erc20Initialized = true;
    }

    /// @notice Burns tokens from sender
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function testMintBoth(address to, uint256 mgovAmount, uint256 tlAmount) external {
        require(msg.sender == LibDiamond.contractOwner(), "Only owner");
        _mint(to, mgovAmount);
        // Mint TL via owner-only mint()
        ITLToken tl = LibStorage.diamondStorage().tlToken;
        tl.faucet(to, tlAmount);
    }

    // ------------------------------------------------------------------------
    // Internal Transfers and Logic
    // ------------------------------------------------------------------------

    function _transfer(address from, address to, uint256 amount) internal {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        require(to != address(0), "ERC20: transfer to zero address");
        require(s.balances[from] >= amount, "ERC20: insufficient balance");

        s.balances[from] -= amount;
        s.balances[to] += amount;

        // Update membership
        if (s.balances[to] >= 1e18) s.isMember[to] = true;
        if (s.balances[from] < 1e18) s.isMember[from] = false;

        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        require(to != address(0), "ERC20: mint to zero address");
        require(s.totalSupply + amount <= MAX_SUPPLY, "Exceeds max supply");
        if(to != address(this)){
            s.totalSupply += amount;
        }
        s.balances[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        require(from != address(0), "ERC20: burn from zero address");
        require(s.balances[from] >= amount, "ERC20: insufficient balance");

        s.balances[from] -= amount;
        s.totalSupply -= amount;

        emit Transfer(from, address(0), amount);
    }

    /// @notice Used by faucet facet to distribute tokens from Diamond treasury
    function transferFaucetToken(address to, uint256 amount) external {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();
        require(msg.sender == address(this), "Internal use only");

        require(s.balances[address(this)] >= amount, "Insufficient faucet balance");
        s.balances[address(this)] -= amount;
        s.balances[to] += amount;

        emit Transfer(address(this), to, amount);
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

        uint256 balance = s.balances[user];
        if (amount > balance || balance - amount < 1e18) {
            if (voted || delegated) {
                return true;
            }
        }

        return false;
    }

    // ------------------------------------------------------------------------
    // Events
    // ------------------------------------------------------------------------

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
