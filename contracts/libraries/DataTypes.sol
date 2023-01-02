// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

library DataTypes {
    struct MappedToken {
        address tokenAddr;
        uint8 decimals;
    }

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
}
