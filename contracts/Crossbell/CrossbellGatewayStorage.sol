// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../interfaces/IMappedToken.sol";

/**
 * @title SidechainGatewayStorage
 * @dev Storage of deposit and withdraw information.
 */
contract CrossbellGatewayStorage is IMappedToken {
    event TokenMapped(
        address[] crossbellTokens,
        uint256[] chainIds,
        address[] mainchainTokens,
        uint8[] crossbellTokensDecimals
    );

    event Deposited(
        uint256 indexed chainId,
        uint256 indexed depositId,
        address indexed recipient,
        address token,
        uint256 amount // ERC-20 amount
    );

    event AckDeposit(
        uint256 indexed chainId,
        uint256 indexed depositId,
        address indexed recipient,
        address token,
        uint256 tokenNumber // ERC-20 amount
    );

    event RequestWithdrawal(
        uint256 indexed chainId,
        uint256 indexed withdrawId,
        address indexed recipient,
        address token,
        uint256 transformedAmount,
        uint256 originalAmount
    );

    event RequestWithdrawalSigAgain(
        uint256 indexed chainId,
        uint256 indexed withdrawalId,
        address indexed owner,
        address token,
        uint256 amount
    );

    struct DepositEntry {
        uint256 chainId;
        address recipient;
        address token;
        uint256 amount;
    }

    struct WithdrawalEntry {
        uint256 chainId;
        address recipient;
        address token;
        uint256 transformedAmount;
        uint256 amount;
    }

    // Acknowledge status, once the acknowledgements reach the threshold the 1st
    // time, it can take effect to the system. E.g. confirm a deposit.
    // Acknowledgments after that should not have any effects.
    enum Status {
        NotApproved,
        FirstApproved,
        AlreadyApproved
    }

    // Final deposit state, update only once when there is enough acknowledgement
    // chainId => depositId => DepositEntry
    mapping(uint256 => mapping(uint256 => DepositEntry)) internal _deposits;

    // chainId => withdrawCount
    mapping(uint256 => uint256) internal _withdrawalCounts;
    // chainId =>  withdrawId =>WithdrawalEntry
    mapping(uint256 => mapping(uint256 => WithdrawalEntry)) internal _withdrawals;
    // chainId => withdrawId  => signature
    mapping(uint256 => mapping(uint256 => mapping(address => bytes))) internal withdrawalSig;
    // chainId => withdrawId => address[]
    mapping(uint256 => mapping(uint256 => address[])) internal _withdrawalSigners;

    // Mapping from token address => chain id => mainchain token address
    mapping(address => mapping(uint256 => MappedToken)) internal _mainchainToken;
    address public _admin;

    address internal _validator;

    // Mapping from chainId => id => validator => data hash
    mapping(uint256 => mapping(uint256 => mapping(address => bytes32))) internal _validatorAck;
    // Mapping from chainId => id => data hash => ack count
    mapping(uint256 => mapping(uint256 => mapping(bytes32 => uint256))) internal _ackCount;
    // Mapping from chainId => id => data hash => ack status
    mapping(uint256 => mapping(uint256 => mapping(bytes32 => Status))) internal _ackStatus;
}
