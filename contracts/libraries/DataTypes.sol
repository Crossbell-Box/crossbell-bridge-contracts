// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

library DataTypes {
    /**
     * @notice A struct containing mapped token data.
     * @param token The address of token.
     * @param amount The decimals of token.
     */
    struct MappedToken {
        address token;
        uint8 decimals;
    }

    /**
     * @notice A struct containing deposit data.
     * @param chainId The ChainId of specific network.
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
     * @param chainId The ChainId of specific network.
     * @param recipient The address of account to receive the withdrawal.
     * @param token The address of token to withdraw.
     * @param transformedAmount The amount of token to be withdrawn on mainchain network.
     * @param amount The original amount of token to withdraw from crossbell network.
     */
    struct WithdrawalEntry {
        uint256 chainId;
        address recipient;
        address token;
        uint256 transformedAmount;
        uint256 amount;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // @notice Acknowledge status, once the acknowledgements reach the threshold the 1st
    // time, it can take effect to the system. E.g. confirm a deposit.
    // Acknowledgments after that should not have any effects.
    enum Status {
        NotApproved,
        FirstApproved,
        AlreadyApproved
    }
}
