import hre from "hardhat";
import assert from "assert";
import { ZeroAddress } from "ethers";

const { ethers } = hre;

const diamondAddress = "0x9047E04868684a352Eb48df4e1d8A013f8EDeBB6"; 

function getSelectors(contract) {
  const selectors = [];

  for (const fragment of contract.interface.fragments) {
    if (fragment.type === "function" && fragment.name !== "init") {
      const fullSig = contract.interface.getFunction(fragment.name).format();
      const data = contract.interface.encodeFunctionData(fullSig);
      selectors.push(data.slice(0, 10));
    }
  }

  return selectors;
}

describe(" Add HelloFacet dynamically", function () {
  it("adds HelloFacet to diamond", async () => {
    // 1. Get the diamond cut facet
    const diamondCutFacet = await ethers.getContractAt("IDiamondCut", diamondAddress);

    // 2. Deploy the new facet
    const HelloFacet = await ethers.getContractFactory("HelloFacet");
    const helloFacet = await HelloFacet.deploy();
    await helloFacet.waitForDeployment();

    // 3. Extract function selectors
    const selectors = getSelectors(helloFacet);
    assert(selectors.length > 0, "No function selectors extracted");

    // 4. Perform diamond cut
    const cut = [{
      facetAddress: await helloFacet.getAddress(),
      action: 0, // 0 = Add
      functionSelectors: selectors
    }];

    const tx = await diamondCutFacet.diamondCut(cut, ZeroAddress, "0x");
    const receipt = await tx.wait();
    assert.equal(receipt.status, 1, "DiamondCut failed");


  });
});
