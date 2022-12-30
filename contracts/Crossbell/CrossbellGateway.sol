// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

import "../interfaces/IERC20Mintable.sol";
import "../libraries/ECVerify.sol";
import "./CrossbellGatewayStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title SidechainBridge
 * @dev Logic to handle deposits and withdrawals on Sidechain.
 */
abstract contract CrossbellGateway is Initializable, Pausable, CrossbellGatewayStorage {
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
        require(_msgSender() == _admin, "onlyAdmin");
    }

    function _checkValidator() internal view {
        require(
            _validator.isValidator(_msgSender()),
            "SidechainGatewayManager: sender is not validator"
        );
    }

    function initialize(
        address validator,
        address acknowledgement,
        address admin
    ) external initializer {
        _validator = Validator(validator);
        _acknowledgement = Acknowledgement(acknowledgement);
        _admin = admin;
    }

    function pause() external whenNotPaused onlyAdmin {
        _pause();
    }

    function unpause() external whenPaused onlyAdmin {
        _unpause();
    }

    function batchAckDeposit(
        uint256[] calldata chainIds,
        uint256[] calldata depositIds,
        address[] calldata owners,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external whenNotPaused onlyValidator {
        require(
            depositIds.length == chainIds.length &&
                depositIds.length == owners.length &&
                depositIds.length == amounts.length,
            "SidechainGatewayManager: invalid input array length"
        );

        for (uint256 i; i < depositIds.length; i++) {
            _ackDeposit(chainIds[i], depositIds[i], owners[i], tokens[i], amounts[i]);
        }
    }

    function batchSubmitWithdrawalSignatures(
        uint256[] calldata chainIds,
        uint256[] calldata withdrawalIds,
        bool[] calldata shouldReplaces,
        bytes[] calldata sigs
    ) external whenNotPaused onlyValidator {
        require(
            withdrawalIds.length == chainIds.length &&
                withdrawalIds.length == shouldReplaces.length &&
                withdrawalIds.length == sigs.length,
            "SidechainGatewayManager: invalid input array length"
        );

        for (uint256 i; i < withdrawalIds.length; i++) {
            submitWithdrawalSignatures(chainIds[i], withdrawalIds[i], shouldReplaces[i], sigs[i]);
        }
    }

    function ackDeposit(
        uint256 chainId,
        uint256 depositId,
        address owner,
        address token,
        uint256 amount
    ) external {
        _ackDeposit(chainId, depositId, owner, token, amount);
    }

    function _ackDeposit(
        uint256 chainId,
        uint256 depositId,
        address owner,
        address token,
        uint256 amount
    ) internal whenNotPaused onlyValidator {
        bytes32 hash = keccak256(abi.encode(owner, chainId, depositId, token, amount));

        Acknowledgement.Status status = _acknowledgement.acknowledge(
            _getDepositAckChannel(),
            chainId,
            depositId,
            hash,
            msg.sender
        );

        if (status == Acknowledgement.Status.FirstApproved) {
            _depositFor(owner, token, amount);

            _deposits[chainId][depositId] = DepositEntry(chainId, owner, token, amount);
            emit Deposited(chainId, depositId, owner, token, amount);
        }

        emit AckDeposit(chainId, depositId, owner, token, amount);
    }

    function requestWithdrawal(
        uint256 chainId,
        address owner,
        address token,
        uint256 amount
    ) public whenNotPaused returns (uint256 withdrawId) {
        MappedToken memory mainchainToken = getMainchainToken(chainId, token);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // transform token amount by different chain
        uint256 transformedAmount = _transformWithdrawalAmount(
            token,
            amount,
            mainchainToken.decimals
        );

        withdrawId = _withdrawalCounts[chainId]++;
        _withdrawals[chainId][withdrawId] = WithdrawalEntry(
            chainId,
            owner,
            token,
            transformedAmount,
            amount
        );

        emit RequestWithdrawal(chainId, withdrawId, owner, token, transformedAmount, amount);
    }

    function _transformWithdrawalAmount(
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

    function getMainchainToken(
        uint256 chainId,
        address crossbellToken
    ) public view returns (MappedToken memory token) {
        token = _mainchainToken[crossbellToken][chainId];
    }

    function submitWithdrawalSignatures(
        uint256 chainId,
        uint256 withdrawalId,
        bool shouldReplace,
        bytes memory sig
    ) public whenNotPaused onlyValidator {
        bytes memory currentSig = withdrawalSig[chainId][withdrawalId][msg.sender];

        bool alreadyHasSig = currentSig.length != 0;

        if (!shouldReplace && alreadyHasSig) {
            return;
        }

        withdrawalSig[chainId][withdrawalId][msg.sender] = sig;
        if (!alreadyHasSig) {
            _withdrawalSigners[chainId][withdrawalId].push(msg.sender);
        }
    }

    /**
     * Request signature again, in case the withdrawer didn't submit to mainchain in time and the set of the validator
     * has changed. Later on this should require some penaties, e.g some money.
     */
    function requestSignatureAgain(uint256 chainId, uint256 withdrawalId) public whenNotPaused {
        WithdrawalEntry memory entry = _withdrawals[chainId][withdrawalId];

        require(entry.owner == msg.sender, "SidechainGatewayManager: sender is not entry owner");

        emit RequestTokenWithdrawalSigAgain(
            chainId,
            withdrawalId,
            entry.owner,
            entry.token,
            entry.tokenNumber
        );
    }

    function getWithdrawalSigners(
        uint256 chainId,
        uint256 withdrawalId
    ) public view returns (address[] memory) {
        return _withdrawalSigners[chainId][withdrawalId];
    }

    function getWithdrawalSignatures(
        uint256 chainId,
        uint256 withdrawalId
    ) public view returns (address[] memory signers, bytes[] memory sigs) {
        signers = getWithdrawalSigners(chainId, withdrawalId);
        sigs = new bytes[](signers.length);
        for (uint256 i = 0; i < signers.length; i++) {
            sigs[i] = withdrawalSig[chainId][withdrawalId][signers[i]];
        }
    }

    function _depositFor(address owner, address token, uint256 amount) internal {
        uint256 gatewayBalance = IERC20(token).balanceOf(address(this));
        if (gatewayBalance < amount) {
            IERC20Mintable(token).mint(address(this), amount - gatewayBalance);
        }

        IERC20(token).safeTransfer(owner, amount);
    }

    function _getDepositAckChannel() internal view returns (string memory) {
        return _acknowledgement.DEPOSIT_CHANNEL();
    }

    function _getWithdrawalAckChannel() internal view returns (string memory) {
        return _acknowledgement.WITHDRAWAL_CHANNEL();
    }
}
