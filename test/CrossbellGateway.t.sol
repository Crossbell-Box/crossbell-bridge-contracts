// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "./helpers/utils.sol";
import "../contracts/CrossbellGateway.sol";
import "../contracts/Validator.sol";
import "../contracts/mocks/MintableERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CrossbellGatewayTest is Test, Utils {
    // events
    event Paused(address account);
    event Unpaused(address account);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address internal alice = address(0x111);
    address internal bob = address(0x222);
    address internal carol = address(0x333);
    address internal dave = address(0x444);
    address internal eve = address(0x555);
    address internal frank = address(0x666);

    address internal admin = address(0x777);

    // validators
    uint256 internal validator1PrivateKey = 1;
    uint256 internal validator2PrivateKey = 2;
    uint256 internal validator3PrivateKey = 3;
    address internal validator1 = vm.addr(validator1PrivateKey);
    address internal validator2 = vm.addr(validator2PrivateKey);
    address internal validator3 = vm.addr(validator3PrivateKey);

    CrossbellGateway internal gateway;
    Validator internal validator;

    MintableERC20 internal mainchainToken;
    MintableERC20 internal crossbellToken;

    // initial balances: 100 tokens
    uint256 internal constant INITIAL_AMOUNT_MAINCHAIN = 200 * 10 ** 6;
    uint256 internal constant INITIAL_AMOUNT_CROSSBELL = 200 * 10 ** 18;

    uint256 internal constant MAINCHAIN_CHAIN_ID = 1;

    function setUp() public {
        // setup ERC20 token
        mainchainToken = new MintableERC20("mainchain ERC20", "ERC20", 6);
        crossbellToken = new MintableERC20("crossbell ERC20", "ERC20", 18);

        uint8[] memory decimals = new uint8[](1);
        decimals[0] = 6;

        // init [validator1, validator2, validator3] as validators, with requiredNumber 2
        validator = new Validator(array(validator1, validator2, validator3), 2);

        // setup MainchainGateway
        gateway = new CrossbellGateway();
        gateway.initialize(
            address(validator),
            admin,
            array(address(crossbellToken)),
            array(MAINCHAIN_CHAIN_ID),
            array(address(mainchainToken)),
            decimals
        );

        // mint tokens
        mainchainToken.mint(alice, INITIAL_AMOUNT_MAINCHAIN);
        crossbellToken.mint(alice, INITIAL_AMOUNT_MAINCHAIN);
    }

    function testSetupState() public {
        // check status after initialization
        assertEq(gateway.getValidatorContract(), address(validator));
        assertEq(gateway.hasRole(ADMIN_ROLE, admin), true);
        DataTypes.MappedToken memory token = gateway.getMainchainToken(
            MAINCHAIN_CHAIN_ID,
            address(crossbellToken)
        );
        assertEq(token.token, address(mainchainToken));
        assertEq(token.decimals, 6);
    }

    function testReinitializeFail() public {
        uint8[] memory decimals = new uint8[](1);
        decimals[0] = 8;

        vm.expectRevert(abi.encodePacked("Initializable: contract is already initialized"));
        gateway.initialize(
            address(validator),
            bob,
            array(address(crossbellToken)),
            array(1337),
            array(address(mainchainToken)),
            decimals
        );

        // check status
        assertEq(gateway.getValidatorContract(), address(validator));
        assertEq(gateway.hasRole(ADMIN_ROLE, admin), true);

        DataTypes.MappedToken memory token = gateway.getMainchainToken(
            MAINCHAIN_CHAIN_ID,
            address(crossbellToken)
        );
        assertEq(token.token, address(mainchainToken));
        assertEq(token.decimals, 6);
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
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(address(this)),
                " is missing role ",
                Strings.toHexString(uint256(ADMIN_ROLE), 32)
            )
        );
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

        // case 2: caller is not admin
        vm.prank(admin);
        gateway.pause();
        // check paused
        assertEq(gateway.paused(), true);
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(address(this)),
                " is missing role ",
                Strings.toHexString(uint256(ADMIN_ROLE), 32)
            )
        );
        gateway.unpause();
        // check paused
        assertEq(gateway.paused(), true);
    }
}
