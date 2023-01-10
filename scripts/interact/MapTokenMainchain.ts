// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    const proxyAddr = "0x1384CD5f2a66EA3101fcBe71720242Fbbfa5EAf8";

    const MainchainGateway = await ethers.getContractFactory("MainchainGateway");

    const proxyGateway = await MainchainGateway.attach(proxyAddr);
    proxyGateway.mapTokens(
        ["0x43ca1e76d31f0138356a4422b294f895418fFca3"],
        ["0x112351ddcc1Ba7842618aF89Af8274F4652E9246"],
        [18]
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
