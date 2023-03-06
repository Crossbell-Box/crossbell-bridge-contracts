// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    const [owner] = await ethers.getSigners();

    // NOTE: update `initial_validators` and `requiredNumber` before deployment
    const name = "Mira Token";
    const symbol = "MIRA";
    const admin = "0x0f32b88f13Bd98D047411744fEa49a19598e669B";

    const Token = await ethers.getContractFactory("MiraToken");
    const token = await Token.deploy(name, symbol, admin);

    console.log("token deployed to:", token.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
