// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibStorage} from "./libraries/LibStorage.sol";
import {ITLToken} from "./interfaces/ITLToken.sol";

/**
 * @title DiamondInit
 * @dev This contract initializes the AppStorage once via delegatecall.
 */
contract DiamondInit {
    function init(address _tlToken) external {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();
        require(!s.initialized, "Already initialized");

        s.tlToken = ITLToken(_tlToken);
        s.contractOwner = msg.sender;
        s.initialized = true;
    }
}
