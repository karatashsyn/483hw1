import hre from "hardhat";

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with:", deployer.address);

    const balance = await deployer.provider.getBalance(deployer.address);
    console.log("Current ETH Balance:", hre.ethers.formatEther(balance));

    // Deploy TLToken
    console.log("Preparing to deploy TLToken...");
    let tl;
    try {
        const TLToken = await hre.ethers.getContractFactory("TLToken");
        tl = await TLToken.deploy();
        await tl.waitForDeployment();
        console.log("TLToken deployed to:", await tl.getAddress());
    } catch (err) {
        console.error("TLToken deployment failed:", err);
        return; // Stop the script if TLToken fails
    }

    // Deploy MyGov with TLToken address
    console.log("Preparing to deploy MyGov...");
    const MyGov = await hre.ethers.getContractFactory("MyGov");
    const mgv = await MyGov.deploy(await tl.getAddress());
    await mgv.waitForDeployment();
    console.log("MyGov deployed to:", await mgv.getAddress());

    const supply = await mgv.totalSupply();
    const treasury = await mgv.owner();
    console.log("Total MGV Supply:", hre.ethers.formatEther(supply));
    console.log("Owner (Treasury):", treasury);

    // Transfer ownership of TLToken to MyGov contract
    const tx = await tl.transferOwnership(await mgv.getAddress());
    await tx.wait();
    console.log("TLToken ownership transferred to MyGov");

    console.log("\nDeployment complete!");
    console.log("TLToken: ", await tl.getAddress());
    console.log("MyGov  : ", await mgv.getAddress());
}

main().catch(error => {
    console.error("Deployment failed:", error);
    process.exitCode = 1;
});
