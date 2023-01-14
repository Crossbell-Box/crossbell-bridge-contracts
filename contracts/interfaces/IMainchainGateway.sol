// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../libraries/DataTypes.sol";

interface IMainchainGateway {
    /**
     * @dev Emitted when the tokens are mapped
     * @param mainchainTokens Addresses of mainchain tokens.
     * @param crossbellTokens Addresses of crossbell tokens.
     * @param crossbellTokenDecimals Decimals of crossbell tokens.
     */
    event TokenMapped(
        address[] mainchainTokens,
        address[] crossbellTokens,
        uint8[] crossbellTokenDecimals
    );

    /**
     * @dev Emitted when the deposit is requested
     * @param chainId The chain ID of mainchain network
     * @param depositId Deposit id
     * @param recipient Address to receive deposit on crossbell network
     * @param token Address of token to deposit on crossbell network
     * @param amount Amount of token to deposit on crossbell network
     */
    event RequestDeposit(
        uint256 indexed chainId,
        uint256 indexed depositId,
        address indexed recipient,
        address token,
        uint256 amount
    );

    /**
     * @dev Emitted when the assets are withdrawn on mainchain
     * @param chainId The chain ID of mainchain network
     * @param withdrawalId Withdrawal ID from crossbell chain
     * @param recipient Address to receive withdrawal on mainchain chain
     * @param token Address of token to withdraw
     * @param amount Amount of token to withdraw
     * @param fee The fee amount to pay for the withdrawal tx sender. This is subtracted from the `amount`
     */
    event Withdrew(
        uint256 indexed chainId,
        uint256 indexed withdrawalId,
        address indexed recipient,
        address token,
        uint256 amount,
        uint256 fee
    );

    /// @dev Emitted when the daily quota thresholds are updated
    event DailyWithdrawalMaxQuotasUpdated(address[] tokens, uint256[] quotas);

    /**
     * @notice Returns the domain separator for this contract.
     * @return bytes32 The domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);

    /**
     * @notice Initializes the MainchainGateway.
     * Note that the thresholds contains:
     *  - thresholds[1]:
     * @param validator Address of validator contract.
     * @param admin Address of gateway admin.
     * @param mainchainTokens Addresses of mainchain tokens.
     * @param dailyWithdrawalMaxQuota The daily withdrawal max quotas for mainchain tokens.
     * @param crossbellTokens Addresses of crossbell tokens.
     * @param crossbellTokenDecimals Decimals of crossbell tokens.
     */
    function initialize(
        address validator,
        address admin,
        address[] calldata mainchainTokens,
        uint256[] calldata dailyWithdrawalMaxQuota,
        address[] calldata crossbellTokens,
        uint8[] calldata crossbellTokenDecimals
    ) external;

    /**
     * @notice Pauses interaction with the gateway contract.
     * Requirements:
     * - The caller must have the ADMIN_ROLE.
     */
    function pause() external;

    /**
     * @notice Resumes interaction with the gateway contract.
     * Requirements:
     * - The caller must have the ADMIN_ROLE.
     */
    function unpause() external;

    /**
     * @notice Maps Crossbell tokens to mainchain.
     * Emits the `TokenMapped` event.
     * Requirements:
     * - The caller must have the ADMIN_ROLE.
     * @param mainchainTokens Addresses of mainchain tokens.
     * @param crossbellTokens Addresses of crossbell tokens.
     * @param crossbellTokenDecimals Decimals of crossbell tokens.
     */
    function mapTokens(
        address[] calldata mainchainTokens,
        address[] calldata crossbellTokens,
        uint8[] calldata crossbellTokenDecimals
    ) external;

    /**
     * @notice Requests deposit to crossbell chain.
     * Emits the `RequestDeposit` event.
     * @param recipient Address to receive deposit on crossbell chain
     * @param token Address of token to deposit from mainchain network
     * @param amount Amount of token to deposit  from mainchain network
     * @return depositId Deposit id
     */
    function requestDeposit(
        address recipient,
        address token,
        uint256 amount
    ) external returns (uint256 depositId);

    /**
     * @notice Withdraws based on the validator signatures.
     * Emits the `Withdrew` event.
     * Requirements:
     * - The signatures should be sorted by signing addresses of validators in ascending order.
     * @param chainId The chain ID of mainchain network.
     * @param withdrawalId Withdrawal ID from crossbell chain
     * @param recipient Address to receive withdrawal on mainchain chain
     * @param token Address of token to withdraw
     * @param amount Amount of token to withdraw
     * @param fee The fee amount to pay for the withdrawal tx sender. This is subtracted from the `amount`
     * @param signatures The list of signatures sorted by signing addresses of validators in ascending order.
     */
    function withdraw(
        uint256 chainId,
        uint256 withdrawalId,
        address recipient,
        address token,
        uint256 amount,
        uint256 fee,
        DataTypes.Signature[] calldata signatures
    ) external;

    /**
     * @notice Sets daily max quotas for the withdrawals.
     * Emits the `DailyWithdrawalMaxQuotasUpdated` event.
     * Requirements:
     * - The caller must have the ADMIN_ROLE.
     * - The arrays have the same length.
     * @param tokens Addresses of token to set
     * @param quotas quotas corresponding to the tokens to set
     */
    function setDailyWithdrawalMaxQuotas(
        address[] calldata tokens,
        uint256[] calldata quotas
    ) external;

    /**
     * @notice Returns the address of the validator contract.
     * @return The validator contract address
     */
    function getValidatorContract() external view returns (address);

    /**
     * @notice Returns the deposit count of the gateway contract.
     * @return The deposit count
     */
    function getDepositCount() external view returns (uint256);

    /**
     * @notice Returns the withdrawal hash by withdrawal id.
     * @param withdrawalId WithdrawalId to query
     * @return The withdrawal hash
     */
    function getWithdrawalHash(uint256 withdrawalId) external view returns (bytes32);

    /**
     * @notice Returns the daily withdrawal max quota.
     * @param token Token address
     */
    function getDailyWithdrawalMaxQuota(address token) external view returns (uint256);

    /**
     * @notice Returns today's withdrawal remaining quota.
     * @param token Token address to query
     */
    function getDailyWithdrawalRemainingQuota(address token) external view returns (uint256);

    /**
     * @notice Returns mapped tokens from crossbell chain
     * @param mainchainToken Token address on mainchain
     * @return token Mapped token from crossbell chain
     */
    function getCrossbellToken(
        address mainchainToken
    ) external view returns (DataTypes.MappedToken memory token);
}
