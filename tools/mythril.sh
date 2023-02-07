#!/usr/bin/env bash
set -x

if [ ! -d "contracts" ]; then
	echo "error: script needs to be run from project root './tools/mythril.sh'"
	exit 1
fi

echo '
myth analyze contracts/MainchainGateway.sol --solc-json mythril.config.json --max-depth 10 --execution-timeout 900  --solver-timeout 900 &&
myth analyze contracts/CrossbellGateway.sol --solc-json mythril.config.json --max-depth 10 --execution-timeout 900  --solver-timeout 900 &&
myth analyze contracts/Validator.sol --solc-json mythril.config.json --max-depth 10 --execution-timeout 900  --solver-timeout 900 ' |
docker run --rm -v "$PWD":/project -i --workdir=/project --entrypoint=sh mythril/myth