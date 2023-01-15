// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../libraries/DataTypes.sol";

interface ICrossbellGateway {
    /**
     * @dev Emitted when the tokens are mapped.
     * @param crossbellTokens Addresses of crossbell tokens.
     * @param chainIds The chain IDs of mainchain networks.
     * @param mainchainTokens Addresses of mainchain tokens.
     * @param mainchainTokenDecimals Decimals of mainchain tokens.
     */
    event TokenMapped(
        address[] crossbellTokens,
        uint256[] chainIds,
        address[] mainchainTokens,
        uint8[] mainchainTokenDecimals
    );

    /**
     * @dev Emitted when the assets are deposited.
     * @param chainId The chain ID of mainchain network.
     * @param depositId Deposit identifier id.
     * @param recipient The address of account to receive the deposit.
     * @param token The address of token to deposit.
     * @param amount The amount of token to deposit.
     */
    event Deposited(
        uint256 indexed chainId,
        uint256 indexed depositId,
        address indexed recipient,
        address token,
        uint256 amount
    );

    /**
     * @dev Emitted when the deposit is acknowledged by a validator.
     * @param chainId The ChainId of mainchain network.
     * @param depositId Deposit identifier id.
     * @param recipient The address of account to receive the deposit.
     * @param token The address of token to deposit.
     * @param amount The amount of token to deposit.
     */
    event AckDeposit(
        uint256 indexed chainId,
        uint256 indexed depositId,
        address indexed recipient,
        address token,
        uint256 amount
    );

    /**
     * @dev Emitted when the withdrawal is requested.
     * @param chainId The ChainId of mainchain network.
     * @param withdrawalId Withdrawal identifier id.
     * @param recipient The address of account to receive the withdrawal.
     * @param token The address of token to withdraw on mainchain network.
     * @param amount The amount of token to withdraw on mainchain network.
     * Note that validator should use this `amount' for submitting signature.
     * @param fee The fee amount to pay for the withdrawal tx sender on mainchain network.
     */
    event RequestWithdrawal(
        uint256 indexed chainId,
        uint256 indexed withdrawalId,
        address indexed recipient,
        address token,
        uint256 amount,
        uint256 fee
    );

    /**
     * @dev Emitted when a withdrawal signature is submitted by validator.
     * @param chainId The ChainId of mainchain network.
     * @param withdrawalId Withdrawal identifier id.
     * @param validator The address of validator who submitted the signature.
     * @param signature The submitted signature.
     */
    event SubmitWithdrawalSignature(
        uint256 indexed chainId,
        uint256 indexed withdrawalId,
        address indexed validator,
        bytes signature
    );

    /**
     * @notice Initializes the CrossbellGateway.
     * @param validator Address of validator contract.
     * @param admin Address of gateway admin.
     * @param crossbellTokens Addresses of crossbell tokens.
     * @param chainIds The chain IDs of mainchain networks.
     * @param mainchainTokens Addresses of mainchain tokens.
     * @param mainchainTokenDecimals Decimals of mainchain tokens.
     */
    function initialize(
        address validator,
        address admin,
        address[] calldata crossbellTokens,
        uint256[] calldata chainIds,
        address[] calldata mainchainTokens,
        uint8[] calldata mainchainTokenDecimals
    ) external;

    /**
     * @notice Pauses interaction with the gateway contract
     */
    function pause() external;

    /**
     * @notice Resumes interaction with the gateway contract
     */
    function unpause() external;

    /**
     * @notice Maps mainchain tokens to Crossbell network.
     * @param crossbellTokens Addresses of crossbell tokens.
     * @param chainIds The chain IDs of mainchain networks.
     * @param mainchainTokens Addresses of mainchain tokens.
     * @param mainchainTokenDecimals Decimals of mainchain tokens.
     */
    function mapTokens(
        address[] calldata crossbellTokens,
        uint256[] calldata chainIds,
        address[] calldata mainchainTokens,
        uint8[] calldata mainchainTokenDecimals
    ) external;

