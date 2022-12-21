// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract HasOperators is Ownable {
    event OperatorAdded(address indexed _operator);
    event OperatorRemoved(address indexed _operator);

    address[] public operators;
    mapping(address => bool) public operator;

    modifier onlyOperator() {
        require(operator[msg.sender]);
        _;
    }

    function addOperators(address[] memory _addedOperators) public onlyOwner {
        address _operator;

        for (uint256 i = 0; i < _addedOperators.length; i++) {
            _operator = _addedOperators[i];

            if (!operator[_operator]) {
                operators.push(_operator);
                operator[_operator] = true;
                emit OperatorAdded(_operator);
            }
        }
    }

    function removeOperators(
        address[] memory _removedOperators
    ) public onlyOwner {
        address _operator;

        for (uint256 i = 0; i < _removedOperators.length; i++) {
            _operator = _removedOperators[i];

            if (operator[_operator]) {
                operator[_operator] = false;
                emit OperatorRemoved(_operator);
            }
        }

        uint256 j = 0;

        while (j < operators.length) {
            _operator = operators[j];

            if (!operator[_operator]) {
                operators[j] = operators[operators.length - 1];
                delete operators[operators.length - 1];
                operators.pop();
            } else {
                j++;
            }
        }
    }
}
