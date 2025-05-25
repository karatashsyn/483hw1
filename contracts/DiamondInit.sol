// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {LibStorage} from "./libraries/LibStorage.sol";
import { ITLToken } from "./interfaces/ITLToken.sol";


interface IERC20Facet {
    function initializeERC20Facet() external;
}

/**
 * @title DiamondInit
 * @notice Initializes the Diamond proxy storage and token supply.
 */
contract DiamondInit {
    using LibStorage for LibStorage.AppStorage;

    /// @notice Initializes the Diamond proxy.
    /// @param tlToken Address of the external TLToken (ERC20)
    function init(address tlToken) external {
        LibStorage.AppStorage storage s = LibStorage.diamondStorage();

        require(!s.initialized, "Diamond: already initialized");

        // Set TLToken dependency
        s.tlToken = ITLToken(tlToken);

        // Initialize ERC20 facet (mint full supply to Diamond)
        IERC20Facet(address(this)).initializeERC20Facet();

        // Mark global init complete
        s.initialized = true;
    }
}
