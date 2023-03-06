// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import {
    proxyAdmin,
    validatorContract,
    gatewayAdmin,
    mainchainTokens,
    dailyWithdrawalMaxQuota,
    crossbellTokens,
    crossbellTokenDecimals,
} from "./config/mainnet/polygon"; // NOTE: update the config before deployment

async function main() {
    // deploy mainchainGateway
    const MainchainGateway = await ethers.getContractFactory("MainchainGateway");


    // deploy proxy
    const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
    const proxyMainchainGateway = await Proxy.deploy("0x3fA10439a518059a02863ec1581636882f62995F", proxyAdmin, "0x");
    await proxyMainchainGateway.deployed();

    // initialize proxy
    const proxyGateway = await MainchainGateway.attach(proxyMainchainGateway.address);
    await proxyGateway.initialize(
        validatorContract,
        gatewayAdmin,
        mainchainTokens,
        dailyWithdrawalMaxQuota,
        crossbellTokens,
        crossbellTokenDecimals,
    );

    console.log("proxyMainchainGateway deployed to:", proxyMainchainGateway.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
