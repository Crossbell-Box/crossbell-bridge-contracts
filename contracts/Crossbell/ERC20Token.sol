// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract CrossbellERC20 is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("Crossbell ERC20", "ERC20") {}
}
