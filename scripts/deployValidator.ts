// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    // NOTE: update `initial_validators` and `requiredNumber` before deployment
    const [addr] = await ethers.getSigners();
    const address = await addr.getAddress();
    console.log(address);
    const initial_validators = [
        "0x211F1925f0409957927e33bc1a8eA5FB67A37516", // mainchain
        "0x6d4C924Cbe6c3B2349517477Edc4933c3059d5d0", // crossbell
    ];
    const requiredNumber = 2;

    var Validator = await ethers.getContractFactory("Validator");

    const validator = await Validator.deploy(initial_validators, requiredNumber);

    console.log("validator deployed to:", validator.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});


[
    "0x211F1925f0409957927e33bc1a8eA5FB67A37516", // mainchain
    "0x6d4C924Cbe6c3B2349517477Edc4933c3059d5d0"]