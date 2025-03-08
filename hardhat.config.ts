require("@nomicfoundation/hardhat-toolbox");
import dotenv from "dotenv";
dotenv.config();

module.exports = {
  solidity: "0.8.19",
  sourcify: {
    enabled: true
  },
  networks: {
    base_sepolia: {
      url: 'https://sepolia.base.org',
      accounts: [process.env.MNEMONIC ?? ''],
    },
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_SEPOLIA_KEY ?? ''}`,
      accounts: [process.env.MNEMONIC ?? ''],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY!,

    customChains: [
      {
        network: "base_sepolia",
        chainId: 84532,
        urls: {
          apiURL: "https://api-sepolia.basescan.org/api",
        }
      }
    ]
  },
};