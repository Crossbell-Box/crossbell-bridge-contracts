// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./interfaces/IERC20Mintable.sol";
import "./interfaces/IValidator.sol";
import "./interfaces/ICrossbellGateway.sol";
import "./storage/CrossbellGatewayStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

/**
 * @title CrossbellGateway
 * @dev Logic to handle deposits and withdrawals on Crossbell.
 */
contract CrossbellGateway is
    ICrossbellGateway,
    Initializable,
    ReentrancyGuard,
    Pausable,
    AccessControlEnumerable,
    IERC777Recipient,
    CrossbellGatewayStorage
{
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IERC1820Registry public constant ERC1820_REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 public constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    modifier onlyValidator() {
        _checkValidator();
        _;
    }

    /// @inheritdoc ICrossbellGateway
    function initialize(
        address validator,
        address admin,
        address[] calldata crossbellTokens,
        uint256[] calldata chainIds,
        address[] calldata mainchainTokens,
        uint8[] calldata mainchainTokenDecimals
    ) external override initializer {
        _validator = validator;

        // map mainchain tokens
        if (crossbellTokens.length > 0) {
            _mapTokens(crossbellTokens, chainIds, mainchainTokens, mainchainTokenDecimals);
        }

        // grants `DEFAULT_ADMIN_ROLE`, `ADMIN_ROLE`
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(ADMIN_ROLE, admin);

        // register interfaces
        ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
    }

    /// @inheritdoc ICrossbellGateway
    function pause() external override whenNotPaused onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @inheritdoc ICrossbellGateway
    function unpause() external override whenPaused onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @inheritdoc ICrossbellGateway
    function mapTokens(
        address[] calldata crossbellTokens,
        uint256[] calldata chainIds,
        address[] calldata mainchainTokens,
        uint8[] calldata mainchainTokenDecimals
    ) external override onlyRole(ADMIN_ROLE) {
        // map mainchain tokens
        if (crossbellTokens.length > 0) {
            _mapTokens(crossbellTokens, chainIds, mainchainTokens, mainchainTokenDecimals);
        }
    }

    /// @inheritdoc ICrossbellGateway
    function batchAckDeposit(
        uint256[] calldata chainIds,
        uint256[] calldata depositIds,
        address[] calldata recipients,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes32[] calldata depositHashes
    ) external override nonReentrant whenNotPaused onlyValidator {
        require(
            chainIds.length == depositIds.length &&
                chainIds.length == recipients.length &&
                chainIds.length == tokens.length &&
                chainIds.length == amounts.length &&
                chainIds.length == depositHashes.length,
            "InvalidArrayLength"
        );

        for (uint256 i = 0; i < depositIds.length; i++) {
            _ackDeposit(
                chainIds[i],
                depositIds[i],
                recipients[i],
                tokens[i],
                amounts[i],
                depositHashes[i]
            );
        }
    }

    /// @inheritdoc ICrossbellGateway
    function batchSubmitWithdrawalSignatures(
        uint256[] calldata chainIds,
        uint256[] calldata withdrawalIds,
        bytes[] calldata sigs
    ) external override whenNotPaused onlyValidator {
        require(
            chainIds.length == withdrawalIds.length && chainIds.length == sigs.length,
            "InvalidArrayLength"
        );

        for (uint256 i = 0; i < chainIds.length; i++) {
            _submitWithdrawalSignature(chainIds[i], withdrawalIds[i], sigs[i]);
        }
    }

    /// @inheritdoc ICrossbellGateway
    function ackDeposit(
        uint256 chainId,
        uint256 depositId,
        address recipient,
        address token,
        uint256 amount,
        bytes32 depositHash
    ) external override nonReentrant whenNotPaused onlyValidator {
        _ackDeposit(chainId, depositId, recipient, token, amount, depositHash);
    }

    /// @inheritdoc ICrossbellGateway
    function requestWithdrawal(
        uint256 chainId,
        address recipient,
        address token,
        uint256 amount,
        uint256 fee
    ) external override nonReentrant whenNotPaused returns (uint256 withdrawalId) {
        require(amount > 0, "ZeroAmount");
        require(amount >= fee, "FeeExceedAmount");

        DataTypes.MappedToken memory mainchainToken = _getMainchainToken(chainId, token);
        require(mainchainToken.token != address(0), "UnsupportedToken");

        // convert token amount by mainchain token decimals
        uint256 convertedAmount = _convertToBase(token, amount, mainchainToken.decimals);
        uint256 feeAmount = _convertToBase(token, fee, mainchainToken.decimals);
        // save withdrawal
        unchecked {
            withdrawalId = _withdrawalCounter[chainId]++;
        }
        _withdrawals[chainId][withdrawalId] = DataTypes.WithdrawalEntry(
            chainId,
            recipient,
            mainchainToken.token,
            convertedAmount,
            feeAmount
        );

        // lock token
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit RequestWithdrawal(
            chainId,
            withdrawalId,
            recipient,
            mainchainToken.token,
            convertedAmount,
            feeAmount
        );
    }

    /// @inheritdoc ICrossbellGateway
    function submitWithdrawalSignature(
        uint256 chainId,
        uint256 withdrawalId,
        bytes calldata sig
    ) external override whenNotPaused onlyValidator {
        _submitWithdrawalSignature(chainId, withdrawalId, sig);
    }

    /// @inheritdoc ICrossbellGateway
    function getMainchainToken(
        uint256 chainId,
        address crossbellToken
    ) external view override returns (DataTypes.MappedToken memory token) {
        return _getMainchainToken(chainId, crossbellToken);
    }

    /// @inheritdoc ICrossbellGateway
    function getValidatorAcknowledgementHash(
        uint256 chainId,
        uint256 id,
        address validator
    ) external view override returns (bytes32) {
        return _validatorAck[chainId][id][validator];
    }

    /// @inheritdoc ICrossbellGateway
    function getAcknowledgementStatus(
        uint256 chainId,
        uint256 id,
        bytes32 hash
    ) external view override returns (DataTypes.Status) {
        return _ackStatus[chainId][id][hash];
    }

    /// @inheritdoc ICrossbellGateway
    function getAcknowledgementCount(
        uint256 chainId,
        uint256 id,
        bytes32 hash
    ) external view override returns (uint256) {
        return _ackCount[chainId][id][hash];
    }

    /// @inheritdoc ICrossbellGateway
    function getWithdrawalSignatures(
        uint256 chainId,
        uint256 withdrawalId
    ) external view override returns (address[] memory signers, bytes[] memory sigs) {
        signers = _getWithdrawalSigners(chainId, withdrawalId);
        sigs = new bytes[](signers.length);
        for (uint256 i = 0; i < signers.length; i++) {
            sigs[i] = _withdrawalSig[chainId][withdrawalId][signers[i]];
        }
    }

    /// @inheritdoc ICrossbellGateway
    function getValidatorContract() external view override returns (address) {
        return _validator;
    }

    /// @inheritdoc ICrossbellGateway
    function getDepositEntry(
        uint256 chainId,
        uint256 depositId
    ) external view override returns (DataTypes.DepositEntry memory) {
        return _deposits[chainId][depositId];
    }

    /// @inheritdoc ICrossbellGateway
    function getWithdrawalCount(uint256 chainId) external view override returns (uint256) {
        return _withdrawalCounter[chainId];
    }

    /// @inheritdoc ICrossbellGateway
    function getWithdrawalEntry(
        uint256 chainId,
        uint256 withdrawalId
    ) external view override returns (DataTypes.WithdrawalEntry memory) {
        return _withdrawals[chainId][withdrawalId];
    }

    /// @inheritdoc IERC777Recipient
    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata userData,
        bytes calldata operatorData
    ) external pure override(IERC777Recipient) {
        /// @dev Should revert if receiving ERC777 tokens through `send` with data.
        if (userData.length > 0 || operatorData.length > 0) {
            revert("ShouldRevertReceive");
        }
    }

    function _ackDeposit(
        uint256 chainId,
        uint256 depositId,
        address recipient,
        address token,
        uint256 amount,
        bytes32 depositHash
    ) internal {
        bytes32 hash = keccak256(abi.encodePacked(chainId, depositId, recipient, token, amount));
        require(depositHash == hash, "InvalidHashCheck");

        DataTypes.Status status = _acknowledge(chainId, depositId, hash, msg.sender);
        if (status == DataTypes.Status.FirstApproved) {
            // send token
            _sendToken(recipient, token, amount);

            // record deposit
            _deposits[chainId][depositId] = DataTypes.DepositEntry(
                chainId,
                recipient,
                token,
                amount
            );
            emit Deposited(chainId, depositId, recipient, token, amount);
        }

        emit AckDeposit(chainId, depositId, msg.sender, recipient, token, amount);
    }

    /**
     * @dev Maps crossbell tokens to mainchain networks.
     */
    function _mapTokens(
        address[] calldata crossbellTokens,
        uint256[] calldata chainIds,
        address[] calldata mainchainTokens,
        uint8[] calldata mainchainTokenDecimals
    ) internal {
        require(
            crossbellTokens.length == mainchainTokens.length &&
                crossbellTokens.length == mainchainTokenDecimals.length &&
                crossbellTokens.length == chainIds.length,
            "InvalidArrayLength"
        );

        for (uint i = 0; i < crossbellTokens.length; i++) {
            _mainchainTokens[crossbellTokens[i]][chainIds[i]] = DataTypes.MappedToken({
                token: mainchainTokens[i],
                decimals: mainchainTokenDecimals[i]
            });
        }
        emit TokenMapped(crossbellTokens, chainIds, mainchainTokens, mainchainTokenDecimals);
    }

    function _submitWithdrawalSignature(
        uint256 chainId,
        uint256 withdrawalId,
        bytes calldata sig
    ) internal {
        bytes memory currentSig = _withdrawalSig[chainId][withdrawalId][msg.sender];
        if (0 == currentSig.length) {
            _withdrawalSigners[chainId][withdrawalId].push(msg.sender);
        }

        _withdrawalSig[chainId][withdrawalId][msg.sender] = sig;
        emit SubmitWithdrawalSignature(chainId, withdrawalId, msg.sender, sig);
    }

    function _acknowledge(
        uint256 chainId,
        uint256 id,
        bytes32 hash,
        address validator
    ) internal returns (DataTypes.Status) {
        require(_validatorAck[chainId][id][validator] == bytes32(0), "AlreadyAcknowledged");

        _validatorAck[chainId][id][validator] = hash;
        DataTypes.Status status = _ackStatus[chainId][id][hash];
        uint256 count = _ackCount[chainId][id][hash];

        // slither-disable-next-line calls-loop
        if (IValidator(_validator).checkThreshold(count + 1)) {
            if (status == DataTypes.Status.NotApproved) {
                _ackStatus[chainId][id][hash] = DataTypes.Status.FirstApproved;
            } else {
                _ackStatus[chainId][id][hash] = DataTypes.Status.AlreadyApproved;
            }
        }

        _ackCount[chainId][id][hash]++;

        return _ackStatus[chainId][id][hash];
    }

    // slither-disable-next-line calls-loop
    function _sendToken(address recipient, address token, uint256 amount) internal {
        uint256 gatewayBalance = IERC20(token).balanceOf(address(this));
        if (gatewayBalance < amount) {
            IERC20Mintable(token).mint(address(this), amount - gatewayBalance);
        }

        IERC20(token).safeTransfer(recipient, amount);
    }

    function _getWithdrawalSigners(
        uint256 chainId,
        uint256 withdrawalId
    ) internal view returns (address[] memory) {
        return _withdrawalSigners[chainId][withdrawalId];
    }

    function _getMainchainToken(
        uint256 chainId,
        address crossbellToken
    ) internal view returns (DataTypes.MappedToken memory token) {
        token = _mainchainTokens[crossbellToken][chainId];
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

    function _checkValidator() internal view {
        require(IValidator(_validator).isValidator(_msgSender()), "NotValidator");
    }
}
