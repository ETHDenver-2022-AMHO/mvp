require("@nomiclabs/hardhat-waffle");
require("dotenv").config();
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  // solidity: "0.8.4",
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
      url: "https://polygon-mumbai.infura.io/v3/3f0ceebfdf3e49ff80d5f59fa57cf0b4",
      accounts: [process.env.PRIVATE_KEY_SELLER, process.env.PRIVATE_KEY_BUYER],
    },
  },
  mocha: {
    timeout: 500000,
  },
};
