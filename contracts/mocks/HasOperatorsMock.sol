// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../references/HasOperators.sol";

contract HasOperatorsMock is HasOperators {
    uint256 public count;

    function doStuff() public onlyOperator {
        count++;
    }
}
