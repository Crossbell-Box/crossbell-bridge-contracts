// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../common/Validator.sol";
import "../common/Registry.sol";
import "./Acknowledgement.sol";

/**
 * @title SidechainGatewayStorage
 * @dev Storage of deposit and withdraw information.
 */
contract SidechainGatewayStorage {
    event TokenDeposited(
        uint256 indexed _chainId,
        uint256 indexed depositId,
        address indexed owner,
        uint256 tokenNumber // ERC-20 amount or ERC721 tokenId
    );

    event TokenWithdrew(
        uint256 indexed _chainId,
        uint256 indexed _withdrawId,
        address indexed _owner,
        uint256 _tokenNumber
    );

    event RequestTokenWithdrawalSigAgain(
        uint256 indexed _chainId,
        uint256 indexed _withdrawalId,
        address indexed _owner,
        uint256 _tokenNumber
    );

    struct DepositEntry {
        address owner;
        uint256 tokenNumber;
    }

    struct WithdrawalEntry {
        uint256 chainId;
        address owner;
        uint256 tokenNumber;
    }

    struct PendingWithdrawalInfo {
        uint256[] withdrawalIds;
        uint256 count;
    }

    // Final deposit state, update only once when there is enough acknowledgement
    // chainId => depositId => DepositEntry
    mapping(uint256 => mapping(uint256 => DepositEntry)) public deposits;

    // chainId => withdrawCount
    mapping(uint256 => uint256) public withdrawalCounts;
    // chainId =>  WithdrawalEntry[]
    mapping(uint256 => WithdrawalEntry[]) public withdrawals;
    // chainId => withdrawId => address => signature
    mapping(uint256 => mapping(uint256 => mapping(address => bytes))) public withdrawalSig;
    // chainId => withdrawId => address[]
    mapping(uint256 => mapping(uint256 => address[])) public withdrawalSigners;

    // address => chainId => withdrawIds
    mapping(address => mapping(uint256 => uint256[])) public userWithdrawals;

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
