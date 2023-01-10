// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    // NOTE: update these addresses before deployment
    const proxyAdmin = "0x889Bc6a2b4234d68B95Af60FE9e490C50879FE08"; // validator contract
    const withdrawalUnlocker = "0x2df7C8956Eb62BBE7B888aDf3C9c6969689F3084";

    const validatorContract = "0x889Bc6a2b4234d68B95Af60FE9e490C50879FE08";
    const gatewayAdmin = "0x2df7C8956Eb62BBE7B888aDf3C9c6969689F3084";
    const mainchainTokens = ["0x8C533B1B98Deb449d100687140a8446c51Ee81a1"];
    const thresholds = [[1000000000], [1000000000000]];
    const crossbellTokens = ["0x8a9C9688574081898DF981Bdde4F1Fd9EF44E2AC"];
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
