// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    const [_, addr2] = await ethers.getSigners();

    // NOTE: update `initial_validators` and `requiredNumber` before deployment
    const initial_validators = [
        "0x2df7C8956Eb62BBE7B888aDf3C9c6969689F3084", // mainchain
        "0xEA21E4C0d7256a858122B6FA0121D3A8C7f94f4E", // crossbell
    ];
    const requiredNumber = 1;

    var Validator = await (await ethers.getContractFactory("Validator")).connect(addr2);

    const validator = await Validator.deploy(initial_validators, requiredNumber);

    console.log("validator deployed to:", validator.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
