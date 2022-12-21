// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../references/ERC20/ERC20Detailed.sol";
import "../../references/ERC20/ERC20Mintable.sol";

contract CrossbellWETH is ERC20Detailed, ERC20Mintable {
    constructor() public ERC20Detailed("Crossbell Wrapped Ether", "WETH", 18) {}
}
