// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MiraToken is Context, AccessControlEnumerable, ERC20 {
    bytes32 public constant BLOCK_ROLE = keccak256("BLOCK_ROLE");

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        // Grant `DEFAULT_ADMIN_ROLE` to the account that deploys the contract
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
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

    /**
     * @dev Revokes `role` from the calling account.
     * Requirements:
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function renounceRole(
        bytes32 role,
        address account
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }
}
