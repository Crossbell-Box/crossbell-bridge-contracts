// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    const myAddr = "0x678e0E67555E8fC4533c1a9f204e2C1C7C1C9665";
    const proxyAddr = "0x1384CD5f2a66EA3101fcBe71720242Fbbfa5EAf8";

    const mainchainTokenAddr = "0x462074b85c3bD27721FaF01be6600D5d7Bf49A7c";
    const erc20 = await (
        await ethers.getContractFactory("MintableERC20")
    ).attach(mainchainTokenAddr);
    await erc20.approve(proxyAddr, 6000000n);

    const MainchainGateway = await ethers.getContractFactory("MainchainGateway");

    const proxyGateway = await MainchainGateway.attach(proxyAddr);

    await proxyGateway.requestDeposit(myAddr, mainchainTokenAddr, 6000000n);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
