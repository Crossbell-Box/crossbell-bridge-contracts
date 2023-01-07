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

    /// @dev Emitted when the thresholds for locked withdrawals are updated
    event LockedThresholdsUpdated(address[] tokens, uint256[] thresholds);

    /// @dev Emitted when the daily limit thresholds are updated
    event DailyWithdrawalLimitsUpdated(address[] tokens, uint256[] limits);

    /// @dev Emitted when the withdrawal is locked
    event WithdrawalLocked(uint256 indexed withdrawId);

    /// @dev Emitted when the withdrawal is unlocked
    event WithdrawalUnlocked(uint256 indexed withdrawId);

    function TYPE_HASH() external view returns (bytes32);

    /**
     * @notice Initializes the MainchainGateway.
     * Note that the thresholds contains:
     *  - thresholds[0]: lockedThresholds The amount thresholds to lock withdrawal.
     *  - thresholds[1]: dailyWithdrawalLimits Daily withdrawal limits for mainchain tokens.
     * @param validator Address of validator contract.
     * @param admin Address of gateway admin.
     * @param withdrawalUnlocker Address of operator who can unlock the locked withdrawals.
     * @param mainchainTokens Addresses of mainchain tokens.
     * @param thresholds The amount thresholds  for withdrawal.
     * @param crossbellTokens Addresses of crossbell tokens.
     * @param crossbellTokenDecimals Decimals of crossbell tokens.
     */
    function initialize(
        address validator,
        address admin,
        address withdrawalUnlocker,
        address[] calldata mainchainTokens,
        // thresholds[0]: lockedThresholds
        // thresholds[1]: dailyWithdrawalLimits
        uint256[][2] calldata thresholds,
        address[] calldata crossbellTokens,
        uint8[] calldata crossbellTokenDecimals
    ) external;

    /**
     * @notice Pause interaction with the gateway contract.
     * Requirements:
     * - The caller must have the ADMIN_ROLE.
     */
    function pause() external;

    /**
     * @notice Resume interaction with the gateway contract.
     * Requirements:
     * - The caller must have the ADMIN_ROLE.
     */
    function unpause() external;

    /**
     * @notice Maps Crossbell tokens to mainchain.
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
     * @notice Request deposit to crossbell chain.
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
     * @notice Withdraw based on the validator signatures.
     * Requirements:
     * - The order of the signatures should be arranged in ascending order of the signer address.
     * @param chainId ChainId
     * @param withdrawalId Withdrawal ID from crossbell chain
     * @param recipient Address to receive withdrawal on mainchain chain
     * @param token Address of token to withdraw
     * @param amount Amount of token to withdraw
     * @param fee The fee amount to pay for the withdrawal tx sender. This is subtracted from the `amount`
     * @param signatures Validator signatures for withdrawal
     */
    function withdraw(
        uint256 chainId,
        uint256 withdrawalId,
        address recipient,
        address token,
        uint256 amount,
        uint256 fee,
        DataTypes.Signature[] calldata signatures
    ) external returns (bool locked);

    /**
     * @notice Approves a specific withdrawal.
     * Requirements:
     * - The caller must have the WITHDRAWAL_UNLOCKER_ROLE.
     * @param chainId ChainId
     * @param withdrawalId Withdrawal ID from crossbell chain
     * @param recipient Address to receive withdrawal on mainchain chain
     * @param token Address of token to withdraw
     * @param amount Amount of token to withdraw
     * @param fee The fee amount to pay for the withdrawal tx sender. This is subtracted from the `amount`
     */
    function unlockWithdrawal(
        uint256 chainId,
        uint256 withdrawalId,
        address recipient,
        address token,
        uint256 amount,
        uint256 fee
    ) external;

    /**
     * @notice Sets the amount thresholds to lock withdrawal.
     * Requirements:
     * - The caller must have the ADMIN_ROLE.
     * - The arrays have the same length.
     * @param tokens Addresses of token to set
     * @param thresholds Thresholds corresponding to the tokens to set
     */
    function setLockedThresholds(address[] calldata tokens, uint256[] calldata thresholds) external;

    /**
     * @notice Sets daily limit amounts for the withdrawals.
     * Requirements:
     * - The caller must have the ADMIN_ROLE.
     * - The arrays have the same length.
     * Emits the `DailyWithdrawalLimitsUpdated` event.
     * @param tokens Addresses of token to set
     * @param limits Limits corresponding to the tokens to set
     */
    function setDailyWithdrawalLimits(
        address[] calldata tokens,
        uint256[] calldata limits
    ) external;

    /**
     * @notice Returns true if there is enough signatures from validators.
     * @param hash WithdrawHash
     * @param signatures Validator's withdrawal signatures synced from crossbell network
     */
    function verifySignatures(
        bytes32 hash,
        DataTypes.Signature[] calldata signatures
    ) external view returns (bool);

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
     * @notice Returns whether the withdrawal is locked or not.
     * @param withdrawalId WithdrawalId to query
     */
    function getWithdrawalLocked(uint256 withdrawalId) external view returns (bool);

    /**
     * @notice Returns the amount thresholds to lock withdrawal.
     * @param token Token address
     */
    function getWithdrawalLockedThreshold(address token) external view returns (uint256);

    /**
     * @notice Returns the daily withdrawal limit.
     * @param token Token address
     */
    function getDailyWithdrawalLimit(address token) external view returns (uint256);

    /**
     * @notice Checks whether the withdrawal reaches the daily limitation.
     * @param token Token address to withdraw
     * @param amount Token amount to withdraw
     */
    function reachedDailyWithdrawalLimit(
        address token,
        uint256 amount
    ) external view returns (bool);

    /**
     * @notice Get mapped tokens from crossbell chain
     * @param mainchainToken Token address on mainchain
     * @return token Mapped token from crossbell chain
     */
    function getCrossbellToken(
        address mainchainToken
    ) external view returns (DataTypes.MappedToken memory token);
}
