require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");
require("hardhat-abi-exporter");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    sepolia: {
      url: process.env.INFURA_URL,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },

  abiExporter: {
    path: "./frontend/src/abi",
    runOnCompile: true,
    clear: true,
    flat: false,
    spacing: 2,
    only: [
      "ERC20Facet",
      "MembershipFacet",
      "SurveyFacet",
      "ProposalFacet",
      "FaucetFacet",
      "DonationFacet",
      "DiamondLoupeFacet"
    ]
  }
};
