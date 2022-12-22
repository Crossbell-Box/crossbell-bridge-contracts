// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../../contracts/references/HasOperators.sol";
import "../helpers/utils.sol";

contract UseHasOperators is HasOperators {
    function isOperator() public onlyOperator {}
}

contract HasOperatorsTest is Test, Utils {
    address public alice = address(0x1111);
    address public bob = address(0x2222);
    address public carol = address(0x3333);

    event OperatorAdded(address indexed _operator);
    event OperatorRemoved(address indexed _operator);

    HasOperators hasOperator;
    UseHasOperators useHasOperators;
    address[] public operators = [alice, bob];
    address[] public duplicateOperators = [alice, alice];
    address[] public removeBob = [bob];

    function setUp() public {
        hasOperator = new HasOperators();
        useHasOperators = new UseHasOperators();
    }

    function testAddOperators() public {
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit OperatorAdded(alice);
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit OperatorAdded(bob);
        hasOperator.addOperators(operators);
    }

    function testAddOperatorsFail() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        hasOperator.addOperators(operators);
    }

    function testRemoveOperators() public {
        hasOperator.addOperators(operators);

        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit OperatorRemoved(alice);
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit OperatorRemoved(bob);
        hasOperator.removeOperators(operators);
    }

    function testRemoveOperatorsFail() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        hasOperator.removeOperators(operators);
    }

    function testGetOperators() public {
        address[] memory operatorsList = hasOperator.getOperators();
        assertEq(operatorsList.length, 0);

        // add duplicate operators
        hasOperator.addOperators(duplicateOperators);
        operatorsList = hasOperator.getOperators();
        assertEq(operatorsList.length, 1);
        assertEq(operatorsList[0], alice);

        // add 2 operators
        hasOperator.addOperators(operators);
        operatorsList = hasOperator.getOperators();
        assertEq(operatorsList.length, 2);
        assertEq(operatorsList[0], alice);
        assertEq(operatorsList[1], bob);

        // remove an operator
        hasOperator.removeOperators(removeBob);
        operatorsList = hasOperator.getOperators();
        assertEq(operatorsList.length, 1);
        assertEq(operatorsList[0], alice);
    }

    function testIsOperator() public {
        // add alice and bob as operators
        hasOperator.addOperators(operators);
        bool isOperator = hasOperator.isOperator(alice);
        assert(isOperator);
        isOperator = hasOperator.isOperator(bob);
        assert(isOperator);

        // carol is not operator
        isOperator = hasOperator.isOperator(carol);
        assert(!isOperator);

        // remove bob
        hasOperator.removeOperators(removeBob);
        isOperator = hasOperator.isOperator(bob);
        assert(!isOperator);
    }

    function testOnlyOperator() public {
        useHasOperators.addOperators(operators);
        vm.prank(alice);
        useHasOperators.isOperator();

        vm.prank(bob);
        useHasOperators.isOperator();
    }

    function testOnlyOperatorFail() public {
        // not operator
        vm.expectRevert(abi.encodePacked("NotOperator"));
        vm.prank(alice);
        useHasOperators.isOperator();

        // deleted operator is not operator
        hasOperator.addOperators(operators);
        hasOperator.removeOperators(removeBob);
        vm.expectRevert(abi.encodePacked("NotOperator"));
        vm.prank(bob);
        useHasOperators.isOperator();
    }
}
