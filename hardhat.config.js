require("@nomiclabs/hardhat-waffle");
require("dotenv").config();
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000
      }
    },
    compilers: [
      {
        version: "0.8.4",
      },
      {
        version: "0.6.6",
      },
      {
        version: "0.8.0",
      },
    ],
  },
  networks: {
    mumbai: {
      url: "", // TODO: Hard coded
      accounts: [process.env.PRIVATE_KEY_SELLER, process.env.PRIVATE_KEY_BUYER],
    },
  },
  mocha: {
    timeout: 500000,
  },
};
