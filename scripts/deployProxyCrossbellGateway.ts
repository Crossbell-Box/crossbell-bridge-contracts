// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    // NOTE: update these addresses before deployment
    const proxyAdmin = "0x0000000000000000000000000000000000000002";
    const validatorContract = "0x0000000000000000000000000000000000000001";
    const gatewayAdmin = "0x0000000000000000000000000000000000000003";
    const crossbellTokens = ["0x0000000000000000000000000000000000000004"];
    const chainIds = [1];
    const mainchainTokens = ["0x0000000000000000000000000000000000000004"];
    const mainchainTokenDecimals = [6];

    // deploy crossbellGateway
    const CrossbellGateway = await ethers.getContractFactory("CrossbellGateway");
    const crossbellGateway = await CrossbellGateway.deploy();
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
