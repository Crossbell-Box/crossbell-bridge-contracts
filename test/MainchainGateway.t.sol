// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "./helpers/utils.sol";
import "../contracts/MainchainGateway.sol";
import "../contracts/Validator.sol";
import "../contracts/mocks/MintableERC20.sol";

contract MainchainGatewayTest is Test, Utils {
    address internal alice = address(0x111);
    address internal bob = address(0x222);
    address internal carol = address(0x333);
    address internal dave = address(0x444);
    address internal eve = address(0x555);
    address internal frank = address(0x666);

    address internal admin = address(0x777);

    // events
    event Paused(address account);
    event Unpaused(address account);

    // validators
    uint256 internal validator1PrivateKey = 1;
    uint256 internal validator2PrivateKey = 2;
    uint256 internal validator3PrivateKey = 3;
    address internal validator1 = vm.addr(validator1PrivateKey);
    address internal validator2 = vm.addr(validator2PrivateKey);
    address internal validator3 = vm.addr(validator3PrivateKey);

    MainchainGateway internal gateway;
    Validator internal validator;

    MintableERC20 internal mainchainToken;
    MintableERC20 internal crossbellToken;

    function setUp() public {
        // setup ERC20 token
        mainchainToken = new MintableERC20("mainchain ERC20", "ERC20", 18);
        crossbellToken = new MintableERC20("crossbell ERC20", "ERC20", 18);

        uint8[] memory decimals = new uint8[](1);
        decimals[0] = 18;

        // init [validator1, validator2, validator3] as validators, with requiredNumber 2
        validator = new Validator(array(validator1, validator2, validator3), 2);

        // setup MainchainGateway
        gateway = new MainchainGateway();
        gateway.initialize(
            address(validator),
            admin,
            array(address(mainchainToken)),
            array(address(crossbellToken)),
            decimals
        );

        // mint tokens
        mainchainToken.mint(alice, 100 ether);
        crossbellToken.mint(alice, 100 ether);
    }

    function testSetupState() public {
        // check status after initialization
        assertEq(gateway.getAdmin(), admin);
        assertEq(gateway.getValidatorContract(), address(validator));
        DataTypes.MappedToken memory token = gateway.getCrossbellToken(address(mainchainToken));
        assertEq(token.tokenAddr, address(crossbellToken));
        assertEq(token.decimals, 18);
    }

    function testReinitializeFail() public {
        uint8[] memory decimals = new uint8[](1);
        decimals[0] = 6;

        vm.expectRevert(abi.encodePacked("Initializable: contract is already initialized"));
        gateway.initialize(
            address(validator),
            bob,
            array(address(mainchainToken)),
            array(address(crossbellToken)),
            decimals
        );

        // check status
        assertEq(gateway.getAdmin(), admin);
        assertEq(gateway.getValidatorContract(), address(validator));
        DataTypes.MappedToken memory token = gateway.getCrossbellToken(address(mainchainToken));
        assertEq(token.tokenAddr, address(crossbellToken));
        assertEq(token.decimals, 18);
    }

    function testPause() public {
        // check paused
        assertFalse(gateway.paused());

        // expect events
        expectEmit(CheckAll);
        emit Paused(admin);
        vm.prank(admin);
        gateway.pause();

        // check paused
        assertEq(gateway.paused(), true);
    }

    function testPauseFail() public {
        // check paused
        assertEq(gateway.paused(), false);

        // case 1: caller is not admin
        vm.expectRevert(abi.encodePacked("onlyAdmin"));
        gateway.pause();
        // check paused
        assertEq(gateway.paused(), false);

        // pause gateway
        vm.startPrank(admin);
        gateway.pause();
        // case 2: gateway has been paused
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        gateway.pause();
        vm.stopPrank();
    }

    function testUnpause() public {
        vm.prank(admin);
        gateway.pause();
        // check paused
        assertEq(gateway.paused(), true);

        // expect events
        expectEmit(CheckAll);
        emit Unpaused(admin);
        vm.prank(admin);
        gateway.unpause();

        // check paused
        assertEq(gateway.paused(), false);
    }

    function testUnpauseFail() public {
        assertEq(gateway.paused(), false);
        // case 1: gateway not paused
        vm.expectRevert(abi.encodePacked("Pausable: not paused"));
        gateway.unpause();
        // check paused
        assertEq(gateway.paused(), false);

        // case 1: caller is not admin
        vm.prank(admin);
        gateway.pause();
        // check paused
        assertEq(gateway.paused(), true);
        vm.expectRevert(abi.encodePacked("onlyAdmin"));
        gateway.unpause();
        // check paused
        assertEq(gateway.paused(), true);
    }

    function testVerifySignatures() public {
        bytes32 hash = keccak256(abi.encodePacked("testVerifySignatures"));

        // one validator signature, not enough signatures
        bytes memory signatures = _getOneSignature(hash);
        assertFalse(gateway.verifySignatures(hash, signatures));

        // two validator signature, enough signatures
        signatures = _getTwoSignatures(hash);
        assertTrue(gateway.verifySignatures(hash, signatures));

        // three validator signature, enough signatures
        signatures = _getThreeSignatures(hash);
        assertTrue(gateway.verifySignatures(hash, signatures));
    }

    function _getOneSignature(bytes32 hash) internal view returns (bytes memory signatures) {
        bytes memory sig1 = _getSignature(hash, validator1PrivateKey);

        signatures = abi.encodePacked(sig1);
    }

    function _getTwoSignatures(bytes32 hash) internal view returns (bytes memory signatures) {
        bytes memory sig1 = _getSignature(hash, validator1PrivateKey);
        bytes memory sig2 = _getSignature(hash, validator2PrivateKey);

        // note: for verifySignatures, signatures need to be arranged in ascending order of addresses
        // sorted address: validator1 > validator3 > validator2
        signatures = abi.encodePacked(sig2, sig1);
    }

    function _getThreeSignatures(bytes32 hash) internal view returns (bytes memory signatures) {
        bytes memory sig1 = _getSignature(hash, validator1PrivateKey);
        bytes memory sig2 = _getSignature(hash, validator2PrivateKey);
        bytes memory sig3 = _getSignature(hash, validator3PrivateKey);

        // note: for verifySignatures, signatures need to be arranged in ascending order of addresses
        // sorted address: validator1 > validator3 > validator2
        signatures = abi.encodePacked(sig2, sig3, sig1);
    }

    function _getSignature(
        bytes32 hash,
        uint256 privateKey
    ) internal pure returns (bytes memory signature) {
        bytes32 prefixedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, prefixedHash);
        return abi.encodePacked(r, s, v);
    }
}
