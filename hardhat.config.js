// require("@nomiclabs/hardhat-ethers");
// require("hardhat-deploy");
require("dotenv").config();
// require("@nomiclabs/hardhat-web3");
// require("@nomiclabs/hardhat-etherscan");
// npx hardhat run --network gnosis scripts/2_init_assets.js
// npx hardhat node
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      forking: {
        enabled: true,
        url: "https://eth-mainnet.g.alchemy.com/v2/GoM_CaOEw9fCc95dleLZO3MUoDgdTgz7",
      },
      chainId: 1,
    },
    sepolia: {
      url: "https://sepolia.infura.io/v3/<key>",
      accounts: [process.env.PRIVATEKEY],
    },
    amoy: {
      url: process.env.AMOYURL,
      accounts: [process.env.PRIVATEKEY],
      chainId: 80002,
    },
    matic: {
      url: process.env.POLYGONURL,
      accounts: [process.env.PRIVATEKEY],
      chainId: 137,
    },
  },
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  mocha: {
    timeout: 40000,
  },
};
