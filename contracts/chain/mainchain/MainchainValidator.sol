// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../common/Validator.sol";

/**
 * @title Validator
 * @dev Simple validator contract
 */
contract MainchainValidator is Validator, Ownable {
    uint256 nonce;

    constructor(
        address[] memory _validators,
        uint256 _num,
        uint256 _denom
    ) Validator(_validators, _num, _denom) {}

    function addValidators(address[] calldata _validators) external onlyOwner {
        for (uint256 _i; _i < _validators.length; ++_i) {
            _addValidator(nonce++, _validators[_i]);
        }
    }

    function removeValidator(address _validator) external onlyOwner {
        _removeValidator(nonce++, _validator);
    }

    function updateQuorum(uint256 _numerator, uint256 _denominator) external onlyOwner {
        _updateQuorum(nonce++, _numerator, _denominator);
    }
}
