// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    // NOTE: update these addresses before deployment
    const proxyAdmin = "0x0000000000000000000000000000000000000001";
    const withdrawalUnlocker = "0x0000000000000000000000000000000000000002";

    const validatorContract = "0x0000000000000000000000000000000000000001";
    const gatewayAdmin = "0x0000000000000000000000000000000000000003";
    const mainchainTokens = ["0x0000000000000000000000000000000000000004"];
    const thresholds = [[1000000000], [1000000000000]];
    const crossbellTokens = ["0x0000000000000000000000000000000000000004"];
    const crossbellTokenDecimals = [18];

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
