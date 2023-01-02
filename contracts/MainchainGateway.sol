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

/**
 * @title MainchainGateway
 * @dev Logic to handle deposits and withdrawl on Mainchain.
 */
contract MainchainGateway is IMainchainGateway, Initializable, Pausable, MainchainGatewayStorage {
    using ECVerify for bytes32;
    using SafeERC20 for IERC20;

    // keccak256("withdraw(uint256 chainId,uint256 withdrawalId,address recipient,address token,uint256 amount,bytes signatures)")
    bytes32 public constant TYPE_HASH =
        0xed7a87d78461bdc12aba24d19e67131757b33eab78ae3c422b3617d69a018b2f;

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

    /**
     * @notice Pause interaction with the gateway contract
     */
    function pause() external whenNotPaused onlyAdmin {
        _pause();
    }

    /**
     * @notice Resume interaction with the gateway contract
     */
    function unpause() external whenPaused onlyAdmin {
        _unpause();
    }

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
    ) external whenNotPaused returns (uint256 depositId) {
        DataTypes.MappedToken memory crossbellToken = _getCrossbellToken(token);
        require(crossbellToken.tokenAddr != address(0), "UnsupportedToken");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // transform token amount by different chain
        uint256 transformedAmount = _transformDepositAmount(token, amount, crossbellToken.decimals);

        depositId = _depositCount;
        unchecked {
            _depositCount++;
        }
        emit RequestDeposit(depositId, recipient, crossbellToken.tokenAddr, transformedAmount);
    }

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
    ) external whenNotPaused {
        require(chainId == block.chainid, "InvalidChainId");
        require(_withdrawalHash[withdrawalId] == bytes32(0), "NotNewWithdrawal");

        bytes32 hash = keccak256(
            abi.encodePacked(TYPE_HASH, chainId, withdrawalId, recipient, token, amount)
        );
        require(_verifySignatures(hash, signatures), "InsufficientSignaturesNumber");

        // record withdrawal hash
        _withdrawalHash[withdrawalId] = hash;
        // transfer
        IERC20(token).safeTransfer(recipient, amount);

        emit Withdrew(withdrawalId, recipient, token, amount);
    }

    /**
     * @dev returns true if there is enough signatures from validators.
     */
    function verifySignatures(
        bytes32 hash,
        bytes calldata signatures
    ) external view returns (bool) {
        return _verifySignatures(hash, signatures);
    }

    /**
     * @notice Returns the address of the validator contract.
     * @return The validator contract address
     */
    function getValidatorContract() external view returns (address) {
        return _validator;
    }

    /**
     * @notice Returns the admin address of the gateway contract.
     * @return The admin address
     */
    function getAdmin() external view returns (address) {
        return _admin;
    }

    /**
     * @notice Returns the deposit count of the gateway contract.
     * @return The deposit count
     */
    function getDepositCount() external view returns (uint256) {
        return _depositCount;
    }

    /**
     * @notice Returns the withdrawal hash by withdrawal id.
     * @param withdrawalId WithdrawalId to query
     * @return The withdrawal hash
     */
    function getWithdrawalHash(uint256 withdrawalId) external view returns (bytes32) {
        return _withdrawalHash[withdrawalId];
    }

    /**
     * @notice Gets mapped tokens from crossbell chain.
     * @param mainchainToken Token address on mainchain
     * @return token Mapped token from crossbell chain
     */
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

    function _getCrossbellToken(
        address mainchainToken
    ) internal view returns (DataTypes.MappedToken memory token) {
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
            "InvalidArrayLength"
        );

        for (uint256 i; i < mainchainTokens.length; i++) {
            _crossbellToken[mainchainTokens[i]] = DataTypes.MappedToken({
                tokenAddr: crossbellTokens[i],
                decimals: crossbellTokenDecimals[i]
            });
        }

        emit TokenMapped(mainchainTokens, crossbellTokens, crossbellTokenDecimals);
    }
}
