// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    const myAddr = "0x4BCe096F44b90B812420637068dC215C1C3C8B54";
    const proxyAddr = "0x1384CD5f2a66EA3101fcBe71720242Fbbfa5EAf8";
    const mainchainId = 80001;

    const CrossbellGateway = await ethers.getContractFactory("CrossbellGateway");
    const crossbellTokenAddr = "0x9ea19eBFc28908C8422547740d2ccc2a8fF9B17D";

    const erc20 = await (
        await ethers.getContractFactory("MintableERC20")
    ).attach(crossbellTokenAddr);
    const amount = 1 * 10 ** 18;
    const fee = 1 * 10 ** 17;
    await erc20.approve(proxyAddr, 2000000000000000000n);

    const proxyGateway = await CrossbellGateway.attach(proxyAddr);
    await proxyGateway.requestWithdrawal(
        mainchainId,
        myAddr,
        crossbellTokenAddr,
        1000000000000000000n,
        2000000000000000000n
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
