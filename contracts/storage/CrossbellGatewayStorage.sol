// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../libraries/DataTypes.sol";

/**
 * @title SidechainGatewayStorage
 * @dev Storage of deposit and withdraw information.
 */
abstract contract CrossbellGatewayStorage {
    // slither-disable-start naming-convention
    // https://github.com/crytic/slither/issues/1034 [issue]

    // Final deposit state, update only once when there is enough acknowledgement
    /// @dev Mapping from chainId => depositId => DepositEntry
    mapping(uint256 => mapping(uint256 => DataTypes.DepositEntry)) internal _deposits;

    /// @dev Mapping from chainId => withdrawCount
    mapping(uint256 => uint256) internal _withdrawalCounter;
    /// @dev Mapping from chainId =>  withdrawalId => WithdrawalEntry
    mapping(uint256 => mapping(uint256 => DataTypes.WithdrawalEntry)) internal _withdrawals;
    /// @dev Mapping from chainId => withdrawalId  => signature
    mapping(uint256 => mapping(uint256 => mapping(address => bytes))) internal _withdrawalSig;
    /// @dev Mapping from chainId => withdrawalId => address[]
    mapping(uint256 => mapping(uint256 => address[])) internal _withdrawalSigners;

    /// @dev Mapping from token address => chain id => mainchain token address
    mapping(address => mapping(uint256 => DataTypes.MappedToken)) internal _mainchainTokens;

    address internal _validator;

    /// @dev Mapping from chainId => id => validator => data hash
    mapping(uint256 => mapping(uint256 => mapping(address => bytes32))) internal _validatorAck;
    /// @dev Mapping from chainId => id => data hash => ack count
    mapping(uint256 => mapping(uint256 => mapping(bytes32 => uint256))) internal _ackCount;
    /// @dev Mapping from chainId => id => data hash => ack status
    mapping(uint256 => mapping(uint256 => mapping(bytes32 => DataTypes.Status)))
        internal _ackStatus;

    // slither-disable-end naming-convention
}
