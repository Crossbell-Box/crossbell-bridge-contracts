// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "./helpers/utils.sol";
import "../contracts/token/MiraToken.sol";

contract MiraTokenTest is Test {
    bytes32 public constant BLOCK_ROLE = keccak256("BLOCK_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    address internal constant alice = address(0x111);
    address internal constant bob = address(0x222);

    string internal constant name = "Mira Token";
    string internal constant symbol = "MIRA";

    MiraToken public token;

    function setUp() public {
        token = new MiraToken(name, symbol);
    }

    function testSetupState() public {
        string memory name_ = token.name();
        string memory symbol_ = token.symbol();
        assertEq(_compare(name, name_), true);
        assertEq(_compare(symbol, symbol_), true);
        assertEq(token.decimals(), uint8(18));
        assertEq(token.totalSupply(), 0);

        // check role
        assertEq(token.hasRole(DEFAULT_ADMIN_ROLE, address(this)), true);
        assertEq(token.getRoleMemberCount(DEFAULT_ADMIN_ROLE), 1);
        assertEq(token.getRoleMember(DEFAULT_ADMIN_ROLE, 0), address(this));
    }

    function testGrantRole() public {
        // grant `DEFAULT_ADMIN_ROLE` to bob
        token.grantRole(DEFAULT_ADMIN_ROLE, bob);
        assertEq(token.hasRole(DEFAULT_ADMIN_ROLE, bob), true);
        assertEq(token.getRoleMemberCount(DEFAULT_ADMIN_ROLE), 2);
        assertEq(token.getRoleMember(DEFAULT_ADMIN_ROLE, 1), bob);

        // grant `BLOCK_ROLE` to bob
        token.grantRole(BLOCK_ROLE, bob);
        assertEq(token.hasRole(BLOCK_ROLE, bob), true);
        assertEq(token.getRoleMemberCount(BLOCK_ROLE), 1);
        assertEq(token.getRoleMember(BLOCK_ROLE, 0), bob);
    }

    function testGrantRoleFail() public {
        // case 1: caller has no `DEFAULT_ADMIN_ROLE`
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(alice),
                " is missing role ",
                Strings.toHexString(uint256(DEFAULT_ADMIN_ROLE), 32)
            )
        );
        vm.prank(alice);
        token.grantRole(DEFAULT_ADMIN_ROLE, bob);
        // check role
        assertEq(token.hasRole(DEFAULT_ADMIN_ROLE, bob), false);

        // case 2: caller has no `DEFAULT_ADMIN_ROLE`
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(alice),
                " is missing role ",
                Strings.toHexString(uint256(DEFAULT_ADMIN_ROLE), 32)
            )
        );
        vm.prank(alice);
        token.grantRole(BLOCK_ROLE, bob);
        // check role
        assertEq(token.hasRole(BLOCK_ROLE, bob), false);
    }

    function testRenounceRole() public {
        // grant `DEFAULT_ADMIN_ROLE` to bob
        token.grantRole(DEFAULT_ADMIN_ROLE, bob);
        // bob renounce `DEFAULT_ADMIN_ROLE`
        vm.prank(bob);
        token.renounceRole(DEFAULT_ADMIN_ROLE, bob);
        assertEq(token.hasRole(DEFAULT_ADMIN_ROLE, bob), false);
        assertEq(token.getRoleMemberCount(DEFAULT_ADMIN_ROLE), 1);

        // grant `DEFAULT_ADMIN_ROLE` to alice
        token.grantRole(DEFAULT_ADMIN_ROLE, alice);
    }

    function testRenounceRoleFail() public {
        // grant role to bob
        token.grantRole(BLOCK_ROLE, bob);

        // renounce role
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(bob),
                " is missing role ",
                Strings.toHexString(uint256(DEFAULT_ADMIN_ROLE), 32)
            )
        );
        vm.prank(bob);
        token.renounceRole(BLOCK_ROLE, bob);
        assertEq(token.hasRole(BLOCK_ROLE, bob), true);
    }

    function testRevokeRole() public {
        // grant role to bob
        token.grantRole(BLOCK_ROLE, bob);
        assertEq(token.hasRole(BLOCK_ROLE, bob), true);

        // renounce role
        token.revokeRole(BLOCK_ROLE, bob);
        assertEq(token.hasRole(BLOCK_ROLE, bob), false);
        assertEq(token.getRoleMemberCount(BLOCK_ROLE), 0);
    }

    function testRevokeRoleFail() public {
        // grant role to bob
        token.grantRole(BLOCK_ROLE, bob);
        assertEq(token.hasRole(BLOCK_ROLE, bob), true);

        // renounce role
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(bob),
                " is missing role ",
                Strings.toHexString(uint256(DEFAULT_ADMIN_ROLE), 32)
            )
        );
        vm.prank(bob);
        token.revokeRole(BLOCK_ROLE, bob);
        assertEq(token.hasRole(BLOCK_ROLE, bob), true);
    }

    function testMint() public {}

    function testMintFail() public {}

    function testTransfer() public {}

    function testTransferFail() public {}

    function _compare(string memory str1, string memory str2) internal pure returns (bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }
}
