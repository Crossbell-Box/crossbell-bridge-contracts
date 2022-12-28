// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract HasOperators is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event OperatorAdded(address indexed _operator);
    event OperatorRemoved(address indexed _operator);

    EnumerableSet.AddressSet internal operators;

    modifier onlyOperator() {
        _checkOperator();
        _;
    }

    function addOperators(address[] memory _operators) external onlyOwner {
        address _operator;

        for (uint256 i = 0; i < _operators.length; i++) {
            _operator = _operators[i];
            if (operators.add(_operator)) {
                emit OperatorAdded(_operator);
            }
        }
    }

    function removeOperators(address[] memory _operators) external onlyOwner {
        address _operator;

        for (uint256 i = 0; i < _operators.length; i++) {
            _operator = _operators[i];
            if (operators.remove(_operator)) {
                emit OperatorRemoved(_operator);
            }
        }
    }

    function getOperators() external view returns (address[] memory) {
        return operators.values();
    }

    function isOperator(address _operator) external view returns (bool) {
        return _isOperator(_operator);
    }

    function _isOperator(address _operator) internal view returns (bool) {
        return operators.contains(_operator);
    }

    function _checkOperator() internal view {
        require(_isOperator(_msgSender()), "NotOperator");
    }
}
