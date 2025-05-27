// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITLToken
 * @dev Interface for the TLToken used for project proposals and donations.
 */
interface ITLToken {
    function transferFrom(address from, address to, uint amount) external returns (bool);
    function transfer(address to, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
    function faucet(address to, uint amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

}
