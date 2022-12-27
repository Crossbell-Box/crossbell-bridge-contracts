// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../common/Validator.sol";
import "../common/Registry.sol";
import "./MainchainValidator.sol";

/**
 * @title GatewayStorage
 * @dev Storage of deposit and withdraw information.
 */
contract MainchainGatewayStorage {
    event TokenDeposited(
        uint256 indexed _depositId,
        address indexed _owner,
        uint256 indexed _tokenNumber // ERC-20 amount
    );

    event TokenWithdrew(
        uint256 indexed _withdrawId,
        address indexed _owner,
        uint256 indexed _tokenNumber
    );

    struct DepositEntry {
        address owner;
        uint256 tokenNumber;
    }

    struct WithdrawalEntry {
        address owner;
        uint256 tokenNumber;
    }

    Registry public registry;

    uint256 public depositCount;
    DepositEntry[] public deposits;
    mapping(uint256 => WithdrawalEntry) public withdrawals;

    address public admin;
}
