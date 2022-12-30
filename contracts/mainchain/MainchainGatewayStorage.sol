// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../common/Validator.sol";
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
        address indexed owner,
        address indexed token,
        uint256 amount // ERC-20 amount
    );

    event Withdrew(
        uint256 indexed withdrawId,
        address indexed owner,
        address indexed token,
        uint256 amount
    );

    struct DepositEntry {
        address owner;
        uint256 transformedAmount;
        uint256 originalAmount;
    }

    struct WithdrawalEntry {
        address owner;
        address token;
        uint256 amount;
    }

    Validator public validator;

    uint256 public depositCount;
    mapping(uint256 => WithdrawalEntry) public withdrawals;

    address public admin;

    /// @dev Crossbell network id
    uint256 public crossbellChainId;

    // @dev Mapping from mainchain token => token address on crossbell network
    mapping(address => MappedToken) internal crossbellToken;
}
