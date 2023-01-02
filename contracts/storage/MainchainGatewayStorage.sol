// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../libraries/DataTypes.sol";

/**
 * @title GatewayStorage
 * @dev Storage of deposit and withdraw information.
 */
abstract contract MainchainGatewayStorage {
    event TokenMapped(
        address[] mainchainTokens,
        address[] crossbellTokens,
        uint8[] crossbellTokensDecimals
    );

    event RequestDeposit(
        uint256 indexed depositId,
        address indexed recipient,
        address indexed token,
        uint256 amount // ERC-20 amount
    );

    event Withdrew(
        uint256 indexed withdrawId,
        address indexed recipient,
        address indexed token,
        uint256 amount
    );

    struct DepositEntry {
        address recipient;
        uint256 transformedAmount;
        uint256 originalAmount;
    }

    address public _validator;

    uint256 public _depositCount;
    address public _admin;
    mapping(uint256 => bytes32) public _withdrawalHash;

    // @dev Mapping from mainchain token => token address on crossbell network
    mapping(address => DataTypes.MappedToken) internal _crossbellToken;
}
