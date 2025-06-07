import hardhat from "hardhat";

const { ethers } = hardhat;

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying as:", deployer.address);

  const balance = await deployer.provider.getBalance(deployer.address);
  console.log("ETH Balance:", ethers.formatEther(balance));

  // 1. Deploy TLToken (external token)
  const TLToken = await ethers.getContractFactory("TLToken");
  const tl = await TLToken.deploy();
  await tl.waitForDeployment();
  const tlAddress = await tl.getAddress();
  console.log("TLToken deployed:", tlAddress);

  // 2. Deploy DiamondCutFacet
  const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet");
  const cutFacet = await DiamondCutFacet.deploy();
  await cutFacet.waitForDeployment();
  const cutFacetAddress = await cutFacet.getAddress();
  console.log("DiamondCutFacet deployed:", cutFacetAddress);

  // 3. Deploy Diamond
  const Diamond = await ethers.getContractFactory("Diamond");
  const diamond = await Diamond.deploy(deployer.address, cutFacetAddress);
  await diamond.waitForDeployment();
  const diamondAddress = await diamond.getAddress();
  console.log("Diamond deployed:", diamondAddress);

  // 4. Deploy DiamondInit
  const DiamondInit = await ethers.getContractFactory("DiamondInit");
  const diamondInit = await DiamondInit.deploy();
  await diamondInit.waitForDeployment();
  const diamondInitAddress = await diamondInit.getAddress();
  console.log("DiamondInit deployed:", diamondInitAddress);

  // 5. Deploy all business logic facets
  const facetFileMap = {
    DiamondLoupeFacet: "DiamondLoupeFacet",
    ERC20Facet: "contracts/facets/ERC20Facet.sol:ERC20Facet",
    MembershipFacet: "contracts/facets/MembershipFacet.sol:MembershipFacet",
    SurveyFacet: "contracts/facets/SurveyFacet.sol:SurveyFacet",
    ProposalFacet: "contracts/facets/ProposalFacet.sol:ProposalFacet",
    FaucetFacet: "contracts/facets/FaucetFacet.sol:FaucetFacet",
    DonationFacet: "contracts/facets/DonationFacet.sol:DonationFacet",
  };

  const cut = [];

  for (const name of Object.keys(facetFileMap)) {
    const qualifiedName = facetFileMap[name];
    const Facet = await ethers.getContractFactory(qualifiedName);
    const facet = await Facet.deploy();
    await facet.waitForDeployment();

    const facetAddress = await facet.getAddress();
    const selectors = getSelectors(facet);

    cut.push({
      facetAddress: facetAddress,
      action: 0, // FacetCutAction.Add
      functionSelectors: selectors,
    });

    console.log(`${name} deployed:`, facetAddress);
  }

  // 6. Prepare DiamondInit call data
  const diamondInitContract = await ethers.getContractAt(
    "DiamondInit",
    diamondInitAddress
  );
  const initCallData = diamondInitContract.interface.encodeFunctionData(
    "init",
    [tlAddress]
  );

  // 7. Execute diamondCut
  const diamondCut = await ethers.getContractAt("IDiamondCut", diamondAddress);
  const tx = await diamondCut.diamondCut(cut, diamondInitAddress, initCallData);
  const receipt = await tx.wait();

  if (!receipt.status) {
    throw new Error("DiamondCut failed.");
  }

  console.log("Diamond initialized via diamondCut");
  const tl1 = await ethers.getContractAt("TLToken", tlAddress, deployer);
  await tl1.transferOwnership(diamondAddress);
  console.log("Now TLToken.owner() =", await tl1.owner());
  // Final report
  console.log("\nDeployment Complete:");
  console.log("Diamond (MGOV):", diamondAddress);
  console.log("TLToken       :", tlAddress);
}

// function getSelectors(contract) {
//   const selectors = Object.keys(contract.interface.functions)
//     .filter((fn) => fn !== "init(address)") // exclude initializer
//     .map((fn) => contract.interface.getSighash(fn));
//   return selectors;
// }
function getSelectors(contract) {
  const selectors = [];
  contract.interface.forEachFunction((fragment) => {
    // fragment.format() returns the full human-readable signature, e.g., "transfer(address,uint256)"
    // fragment.selector returns the 4-byte sighash, e.g., "0xa9059cbb"
    const signature = fragment.format();
    if (signature !== "init(address)") {

      selectors.push(fragment.selector);
    }
  });
  return selectors;
}

main().catch((err) => {
  console.error("Deployment failed:", err);
  process.exit(1);
});
