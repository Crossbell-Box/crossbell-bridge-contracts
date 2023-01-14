// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../libraries/DataTypes.sol";

/**
 * @title GatewayStorage
 * @dev Storage of deposit and withdraw information.
 */
abstract contract MainchainGatewayStorage {
    /// @dev Domain seperator
    bytes32 internal _domainSeparator;

    /// @dev Validator contract address
    address internal _validator;

    /// @dev Total deposit count
    uint256 internal _depositCounter;

    /// @dev Mapping from withdrawal id => withdrawal hash
    mapping(uint256 => bytes32) internal _withdrawalHash;

    /// for withdrawal restriction
    /// @dev Mapping from mainchain token => daily max amount for withdrawal
    mapping(address => uint256) internal _dailyWithdrawalMaxQuota;
    /// @dev Mapping from token address => today withdrawal amount
    mapping(address => uint256) internal _lastSyncedWithdrawal;
    /// @dev Mapping from token address => last date synced to record the `_lastSyncedWithdrawal`
    mapping(address => uint256) internal _lastDateSynced;

    // @dev Mapping from mainchain token => token address on crossbell network
    mapping(address => DataTypes.MappedToken) internal _crossbellTokens;
}
