const { ethers } = require("hardhat");

async function main() {
  const accountAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
  const myGovAddress = "0xe7f1725e7734ce288f8367e1bb143e90bb3f0512";

  // Get signer for the account
  const signer = await ethers.getSigner(accountAddress);

  // Attach to MyGov contract
  const MyGov = await ethers.getContractFactory("MyGov");
  const myGov = await MyGov.attach(myGovAddress);

  console.log("Using account:", accountAddress);

  // ✅ Call faucet to mint 1 token (creates a transaction + new block)
  try {
    const tx = await myGov.connect(signer).faucet();
    const receipt = await tx.wait();
    console.log("Faucet transaction mined in block:", receipt.blockNumber);
  } catch (err) {
    console.error(
      "Faucet call failed (account may have already claimed):",
      err.message
    );
  }

  // 🔍 Check MyGov token balance
  const tokenBalance = await myGov.balanceOf(accountAddress);
  console.log("MyGov token balance:", ethers.formatEther(tokenBalance));

  // 🔍 Check ETH balance of the account
  const ethBalance = await ethers.provider.getBalance(accountAddress);
  console.log("ETH balance:", ethers.formatEther(ethBalance));

  // --- Begin appended code for second account ---
  const secondAccount = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
  const secondSigner = await ethers.getSigner(secondAccount);

  // Call faucet for second account
  console.log("Calling faucet for second account:", secondAccount);
  try {
    const tx2 = await myGov.connect(secondSigner).faucet();
    await tx2.wait();
  } catch (err) {
    console.error(
      "Faucet call failed (second account may have already claimed):",
      err.message
    );
  }

  // Check balance before submitting survey
  const secondBalance = await myGov.balanceOf(secondAccount);
  console.log(
    "Second account MyGov token balance:",
    ethers.utils.formatEther(secondBalance)
  );

  if (secondBalance > 0) {
    // Submit a survey
    console.log("Submitting a survey from second account...");
    const submitTx = await myGov.connect(secondSigner).submitSurvey(
      "https://example.com/survey1",
      Math.floor(Date.now() / 1000) + 3600, // deadline 1hr from now
      3, // num choices
      2 // max choices
    );
    const receipt2 = await submitTx.wait();
    console.log("Survey submitted in block:", receipt2.blockNumber);
  } else {
    console.log("Second account is not a member. Survey submission skipped.");
  }
  // --- End appended code for second account ---
}

main().catch(console.error);
