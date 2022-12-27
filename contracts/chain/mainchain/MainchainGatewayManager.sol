// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../references/ECVerify.sol";
import "./MainchainGatewayStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title MainchainGatewayManager
 * @dev Logic to handle deposits and withdrawl on Mainchain.
 */
contract MainchainGatewayManager is Initializable, Pausable, MainchainGatewayStorage {
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

    /**
     * @dev Get the current chainId
     * @return chainId The current chainId
     */
    function getChainId() public view virtual returns (uint256 chainId) {
        this; // Silence state mutability warning without generating any additional byte code
        assembly {
            chainId := chainid()
        }
    }

    function depositERC20(uint256 _amount) external whenNotPaused returns (uint256) {
        return depositERC20For(msg.sender, _amount);
    }

    function depositERC20For(
        address _user,
        uint256 _amount
    ) public whenNotPaused returns (uint256) {
        address token = registry.getContract(registry.TOKEN());

        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);

        return _createDepositEntry(_user, _amount);
    }

    function withdrawERC20(
        uint256 _chainId,
        uint256 _withdrawalId,
        uint256 _amount,
        bytes memory _signatures
    ) public whenNotPaused {
        withdrawERC20For(_chainId, _withdrawalId, msg.sender, _amount, _signatures);
    }

    function withdrawERC20For(
        uint256 _chainId,
        uint256 _withdrawalId,
        address _user,
        uint256 _amount,
        bytes memory _signatures
    ) public whenNotPaused {
        require(_chainId == getChainId(), "MainchainGatewayManager: invalid chainId");

        bytes32 _hash = keccak256(
            abi.encodePacked("withdrawERC20", _chainId, _withdrawalId, _user, _amount)
        );

        require(verifySignatures(_hash, _signatures));

        address token = registry.getContract(registry.TOKEN());
        IERC20(token).safeTransfer(_user, _amount);

        _insertWithdrawalEntry(_withdrawalId, _user, _amount);
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
        uint256 _number
    ) internal returns (uint256 _depositId) {
        DepositEntry memory _entry = DepositEntry(_owner, _number);

        deposits.push(_entry);
        _depositId = depositCount++;

        emit TokenDeposited(_depositId, _owner, _number);
    }

    function _insertWithdrawalEntry(
        uint256 _withdrawalId,
        address _owner,
        uint256 _number
    ) internal onlyNewWithdrawal(_withdrawalId) {
        WithdrawalEntry memory _entry = WithdrawalEntry(_owner, _number);

        withdrawals[_withdrawalId] = _entry;

        emit TokenWithdrew(_withdrawalId, _owner, _number);
    }
}
