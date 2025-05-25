// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibDiamond} from "./libraries/LibDiamond.sol";

/**
 * @title Diamond
 * @notice EIP-2535 Diamond proxy. Delegates calls to facets via selector routing.
 */
contract Diamond {
    constructor(address _contractOwner, address _diamondCutFacet) {
        // Set the contract owner in storage
        LibDiamond.setContractOwner(_contractOwner);

        // ✅ Declare and assign functionSelectors array (length = 1)
        bytes4 ;

        functionSelectors[0] = bytes4(
            keccak256("diamondCut((address,uint8,bytes4[])[],address,bytes)")
        );

        // ✅ Declare and assign FacetCut array (length = 1)
        LibDiamond.FacetCut ;

        cut[0] = LibDiamond.FacetCut({
            facetAddress: _diamondCutFacet,
            action: LibDiamond.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        // ✅ Apply the facet cut — adds diamondCut function to the Diamond
        LibDiamond.diamondCut(cut, address(0), "");
    }

    /// @notice Delegates calls to registered facets
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }

        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /// @notice Accept ETH
    receive() external payable {}
}
