import { ethers } from "hardhat";

export const proxyAdmin = "0xc72cE0090718502f08506c4592F18f13094d4CE3";
export const withdrawalUnlocker = "0xcFdF30fa7F8236879aff3C4d1EE3aC95CBA16D5c";
export const validatorContract = "0x9e1c2f03a4E771D2a5543deEC24C2be58fd9C388";
export const gatewayAdmin = "0x4BCe096F44b90B812420637068dC215C1C3C8B54";
export const mainchainTokens = ["0x9ea19eBFc28908C8422547740d2ccc2a8fF9B17D"];
export const thresholds = [
    [ethers.BigNumber.from("1000000000000000000000")],
    [ethers.BigNumber.from("200000000000000000000000")],
];
export const crossbellTokens = ["0x112351ddcc1Ba7842618aF89Af8274F4652E9246"];
export const crossbellTokenDecimals = [18];
