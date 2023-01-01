// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../libraries/DataTypes.sol";

interface IMainchainGateway {
    /**
     * @notice Request deposit to crossbell chain
     * @param recipient Address to receive deposit on crossbell chain
     * @param token Address of token to deposit
     * @param amount Amount of token to deposit
     * @return depositId Deposit id
     */
    function requestDeposit(
        address recipient,
        address token,
        uint256 amount
    ) external returns (uint256 depositId);

    /**
     * @notice Withdraw based on the validator signatures.
     * @param chainId ChainId
     * @param withdrawalId Withdrawal ID from crossbell chain
     * @param recipient Address to receive withdrawal on mainchain chain
     * @param token Address of token to withdraw
     * @param amount Amount of token to withdraw
     * @param signatures Validator signatures for withdrawal
     */
    function withdraw(
        uint256 chainId,
        uint256 withdrawalId,
        address recipient,
        address token,
        uint256 amount,
        bytes calldata signatures
    ) external;

    /**
     * @notice Pause interaction with the gateway contract
     */
    function pause() external;

    /**
     * @notice Resume interaction with the gateway contract
     */
    function unpause() external;

    /**
     * @dev returns true if there is enough signatures from validators.
     */
    function verifySignatures(bytes32 hash, bytes calldata signatures) external view returns (bool);

    /**
     * @notice Get mapped tokens from crossbell chain
     * @param mainchainToken Token address on mainchain
     * @return token Mapped token from crossbell chain
     */
    function getCrossbellToken(
        address mainchainToken
    ) external view returns (DataTypes.MappedToken memory token);
}
