// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    // NOTE: update these addresses before deployment
    const [_, addr2] = await ethers.getSigners();
    const proxyAdmin = "0x4fa9e39af9aA188c49a8AaF2984F2943107ca5b5"; // validator contract
    const validatorContract = "0x4fa9e39af9aA188c49a8AaF2984F2943107ca5b5";
    const gatewayAdmin = "0xEA21E4C0d7256a858122B6FA0121D3A8C7f94f4E"; // addr2
    const crossbellTokens = ["0xaBea54cF50F1Cc269B664662AE33cF9B736dC953"];
    const chainIds = [5];
    const mainchainTokens = ["0xBa023BAE41171260821d5bADE769B8E242468B9e"];
    const mainchainTokenDecimals = [6];

    // deploy crossbellGateway
    const CrossbellGateway = await (
        await ethers.getContractFactory("CrossbellGateway")
    ).connect(addr2);
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
    const Proxy = await (
        await ethers.getContractFactory("TransparentUpgradeableProxy")
    ).connect(addr2);
    const proxyCrossbellGateway = await (
        await Proxy.deploy(crossbellGateway.address, proxyAdmin, "0x")
    ).connect(addr2);
    await proxyCrossbellGateway.deployed();

    // initialize proxy
    const proxyGateway = await CrossbellGateway.attach(proxyCrossbellGateway.address).connect(
        addr2
    );
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
