// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibStorage} from "../libraries/LibStorage.sol";

/**
 * @title ERC20Facet
 * @notice ERC20 token logic for MGOV including custom transfer behavior linked to voting and membership.
 */
contract ERC20Facet {
    using LibStorage for LibStorage.AppStorage;

    // Constants
    string public constant name = "MyGov";
    string public constant symbol = "MGOV";
    uint8 public constant decimals = 18;
    uint256 public constant MAX_SUPPLY = 10_000_000 * 1e18;

    // ERC20 mappings stored in Diamond's AppStorage
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;

    /// @notice Returns the total token supply
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Returns the token balance of a specific account
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /// @notice Transfers tokens to another address, enforcing voting constraints
    /// @dev Custom logic to restrict transfers that violate voting rules
    function transfer(address to, uint256 amount) external returns (bool) {
        address sender = msg.sender;
        require(!_willViolateProposal(sender, amount), "Transfer violates active voting requirements");

        _transfer(sender, to, amount);

        return true;
    }

    /// @notice Approves another address to spend the caller's tokens
    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Returns allowance from owner to spender
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @notice Transfers tokens from one address to another (using allowance)
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: insufficient allowance");

        _allowances[from][msg.sender] = currentAllowance - amount;
        _transfer(from, to, amount);

        return true;
    }

    /// @dev Internal transfer with custom membership and proposal checks
    function _transfer(address from, address to, uint256 amount) internal {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: insufficient balance");

        _balances[from] -= amount;
        _balances[to] += amount;

        // Update membership status
        if (amount >= 1e18) {
            s.isMember[to] = true;
        }

        if (_balances[from] < 1e18) {
            s.isMember[from] = false;
        }

        emit Transfer(from, to, amount);
    }

    /// @notice Mints tokens to a given address
    /// @dev Callable by initialization only (simulate constructor mint)
    function mint(address to, uint256 amount) external {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();
        require(msg.sender == s.contractOwner, "Only owner can mint");
        require(_totalSupply + amount <= MAX_SUPPLY, "Exceeds max supply");

        _totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    /// @notice Burns tokens from an address
    function burn(address from, uint256 amount) external {
        require(msg.sender == from, "Only token owner can burn");
        require(_balances[from] >= amount, "Insufficient balance");

        _balances[from] -= amount;
        _totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    /// @dev Logic that checks if a transfer will violate an active proposal voting constraint
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

        uint256 balance = _balances[user];
        if (amount > balance || balance - amount < 1e18) {
            if (hasVotedNonExpired || hasDelegatedNonExpired) {
                return true;
            }
        }

        return false;
    }
    /// @notice Allows internal systems like faucet to transfer from contract balance
    function transferFaucetToken(address to, uint256 amount) external {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();
        require(msg.sender == address(this), "Only callable internally via delegatecall");

        require(_balances[address(this)] >= amount, "Insufficient faucet balance");
        _balances[address(this)] -= amount;
        _balances[to] += amount;

        emit Transfer(address(this), to, amount);
    }

    // ERC20 Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
