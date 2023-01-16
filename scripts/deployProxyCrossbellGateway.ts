// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

const proxyAdmin = "0xbf58a5d64F451f537ABdB8B0203eF3F105097285";
const validatorContract = "0xbf58a5d64F451f537ABdB8B0203eF3F105097285";
const gatewayAdmin = "0x678e0E67555E8fC4533c1a9f204e2C1C7C1C9665";
const crossbellTokens = ["0x73bE5E9f82f45564565Ffb53F52b23eAB32032F9","0x73bE5E9f82f45564565Ffb53F52b23eAB32032F9", "0x73bE5E9f82f45564565Ffb53F52b23eAB32032F9"];
const chainIds = [5, 80001, 97];
const mainchainTokens = ["0xbf58a5d64F451f537ABdB8B0203eF3F105097285", "0x460248221088C2D9541435f5cd0AB817BB0F197F", "0xB865a7c5E88B052540213E77b43a76dDCEB1893b"];
const mainchainTokenDecimals = [6, 18, 18];

async function main() {
    // deploy crossbellGateway
    const CrossbellGateway = await ethers.getContractFactory("CrossbellGateway");
    const crossbellGateway = await CrossbellGateway.deploy();
    // always initialize the logic contract
    await crossbellGateway.initialize(
        validatorContract,
        gatewayAdmin,
        crossbellTokens,
        chainIds,
        mainchainTokens,
        mainchainTokenDecimals
    );

    // deploy proxy
    const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
    const proxyCrossbellGateway = await Proxy.deploy(crossbellGateway.address, proxyAdmin, "0x");
    await proxyCrossbellGateway.deployed();

    // initialize proxy
    const proxyGateway = await CrossbellGateway.attach(proxyCrossbellGateway.address);
    await proxyGateway.initialize(
        validatorContract,
        gatewayAdmin,
        crossbellTokens,
        chainIds,
        mainchainTokens,
        mainchainTokenDecimals
    );

    console.log("crossbellGateway deployed to:", crossbellGateway.address);
    console.log("proxyCrossbellGateway deployed to:", proxyCrossbellGateway.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});