// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title DataTypes
 * @notice A standard library of data types.
 */
library DataTypes {
    /// @custom:struct MappedToken struct
    struct MappedToken {
        address token;
        uint8 decimals;
    }

    /**
     * @notice A struct containing deposit data.
     * @param chainId The ChainId of mainchain network.
     * @param recipient The address of account to receive the deposit.
     * @param token The address of token to deposit.
     * @param amount The amount of token to deposit.
     */
    struct DepositEntry {
        uint256 chainId;
        address recipient;
        address token;
        uint256 amount;
    }

    /**
     * @notice A struct containing withdrawal data.
     * @param chainId The ChainId of mainchain network.
     * @param recipient The address of account to receive the withdrawal.
     * @param token The address of token to withdraw.
     * @param amount The amount of token to be withdrawn on mainchain network. Note that validator should use this `amount' for submitting signature
     * @param fee The fee amount to pay for the withdrawal tx sender on mainchain network.
     */
    struct WithdrawalEntry {
        uint256 chainId;
        address recipient;
        address token;
        uint256 amount;
        uint256 fee;
    }

    /**
     * @notice A struct containing a validator signature for the withdrawal.
     */
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /**
     * @notice Acknowledge status, once the acknowledgements reach the threshold the 1st time, it can take effect to the system.
     * Acknowledgments after that should not have any effects.
     */
    enum Status {
        NotApproved,
        FirstApproved,
        AlreadyApproved
    }
}
