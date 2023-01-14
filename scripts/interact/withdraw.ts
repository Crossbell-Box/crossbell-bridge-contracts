// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    const myAddr = "0x4BCe096F44b90B812420637068dC215C1C3C8B54";
    const proxyAddr = "0x1384CD5f2a66EA3101fcBe71720242Fbbfa5EAf8";
    const mainchainId = 80001;
    const withdrawalId = 4;

    const mainchainTokenAddr = "0x43ca1e76d31f0138356a4422b294f895418fFca3";


    const MainchainGateway = await ethers.getContractFactory("MainchainGateway");

    const proxyGateway = await MainchainGateway.attach(proxyAddr);

    await proxyGateway.withdraw(mainchainId, withdrawalId, myAddr, mainchainTokenAddr, 
        2, 3, [[28, "0xf4297ca7b26004dd962cffc8b4136388fb66063a2598b93e0a980594ae62cb99","0x256d6ca34beec3287048b3f2957284b51e61d949ed95fc91d604830d4f00c19c"],[27,"0x1fb7dbfcd7f1967c02426dd91b1408c4af5407b75456dacb9ce445688ebded19","0x7a71d765b6f2bf50084a7587658fa91cba7f4a923cb029dd3ed8d74dafc8cf06"]]);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
