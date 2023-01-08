# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

all: clean install build foundry-test abi docgen

# Install proper solc version.
solc:; nix-env -f https://github.com/dapphub/dapptools/archive/master.tar.gz -iA solc-static-versions.solc_0_8_10

# Clean the repo
clean  :; forge clean

# Install the Modules
install :; forge install --no-commit

# Update Dependencies
update:; forge update

# Builds
build  :; forge build

bindings: build
	@echo " > \033[32mCreating go bindings for contracts... \033[0m "
	./scripts/create_bindings.sh

# chmod scripts
scripts :; chmod +x ./scripts/*

# Tests
foundry-test :; forge clean && forge test --optimize --optimizer-runs 200 -v # --ffi # enable if you need the `ffi` cheat code on HEVM

# Run solhint
check :; solhint "{contracts,test,scripts}/**/*.sol"

# slither
slither :; slither .

# Lints
lint :; prettier --write "{contracts,test,scripts}/**/*.{sol,ts}"

# Generate Gas Snapshots
snapshot :; forge clean && forge snapshot

# Rename all instances of femplate with the new repo name
rename :; chmod +x ./scripts/* && ./scripts/rename.sh

# export abi
abi :; yarn run hardhat export-abi

# generate docs
docgen :; yarn docgen