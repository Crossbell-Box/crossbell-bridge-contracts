// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MiraToken is Context, AccessControlEnumerable, ERC20 {
    bytes32 public constant BLOCK_ROLE = keccak256("BLOCK_ROLE");

    uint8 internal _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        // Grant `DEFAULT_ADMIN_ROLE` to the account that deploys the contract
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Create `amount` new tokens for `to`.
     * Requirements:
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function mint(address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, amount);
    }

    /**
     * @dev Block transfers from account `from` who has the `BLOCK_ROLE`.
     */
    function _transfer(address from, address to, uint256 amount) internal override {
        require(!hasRole(BLOCK_ROLE, from), "transfer is blocked");
        super._transfer(from, to, amount);
    }
}
