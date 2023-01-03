// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IValidator.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Validator is IValidator, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _validators;

    uint256 internal _requiredNumber;

    /**
     * @notice Initializes the validators and required number.
     * @param validators Validators to set.
     * @param requiredNumber Required number to set.
     */
    constructor(address[] memory validators, uint256 requiredNumber) {
        for (uint256 i = 0; i < validators.length; i++) {
            _addValidator(validators[i]);
        }

        _requiredNumber = requiredNumber;
    }

    /// @inheritdoc IValidator
    function addValidators(address[] calldata validators) external onlyOwner {
        for (uint256 i = 0; i < validators.length; i++) {
            _addValidator(validators[i]);
        }
    }

    /// @inheritdoc IValidator
    function removeValidators(address[] calldata validators) external onlyOwner {
        for (uint256 i = 0; i < validators.length; i++) {
            _removeValidator(validators[i]);
        }
    }

    /// @inheritdoc IValidator
    function changeRequiredNumber(uint256 newRequiredNumber) external onlyOwner {
        require(
            newRequiredNumber <= _validators.length() && newRequiredNumber != 0,
            "InvalidRequiredNumber"
        );

        uint256 _previousRequiredNumber = _requiredNumber;

        _requiredNumber = newRequiredNumber;

        emit RequirementChanged(newRequiredNumber, _previousRequiredNumber);
    }

    /// @inheritdoc IValidator
    function isValidator(address addr) external view returns (bool) {
        return _isValidator(addr);
    }

    /// @inheritdoc IValidator
    function getValidators() external view returns (address[] memory validators) {
        return _validators.values();
    }

    /// @inheritdoc IValidator
    function getRequiredNumber() external view returns (uint256) {
        return _requiredNumber;
    }

    /// @inheritdoc IValidator
    function checkThreshold(uint256 voteCount) external view returns (bool) {
        return voteCount >= _requiredNumber;
    }

    function _isValidator(address addr) internal view returns (bool) {
        return _validators.contains(addr);
    }

    function _addValidator(address validator) internal {
        require(_validators.add(validator), "ValidatorAlreadyExists");

        emit ValidatorAdded(validator);
    }

    function _removeValidator(address validator) internal {
        require(_validators.remove(validator), "ValidatorNotExists");

        emit ValidatorRemoved(validator);
    }
}
