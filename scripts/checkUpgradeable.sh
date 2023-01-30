#!/usr/bin/env bash
#set -x

# create tmp files
file1=$(mktemp /tmp/crossbell-bridge-slither-check.XXXXX) || exit 1
file2=$(mktemp /tmp/crossbell-bridge-slither-check.XXXXX) || exit 1

# slither-check
echo "MainchainGateway: " >"$file1"
slither-check-upgradeability . MainchainGateway \
--proxy-filename . \
--proxy-name TransparentUpgradeableProxy \
--compile-force-framework 'hardhat' \
--exclude "initialize-target" \
2>>"$file1" 1>&2

echo "CrossbellGateway: " >"$file2"
slither-check-upgradeability . CrossbellGateway \
--proxy-filename . \
--proxy-name TransparentUpgradeableProxy \
--compile-force-framework 'hardhat' \
--exclude "initialize-target" \
2>>"$file2" 1>&2

# output
lines1=$(sed -n '$=' "$file1")
lines2=$(sed -n '$=' "$file2")
# if the check fails, there will be 2+ lines in the files
if [ "$lines1" -gt 2 ] || [ "$lines2" -gt 2 ]
then
  echo "upgradeable check failed"
  cat "$file1"
  cat "$file2"
  exit 2
fi