    /**
     * @notice Tries bulk deposit.
     */
    function batchAckDeposit(
        uint256[] calldata chainIds,
        uint256[] calldata depositIds,
        address[] calldata recipients,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Tries bulk submit withdrawal signatures.
     * Note that the caller must be a validator.
     */
    function batchSubmitWithdrawalSignatures(
        uint256[] calldata chainIds,
        uint256[] calldata withdrawalIds,
        bytes[] calldata sigs
    ) external;

    /**
     * @notice Acknowledges a deposit.
     * Note that the caller must be a validator.
     * @param chainId The chain ID of mainchain network.
     * @param depositId Deposit identifier id.
     * @param recipient Address to receive deposit on crossbell network.
     * @param token Token address to deposit on crossbell network.
     * @param amount Token amount to deposit on crossbell network.
     */
    function ackDeposit(
        uint256 chainId,
        uint256 depositId,
        address recipient,
        address token,
        uint256 amount
    ) external;

    /**
     * @notice Locks the assets and request withdrawal.
     * @param chainId The chain ID of mainchain network.
     * @param recipient Address to receive withdrawal on mainchain network.
     * @param token Token address to lock from crossbell network.
     * @param amount Token amount to lock from crossbell network.
     * @param fee Fee amount to pay. This is subtracted from the `amount`.
     * @return withdrawalId The newly generated withdrawalId.
     */
    function requestWithdrawal(
        uint256 chainId,
        address recipient,
        address token,
        uint256 amount,
        uint256 fee
    ) external returns (uint256 withdrawalId);

    /**
     * @notice Submits validator signature for withdrawal.
     * Note that the caller must be a validator.
     * @param chainId The chain ID of mainchain network.
     * @param withdrawalId WithdrawalId.
     * @param sig Validator signature for the withdrawal.
     */
    function submitWithdrawalSignature(
        uint256 chainId,
        uint256 withdrawalId,
        bytes calldata sig
    ) external;

    /**
     * @notice Returns mapped token on mainchain.
     * @param chainId The chain ID of mainchain network.
     * @param crossbellToken Token address on crossbell.
     * @return token Mapped token on mainchain chain.
     */
    function getMainchainToken(
        uint256 chainId,
        address crossbellToken
    ) external view returns (DataTypes.MappedToken memory token);

    /**
     * @notice Returns the acknowledge depositHash by validator.
     * @param chainId The chain ID of mainchain network.
     * @param id DepositId.
     * @param validator Validator address.
     * @return bytes32 depositHash if validator has acknowledged, otherwise 0.
     */
    function getValidatorAcknowledgementHash(
        uint256 chainId,
        uint256 id,
        address validator
    ) external view returns (bytes32);

    /**
     * @notice Returns the acknowledge status of deposit by validators.
     * @param chainId The chain ID of mainchain network.
     * @param id DepositId.
     * @param hash depositHash.
     * @return DataTypes.Status Acknowledgement status.
     */
    function getAcknowledgementStatus(
        uint256 chainId,
        uint256 id,
        bytes32 hash
    ) external view returns (DataTypes.Status);

    /**
     * @notice Returns the acknowledge count of deposit by validators.
     * @param chainId The chain ID of mainchain network.
     * @param id DepositId.
     * @param hash depositHash.
     * @return uint256 Acknowledgement count.
     */
    function getAcknowledgementCount(
        uint256 chainId,
        uint256 id,
        bytes32 hash
    ) external view returns (uint256);

    /**
     * @notice Returns withdrawal signatures.
     * @param chainId The chain ID of mainchain network.
     * @param withdrawalId Withdrawal Id to query.
     * @return signers Signer addresses.
     * @return sigs Signer signatures.
     */
    function getWithdrawalSignatures(
        uint256 chainId,
        uint256 withdrawalId
    ) external view returns (address[] memory signers, bytes[] memory sigs);

    /**
     * @notice Returns the address of the validator contract.
     * @return The validator contract address.
     */
    function getValidatorContract() external view returns (address);

    /**
     * @notice Returns the deposit entry.
     * @param chainId The chain ID of mainchain network.
     * @param depositId Deposit Id to query.
     * @return DataTypes.DepositEntry Deposit entry.
     */
    function getDepositEntry(
        uint256 chainId,
        uint256 depositId
    ) external view returns (DataTypes.DepositEntry memory);

    /**
     * @notice Returns the withdrawal count of different mainchain networks.
     * @param chainId The chain ID of mainchain network.
     * @return Withdrawal count.
     */
    function getWithdrawalCount(uint256 chainId) external view returns (uint256);

    /**
     * @notice Returns the withdrawal entry.
     * @param chainId The chain ID of mainchain network.
     * @param withdrawalId Withdrawal Id to query.
     * @return DataTypes.WithdrawalEntry Withdrawal entry.
     */
    function getWithdrawalEntry(
        uint256 chainId,
        uint256 withdrawalId
    ) external view returns (DataTypes.WithdrawalEntry memory);
}
