import { HardhatUserConfig } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "hardhat-contract-sizer";
import "solidity-docgen";
import * as dotenv from "dotenv";
import "hardhat-abi-exporter";

dotenv.config();

const infuraApiKey: string | undefined = process.env.INFURA_API_KEY;
if (!infuraApiKey) {
    throw new Error("Please set your INFURA_API_KEY in a .env file");
}

const chainIds = {
    bsc: 56,
    bscTestnet: 97,
    mainnet: 1,
    goerli: 5,
    polygon: 137,
    polygonMumbai: 80001,
    sepolia: 11155111,
    avaxFuji: 43113,
};

function getChainConfig(chain: keyof typeof chainIds): NetworkUserConfig {
    let jsonRpcUrl: string;
    switch (chain) {
        case "bsc":
            jsonRpcUrl = "https://bsc-dataseed1.binance.org";
            break;
        case "bscTestnet":
            jsonRpcUrl = "https://endpoints.omniatech.io/v1/bsc/testnet/public";
            break;
        case "polygon":
            jsonRpcUrl = "https://polygon-rpc.com/";
            break;
        case "polygonMumbai":
            jsonRpcUrl = "https://matic-mumbai.chainstacklabs.com";
            break;
        case "avaxFuji":
            jsonRpcUrl = "https://avalanche-fuji.infura.io/v3/461d31c50880488685731b86e524e3e6";
            break;
        default:
            jsonRpcUrl = "https://" + chain + ".infura.io/v3/" + infuraApiKey;
    }
    return {
        accounts: [`0x${process.env.PRIVATE_KEY}`],
        chainId: chainIds[chain],
        url: jsonRpcUrl,
    };
}

module.exports = {
    solidity: {
        version: "0.8.10",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    docgen: {
        output: "docs",
        pages: "files",
    },
    paths: {
        sources: "./contracts",
        cache: "./cache",
        artifacts: "./artifacts",
    },
    networks: {
        crossbell: {
            url: "https://rpc.crossbell.io",
            accounts: [`0x${process.env.PRIVATE_KEY}`],
        },
        bsc: getChainConfig("bsc"),
        bscTestnet: getChainConfig("bscTestnet"),
        mainnet: getChainConfig("mainnet"),
        goerli: getChainConfig("goerli"),
        polygon: getChainConfig("polygon"),
        polygonMumbai: getChainConfig("polygonMumbai"),
        sepolia: getChainConfig("sepolia"),
        avaxFuji:getChainConfig("avaxFuji")
    },

    etherscan: {
        apiKey: {
            crossbell: "no API key",
            bsc: process.env.BSCSCAN_API_KEY || "",
            bscTestnet: process.env.BSCSCAN_API_KEY || "",
            mainnet: process.env.ETHERSCAN_API_KEY || "",
            goerli: process.env.ETHERSCAN_API_KEY || "",
            sepolia: process.env.ETHERSCAN_API_KEY || "",
            polygon: process.env.POLYGONSCAN_API_KEY || "",
            polygonMumbai: process.env.POLYGONSCAN_API_KEY || "",
        },
        customChains: [
            {
                network: "crossbell",
                chainId: 3737,
                urls: {
                    apiURL: "https://scan.crossbell.io/api",
                    browserURL: "https://scan.crossbell.io",
                },
            },
        ],
    },

    abiExporter: {
        path: "./build-info",
        pretty: false,
        except: ["@openzeppelin"],
    },
} as HardhatUserConfig;
