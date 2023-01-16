// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    const myAddr = "0x678e0E67555E8fC4533c1a9f204e2C1C7C1C9665";
    const proxyAddr = "0x26E8166b41d1c0E89F2a6d97Be8eB8f8c7337384";

    const [addr] = await ethers.getSigners();
    console.log("this is the address:", addr.getAddress);

    const mainchainTokenAddr = "0xB865a7c5E88B052540213E77b43a76dDCEB1893b";
    const erc20 = await (
        await ethers.getContractFactory("MintableERC20")
    ).attach(mainchainTokenAddr);
    const balance = await erc20.balanceOf(myAddr);
    console.log("this is my balance: ", balance);
    await erc20.approve(proxyAddr, balance);

    const MainchainGateway = await ethers.getContractFactory("MainchainGateway");
    const proxyGateway = await MainchainGateway.attach(proxyAddr);
    await proxyGateway.requestDeposit(myAddr, mainchainTokenAddr, balance);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
