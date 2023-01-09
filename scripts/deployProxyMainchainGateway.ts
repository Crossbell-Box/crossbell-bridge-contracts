// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import {
    proxyAdmin,
    withdrawalUnlocker,
    validatorContract,
    gatewayAdmin,
    mainchainTokens,
    thresholds,
    crossbellTokens,
    crossbellTokenDecimals,
} from "./config/polygonMumbai"; // NOTE: update the config before deployment

async function main() {
    // deploy mainchainGateway
    const MainchainGateway = await ethers.getContractFactory("MainchainGateway");
    // always initialize the logic contract
    const mainchainGateway = await MainchainGateway.deploy();
    await mainchainGateway.initialize(
        validatorContract,
        gatewayAdmin,
        withdrawalUnlocker,
        mainchainTokens,
        thresholds,
        crossbellTokens,
        crossbellTokenDecimals
    );

    // deploy proxy
    const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
    const proxyMainchainGateway = await Proxy.deploy(mainchainGateway.address, proxyAdmin, "0x");
    await proxyMainchainGateway.deployed();

    // initialize proxy
    const proxyGateway = await MainchainGateway.attach(proxyMainchainGateway.address);
    await proxyGateway.initialize(
        validatorContract,
        gatewayAdmin,
        withdrawalUnlocker,
        mainchainTokens,
        thresholds,
        crossbellTokens,
        crossbellTokenDecimals
    );

    console.log("mainchainGateway deployed to:", mainchainGateway.address);
    console.log("proxyMainchainGateway deployed to:", proxyMainchainGateway.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
