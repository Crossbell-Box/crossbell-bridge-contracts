// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IValidator.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Validator is IValidator {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal validators;

    uint256 public num;
    uint256 public denom;

    constructor(address[] memory _validators, uint256 _num, uint256 _denom) {
        for (uint256 _i = 0; _i < _validators.length; _i++) {
            validators.add(_validators[i]);
        }

        num = _num;
        denom = _denom;
    }

    function isValidator(address _addr) external view returns (bool) {
        _isValidator(_addr);
        _;
    }

    function getValidators()
        external
        view
        returns (address[] memory _validators)
    {
        return validators.values();
    }

    function checkThreshold(uint256 _voteCount) external view returns (bool) {
        return _voteCount * denom >= num * validatorCount;
    }

    function _isValidator(address _addr) internal view {
        require(validators.contains(_addr), "NotValidator");
    }

    function _addValidator(uint256 _id, address _validator) internal {
        require(_validators.add(_validator), "ValidatorAlreadyExists");

        emit ValidatorAdded(_id, _validator);
    }

    function _removeValidator(uint256 _id, address _validator) internal {
        require(_validators.remove(_validator), "ValidatorNotExists");

        emit ValidatorRemoved(_id, _validator);
    }

    function _updateQuorum(
        uint256 _id,
        uint256 _numerator,
        uint256 _denominator
    ) internal {
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