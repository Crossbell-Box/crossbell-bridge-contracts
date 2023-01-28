// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract MiraToken is Context, AccessControlEnumerable, ERC20Permit {
    bytes32 public constant BLOCK_ROLE = keccak256("BLOCK_ROLE");

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) ERC20Permit(name_) {
        // Grants `DEFAULT_ADMIN_ROLE` to the account that deploys the contract
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     * Requirements:
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function mint(address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, amount);
    }

    /**
     * @dev Blocks transfer from account `from` who has the `BLOCK_ROLE`.
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
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        super.renounceRole(role, account);
    }
}
