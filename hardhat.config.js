require("@nomiclabs/hardhat-waffle");
require("dotenv").config();
import "hardhat-preprocessor";
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 function getRemappings() {
  return fs
    .readFileSync("remappings.txt", "utf8")
    .split("\n")
    .filter(Boolean) // remove empty lines
    .map((line) => line.trim().split("="));
}

module.exports = {
  preprocess: {
    eachLine: (hre) => ({
      transform: (line) => {
        if (line.match(/^\s*import /i)) {
          getRemappings().forEach(([find, replace]) => {
            if (line.match(find)) {
              line = line.replace(find, replace);
            }
          });
        }
        return line;
      },
    }),
  },
  paths: {
    sources: "./src",
    cache: "./cache_hardhat",
  },
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
