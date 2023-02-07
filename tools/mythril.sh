#!/usr/bin/env bash
#set -x

if [ ! -d "contracts" ]; then
	echo "error: script needs to be run from project root './tools/mythril.sh'"
	exit 1
fi

echo '
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "MainchainGateway: "
myth analyze contracts/MainchainGateway.sol --solc-json mythril.config.json --solv 0.8.16 --max-depth 10 --execution-timeout 900  --solver-timeout 900 &&
echo "CrossbellGateway: "
myth analyze contracts/CrossbellGateway.sol --solc-json mythril.config.json --solv 0.8.16 --max-depth 10 --execution-timeout 900  --solver-timeout 900 &&
echo "Validator: "
myth analyze contracts/Validator.sol --solc-json mythril.config.json --solv 0.8.16 --max-depth 10 --execution-timeout 900  --solver-timeout 900 &&
echo "MiraToken: "
myth analyze contracts/token/MiraToken.sol --solc-json mythril.config.json --solv 0.8.16 --max-depth 10 --execution-timeout 900  --solver-timeout 900 &&
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" ' |
docker run --rm -v "$PWD":/project -i --workdir=/project --entrypoint=sh mythril/myth