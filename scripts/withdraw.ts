// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the scripts in a standalone fashion through `node <scripts>`.
//
// When running the scripts with `npx hardhat run <scripts>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import {
    proxyAdmin,
    validatorContract,
    gatewayAdmin,
    crossbellTokens,
    chainIds,
    mainchainTokens,
    mainchainTokenDecimals,
    proxyGatewayAddr,
} from "./config/testnet/sepolia"; // NOTE: update the config before deployment
var { fromRpcSig } = require("ethereumjs-util");

async function main() {
    const mainchainId = chainIds[0]; // goerli chainId

    const CrossbellGateway = await ethers.getContractFactory("CrossbellGateway");
    const proxyGateway = await CrossbellGateway.attach(proxyGatewayAddr);
    const withdrawalId = (await proxyGateway.getWithdrawalCount(mainchainId)) - 1; // get the latest withdrawal request id
    const [chainId, recipient, token, amount, fee] = await proxyGateway.getWithdrawalEntry(
        mainchainId,
        withdrawalId
    );
    const [signers, signs] = await proxyGateway.getWithdrawalSignatures(chainId, withdrawalId);
    console.log(signers, signs);

    if (signs.length == 3) {
        console.log("ok there's enough signatures, starting withdraw....");
        const rsvList: any[] = [];
        type rsv = [any, any, any];
        type rsvList = rsv[];
        for (let i = 0; i < 3; i++) {
            const sig = fromRpcSig(signs[i]);
            var r = "0x" + sig.r.toString("hex");
            var s = "0x" + sig.s.toString("hex");
            var v = sig.v;
            var rsv = [v, r, s];
            rsvList.push(rsv);
        }
        await proxyGateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, rsvList);
    } else {
        console.log(":(  Not enough signs...");
    }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});