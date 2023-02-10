#!/usr/bin/env bash
set -x

if [ ! -d "contracts" ]; then
	echo "error: script needs to be run from project root './tools/manticore/manticore.sh'"
	exit 1
fi

# flatten
yarn
mkdir -p flattened
forge flatten contracts/Validator.sol -o ./flattened/Validator.sol
forge flatten contracts/MainchainGateway.sol -o ./flattened/MainchainGateway.sol
forge flatten contracts/CrossbellGateway.sol -o ./flattened/CrossbellGateway.sol
forge flatten contracts/token/MiraToken.sol -o ./flattened/MiraToken.sol

# run check
echo '
pip3 install solc-select && solc-select install 0.8.16 && solc-select use 0.8.16 && cd /project &&
pip3 install crytic-compile==0.2.2 &&
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "MiraToken: "
manticore ./flattened/MiraToken.sol --contract=MiraToken --config=tools/manticore/manticore.yaml &&
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" ' |
docker run --rm -v "$PWD":/project -i --ulimit stack=100000000:100000000 --entrypoint=sh  trailofbits/manticore

# KeyError: 'withdraw(uint256,uint256,address,address,uint256,uint256,tuple[])'
# https://github.com/trailofbits/manticore/issues/2560 [KeyError issue]
# manticore ./flattened/MainchainGateway.sol --contract=MainchainGateway --config=tools/manticore/manticore.yaml &&
# manticore ./flattened/CrossbellGateway.sol --contract=CrossbellGateway --config=tools/manticore/manticore.yaml &&
# manticore ./flattened/Validator.sol --contract=Validator --config=tools/manticore/manticore.yaml