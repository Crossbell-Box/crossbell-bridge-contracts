// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IERC20Mintable {
    function mint(address _to, uint256 _value) external returns (bool _success);
}
