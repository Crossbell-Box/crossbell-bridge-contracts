// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../libraries/DataTypes.sol";

/**
 * @title SidechainGatewayStorage
 * @dev Storage of deposit and withdraw information.
 */
abstract contract CrossbellGatewayStorage {
    // Final deposit state, update only once when there is enough acknowledgement
    // chainId => depositId => DepositEntry
    mapping(uint256 => mapping(uint256 => DataTypes.DepositEntry)) internal _deposits;

    // chainId => withdrawCount
    mapping(uint256 => uint256) internal _withdrawalCounts;
    // chainId =>  withdrawId =>WithdrawalEntry
    mapping(uint256 => mapping(uint256 => DataTypes.WithdrawalEntry)) internal _withdrawals;
    // chainId => withdrawId  => signature
    mapping(uint256 => mapping(uint256 => mapping(address => bytes))) internal _withdrawalSig;
    // chainId => withdrawId => address[]
    mapping(uint256 => mapping(uint256 => address[])) internal _withdrawalSigners;

    // Mapping from token address => chain id => mainchain token address
    mapping(address => mapping(uint256 => DataTypes.MappedToken)) internal _mainchainToken;

    address internal _admin;
    address internal _validator;

    // Mapping from chainId => id => validator => data hash
    mapping(uint256 => mapping(uint256 => mapping(address => bytes32))) internal _validatorAck;
    // Mapping from chainId => id => data hash => ack count
    mapping(uint256 => mapping(uint256 => mapping(bytes32 => uint256))) internal _ackCount;
    // Mapping from chainId => id => data hash => ack status
    mapping(uint256 => mapping(uint256 => mapping(bytes32 => DataTypes.Status)))
        internal _ackStatus;
}
