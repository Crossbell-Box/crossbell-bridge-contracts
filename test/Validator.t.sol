// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "./helpers/utils.sol";
import "../contracts/Validator.sol";

contract ValidatorTest is Test, Utils {
    address internal constant alice = address(0x111);
    address internal constant bob = address(0x222);
    address internal constant carol = address(0x333);
    address internal constant dave = address(0x444);
    address internal constant eve = address(0x555);
    address internal constant frank = address(0x666);

    event ValidatorAdded(address indexed validator);
    event ValidatorRemoved(address indexed validator);
    event RequirementChanged(uint256 indexed requirement, uint256 indexed previousRequired);

    Validator internal validator;

    function setUp() public {
        // init [alice,bob,carol] as validators, with requiredNumber 2
        validator = new Validator(array(alice, bob, carol), 2);
    }

    function testAddValidators() public {
        address[] memory newValidators = array(dave, eve);
        // expect events
        expectEmit(CheckAll);
        emit ValidatorAdded(dave);
        expectEmit(CheckAll);
        emit ValidatorAdded(eve);
        // add validators
        validator.addValidators(newValidators);

        // check validators
        for (uint256 i = 0; i < newValidators.length; i++) {
            assertTrue(validator.isValidator(newValidators[i]));
        }

        // frank is not operator
        assertFalse(validator.isValidator(frank));
    }

    function testAddValidatorsFail() public {
        // check if alice is a validator
        assertTrue(validator.isValidator(alice));

        // add an existing validator
        vm.expectRevert(abi.encodePacked("ValidatorAlreadyExists"));
        validator.addValidators(array(alice));

        // alice is not owner of validator contract
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        vm.prank(alice);
        validator.addValidators(array(alice));

        // check if alice is a validator
        assertTrue(validator.isValidator(alice));
    }

    function testRemoveValidators() public {
        address[] memory validators = array(dave, eve);
        validator.addValidators(validators);

        // expect events
        expectEmit(CheckAll);
        emit ValidatorRemoved(dave);
        expectEmit(CheckAll);
        emit ValidatorRemoved(eve);
        // remove validators
        validator.removeValidators(validators);

        // check validators
        for (uint256 i = 0; i < validators.length; i++) {
            assertFalse(validator.isValidator(validators[i]));
        }
    }

    function testRemoveValidatorsFail() public {
        // check if dave is a validator
        assertFalse(validator.isValidator(dave));

        // remove a nonexistent validator
        vm.expectRevert(abi.encodePacked("ValidatorNotExists"));
        validator.removeValidators(array(dave));

        // alice is not owner of validator contract
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        vm.prank(alice);
        validator.removeValidators(array(dave));

        // check if dave is a validator
        assertFalse(validator.isValidator(dave));
    }

    function testChangeRequiredNumber() public {
        // check current requireNumber
        assertEq(validator.getRequiredNumber(), 2);

        // expect events
        expectEmit(CheckAll);
        emit RequirementChanged(3, 2);
        // change new requiredNumber as 3
        validator.changeRequiredNumber(3);

        // check new requiredNumber
        assertEq(validator.getRequiredNumber(), 3);
    }

    function testChangeRequiredNumberFail() public {
        // check current requireNumber
        assertEq(validator.getRequiredNumber(), 2);

        // invalid requireNumber
        vm.expectRevert(abi.encodePacked("InvalidRequiredNumber"));
        validator.changeRequiredNumber(0);

        // invalid requireNumber
        vm.expectRevert(abi.encodePacked("InvalidRequiredNumber"));
        validator.changeRequiredNumber(4);

        // alice is not owner of validator contract
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        vm.prank(alice);
        validator.changeRequiredNumber(3);

        // check current requireNumber
        assertEq(validator.getRequiredNumber(), 2);
    }

    function testIsValidator() public {
        assertTrue(validator.isValidator(alice));

        // remove alice
        validator.removeValidators(array(alice));
        assertFalse(validator.isValidator(alice));

        // add alice and dave
        validator.addValidators(array(alice, dave));
        assertTrue(validator.isValidator(alice));
        assertTrue(validator.isValidator(dave));
    }

    function testGetValidator() public {
        assertEq(validator.getValidators(), array(alice, bob, carol));

        validator.addValidators(array(dave));
        assertEq(validator.getValidators(), array(alice, bob, carol, dave));

        validator.removeValidators(array(bob));
        assertEq(validator.getValidators(), array(alice, dave, carol));
    }

    function testCheckThreshold() public {
        // default requireNumber is 2
        assertFalse(validator.checkThreshold(1));
        assertTrue(validator.checkThreshold(2));
        assertTrue(validator.checkThreshold(3));
    }
}
