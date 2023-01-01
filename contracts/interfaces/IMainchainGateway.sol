// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../libraries/DataTypes.sol";

interface IMainchainGateway {
    function requestDeposit(
        address recipient,
        address token,
        uint256 amount
    ) external returns (uint256 depositId);

    function withdraw(
        uint256 chainId,
        uint256 withdrawalId,
        address recipient,
        address token,
        uint256 amount,
        bytes calldata signatures
    ) external;

    function verifySignatures(bytes32 hash, bytes calldata signatures) external view returns (bool);

    function getCrossbellToken(
        address mainchainToken
    ) external view returns (DataTypes.MappedToken memory token);
}
