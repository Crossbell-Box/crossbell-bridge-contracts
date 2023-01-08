#!/usr/bin/env bash
set -x

base_path="./build/bindings"
BIN_DIR="$base_path/bin"
ABI_DIR="$base_path/abi"
GO_DIR="$base_path/go"

rm -rf base_path && mkdir -p ${BIN_DIR} ${ABI_DIR} ${GO_DIR}

# extract abi and bin files
forge inspect Validator abi > ${ABI_DIR}/Validator.abi
forge inspect Validator b > ${BIN_DIR}/Validator.bin
abigen --bin=${BIN_DIR}/Validator.bin --abi=${ABI_DIR}/Validator.abi --pkg=validator --out=${GO_DIR}/validator.go

forge inspect CrossbellGateway abi > ${ABI_DIR}/CrossbellGateway.abi
forge inspect CrossbellGateway b > ${BIN_DIR}/CrossbellGateway.bin
abigen --bin=${BIN_DIR}/CrossbellGateway.bin --abi=${ABI_DIR}/CrossbellGateway.abi --pkg=crossbellGateway --out=${GO_DIR}/crossbellGateway.go

forge inspect MainchainGateway abi > ${ABI_DIR}/MainchainGateway.abi
forge inspect MainchainGateway b > ${BIN_DIR}/MainchainGateway.bin
abigen --bin=${BIN_DIR}/MainchainGateway.bin --abi=${ABI_DIR}/MainchainGateway.abi --pkg=mainchainGateway --out=${GO_DIR}/mainchainGateway.go
