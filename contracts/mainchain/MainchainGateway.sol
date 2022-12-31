// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../libraries/ECVerify.sol";
import "./MainchainGatewayStorage.sol";
import "../interfaces/IValidator.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title MainchainBridge
 * @dev Logic to handle deposits and withdrawl on Mainchain.
 */
abstract contract MainchainGateway is Initializable, Pausable, MainchainGatewayStorage {
    using ECVerify for bytes32;
    using SafeERC20 for IERC20;

    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    function _checkAdmin() internal view {
        require(_msgSender() == _admin, "onlyAdmin");
    }

    function initialize(
        address validator,
        address admin,
        address[] calldata mainchainTokens,
        address[] calldata crossbellTokens,
        uint8[] calldata crossbellTokenDecimals
    ) external initializer {
        _validator = validator;

        _admin = admin;
        // map crossbell tokens
        if (mainchainTokens.length > 0) {
            _mapTokens(mainchainTokens, crossbellTokens, crossbellTokenDecimals);
        }
    }

    function pause() external whenNotPaused onlyAdmin {
        _pause();
    }

    function unpause() external whenPaused onlyAdmin {
        _unpause();
    }

    function requestDeposit(
        address recipient,
        address token,
        uint256 amount
    ) external virtual whenNotPaused returns (uint256 depositId) {
        MappedToken memory crossbellToken = getCrossbellToken(token);
        require(crossbellToken.tokenAddr != address(0), "MainchainBridge: unsupported token");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // transform token amount by different chain
        uint256 transformedAmount = _transformDepositAmount(token, amount, crossbellToken.decimals);

        depositId = _depositCount++;
        emit RequestDeposit(depositId, recipient, crossbellToken.tokenAddr, transformedAmount);
    }

    function withdraw(
        uint256 chainId,
        uint256 withdrawalId,
        address recipient,
        address token,
        uint256 amount,
        bytes memory signatures
    ) external virtual whenNotPaused {
        require(chainId == block.chainid, "MainchainGatewayManager: invalid chainId");

        bytes32 hash = keccak256(
            abi.encodePacked("withdrawERC20", chainId, withdrawalId, recipient, token, amount)
        );

        require(verifySignatures(hash, signatures));

        IERC20(token).safeTransfer(recipient, amount);

        _insertWithdrawalEntry(withdrawalId, recipient, token, amount);
    }

    /**
     * @dev returns true if there is enough signatures from validators.
     */
    function verifySignatures(bytes32 hash, bytes memory signatures) public view returns (bool) {
        uint256 signatureCount = signatures.length / 66;

        uint256 validatorCount = 0;
        address lastSigner = address(0);

        for (uint256 i = 0; i < signatureCount; i++) {
            address signer = hash.recover(signatures, i * 66);
            if (IValidator(_validator).isValidator(signer)) {
                validatorCount++;
            }
            // Prevent duplication of signatures
            require(signer > lastSigner);
            lastSigner = signer;
        }

        return IValidator(_validator).checkThreshold(validatorCount);
    }

    function _insertWithdrawalEntry(
        uint256 withdrawalId,
        address recipient,
        address token,
        uint256 amount
    ) internal {
        require(_withdrawals[withdrawalId].recipient == address(0), "NotNewWithdrawal");

        _withdrawals[withdrawalId] = WithdrawalEntry(recipient, token, amount);

        emit Withdrew(withdrawalId, recipient, token, amount);
    }

    // as there are different token decimals on different chains, so the amount need to be transformed
    // this function should be overridden by subclasses
    function _transformDepositAmount(
        address token,
        uint256 amount,
        uint8 destinationDecimals
    ) internal view returns (uint256 transformedAmount) {
        uint8 decimals = IERC20Metadata(token).decimals();

        if (destinationDecimals == decimals) {
            transformedAmount = amount;
        } else if (destinationDecimals > decimals) {
            transformedAmount = amount * 10 ** (destinationDecimals - decimals);
        } else {
            transformedAmount = amount / (10 ** (decimals - destinationDecimals));
        }
    }

    function getCrossbellToken(
        address mainchainToken
    ) public view returns (MappedToken memory token) {
        token = _crossbellToken[mainchainToken];
    }

    function _mapTokens(
        address[] calldata mainchainTokens,
        address[] calldata crossbellTokens,
        uint8[] calldata crossbellTokenDecimals
    ) internal virtual {
        require(
            mainchainTokens.length == crossbellTokens.length &&
                mainchainTokens.length == crossbellTokenDecimals.length,
            "MainchainBridge: invalid array length"
        );

        for (uint256 i; i < mainchainTokens.length; i++) {
            _crossbellToken[mainchainTokens[i]] = MappedToken({
                tokenAddr: crossbellTokens[i],
                decimals: crossbellTokenDecimals[i]
            });
        }

        emit TokenMapped(mainchainTokens, crossbellTokens, crossbellTokenDecimals);
    }
}
