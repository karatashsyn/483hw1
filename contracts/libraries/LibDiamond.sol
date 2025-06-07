// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    enum FacetCutAction { Add, Replace, Remove }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition;
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // facet address => selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // array of facet addresses
        address[] facetAddresses;
        // contract owner
        address contractOwner;
    }

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // Ownership logic
    function setContractOwner(address _newOwner) internal {
        diamondStorage().contractOwner = _newOwner;
    }

    function contractOwner() internal view returns (address) {
        return diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    // Main diamondCut logic
    function diamondCut(FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            FacetCutAction action = _diamondCut[facetIndex].action;
            address facetAddress = _diamondCut[facetIndex].facetAddress;
            require(facetAddress != address(0) || action == FacetCutAction.Remove, "Facet address required");

            if (action == FacetCutAction.Add) {
                addFunctions(facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == FacetCutAction.Replace) {
                replaceFunctions(facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == FacetCutAction.Remove) {
                removeFunctions(facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("Invalid FacetCutAction");
            }
        }

        emit DiamondCut(_diamondCut, _init, _calldata);

        if (_init != address(0)) {
            require(_calldata.length > 0, "Init data required");
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            require(success, string(error));
        } else {
            require(_calldata.length == 0, "Init address required for calldata");
        }
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "No selectors provided");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress.code.length > 0, "Facet has no code");

        FacetFunctionSelectors storage ffs = ds.facetFunctionSelectors[_facetAddress];
        if (ffs.functionSelectors.length == 0) {
            ds.facetAddresses.push(_facetAddress);
            ffs.facetAddressPosition = ds.facetAddresses.length - 1;
        }

        for (uint i; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            require(ds.selectorToFacetAndPosition[selector].facetAddress == address(0), "Selector already exists");

            ds.selectorToFacetAndPosition[selector] = FacetAddressAndPosition({
                facetAddress: _facetAddress,
                functionSelectorPosition: uint96(ffs.functionSelectors.length)
            });
            ffs.functionSelectors.push(selector);
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "No selectors provided");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress.code.length > 0, "Facet has no code");

        FacetFunctionSelectors storage ffs = ds.facetFunctionSelectors[_facetAddress];
        if (ffs.functionSelectors.length == 0) {
            ds.facetAddresses.push(_facetAddress);
            ffs.facetAddressPosition = ds.facetAddresses.length - 1;
        }

        for (uint i; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            address oldFacet = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacet != _facetAddress, "Replacing with same function");
            removeFunction(oldFacet, selector);
            ds.selectorToFacetAndPosition[selector] = FacetAddressAndPosition({
                facetAddress: _facetAddress,
                functionSelectorPosition: uint96(ffs.functionSelectors.length)
            });
            ffs.functionSelectors.push(selector);
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "No selectors provided");
        DiamondStorage storage ds = diamondStorage();

        for (uint i; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            FacetAddressAndPosition memory fap = ds.selectorToFacetAndPosition[selector];
            require(fap.facetAddress != address(0), "Function does not exist");

            removeFunction(fap.facetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();

        FacetFunctionSelectors storage ffs = ds.facetFunctionSelectors[_facetAddress];
        uint selectorPos = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint lastSelectorPos = ffs.functionSelectors.length - 1;

        if (selectorPos != lastSelectorPos) {
            bytes4 lastSelector = ffs.functionSelectors[lastSelectorPos];
            ffs.functionSelectors[selectorPos] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPos);
        }

        ffs.functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        if (ffs.functionSelectors.length == 0) {
            uint addrPos = ffs.facetAddressPosition;
            uint lastAddrPos = ds.facetAddresses.length - 1;

            if (addrPos != lastAddrPos) {
                address lastAddr = ds.facetAddresses[lastAddrPos];
                ds.facetAddresses[addrPos] = lastAddr;
                ds.facetFunctionSelectors[lastAddr].facetAddressPosition = addrPos;
            }

            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress];
        }
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}
