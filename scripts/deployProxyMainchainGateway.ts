// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    // NOTE: update these addresses before deployment
    const proxyAdmin = "0x96B4f7bAb340E5C9FdeeaA5c0c50c7537201f41f"; // validator contract
    const withdrawalUnlocker = "0x2df7C8956Eb62BBE7B888aDf3C9c6969689F3084";

    const validatorContract = "0x96B4f7bAb340E5C9FdeeaA5c0c50c7537201f41f";
    const gatewayAdmin = "0x2df7C8956Eb62BBE7B888aDf3C9c6969689F3084";
    const mainchainTokens = ["0xBa023BAE41171260821d5bADE769B8E242468B9e"];
    const thresholds = [[1000000000], [1000000000000]];
    const crossbellTokens = ["0xaBea54cF50F1Cc269B664662AE33cF9B736dC953"];
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
