#!/usr/bin/env bash
set -x

if [ ! -d "contracts" ]; then
	echo "error: script needs to be run from project root './tools/mythril.sh'"
	exit 1
fi

docker run --rm -v "$PWD":/project -it --workdir=/project --entrypoint=sh mythril/myth -c '
myth analyze contracts/MainchainGateway.sol --solc-json mythril.config.json --max-depth 10 --execution-timeout 900  --solver-timeout 900 &&
myth analyze contracts/CrossbellGateway.sol --solc-json mythril.config.json --max-depth 10 --execution-timeout 900  --solver-timeout 900 &&
myth analyze contracts/Validator.sol --solc-json mythril.config.json --max-depth 10 --execution-timeout 900  --solver-timeout 900 '