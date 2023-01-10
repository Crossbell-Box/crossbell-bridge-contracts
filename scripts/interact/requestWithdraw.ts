// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    const myAddr = "0x4BCe096F44b90B812420637068dC215C1C3C8B54";
    const proxyAddr = "0xc0ED7Aa61B21468a8a1468D85CF52096664fecf8";
    const mainchainId = 80001;

    const CrossbellGateway = await ethers.getContractFactory("CrossbellGateway");
    const crossbellTokenAddr = "0x112351ddcc1Ba7842618aF89Af8274F4652E9246";

    const erc20 = await (
        await ethers.getContractFactory("MintableERC20")
    ).attach(crossbellTokenAddr);
    const amount = 10 * 10 ** 18;
    // erc20.approve(proxyAddr, BigInt(amount));

    const proxyGateway = await CrossbellGateway.attach(proxyAddr);
    proxyGateway.requestWithdrawal(mainchainId, myAddr, crossbellTokenAddr, 1, 0);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
