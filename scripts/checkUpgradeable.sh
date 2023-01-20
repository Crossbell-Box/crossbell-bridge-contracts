#!/usr/bin/env bash
set -x

slither-check-upgradeability . MainchainGateway \
--proxy-filename . \
--proxy-name TransparentUpgradeableProxy \
--compile-force-framework 'hardhat'

slither-check-upgradeability . CrossbellGateway \
--proxy-filename . \
--proxy-name TransparentUpgradeableProxy \
--compile-force-framework 'hardhat'