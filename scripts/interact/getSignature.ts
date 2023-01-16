var { fromRpcSig } = require("ethereumjs-util");

import { ethers } from "hardhat";

async function main() {
    const proxyAddr = "0x1384CD5f2a66EA3101fcBe71720242Fbbfa5EAf8";

    const CrossbellGateway = await ethers.getContractFactory("CrossbellGateway");
    const proxyGateway = await CrossbellGateway.attach(proxyAddr);

    const chainId = 80001;
    const withdrawalId = 3;
    const [signers, sigs] = await proxyGateway.getWithdrawalSignatures(chainId, withdrawalId);

    console.log("this is the signer 0:");
    console.log(signers[0]);
    console.log("this is the signer 1:");
    console.log(signers[1]);

    console.log("is this the right order?");
    console.log(signers[0] < signers[1]);

    const rsvList: any[] = [];

    for (let i = 0; i < 2; i++) {
        const sig = fromRpcSig(sigs[i]);
        var r = "0x" + sig.r.toString("hex");
        // console.log(r);
        var s = "0x" + sig.s.toString("hex");
        var v = sig.v;
        var vrs = { v: v, r: r, s: s };
        rsvList.push(vrs);
    }
    console.log("hhhhhhh");
    console.log(rsvList);
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
