// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    const proxyAddr = "0xc0ED7Aa61B21468a8a1468D85CF52096664fecf8";

    const CrossbellGateway = await ethers.getContractFactory("CrossbellGateway");
    const crossbellTokenAddr = "0x112351ddcc1Ba7842618aF89Af8274F4652E9246";
    const mainchainTokenAddr = "0x43ca1e76d31f0138356a4422b294f895418fFca3";

    const proxyGateway = await CrossbellGateway.attach(proxyAddr);
    proxyGateway.mapTokens([crossbellTokenAddr], [80001], [mainchainTokenAddr], [6]);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
