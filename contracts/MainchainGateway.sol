// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

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
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title MainchainGateway
 * @dev Logic to handle deposits and withdrawals on mainchain.
 */
contract MainchainGateway is
    IMainchainGateway,
    Initializable,
    ReentrancyGuard,
    Pausable,
    AccessControlEnumerable,
    MainchainGatewayStorage
{
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @inheritdoc IMainchainGateway
    function initialize(
        address validator,
        address admin,
        address[] calldata mainchainTokens,
        uint256[] calldata dailyWithdrawalMaxQuota,
        address[] calldata crossbellTokens,
        uint8[] calldata crossbellTokenDecimals
    ) external override initializer {
        _validator = validator;

        _updateDomainSeparator();

        // map crossbell tokens
        if (mainchainTokens.length > 0) {
            _mapTokens(mainchainTokens, crossbellTokens, crossbellTokenDecimals);
        }

        // set daily withdrawal quotas
        _setDailyWithdrawalMaxQuotas(mainchainTokens, dailyWithdrawalMaxQuota);

        // grants `ADMIN_ROLE`
        _setupRole(ADMIN_ROLE, admin);
    }

    /// @inheritdoc IMainchainGateway
    function pause() external override whenNotPaused onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @inheritdoc IMainchainGateway
    function unpause() external override whenPaused onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @inheritdoc IMainchainGateway
    function mapTokens(
        address[] calldata mainchainTokens,
        address[] calldata crossbellTokens,
        uint8[] calldata crossbellTokenDecimals
    ) external override onlyRole(ADMIN_ROLE) {
        if (mainchainTokens.length > 0) {
            _mapTokens(mainchainTokens, crossbellTokens, crossbellTokenDecimals);
        }
    }

    /// @inheritdoc IMainchainGateway
    function requestDeposit(
        address recipient,
        address token,
        uint256 amount
    ) external override nonReentrant whenNotPaused returns (uint256 depositId) {
        require(amount > 0, "ZeroAmount");

        DataTypes.MappedToken memory crossbellToken = _getCrossbellToken(token);
        require(crossbellToken.token != address(0), "UnsupportedToken");

        unchecked {
            depositId = _depositCounter++;
        }

        // lock token
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // convert token amount by crossbell chain token decimals
        uint256 convertedAmount = _convertToBase(token, amount, crossbellToken.decimals);

        // @dev depositHash is used to verify the integrity of the deposit,
        // in case that validator relays wrong parameters to the crossbell network.
        bytes32 depositHash = keccak256(
            abi.encodePacked(
                _chainId(),
                depositId,
                recipient,
                crossbellToken.token,
                convertedAmount
            )
        );

        emit RequestDeposit(
            _chainId(),
            depositId,
            recipient,
            crossbellToken.token,
            convertedAmount,
            depositHash
        );
    }

    /// @inheritdoc IMainchainGateway
    function withdraw(
        uint256 chainId,
        uint256 withdrawalId,
        address recipient,
        address token,
        uint256 amount,
        uint256 fee,
        DataTypes.Signature[] calldata signatures
    ) external override nonReentrant whenNotPaused {
        require(chainId == block.chainid, "InvalidChainId");
        require(_withdrawalHash[withdrawalId] == bytes32(0), "NotNewWithdrawal");
        require(!_reachedDailyWithdrawalQuota(token, amount), "DailyWithdrawalMaxQuota");

        bytes32 hash = keccak256(
            abi.encodePacked(_domainSeparator, chainId, withdrawalId, recipient, token, amount, fee)
        );
        require(_verifySignatures(hash, signatures), "InsufficientSignaturesNumber");

        // record withdrawal hash
        _withdrawalHash[withdrawalId] = hash;
        // record withdrawal token
        _recordWithdrawal(token, amount);
        // transfer
        IERC20(token).safeTransfer(recipient, amount - fee);
        IERC20(token).safeTransfer(msg.sender, fee);

        emit Withdrew(chainId, withdrawalId, recipient, token, amount, fee);
    }

    /// @inheritdoc IMainchainGateway
    function setDailyWithdrawalMaxQuotas(
        address[] calldata tokens,
        uint256[] calldata quotas
    ) external override onlyRole(ADMIN_ROLE) {
        _setDailyWithdrawalMaxQuotas(tokens, quotas);
    }

    /**
     * @inheritdoc IMainchainGateway
     */
    function getDomainSeparator() external view virtual override returns (bytes32) {
        return _domainSeparator;
    }

    /// @inheritdoc IMainchainGateway
    function getValidatorContract() external view override returns (address) {
        return _validator;
    }

    /// @inheritdoc IMainchainGateway
    function getDepositCount() external view override returns (uint256) {
        return _depositCounter;
    }

    /// @inheritdoc IMainchainGateway
    function getWithdrawalHash(uint256 withdrawalId) external view override returns (bytes32) {
        return _withdrawalHash[withdrawalId];
    }

    /// @inheritdoc IMainchainGateway
    function getDailyWithdrawalMaxQuota(address token) external view override returns (uint256) {
        return _dailyWithdrawalMaxQuota[token];
    }

    /// @inheritdoc IMainchainGateway
    function getDailyWithdrawalRemainingQuota(
        address token
    ) external view override returns (uint256) {
        uint256 currentDate = _currentDate();
        if (currentDate > _lastDateSynced[token]) {
            return _dailyWithdrawalMaxQuota[token];
        } else {
            return _dailyWithdrawalMaxQuota[token] - _lastSyncedWithdrawal[token];
        }
    }

    /// @inheritdoc IMainchainGateway
    function getCrossbellToken(
        address mainchainToken
    ) external view override returns (DataTypes.MappedToken memory token) {
        return _getCrossbellToken(mainchainToken);
    }

    /**
     * @dev Maps Crossbell tokens to mainchain.
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

        for (uint256 i = 0; i < mainchainTokens.length; i++) {
            _crossbellTokens[mainchainTokens[i]] = DataTypes.MappedToken({
                token: crossbellTokens[i],
                decimals: crossbellTokenDecimals[i]
            });
        }

        emit TokenMapped(mainchainTokens, crossbellTokens, crossbellTokenDecimals);
    }

    /**
     * @dev Update domain separator.
     */
    function _updateDomainSeparator() internal {
        _domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
                ),
                keccak256("MainchainGateway"),
                keccak256("1"),
                block.chainid,
                address(this),
                // slither-disable-next-line timestamp
                keccak256(abi.encodePacked(block.timestamp))
            )
        );
    }

    /**
     * @dev Sets daily max quota for the withdrawals.
     * Note that the array lengths must be equal.
     * Emits the `DailyWithdrawalQuotasUpdated` event.
     */
    function _setDailyWithdrawalMaxQuotas(
        address[] calldata tokens,
        uint256[] calldata quotas
    ) internal {
        require(tokens.length == quotas.length, "InvalidArrayLength");

        for (uint256 i = 0; i < tokens.length; i++) {
            _dailyWithdrawalMaxQuota[tokens[i]] = quotas[i];
        }
        emit DailyWithdrawalMaxQuotasUpdated(tokens, quotas);
    }

    /**
     * @dev Record withdrawal token.
     */
    function _recordWithdrawal(address token, uint256 amount) internal {
        uint256 currentDate = _currentDate();
        if (currentDate > _lastDateSynced[token]) {
            _lastDateSynced[token] = currentDate;
            _lastSyncedWithdrawal[token] = amount;
        } else {
            _lastSyncedWithdrawal[token] += amount;
        }
    }

    /**
     * @dev Checks whether the withdrawal reaches the daily quota.
     * @param token Token address to withdraw
     * @param amount Token amount to withdraw
     */
    function _reachedDailyWithdrawalQuota(
        address token,
        uint256 amount
    ) internal view returns (bool) {
        // slither-disable-next-line timestamp
        uint256 currentDate = _currentDate();
        if (currentDate > _lastDateSynced[token]) {
            return _dailyWithdrawalMaxQuota[token] <= amount;
        } else {
            return _dailyWithdrawalMaxQuota[token] <= _lastSyncedWithdrawal[token] + amount;
        }
    }

    /**
     * @dev Checks secp256k1 signatures of validators
     */
    function _verifySignatures(
        bytes32 hash,
        DataTypes.Signature[] calldata signatures
    ) internal view returns (bool) {
        bytes32 prefixedHash = hash.toEthSignedMessageHash();

        uint256 validatorCount = 0;
        address lastSigner = address(0);
        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = prefixedHash.recover(
                signatures[i].v,
                signatures[i].r,
                signatures[i].s
            );
            if (IValidator(_validator).isValidator(signer)) {
                validatorCount++;
            }
            // Prevent duplication of signatures
            require(signer > lastSigner, "InvalidSignerOrder");
            lastSigner = signer;
        }

        return IValidator(_validator).checkThreshold(validatorCount);
    }

    // @dev As there are different token decimals on different chains, so the amount need to be converted.
    function _convertToBase(
        address token,
        uint256 amount,
        uint8 destDecimals
    ) internal view returns (uint256 convertedAmount) {
        uint8 decimals = IERC20Metadata(token).decimals();
        convertedAmount = (destDecimals >= decimals)
            ? amount * 10 ** (destDecimals - decimals)
            : amount / (10 ** (decimals - destDecimals));
    }

    function _getCrossbellToken(
        address mainchainToken
    ) internal view returns (DataTypes.MappedToken memory token) {
        token = _crossbellTokens[mainchainToken];
    }

    /**
     * @dev Returns block chainId.
     */
    function _chainId() internal view returns (uint256) {
        return block.chainid;
    }

    /**
     * @dev Returns the current date
     */
    function _currentDate() internal view returns (uint256) {
        // slither-disable-next-line timestamp
        return block.timestamp / 1 days;
    }
}
