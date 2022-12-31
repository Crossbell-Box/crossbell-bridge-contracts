// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../interfaces/IMappedToken.sol";

/**
 * @title GatewayStorage
 * @dev Storage of deposit and withdraw information.
 */
contract MainchainGatewayStorage is IMappedToken {
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

    struct WithdrawalEntry {
        address recipient;
        address token;
        uint256 amount;
    }

    address public _validator;

    uint256 public _depositCount;
    mapping(uint256 => WithdrawalEntry) public _withdrawals;

    address public _admin;

    // @dev Mapping from mainchain token => token address on crossbell network
    mapping(address => MappedToken) internal _crossbellToken;
}
