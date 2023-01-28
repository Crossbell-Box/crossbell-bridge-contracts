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
build :; forge build

# Build with hardhat
hardhat-build :; npx hardhat clean && npx hardhat compile

bindings: build
	@echo " > \033[32mCreating go bindings for contracts... \033[0m "
	./scripts/createBindings.sh

# chmod scripts
scripts :; chmod +x ./scripts/*

# Tests
# --ffi # enable if you need the `ffi` cheat code on HEVM
foundry-test :; forge clean && forge test --optimize --optimizer-runs 200 -v

# Run solhint
check :; solhint "{contracts,test,scripts}/**/*.sol"

# slither
# to install slither, visit [https://github.com/crytic/slither]
slither :; slither .

# mythril
mythril :
	@echo " > \033[32mChecking contracts with mythril...\033[0m"
	./scripts/mythril.sh

# upgradeable check
upgradeable:
	@echo " > \033[32mChecking upgradeable...\033[0m"
	./scripts/checkUpgradeable.sh

# check erc20 token
check-mira :; slither-check-erc . MiraToken

# Lints
lint :; prettier --write "{contracts,test,scripts}/**/*.{sol,ts}"

# Generate Gas Snapshots
snapshot :; forge clean && forge snapshot

# export abi
abi :; yarn run hardhat export-abi

# generate docs
docgen :; yarn docgen