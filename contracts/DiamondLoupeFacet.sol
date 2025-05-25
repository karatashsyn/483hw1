// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibDiamond} from "./libraries/LibDiamond.sol";

/**
 * @title DiamondLoupeFacet
 * @dev Implements EIP-2535 Diamond Loupe for inspecting facets.
 */
contract DiamondLoupeFacet {
    function facets() external view returns (LibDiamond.Facet[] memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint len = ds.facetAddresses.length;
        LibDiamond.Facet[] memory result = new LibDiamond.Facet[](len);

        for (uint i; i < len; i++) {
            address facetAddr = ds.facetAddresses[i];
            result[i].facetAddress = facetAddr;
            result[i].functionSelectors = ds.facetFunctionSelectors[facetAddr].functionSelectors;
        }
        return result;
    }

    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory) {
        return LibDiamond.diamondStorage().facetFunctionSelectors[_facet].functionSelectors;
        // return LibDiamond.diamondStorage().facetFunctionSelectors[_facet].functionSelectors;
    }

    function facetAddresses() external view returns (address[] memory) {
        return LibDiamond.diamondStorage().facetAddresses;
    }

    function facetAddress(bytes4 _selector) external view returns (address) {
        return LibDiamond.diamondStorage().selectorToFacetAndPosition[_selector].facetAddress;
    }
}
