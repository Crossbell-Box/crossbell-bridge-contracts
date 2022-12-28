// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../common/Validator.sol";
import "../common/Registry.sol";
import "./Acknowledgement.sol";

/**
 * @title SidechainGatewayStorage
 * @dev Storage of deposit and withdraw information.
 */
contract SidechainBridgeStorage {
    event Deposited(
        uint256 indexed chainId,
        uint256 indexed depositId,
        address indexed owner,
        uint256 tokenNumber // ERC-20 amount
    );

    event AckDeposit(
        uint256 indexed chainId,
        uint256 indexed depositId,
        address indexed owner,
        uint256 tokenNumber // ERC-20 amount
    );

    event RequestWithdrawal(
        uint256 indexed chainId,
        uint256 indexed withdrawId,
        address indexed owner,
        uint256 transformedAmount,
        uint256 originalAmount
    );

    event RequestTokenWithdrawalSigAgain(
        uint256 indexed _chainId,
        uint256 indexed _withdrawalId,
        address indexed _owner,
        uint256 _tokenNumber
    );

    struct DepositEntry {
        uint256 chainId;
        address owner;
        uint256 tokenNumber;
    }

    struct WithdrawalEntry {
        uint256 chainId;
        address owner;
        uint256 transformedAmount;
        uint256 tokenNumber;
    }

    // Final deposit state, update only once when there is enough acknowledgement
    // chainId => depositId => DepositEntry
    mapping(uint256 => mapping(uint256 => DepositEntry)) public deposits;

    // chainId => withdrawCount
    mapping(uint256 => uint256) public withdrawalCounts;
    // chainId =>  withdrawId =>WithdrawalEntry
    mapping(uint256 => mapping(uint256 => WithdrawalEntry)) public withdrawals;
    // chainId => withdrawId  => signature
    mapping(uint256 => mapping(uint256 => mapping(address => bytes))) public withdrawalSig;
    // chainId => withdrawId => address[]
    mapping(uint256 => mapping(uint256 => address[])) public withdrawalSigners;

    address public admin;
    Registry public registry;

    mapping(uint256 => bool) public activeChainIds;

    function _getValidator() internal view returns (Validator) {
        return Validator(registry.getContract(registry.VALIDATOR()));
    }

    function _getAcknowledgementContract() internal view returns (Acknowledgement) {
        return Acknowledgement(registry.getContract(registry.ACKNOWLEDGEMENT()));
    }

    function _getDepositAckChannel() internal view returns (string memory) {
        return _getAcknowledgementContract().DEPOSIT_CHANNEL();
    }

    function _getWithdrawalAckChannel() internal view returns (string memory) {
        return _getAcknowledgementContract().WITHDRAWAL_CHANNEL();
    }
}
