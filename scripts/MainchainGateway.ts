// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    const proxyAddr = "0x391A2c28b2Cf920a36f11800636C0532A7a21F58"

    const MainchainGateway = await ethers.getContractFactory("MainchainGateway");

    // initialize proxy
    const proxyGateway = await MainchainGateway.attach(proxyAddr);
    proxyGateway.mapTokens(["0xBa023BAE41171260821d5bADE769B8E242468B9e"],["0xaBea54cF50F1Cc269B664662AE33cF9B736dC953"],[18])

    

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
