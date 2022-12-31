// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../common/Validator.sol";
import "./Acknowledgement.sol";
import "../interfaces/IMappedToken.sol";

/**
 * @title SidechainGatewayStorage
 * @dev Storage of deposit and withdraw information.
 */
contract CrossbellGatewayStorage is IMappedToken {
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

    // Final deposit state, update only once when there is enough acknowledgement
    // chainId => depositId => DepositEntry
    mapping(uint256 => mapping(uint256 => DepositEntry)) public _deposits;

    // chainId => withdrawCount
    mapping(uint256 => uint256) public _withdrawalCounts;
    // chainId =>  withdrawId =>WithdrawalEntry
    mapping(uint256 => mapping(uint256 => WithdrawalEntry)) public _withdrawals;
    // chainId => withdrawId  => signature
    mapping(uint256 => mapping(uint256 => mapping(address => bytes))) public withdrawalSig;
    // chainId => withdrawId => address[]
    mapping(uint256 => mapping(uint256 => address[])) public _withdrawalSigners;

    // Mapping from token address => chain id => mainchain token address
    mapping(address => mapping(uint256 => MappedToken)) internal _mainchainToken;
    address public _admin;

    Validator public _validator;
    Acknowledgement public _acknowledgement;
}
