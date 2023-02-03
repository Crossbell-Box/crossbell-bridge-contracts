// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "./helpers/Utils.sol";
import "../contracts/Validator.sol";

contract ValidatorTest is Test, Utils {
    address public constant alice = address(0x111);
    address public constant bob = address(0x222);
    address public constant carol = address(0x333);
    address public constant dave = address(0x444);
    address public constant eve = address(0x555);
    address public constant frank = address(0x666);

    Validator internal _validator;

    // events
    event ValidatorAdded(address indexed validator);
    event ValidatorRemoved(address indexed validator);
    event RequirementChanged(uint256 indexed requirement, uint256 indexed previousRequired);

    /* solhint-disable comprehensive-interface */
    function setUp() public {
        // init [alice,bob,carol] as validators, with requiredNumber 2
        _validator = new Validator(array(alice, bob, carol), 2);
    }

    function testAddValidators() public {
        address[] memory newValidators = array(dave, eve);
        // expect events
        expectEmit(CheckAll);
        emit ValidatorAdded(dave);
        expectEmit(CheckAll);
        emit ValidatorAdded(eve);
        // add validators
        _validator.addValidators(newValidators);

        // check validators
        for (uint256 i = 0; i < newValidators.length; i++) {
            assertTrue(_validator.isValidator(newValidators[i]));
        }

        // frank is not operator
        assertFalse(_validator.isValidator(frank));
    }

    function testAddValidatorsFail() public {
        // check if alice is a validator
        assertTrue(_validator.isValidator(alice));

        // add an existing validator
        vm.expectRevert(abi.encodePacked("ValidatorAlreadyExists"));
        _validator.addValidators(array(alice));

        // alice is not owner of validator contract
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        vm.prank(alice);
        _validator.addValidators(array(alice));

        // check if alice is a validator
        assertTrue(_validator.isValidator(alice));
    }

    function testRemoveValidators() public {
        address[] memory validators = array(dave, eve);
        _validator.addValidators(validators);

        // expect events
        expectEmit(CheckAll);
        emit ValidatorRemoved(dave);
        expectEmit(CheckAll);
        emit ValidatorRemoved(eve);
        // remove validators
        _validator.removeValidators(validators);

        // check validators
        for (uint256 i = 0; i < validators.length; i++) {
            assertFalse(_validator.isValidator(validators[i]));
        }
    }

    function testRemoveValidatorsFail() public {
        // check if dave is a validator
        assertFalse(_validator.isValidator(dave));

        // remove a nonexistent validator
        vm.expectRevert(abi.encodePacked("ValidatorNotExists"));
        _validator.removeValidators(array(dave));

        // alice is not owner of validator contract
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        vm.prank(alice);
        _validator.removeValidators(array(dave));

        // check if dave is a validator
        assertFalse(_validator.isValidator(dave));
    }

    function testChangeRequiredNumber() public {
        // check current requireNumber
        assertEq(_validator.getRequiredNumber(), 2);

        // expect events
        expectEmit(CheckAll);
        emit RequirementChanged(3, 2);
        // change new requiredNumber as 3
        _validator.changeRequiredNumber(3);

        // check new requiredNumber
        assertEq(_validator.getRequiredNumber(), 3);
    }

    function testChangeRequiredNumberFail() public {
        // check current requireNumber
        assertEq(_validator.getRequiredNumber(), 2);

        // invalid requireNumber
        vm.expectRevert(abi.encodePacked("InvalidRequiredNumber"));
        _validator.changeRequiredNumber(0);

        // invalid requireNumber
        vm.expectRevert(abi.encodePacked("InvalidRequiredNumber"));
        _validator.changeRequiredNumber(4);

        // alice is not owner of validator contract
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        vm.prank(alice);
        _validator.changeRequiredNumber(3);

        // check current requireNumber
        assertEq(_validator.getRequiredNumber(), 2);
    }

    function testIsValidator() public {
        assertTrue(_validator.isValidator(alice));

        // remove alice
        _validator.removeValidators(array(alice));
        assertFalse(_validator.isValidator(alice));

        // add alice and dave
        _validator.addValidators(array(alice, dave));
        assertTrue(_validator.isValidator(alice));
        assertTrue(_validator.isValidator(dave));
    }

    function testGetValidator() public {
        assertEq(_validator.getValidators(), array(alice, bob, carol));

        _validator.addValidators(array(dave));
        assertEq(_validator.getValidators(), array(alice, bob, carol, dave));

        _validator.removeValidators(array(bob));
        assertEq(_validator.getValidators(), array(alice, dave, carol));
    }

    function testCheckThreshold() public {
        // default requireNumber is 2
        assertFalse(_validator.checkThreshold(1));
        assertTrue(_validator.checkThreshold(2));
        assertTrue(_validator.checkThreshold(3));
    }
}
