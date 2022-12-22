// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IValidator.sol";

contract Validator is IValidator {
    mapping(address => bool) validatorMap;
    address[] public validators;
    uint256 public validatorCount;

    uint256 public num;
    uint256 public denom;

    constructor(address[] memory _validators, uint256 _num, uint256 _denom) {
        validators = _validators;
        validatorCount = _validators.length;

        for (uint256 _i = 0; _i < validatorCount; _i++) {
            address _validator = _validators[_i];
            validatorMap[_validator] = true;
        }

        num = _num;
        denom = _denom;
    }

    function isValidator(address _addr) external view returns (bool) {
        return _isValidator(_addr);
    }

    function getValidators() external view returns (address[] memory _validators) {
        _validators = validators;
    }

    function checkThreshold(uint256 _voteCount) external view returns (bool) {
        return _voteCount * denom >= num * validatorCount;
    }

    function _isValidator(address _addr) internal view returns (bool) {
        return validatorMap[_addr];
    }

    function _addValidator(uint256 _id, address _validator) internal {
        require(!_isValidator(_validator));

        validators.push(_validator);
        validatorMap[_validator] = true;
        validatorCount++;

        emit ValidatorAdded(_id, _validator);
    }

    function _removeValidator(uint256 _id, address _validator) internal {
        require(_isValidator(_validator));

        uint256 _index;
        for (uint256 _i = 0; _i < validatorCount; _i++) {
            if (validators[_i] == _validator) {
                _index = _i;
                break;
            }
        }

        validatorMap[_validator] = false;
        validators[_index] = validators[validatorCount - 1];
        validators.pop();

        validatorCount--;

        emit ValidatorRemoved(_id, _validator);
    }

    function _updateQuorum(uint256 _id, uint256 _numerator, uint256 _denominator) internal {
        require(_numerator <= _denominator);
        uint256 _previousNumerator = num;
        uint256 _previousDenominator = denom;

        num = _numerator;
        denom = _denominator;

        emit ThresholdUpdated(
            _id,
            _numerator,
            _denominator,
            _previousNumerator,
            _previousDenominator
        );
    }
}
