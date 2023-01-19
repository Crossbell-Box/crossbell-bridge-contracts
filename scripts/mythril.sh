#!/usr/bin/env bash
set -x

myth analyze contracts/MainchainGateway.sol --solc-json mythril.config.json
myth analyze contracts/CrossbellGateway.sol --solc-json mythril.config.json
myth analyze contracts/Validator.sol --solc-json mythril.config.json
myth analyze contracts/token/MiraToken.sol --solc-json mythril.config.json