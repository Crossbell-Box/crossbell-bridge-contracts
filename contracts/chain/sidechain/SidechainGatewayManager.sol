// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

import "../../references/IERC20Mintable.sol";
import "../../references/ECVerify.sol";
import "./SidechainGatewayStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../references/ERC20/IERC20Mintable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";



/**
 * @title SidechainGatewayManager
 * @dev Logic to handle deposits and withdrawals on Sidechain.
 */
contract SidechainGatewayManager is Initializable, Pausable, SidechainGatewayStorage {
    using ECVerify for bytes32;
    using SafeERC20 for IERC20;

    modifier onlyValidator() {
        _checkValidator();
        _;
    }

    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    function _checkAdmin() internal view {
        require(_msgSender() == admin, "onlyAdmin");
    }

    function _checkValidator() internal view {
        require(
            _getValidator().isValidator(_msgSender()),
            "SidechainGatewayManager: sender is not validator"
        );
    }

    function initialize(
        address _registry,
        uint256[] memory _activeChainIds,
        address _admin
    ) external initializer {
        registry = Registry(_registry);

        for (uint256 i = 0; i < _activeChainIds.length; i++) {
            activeChainIds[_activeChainIds[i]] = true;
        }

        admin = _admin;
    }

    function pause() external whenNotPaused onlyAdmin {
        _pause();
    }

    function unpause() external whenPaused onlyAdmin {
        _unpause();
    }

    function addActiveChainIds(uint256[] calldata chainIds) external onlyAdmin {
        for (uint256 i = 0; i < chainIds.length; i++) {
            activeChainIds[chainIds[i]] = true;
        }
    }

    function removeActiveChainIds(uint256[] calldata chainIds) external onlyAdmin {
        for (uint256 i = 0; i < chainIds.length; i++) {
            activeChainIds[chainIds[i]] = false;
        }
    }

    function batchDepositERCTokenFor(
        uint256[] calldata _chainIds,
        uint256[] calldata _depositIds,
        address[] calldata _owners,
        uint256[] calldata _tokenNumbers
    ) external whenNotPaused onlyValidator {
        require(
            _depositIds.length == _chainIds.length &&
                _depositIds.length == _owners.length &&
                _depositIds.length == _tokenNumbers.length,
            "SidechainGatewayManager: invalid input array length"
        );

        for (uint256 _i; _i < _depositIds.length; _i++) {
            depositERCTokenFor(_chainIds[_i], _depositIds[_i], _owners[_i], _tokenNumbers[_i]);
        }
    }

    function batchSubmitWithdrawalSignatures(
        uint256[] calldata _chainIds,
        uint256[] calldata _withdrawalIds,
        bool[] calldata _shouldReplaces,
        bytes[] calldata _sigs
    ) external whenNotPaused onlyValidator {
        require(
            _withdrawalIds.length == _chainIds.length &&
                _withdrawalIds.length == _shouldReplaces.length &&
                _withdrawalIds.length == _sigs.length,
            "SidechainGatewayManager: invalid input array length"
        );

        for (uint256 _i; _i < _withdrawalIds.length; _i++) {
            submitWithdrawalSignatures(
                _chainIds[_i],
                _withdrawalIds[_i],
                _shouldReplaces[_i],
                _sigs[_i]
            );
        }
    }

    function withdrawERC20(
        uint256 _chainId,
        uint256 _amount
    ) external whenNotPaused returns (uint256) {
        return withdrawERC20For(_chainId, msg.sender, _amount);
    }

    function depositERCTokenFor(
        uint256 _chainId,
        uint256 _depositId,
        address _owner,
        uint256 _tokenNumber
    ) public whenNotPaused onlyValidator {
        bytes32 _hash = keccak256(abi.encode(_owner, _chainId, _depositId, _tokenNumber));

        Acknowledgement.Status _status = _getAcknowledgementContract().acknowledge(
            _getDepositAckChannel(),
            _chainId,
            _depositId,
            _hash,
            msg.sender
        );

        if (_status == Acknowledgement.Status.FirstApproved) {
            _depositERC20For(_owner, _tokenNumber);

            deposits[_chainId][_depositId] = DepositEntry(_owner, _tokenNumber);
            emit TokenDeposited(_chainId, _depositId, _owner, _tokenNumber);
        }
    }

    function withdrawERC20For(
        uint256 _chainId,
        address _owner,
        uint256 _amount
    ) public whenNotPaused returns (uint256) {
        require(activeChainIds[_chainId], "SidechainGatewayManager: chainId is not supported");

        address token = registry.getContract(registry.TOKEN());
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);

        return _createWithdrawalEntry(_chainId, _owner, _amount);
    }

    function submitWithdrawalSignatures(
        uint256 _chainId,
        uint256 _withdrawalId,
        bool _shouldReplace,
        bytes memory _sig
    ) public whenNotPaused onlyValidator {
        bytes memory _currentSig = withdrawalSig[_chainId][_withdrawalId][msg.sender];

        bool _alreadyHasSig = _currentSig.length != 0;

        if (!_shouldReplace && _alreadyHasSig) {
            return;
        }

        withdrawalSig[_chainId][_withdrawalId][msg.sender] = _sig;
        if (!_alreadyHasSig) {
            withdrawalSigners[_chainId][_withdrawalId].push(msg.sender);
        }
    }

    /**
     * Request signature again, in case the withdrawer didn't submit to mainchain in time and the set of the validator
     * has changed. Later on this should require some penaties, e.g some money.
     */
    function requestSignatureAgain(uint256 _chainId, uint256 _withdrawalId) public whenNotPaused {
        WithdrawalEntry memory _entry = withdrawals[_chainId][_withdrawalId];

        require(_entry.owner == msg.sender, "SidechainGatewayManager: sender is not entry owner");

        emit RequestTokenWithdrawalSigAgain(
            _chainId,
            _withdrawalId,
            _entry.owner,
            _entry.tokenNumber
        );
    }

    function getWithdrawalSigners(
        uint256 _chainId,
        uint256 _withdrawalId
    ) public view returns (address[] memory) {
        return withdrawalSigners[_chainId][_withdrawalId];
    }

    function getWithdrawalSignatures(
        uint256 _chainId,
        uint256 _withdrawalId
    ) public view returns (address[] memory _signers, bytes[] memory _sigs) {
        _signers = getWithdrawalSigners(_chainId, _withdrawalId);
        _sigs = new bytes[](_signers.length);
        for (uint256 _i = 0; _i < _signers.length; _i++) {
            _sigs[_i] = withdrawalSig[_chainId][_withdrawalId][_signers[_i]];
        }
    }

    function _depositERC20For(address _owner, uint256 _amount) internal {
        address token = registry.getContract(registry.TOKEN());

        uint256 _gatewayBalance = IERC20(token).balanceOf(address(this));
        if (_gatewayBalance < _amount) {
            require(
                IERC20Mintable(token).mint(address(this), _amount - _gatewayBalance),
                "SidechainGatewayManager: Minting ERC20 to gateway failed"
            );
        }

        IERC20(token).safeTransfer(_owner, _amount);
    }

    function _alreadyReleased(uint256 _chainId, uint256 _depositId) internal view returns (bool) {
        return deposits[_chainId][_depositId].owner != address(0);
    }

    function _createWithdrawalEntry(
        uint256 _chainId,
        address _owner,
        uint256 _number
    ) internal returns (uint256 _withdrawalId) {
        WithdrawalEntry memory _entry = WithdrawalEntry(_chainId, _owner, _number);
        withdrawals[_chainId].push(_entry);

        _withdrawalId = withdrawalCounts[_chainId];
        withdrawalCounts[_chainId]++;

        // save user withdrawal history
        userWithdrawals[_owner][_chainId].push(_withdrawalId);

        emit TokenWithdrew(_chainId, _withdrawalId, _owner, _number);
    }
}
