// SPDX-License-Identifier: MIT
// solhint-disable comprehensive-interface
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../helpers/Utils.sol";
import "../helpers/SigUtils.sol";
import "../../contracts/token/MiraToken.sol";

contract MiraTokenTest is Test {
    bytes32 public constant BLOCK_ROLE = keccak256("BLOCK_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    address public constant alice = address(0x111);
    address public constant bob = address(0x222);
    address public constant carol = address(0x333);

    string public constant name = "Mira Token";
    string public constant symbol = "MIRA";

    uint256 public ownerPrivateKey;
    uint256 public spenderPrivateKey;
    address public owner;
    address public spender;
    SigUtils public sigUtils;

    MiraToken public token;

    function setUp() public {
        // deploy MiraToken
        token = new MiraToken(name, symbol);

        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;
        owner = vm.addr(ownerPrivateKey);
        spender = vm.addr(spenderPrivateKey);
        // deploy SigUtils
        sigUtils = new SigUtils(token.DOMAIN_SEPARATOR());
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
        // bob renounce `DEFAULT_ADMIN_ROLE` for himself
        vm.prank(bob);
        token.renounceRole(DEFAULT_ADMIN_ROLE, bob);
        assertEq(token.hasRole(DEFAULT_ADMIN_ROLE, bob), false);
        assertEq(token.getRoleMemberCount(DEFAULT_ADMIN_ROLE), 1);
    }

    function testRenounceRoleFail() public {
        // grant role to bob
        token.grantRole(BLOCK_ROLE, bob);

        // renounce role
        // bob can't renounce `BLOCK_ROLE' for himself
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

        // admin can't renounce `BLOCK_ROLE' for bob
        vm.expectRevert("AccessControl: can only renounce roles for self");
        token.renounceRole(BLOCK_ROLE, bob);

        // check role
        assertEq(token.hasRole(BLOCK_ROLE, bob), true);
    }

    function testRevokeRole() public {
        // grant role to bob
        token.grantRole(BLOCK_ROLE, bob);
        assertEq(token.hasRole(BLOCK_ROLE, bob), true);

        // renounce role
        token.revokeRole(BLOCK_ROLE, bob);

        // check role
        assertEq(token.hasRole(BLOCK_ROLE, bob), false);
        assertEq(token.getRoleMemberCount(BLOCK_ROLE), 0);
    }

    function testRevokeRoleFail() public {
        // grant role to bob
        token.grantRole(BLOCK_ROLE, bob);
        assertEq(token.hasRole(BLOCK_ROLE, bob), true);

        // revoke role
        // bob has no `DEFAULT_ADMIN_ROLE`, so he can't revoke role
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

        // check role
        assertEq(token.hasRole(BLOCK_ROLE, bob), true);
    }

    function testMint() public {
        uint256 amount = 1 ether;

        // mint tokens
        token.mint(alice, amount);
        token.mint(bob, amount * 2);
        // check balance
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(bob), amount * 2);

        // grant alice `DEFAULT_ADMIN_ROLE`
        token.grantRole(DEFAULT_ADMIN_ROLE, alice);
        // alice mints tokens
        vm.prank(alice);
        token.mint(carol, amount);
        assertEq(token.balanceOf(carol), amount);
    }

    function testMintFail() public {
        // alice has no `DEFAULT_ADMIN_ROLE`, so she can't mint tokens
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(alice),
                " is missing role ",
                Strings.toHexString(uint256(DEFAULT_ADMIN_ROLE), 32)
            )
        );
        vm.prank(alice);
        token.mint(alice, 1 ether);
    }

    function testTransfer() public {
        uint256 amount = 1 ether;

        // mint tokens
        token.mint(alice, amount);

        // transfer
        vm.prank(alice);
        token.transfer(bob, amount / 2);
        // check balances
        assertEq(token.balanceOf(alice), amount / 2);
        assertEq(token.balanceOf(bob), amount / 2);
    }

    function testTransferFail() public {
        uint256 amount = 1 ether;

        // mint tokens
        token.mint(alice, amount);
        // grant alice `BLOCK_ROLE`
        token.grantRole(BLOCK_ROLE, alice);

        // transfer
        // alice is blocked, so she can't transfer tokens
        vm.expectRevert(abi.encodePacked("transfer is blocked"));
        vm.prank(alice);
        token.transfer(bob, amount);

        // check balances
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(bob), 0);
    }

    function testTransferFromFail() public {
        uint256 amount = 1 ether;

        // mint tokens
        token.mint(alice, amount);
        // grant alice `BLOCK_ROLE`
        token.grantRole(BLOCK_ROLE, alice);

        // alice approves tokens for bob
        vm.prank(alice);
        token.approve(bob, amount);
        // bob transfers tokens from account of alice
        vm.expectRevert(abi.encodePacked("transfer is blocked"));
        vm.prank(bob);
        token.transferFrom(alice, carol, amount);

        // check balances
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(bob), 0);
        assertEq(token.balanceOf(carol), 0);
    }

    function testPermit() public {
        uint256 value = 1 ether;
        uint256 deadline = 1 days;
        uint256 nonce = 0;

        bytes32 digest = _getPermitDigest(owner, spender, value, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        // call permit
        token.permit(owner, spender, value, deadline, v, r, s);

        // check state
        assertEq(token.allowance(owner, spender), 1 ether);
        assertEq(token.nonces(owner), 1);
    }

    function testPermitFail() public {
        uint256 value = 1 ether;
        uint256 deadline = 1 days;
        uint256 nonce = 0;

        // case 1: InvalidSigner
        bytes32 digest = _getPermitDigest(owner, spender, value, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(spenderPrivateKey, digest);
        vm.expectRevert("ERC20Permit: invalid signature");
        token.permit(owner, spender, value, deadline, v, r, s);
        // check state
        assertEq(token.allowance(owner, spender), 0);
        assertEq(token.nonces(owner), 0);

        // case 2: ExpiredPermit
        digest = _getPermitDigest(owner, spender, value, nonce, deadline);
        (v, r, s) = vm.sign(ownerPrivateKey, digest);
        vm.warp(1 days + 1 seconds); // fast forward one second past the deadline
        vm.expectRevert("ERC20Permit: expired deadline");
        token.permit(owner, spender, value, deadline, v, r, s);
        // check state
        assertEq(token.allowance(owner, spender), 0);
        assertEq(token.nonces(owner), 0);

        // case 3: InvalidNonce
        nonce = 1;
        deadline = 2 days;
        digest = _getPermitDigest(owner, spender, value, nonce, deadline);
        (v, r, s) = vm.sign(ownerPrivateKey, digest);
        vm.expectRevert("ERC20Permit: invalid signature");
        token.permit(owner, spender, value, deadline, v, r, s);
        // check state
        assertEq(token.allowance(owner, spender), 0);
        assertEq(token.nonces(owner), 0);

        // case 4: UsedSignature
        nonce = 0;
        deadline = 2 days;
        digest = _getPermitDigest(owner, spender, value, nonce, deadline);
        (v, r, s) = vm.sign(ownerPrivateKey, digest);
        token.permit(owner, spender, value, deadline, v, r, s);
        vm.expectRevert("ERC20Permit: invalid signature");
        token.permit(owner, spender, value, deadline, v, r, s);
    }

    function testTransferFromLimitedPermit() public {
        uint256 value = 1 ether;
        uint256 deadline = 1 days;
        uint256 nonce = 0;
        bytes32 digest = _getPermitDigest(owner, spender, value, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        // call permit
        token.permit(owner, spender, value, deadline, v, r, s);

        token.mint(owner, value);
        // transfer
        vm.prank(spender);
        token.transferFrom(owner, spender, value);

        // check state
        assertEq(token.allowance(owner, spender), 0);
        assertEq(token.nonces(owner), 1);
        // check balances
        assertEq(token.balanceOf(owner), 0);
        assertEq(token.balanceOf(spender), value);
    }

    function _getPermitDigest(
        address owner_,
        address spender_,
        uint256 value_,
        uint256 nonce_,
        uint256 deadline_
    ) internal view returns (bytes32) {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner_,
            spender: spender_,
            value: value_,
            nonce: nonce_,
            deadline: deadline_
        });

        return sigUtils.getTypedDataHash(permit);
    }

    function _compare(string memory str1, string memory str2) internal pure returns (bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }
}
