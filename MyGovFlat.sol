// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/Context.sol@v5.3.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File @openzeppelin/contracts/access/Ownable.sol@v5.3.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File @openzeppelin/contracts/interfaces/draft-IERC6093.sol@v5.3.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC-20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(
        address sender,
        uint256 balance,
        uint256 needed
    );

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(
        address spender,
        uint256 allowance,
        uint256 needed
    );

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC-721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in ERC-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC-1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(
        address sender,
        uint256 balance,
        uint256 needed,
        uint256 tokenId
    );

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v5.3.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// File @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol@v5.3.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface for the optional metadata functions from the ERC-20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File @openzeppelin/contracts/token/ERC20/ERC20.sol@v5.3.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.3.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC-20
 * applications.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256))
        private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * Both values are immutable: they can only be set once during construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 value
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Skips emitting an {Approval} event indicating an allowance update. This is not
     * required by the ERC. See {xref-ERC20-_approve-address-address-uint256-bool-}[_approve].
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner`'s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     *
     * ```solidity
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(
        address owner,
        address spender,
        uint256 value,
        bool emitEvent
    ) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner`'s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 value
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(
                    spender,
                    currentAllowance,
                    value
                );
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// File contracts/MyGov.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;

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
