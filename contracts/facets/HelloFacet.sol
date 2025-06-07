// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloFacet {
    function sayHello() external pure returns (string memory) {
        return "Hello from HelloFacet!";
    }
}