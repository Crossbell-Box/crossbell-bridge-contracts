// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IValidator.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Validator is IValidator {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal validators;

    uint256 public required;

    modifier validRequirement(uint _required) {
        require(_required <= validators.length() && _required != 0, "invalid required number");
        _;
    }

    constructor(address[] memory _validators, uint256 _required) {
        for (uint256 _i = 0; _i < _validators.length; _i++) {
            validators.add(_validators[_i]);
        }

        required = _required;
    }

    function isValidator(address _addr) external view returns (bool) {
        return _isValidator(_addr);
    }

    function getValidators() external view returns (address[] memory _validators) {
        return validators.values();
    }

    function checkThreshold(uint256 _voteCount) external view returns (bool) {
        return _voteCount >= required;
    }

    function _isValidator(address _addr) internal view returns (bool) {
        return validators.contains(_addr);
    }

    function _addValidator(uint256 _id, address _validator) internal {
        require(validators.add(_validator), "ValidatorAlreadyExists");

        emit ValidatorAdded(_id, _validator);
    }

    function _removeValidator(uint256 _id, address _validator) internal {
        require(validators.remove(_validator), "ValidatorNotExists");

        emit ValidatorRemoved(_id, _validator);
    }

    function _changeRequirement(
        uint256 _id,
        uint256 _required
    ) internal validRequirement(_required) {
        uint256 _previousRequired = required;

        required = _required;

        emit RequirementChanged(_id, _required, _previousRequired);
    }
}
