// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract HasOperators is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event OperatorAdded(address indexed _operator);
    event OperatorRemoved(address indexed _operator);

    EnumerableSet.AddressSet operators;

    modifier onlyOperator() {
        require(operators.contains(msg.sender), "NotOperator");
        _;
    }

    function addOperators(address[] memory _addedOperators) public onlyOwner {
        address _operator;

        for (uint256 i = 0; i < _addedOperators.length; i++) {
            _operator = _addedOperators[i];
            if (operators.add(_operator)) {
                emit OperatorAdded(_operator);
            }
        }
    }

    function removeOperators(address[] memory _removedOperators) public onlyOwner {
        address _operator;

        for (uint256 i = 0; i < _removedOperators.length; i++) {
            _operator = _removedOperators[i];
            if (operators.remove(_operator)) {
                emit OperatorRemoved(_operator);
            }
        }
    }
}
