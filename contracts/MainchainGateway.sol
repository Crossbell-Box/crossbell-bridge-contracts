// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./libraries/ECVerify.sol";
import "./libraries/DataTypes.sol";
import "./storage/MainchainGatewayStorage.sol";
import "./interfaces/IValidator.sol";
import "./interfaces/IMainchainGateway.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @title MainchainGateway
 * @dev Logic to handle deposits and withdrawals on mainchain.
 */
contract MainchainGateway is
    IMainchainGateway,
    Initializable,
    Pausable,
    AccessControlEnumerable,
    MainchainGatewayStorage
{
    using ECVerify for bytes32;
    using SafeERC20 for IERC20;

    // keccak256("withdraw(uint256 chainId,uint256 withdrawalId,address recipient,address token,uint256 amount,bytes signatures)")
    bytes32 public constant TYPE_HASH =
        0xed7a87d78461bdc12aba24d19e67131757b33eab78ae3c422b3617d69a018b2f;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WITHDRAWAL_UNLOCKER_ROLE = keccak256("WITHDRAWAL_UNLOCKER_ROLE");

    /// @inheritdoc IMainchainGateway
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
    ) external initializer {
        _validator = validator;

        // map crossbell tokens
        if (mainchainTokens.length > 0) {
            _mapTokens(mainchainTokens, crossbellTokens, crossbellTokenDecimals);
        }

        // set the amount thresholds to lock withdrawal
        _setLockedThresholds(mainchainTokens, thresholds[0]);

        // set daily withdrawal limits
        _setDailyWithdrawalLimits(mainchainTokens, thresholds[1]);

        // grants `DEFAULT_ADMIN_ROLE`, `ADMIN_ROLE` and `WITHDRAWAL_UNLOCKER_ROLE`
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(ADMIN_ROLE, admin);
        _setupRole(WITHDRAWAL_UNLOCKER_ROLE, withdrawalUnlocker);
    }

    /// @inheritdoc IMainchainGateway
    function pause() external whenNotPaused onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @inheritdoc IMainchainGateway
    function unpause() external whenPaused onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @inheritdoc IMainchainGateway
    function requestDeposit(
        address recipient,
        address token,
        uint256 amount
    ) external whenNotPaused returns (uint256 depositId) {
        DataTypes.MappedToken memory crossbellToken = _getCrossbellToken(token);
        require(crossbellToken.token != address(0), "UnsupportedToken");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // transform token amount by different chain
        uint256 transformedAmount = _transformDepositAmount(token, amount, crossbellToken.decimals);

        depositId = _depositCount;
        unchecked {
            _depositCount++;
        }
        emit RequestDeposit(depositId, recipient, crossbellToken.token, transformedAmount);
    }

    /// @inheritdoc IMainchainGateway
    function withdraw(
        uint256 chainId,
        uint256 withdrawalId,
        address recipient,
        address token,
        uint256 amount,
        bytes calldata signatures
    ) external whenNotPaused returns (bool locked) {
        require(chainId == block.chainid, "InvalidChainId");
        require(_withdrawalHash[withdrawalId] == bytes32(0), "NotNewWithdrawal");
        require(!_reachedDailyWithdrawalLimit(token, amount), "DailyWithdrawalLimit");

        bytes32 hash = keccak256(
            abi.encodePacked(TYPE_HASH, chainId, withdrawalId, recipient, token, amount)
        );
        require(_verifySignatures(hash, signatures), "InsufficientSignaturesNumber");

        // check locked
        locked = _lockedWithdrawalRequest(token, amount);
        if (locked) {
            _withdrawalLocked[withdrawalId] = true;
            emit WithdrawalLocked(withdrawalId);
            return locked;
        }

        // record withdrawal hash
        _withdrawalHash[withdrawalId] = hash;
        // record withdrawal token
        _recordWithdrawal(token, amount);
        // transfer
        IERC20(token).safeTransfer(recipient, amount);

        emit Withdrew(withdrawalId, recipient, token, amount);
    }

    /**
     * @dev Record withdrawal token.
     */
    function _recordWithdrawal(address token, uint256 amount) internal {
        uint256 currentDate = block.timestamp / 1 days;
        if (currentDate > _lastDateSynced[token]) {
            _lastDateSynced[token] = currentDate;
            _lastSyncedWithdrawal[token] = amount;
        } else {
            _lastSyncedWithdrawal[token] += amount;
        }
    }

    /// @inheritdoc IMainchainGateway
    function unlockWithdrawal(
        uint256 chainId,
        uint256 withdrawalId,
        address recipient,
        address token,
        uint256 amount
    ) external whenNotPaused onlyRole(WITHDRAWAL_UNLOCKER_ROLE) {
        require(chainId == block.chainid, "InvalidChainId");
        require(_withdrawalLocked[withdrawalId], "ApprovedWithdrawal");
        require(_withdrawalHash[withdrawalId] == bytes32(0), "NotNewWithdrawal");

        delete _withdrawalLocked[withdrawalId];
        emit WithdrawalUnlocked(withdrawalId);

        bytes32 hash = keccak256(
            abi.encodePacked(TYPE_HASH, chainId, withdrawalId, recipient, token, amount)
        );

        // record withdrawal hash
        _withdrawalHash[withdrawalId] = hash;
        // transfer
        IERC20(token).safeTransfer(recipient, amount);

        emit Withdrew(withdrawalId, recipient, token, amount);
    }

    /// @inheritdoc IMainchainGateway
    function setLockedThresholds(
        address[] calldata tokens,
        uint256[] calldata thresholds
    ) external onlyRole(ADMIN_ROLE) {
        _setLockedThresholds(tokens, thresholds);
    }

    /// @inheritdoc IMainchainGateway
    function setDailyWithdrawalLimits(
        address[] calldata tokens,
        uint256[] calldata limits
    ) external onlyRole(ADMIN_ROLE) {
        _setDailyWithdrawalLimits(tokens, limits);
    }

    /// @inheritdoc IMainchainGateway
    function verifySignatures(
        bytes32 hash,
        bytes calldata signatures
    ) external view returns (bool) {
        return _verifySignatures(hash, signatures);
    }

    /// @inheritdoc IMainchainGateway
    function getValidatorContract() external view returns (address) {
        return _validator;
    }

    /// @inheritdoc IMainchainGateway
    function getDepositCount() external view returns (uint256) {
        return _depositCount;
    }

    /// @inheritdoc IMainchainGateway
    function getWithdrawalHash(uint256 withdrawalId) external view returns (bytes32) {
        return _withdrawalHash[withdrawalId];
    }

    /// @inheritdoc IMainchainGateway
    function getWithdrawalLocked(uint256 withdrawalId) external view returns (bool) {
        return _withdrawalLocked[withdrawalId];
    }

    /// @inheritdoc IMainchainGateway
    function getWithdrawalLockedThreshold(address token) external view returns (uint256) {
        return _lockedThresholds[token];
    }

    /// @inheritdoc IMainchainGateway
    function reachedDailyWithdrawalLimit(
        address token,
        uint256 amount
    ) external view returns (bool) {
        return _reachedDailyWithdrawalLimit(token, amount);
    }

    /// @inheritdoc IMainchainGateway
    function getCrossbellToken(
        address mainchainToken
    ) external view returns (DataTypes.MappedToken memory token) {
        return _getCrossbellToken(mainchainToken);
    }

    function _verifySignatures(
        bytes32 hash,
        bytes calldata signatures
    ) internal view returns (bool) {
        uint256 signatureCount = signatures.length / 65;

        uint256 validatorCount = 0;
        address lastSigner = address(0);

        for (uint256 i = 0; i < signatureCount; i++) {
            address signer = hash.recover(signatures, i * 65);
            if (IValidator(_validator).isValidator(signer)) {
                validatorCount++;
            }
            // Prevent duplication of signatures
            require(signer > lastSigner, "InvalidOrder");
            lastSigner = signer;
        }

        return IValidator(_validator).checkThreshold(validatorCount);
    }

    /**
     * @dev Sets the amount thresholds to lock withdrawal.
     * Note that the array lengths must be equal.
     */
    function _setLockedThresholds(
        address[] calldata tokens,
        uint256[] calldata thresholds
    ) internal {
        require(tokens.length == thresholds.length, "InvalidArrayLength");

        for (uint256 i = 0; i < tokens.length; i++) {
            _lockedThresholds[tokens[i]] = thresholds[i];
        }
        emit LockedThresholdsUpdated(tokens, thresholds);
    }

    /**
     * @dev Sets daily limit amounts for the withdrawals.
     * Note that the array lengths must be equal.
     * Emits the `DailyWithdrawalLimitsUpdated` event.
     */
    function _setDailyWithdrawalLimits(
        address[] calldata tokens,
        uint256[] calldata limits
    ) internal {
        require(tokens.length == limits.length, "InvalidArrayLength");

        for (uint256 i = 0; i < tokens.length; i++) {
            _dailyWithdrawalLimit[tokens[i]] = limits[i];
        }
        emit DailyWithdrawalLimitsUpdated(tokens, limits);
    }

    /**
     * @dev Returns whether the withdrawal request is locked or not.
     */
    function _lockedWithdrawalRequest(address token, uint256 amount) internal view returns (bool) {
        return _lockedThresholds[token] <= amount;
    }

    /**
     * @dev Checks whether the withdrawal reaches the daily limitation.
     * Note that the daily withdrawal threshold should not apply for locked withdrawals.
     */
    function _reachedDailyWithdrawalLimit(
        address token,
        uint256 amount
    ) internal view returns (bool) {
        if (_lockedWithdrawalRequest(token, amount)) {
            return false;
        }

        uint256 currentDate = block.timestamp / 1 days;
        if (currentDate > _lastDateSynced[token]) {
            return _dailyWithdrawalLimit[token] <= amount;
        } else {
            return _dailyWithdrawalLimit[token] <= _lastSyncedWithdrawal[token] + amount;
        }
    }

    // @dev As there are different token decimals on different chains, so the amount need to be transformed.
    function _transformDepositAmount(
        address token,
        uint256 amount,
        uint8 destinationDecimals
    ) internal view returns (uint256 transformedAmount) {
        uint8 decimals = IERC20Metadata(token).decimals();

        if (destinationDecimals >= decimals) {
            transformedAmount = amount * 10 ** (destinationDecimals - decimals);
        } else {
            transformedAmount = amount / (10 ** (decimals - destinationDecimals));
        }
    }

    function _getCrossbellToken(
        address mainchainToken
    ) internal view returns (DataTypes.MappedToken memory token) {
        token = _crossbellToken[mainchainToken];
    }

    /**
     * @dev Maps mainchain tokens to crossbell network.
     */
    function _mapTokens(
        address[] calldata mainchainTokens,
        address[] calldata crossbellTokens,
        uint8[] calldata crossbellTokenDecimals
    ) internal {
        require(
            mainchainTokens.length == crossbellTokens.length &&
                mainchainTokens.length == crossbellTokenDecimals.length,
            "InvalidArrayLength"
        );

        for (uint256 i; i < mainchainTokens.length; i++) {
            _crossbellToken[mainchainTokens[i]] = DataTypes.MappedToken({
                token: crossbellTokens[i],
                decimals: crossbellTokenDecimals[i]
            });
        }

        emit TokenMapped(mainchainTokens, crossbellTokens, crossbellTokenDecimals);
    }
}