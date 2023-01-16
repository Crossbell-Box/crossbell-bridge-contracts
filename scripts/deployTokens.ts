// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    const [owner] = await ethers.getSigners();

    // NOTE: update `initial_validators` and `requiredNumber` before deployment
    const name = "USD Coin";
    const symbol = "USDC";
    const decimals = 18;

    const Token = await ethers.getContractFactory("MintableERC20");
    const token = await Token.deploy(name, symbol, decimals);

    console.log("token deployed to:", token.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});