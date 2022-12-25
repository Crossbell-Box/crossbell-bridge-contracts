// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../../contracts/mocks/HasOperatorsMock.sol";
import "../helpers/utils.sol";

contract HasOperatorsTest is Test, Utils {
    address public alice = address(0x1111);
    address public bob = address(0x2222);
    address public carol = address(0x3333);

    event OperatorAdded(address indexed _operator);
    event OperatorRemoved(address indexed _operator);

    HasOperatorsMock mock;

    function setUp() public {
        mock = new HasOperatorsMock();
    }

    function testAddOperators() public {
        address[] memory newOperators = toArray(alice, bob);
        // expect events
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit OperatorAdded(alice);
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit OperatorAdded(bob);
        // add operators
        mock.addOperators(newOperators);

        // check operators
        assertEq(mock.getOperators(), newOperators);

        // check isOperator
        for (uint256 i = 0; i < newOperators.length; i++) {
            assertTrue(mock.isOperator(newOperators[i]));
        }

        // carol is not operator
        assertFalse(mock.isOperator(carol));
    }

    function testAddOperatorsFail() public {
        address[] memory newOperators = toArray(alice, bob);

        vm.prank(alice);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        mock.addOperators(newOperators);

        // check operators
        assertEq(mock.getOperators().length, 0);

        // check isOperator
        for (uint256 i = 0; i < newOperators.length; i++) {
            assertFalse(mock.isOperator(newOperators[i]));
        }
    }

    function testRemoveOperators() public {
        address[] memory newOperators = toArray(alice, bob);
        mock.addOperators(newOperators);
        // expect events
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit OperatorRemoved(alice);
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit OperatorRemoved(bob);
        // remove operators
        mock.removeOperators(newOperators);

        // check operators
        assertEq(mock.getOperators().length, 0);

        // check isOperator
        for (uint256 i = 0; i < newOperators.length; i++) {
            assertFalse(mock.isOperator(newOperators[i]));
        }
    }

    function testRemoveOperatorsFail() public {
        address[] memory _operators = toArray(alice, bob, carol);

        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        vm.prank(alice);
        mock.removeOperators(_operators);

        // add operators, and then fail to remove operators
        mock.addOperators(_operators);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        vm.prank(alice);
        mock.removeOperators(_operators);
        // check operators
        address[] memory operators = mock.getOperators();
        assertEq(operators, _operators);
        assertEq(mock.getOperators().length, 3);
    }

    function testGetOperators() public {
        assertEq(mock.getOperators().length, 0);

        // add duplicate operators
        address[] memory duplicateOperators = toArray(alice, alice);
        mock.addOperators(duplicateOperators);
        address[] memory operators = mock.getOperators();
        assertEq(operators.length, 1);
        assertEq(operators[0], alice);

        // add 2 operators alice and bob
        address[] memory newOperators = toArray(alice, bob, carol);
        mock.addOperators(newOperators);
        operators = mock.getOperators();
        assertEq(operators.length, 3);
        assertEq(operators[0], alice);
        assertEq(operators[1], bob);
        assertEq(operators[2], carol);

        // remove bob
        mock.removeOperators(toArray(bob));
        operators = mock.getOperators();
        assertEq(operators.length, 2);
        assertEq(operators[0], alice);
        assertEq(operators[1], carol);

        // remove alice
        mock.removeOperators(toArray(alice));
        operators = mock.getOperators();
        assertEq(operators.length, 1);
        assertEq(operators[0], carol);

        // remove carol
        mock.removeOperators(toArray(carol));
        operators = mock.getOperators();
        assertEq(operators.length, 0);
    }

    function testIsOperator() public {
        // add alice and bob as operators
        address[] memory newOperators = toArray(alice, bob);
        mock.addOperators(newOperators);
        assertTrue(mock.isOperator(alice));
        assertTrue(mock.isOperator(bob));

        // carol is not operator
        assertFalse(mock.isOperator(carol));

        // remove bob
        mock.removeOperators(toArray(bob));
        assertFalse(mock.isOperator(bob));
        assertTrue(mock.isOperator(alice));
    }

    function testOnlyOperator() public {
        address[] memory newOperators = toArray(alice);
        mock.addOperators(newOperators);

        vm.prank(alice);
        mock.doStuff();
        assertEq(mock.count(), 1);
    }

    function testOnlyOperatorFail() public {
        // not operator
        vm.expectRevert(abi.encodePacked("NotOperator"));
        vm.prank(alice);
        mock.doStuff();

        address[] memory newOperators = toArray(alice, bob);
        mock.addOperators(newOperators);
        mock.removeOperators(newOperators);

        // deleted operator is not operator
        vm.expectRevert(abi.encodePacked("NotOperator"));
        vm.prank(bob);
        mock.doStuff();
        assertEq(mock.count(), 0);
    }
}
