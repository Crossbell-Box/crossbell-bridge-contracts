// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../libraries/DataTypes.sol";

/**
 * @title GatewayStorage
 * @dev Storage of deposit and withdraw information.
 */
abstract contract MainchainGatewayStorage {
    /// @dev Validator contract address
    address internal _validator;

    /// @dev Total deposit
    uint256 internal _depositCount;

    /// @dev Mapping from withdrawal id => withdrawal hash
    mapping(uint256 => bytes32) internal _withdrawalHash;
    /// @dev Mapping from withdrawal id => locked
    mapping(uint256 => bool) public _withdrawalLocked;
    /// @dev Mapping from mainchain token => the amount thresholds to lock withdrawal
    mapping(address => uint256) public _lockedThreshold;

    // @dev Mapping from mainchain token => token address on crossbell network
    mapping(address => DataTypes.MappedToken) internal _crossbellToken;
}
