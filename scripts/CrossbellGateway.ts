// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    const proxyAddr = "0x33ABbE79e0f79c7c7430864eB21e87d1004a2D1D"

    const CrossbellGateway = await ethers.getContractFactory("CrossbellGateway");
    const crossbellTokenAddr = "0xaBea54cF50F1Cc269B664662AE33cF9B736dC953";
    const mainchainTokenAddr = "0xBa023BAE41171260821d5bADE769B8E242468B9e";

    const [_, addr2] = await ethers.getSigners();
    
    // transfer ownership of token contract to proxyAdmin
    const proxyCrossbellGatewayAddr = "0x33ABbE79e0f79c7c7430864eB21e87d1004a2D1D";
    const token = await (await ethers.getContractFactory("MintableERC20")).attach(crossbellTokenAddr).connect(addr2);
    token.transferOwnership(proxyCrossbellGatewayAddr);

    // initialize proxy
    var proxyGateway = await CrossbellGateway.attach(proxyAddr);

    proxyGateway = proxyGateway.connect(addr2)
    proxyGateway.mapTokens([crossbellTokenAddr], [5], [mainchainTokenAddr],[18])

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
