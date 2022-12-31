// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract HasOperators is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);

    EnumerableSet.AddressSet internal _operators;

    modifier onlyOperator() {
        _checkOperator();
        _;
    }

    function addOperators(address[] calldata operators) external onlyOwner {
        for (uint256 i = 0; i < operators.length; i++) {
            address op = operators[i];
            if (_operators.add(op)) {
                emit OperatorAdded(op);
            }
        }
    }

    function removeOperators(address[] calldata operators) external onlyOwner {
        for (uint256 i = 0; i < operators.length; i++) {
            address op = operators[i];
            if (_operators.remove(op)) {
                emit OperatorRemoved(op);
            }
        }
    }

    function getOperators() external view returns (address[] memory) {
        return _operators.values();
    }

    function isOperator(address _operator) external view returns (bool) {
        return _isOperator(_operator);
    }

    function _isOperator(address _operator) internal view returns (bool) {
        return _operators.contains(_operator);
    }

    function _checkOperator() internal view {
        require(_isOperator(_msgSender()), "NotOperator");
    }
}
