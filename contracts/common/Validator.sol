// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../interfaces/IValidator.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Validator is IValidator, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _validators;

    uint256 internal _requiredNumber;

    constructor(address[] memory validators, uint256 requiredNumber) {
        for (uint256 i = 0; i < validators.length; i++) {
            _addValidator(validators[i]);
        }

        _requiredNumber = requiredNumber;
    }

    function addValidators(address[] calldata validators) external onlyOwner {
        for (uint256 i; i < validators.length; i++) {
            _addValidator(validators[i]);
        }
    }

    function removeValidators(address[] calldata validators) external onlyOwner {
        for (uint256 i; i < validators.length; i++) {
            _removeValidator(validators[i]);
        }
    }

    function changeRequiredNumber(uint256 newRequiredNumber) external onlyOwner {
        require(
            newRequiredNumber <= _validators.length() && newRequiredNumber != 0,
            "InvalidRequiredNumber"
        );

        uint256 _previousRequiredNumber = _requiredNumber;

        _requiredNumber = newRequiredNumber;

        emit RequirementChanged(newRequiredNumber, _previousRequiredNumber);
    }

    function isValidator(address addr) external view returns (bool) {
        return _isValidator(addr);
    }

    function getValidators() external view returns (address[] memory validators) {
        return _validators.values();
    }

    function getRequiredNumber() external view returns (uint256) {
        return _requiredNumber;
    }

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
