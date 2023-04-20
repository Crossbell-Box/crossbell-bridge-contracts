// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import { proxyAdmin } from "./config/mainnet/polygon";

async function main() {
    // deploy mainchainGateway
    const MainchainGateway = await ethers.getContractFactory("MainchainGateway");
    const mainchainGateway = await MainchainGateway.deploy();

    console.log("mainchainGateway deployed to:", mainchainGateway.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
