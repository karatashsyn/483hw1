require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    holesky: {
      url: "https://holesky.infura.io/v3/1d171a91871a403ea2511f63cc3445d9",
      accounts: [
        "37ac36a34c228cac652720a9a009cf9e1b1076e9e9d11de3993ece56aedbb02c",
      ],
    },
  },
  etherscan: {
    apiKey: "MGMT6RU3YMACAVQNUQ1H9BZMBNIH67J58G",
  },
};
