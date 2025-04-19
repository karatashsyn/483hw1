require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: {
        version: "0.8.28",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    },
    networks: {
        sepolia: {
            // Sepolia project URL
            url: "https://sepolia.infura.io/v3/1d171a91871a403ea2511f63cc3445d9",
            accounts: [
                // Metamask account private key
                "37ac36a34c228cac652720a9a009cf9e1b1076e9e9d11de3993ece56aedbb02c"
            ]
        }
    },
    etherscan: {
        // Etherscan API key for Sepolia
        apiKey: "MGMT6RU3YMACAVQNUQ1H9BZMBNIH67J58G"
    }
};
