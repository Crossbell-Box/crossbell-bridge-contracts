// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../references/ECVerify.sol";
import "../../references/Constants.sol";
import "./MainchainBridgeStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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

    function initialize(address _registry, address _admin) external initializer {
        registry = Registry(_registry);

        admin = _admin;
    }

    function pause() external whenNotPaused onlyAdmin {
        _pause();
    }

    function unpause() external whenPaused onlyAdmin {
        _unpause();
    }

    function updateRegistry(address _registry) external onlyAdmin {
        registry = Registry(_registry);
    }

    function requestDeposit(
        address _owner,
        uint256 _amount
    ) external virtual whenNotPaused returns (uint256 depositId) {
        address token = registry.getContract(registry.TOKEN());
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);

        return _createDepositEntry(_owner, _amount);
    }

    function withdraw(
        uint256 _chainId,
        uint256 _withdrawalId,
        address _owner,
        uint256 _amount,
        bytes memory _signatures
    ) external virtual whenNotPaused {
        require(_chainId == block.chainid, "MainchainGatewayManager: invalid chainId");

        bytes32 _hash = keccak256(
            abi.encodePacked("withdrawERC20", _chainId, _withdrawalId, _owner, _amount)
        );

        require(verifySignatures(_hash, _signatures));

        address token = registry.getContract(registry.TOKEN());
        IERC20(token).safeTransfer(_owner, _amount);

        _insertWithdrawalEntry(_withdrawalId, _owner, _amount);
    }

    /**
     * @dev returns true if there is enough signatures from validators.
     */
    function verifySignatures(bytes32 _hash, bytes memory _signatures) public view returns (bool) {
        uint256 _signatureCount = _signatures.length / 66;

        Validator _validator = Validator(registry.getContract(registry.VALIDATOR()));
        uint256 _validatorCount = 0;
        address _lastSigner = address(0);

        for (uint256 i = 0; i < _signatureCount; i++) {
            address _signer = _hash.recover(_signatures, i * 66);
            if (_validator.isValidator(_signer)) {
                _validatorCount++;
            }
            // Prevent duplication of signatures
            require(_signer > _lastSigner);
            _lastSigner = _signer;
        }

        return _validator.checkThreshold(_validatorCount);
    }

    function _createDepositEntry(
        address _owner,
        uint256 _originalAmount
    ) internal returns (uint256 _depositId) {
        _depositId = depositCount++;

        // transform token amount by different chain
        uint256 transformedAmount = _transformAmount(_originalAmount);

        emit RequestDeposit(_depositId, _owner, transformedAmount, _originalAmount);
    }

    function _insertWithdrawalEntry(
        uint256 _withdrawalId,
        address _owner,
        uint256 _amount
    ) internal onlyNewWithdrawal(_withdrawalId) {
        WithdrawalEntry memory _entry = WithdrawalEntry(_owner, _amount);

        withdrawals[_withdrawalId] = _entry;

        emit Withdrew(_withdrawalId, _owner, _amount);
    }

    // as there are different token decimals on different chains, so the amount need to be transformed
    // this function should be overridden by subclasses
    function _transformAmount(
        uint256 amount
    ) internal pure virtual returns (uint256 transformedAmount);
}
