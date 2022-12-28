// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../common/Validator.sol";
import "../common/Registry.sol";
import "./MainchainValidator.sol";

/**
 * @title GatewayStorage
 * @dev Storage of deposit and withdraw information.
 */
contract MainchainBridgeStorage {
    event RequestDeposit(
        uint256 indexed depositId,
        address indexed owner,
        uint256 indexed transformedAmount, // ERC-20 amount
        uint256 originalAmount
    );

    event Withdrew(uint256 indexed withdrawId, address indexed owner, uint256 indexed amount);

    struct DepositEntry {
        address owner;
        uint256 transformedAmount;
        uint256 originalAmount;
    }

    struct WithdrawalEntry {
        address owner;
        uint256 amount;
    }

    Registry public registry;

    uint256 public depositCount;
    mapping(uint256 => WithdrawalEntry) public withdrawals;

    address public admin;
}
