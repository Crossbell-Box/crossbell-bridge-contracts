// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../references/ECVerify.sol";
import "../../references/Constants.sol";
import "./MainchainBridgeStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title MainchainBridge
 * @dev Logic to handle deposits and withdrawl on Mainchain.
 */
abstract contract MainchainBridge is Initializable, Pausable, MainchainBridgeStorage {
    using ECVerify for bytes32;
    using SafeERC20 for IERC20;

    modifier onlyNewWithdrawal(uint256 _withdrawalId) {
        _checkNewWithdrawal(_withdrawalId);
        _;
    }

    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    function _checkNewWithdrawal(uint256 _withdrawalId) internal view {
        WithdrawalEntry storage _entry = withdrawals[_withdrawalId];
        require(_entry.owner == address(0));
    }

    function _checkAdmin() internal view {
        require(_msgSender() == admin, "onlyAdmin");
    }

    function initialize(
        address _validator,
        address _admin,
        uint256 _crossbellChainId,
        address[] calldata _mainchainTokens,
        address[] calldata _crossbellTokens,
        uint8[] calldata _crossbellTokenDecimals
    ) external initializer {
        validator = Validator(_validator);

        admin = _admin;
        crossbellChainId = _crossbellChainId;

        // map crossbell tokens
        if (_mainchainTokens.length > 0) {
            _mapTokens(_mainchainTokens, _crossbellTokens, _crossbellTokenDecimals);
        }
    }

    function pause() external whenNotPaused onlyAdmin {
        _pause();
    }

    function unpause() external whenPaused onlyAdmin {
        _unpause();
    }

    function requestDeposit(
        address _owner,
        address _token,
        uint256 _amount
    ) external virtual whenNotPaused returns (uint256 depositId) {
        MappedToken memory crossbellToken = getCrossbellToken(_token);
        require(crossbellToken.tokenAddr != address(0), "MainchainBridge: unsupported token");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        // transform token amount by different chain
        uint256 transformedAmount = _transformDepositAmount(
            _token,
            _amount,
            crossbellToken.decimals
        );

        depositId = depositCount++;
        emit RequestDeposit(depositId, _owner, crossbellToken.tokenAddr, transformedAmount);
    }

    function withdraw(
        uint256 _chainId,
        uint256 _withdrawalId,
        address _owner,
        address _token,
        uint256 _amount,
        bytes memory _signatures
    ) external virtual whenNotPaused {
        require(_chainId == block.chainid, "MainchainGatewayManager: invalid chainId");

        bytes32 _hash = keccak256(
            abi.encodePacked("withdrawERC20", _chainId, _withdrawalId, _owner, _token, _amount)
        );

        require(verifySignatures(_hash, _signatures));

        IERC20(_token).safeTransfer(_owner, _amount);

        _insertWithdrawalEntry(_withdrawalId, _owner, _token, _amount);
    }

    /**
     * @dev returns true if there is enough signatures from validators.
     */
    function verifySignatures(bytes32 _hash, bytes memory _signatures) public view returns (bool) {
        uint256 _signatureCount = _signatures.length / 66;

        uint256 _validatorCount = 0;
        address _lastSigner = address(0);

        for (uint256 i = 0; i < _signatureCount; i++) {
            address _signer = _hash.recover(_signatures, i * 66);
            if (validator.isValidator(_signer)) {
                _validatorCount++;
            }
            // Prevent duplication of signatures
            require(_signer > _lastSigner);
            _lastSigner = _signer;
        }

        return validator.checkThreshold(_validatorCount);
    }

    function _insertWithdrawalEntry(
        uint256 _withdrawalId,
        address _owner,
        address _token,
        uint256 _amount
    ) internal onlyNewWithdrawal(_withdrawalId) {
        WithdrawalEntry memory _entry = WithdrawalEntry(_owner, _token, _amount);

        withdrawals[_withdrawalId] = _entry;

        emit Withdrew(_withdrawalId, _owner, _token, _amount);
    }

    // as there are different token decimals on different chains, so the amount need to be transformed
    // this function should be overridden by subclasses
    function _transformDepositAmount(
        address token,
        uint256 amount,
        uint8 crossbellTokenDecimals
    ) internal view returns (uint256 transformedAmount) {
        uint8 decimals = IERC20Metadata(token).decimals();

        if (crossbellTokenDecimals == decimals) {
            transformedAmount = amount;
        } else if (crossbellTokenDecimals > decimals) {
            transformedAmount = amount * 10 ** (crossbellTokenDecimals - decimals);
        } else {
            transformedAmount = amount / (10 ** (decimals - crossbellTokenDecimals));
        }
    }

    function getCrossbellToken(
        address _mainchainToken
    ) public view returns (MappedToken memory _token) {
        _token = crossbellToken[_mainchainToken];
    }

    function _mapTokens(
        address[] calldata _mainchainTokens,
        address[] calldata _crossbellTokens,
        uint8[] calldata _crossbellTokenDecimals
    ) internal virtual {
        require(
            _mainchainTokens.length == _crossbellTokens.length &&
                _mainchainTokens.length == _crossbellTokenDecimals.length,
            "MainchainBridge: invalid array length"
        );

        for (uint256 _i; _i < _mainchainTokens.length; _i++) {
            crossbellToken[_mainchainTokens[_i]].tokenAddr = _crossbellTokens[_i];
            crossbellToken[_mainchainTokens[_i]].decimals = _crossbellTokenDecimals[_i];
        }

        emit TokenMapped(_mainchainTokens, _crossbellTokens, _crossbellTokenDecimals);
    }
}
