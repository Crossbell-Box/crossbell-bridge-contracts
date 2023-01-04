// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "./helpers/utils.sol";
import "../contracts/MainchainGateway.sol";
import "../contracts/Validator.sol";
import "../contracts/mocks/MintableERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MainchainGatewayTest is Test, Utils {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WITHDRAWAL_UNLOCKER_ROLE = keccak256("WITHDRAWAL_UNLOCKER_ROLE");

    address internal alice = address(0x111);
    address internal bob = address(0x222);
    address internal carol = address(0x333);
    address internal dave = address(0x444);
    address internal eve = address(0x555);
    address internal frank = address(0x666);

    address internal admin = address(0x777);
    address internal withdrawalAuditor = address(0x888);

    // events
    event Paused(address account);
    event Unpaused(address account);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event RequestDeposit(
        uint256 indexed depositId,
        address indexed recipient,
        address indexed token,
        uint256 amount // ERC-20 amount
    );
    event Withdrew(
        uint256 indexed withdrawId,
        address indexed recipient,
        address indexed token,
        uint256 amount
    );
    event LockedThresholdsUpdated(address[] tokens, uint256[] thresholds);
    event WithdrawalLocked(uint256 indexed withdrawId);
    event WithdrawalUnlocked(uint256 indexed withdrawId);

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

    // initial balances: 100 tokens
    uint256 internal constant INITIAL_AMOUNT_MAINCHAIN = 200 * 10 ** 6;
    uint256 internal constant INITIAL_AMOUNT_CROSSBELL = 200 * 10 ** 18;
    // withdrawal threshold: 10 tokens
    uint256 internal constant WITHDRAWLAL_THRESHOLD = 10 * 10 ** 6;
    // daily withdrawal limit: 100 tokens
    uint256 internal constant DAILY_WITHDRAWLAL_LIMIT = 100 * 10 ** 6;

    uint256[][2] internal INITIAL_THRESHOLDS = [
        array(WITHDRAWLAL_THRESHOLD),
        array(DAILY_WITHDRAWLAL_LIMIT)
    ];

    function setUp() public {
        // setup ERC20 token
        mainchainToken = new MintableERC20("mainchain ERC20", "ERC20", 6);
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
            withdrawalAuditor,
            array(address(mainchainToken)),
            INITIAL_THRESHOLDS,
            array(address(crossbellToken)),
            decimals
        );

        // mint tokens
        mainchainToken.mint(alice, INITIAL_AMOUNT_MAINCHAIN);
        crossbellToken.mint(alice, INITIAL_AMOUNT_MAINCHAIN);
    }

    function testSetupState() public {
        // check status after initialization
        assertEq(gateway.getValidatorContract(), address(validator));
        DataTypes.MappedToken memory token = gateway.getCrossbellToken(address(mainchainToken));
        assertEq(token.token, address(crossbellToken));
        assertEq(token.decimals, 18);
    }

    function testReinitializeFail() public {
        uint8[] memory decimals = new uint8[](1);
        decimals[0] = 6;

        vm.expectRevert(abi.encodePacked("Initializable: contract is already initialized"));
        gateway.initialize(
            address(validator),
            bob,
            withdrawalAuditor,
            array(address(mainchainToken)),
            INITIAL_THRESHOLDS,
            array(address(crossbellToken)),
            decimals
        );

        // check status
        assertEq(gateway.getValidatorContract(), address(validator));
        DataTypes.MappedToken memory token = gateway.getCrossbellToken(address(mainchainToken));
        assertEq(token.token, address(crossbellToken));
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

        // case 1: caller is not admin
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

    function testSetLockedThresholds() public {
        address token = address(0x00001);
        uint256 threshold = 1000 ether;
        // check state
        assertEq(gateway.getWithdrawalLockedThreshold(token), 0);

        // expect events
        expectEmit(CheckAll);
        emit LockedThresholdsUpdated(array(token), array(threshold));
        vm.prank(admin);
        gateway.setLockedThresholds(array(token), array(threshold));

        // check state
        assertEq(gateway.getWithdrawalLockedThreshold(token), threshold);
    }

    function testSetLockedThresholdsFail() public {
        address token = address(0x00001);
        uint256 threshold = 1000 ether;
        // check state
        assertEq(gateway.getWithdrawalLockedThreshold(token), 0);

        // case 1: invalid array length
        vm.expectRevert(abi.encodePacked("InvalidArrayLength"));
        vm.prank(admin);
        gateway.setLockedThresholds(array(token, address(0x1)), array(threshold));

        // case 2: caller is not admin role
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(address(this)),
                " is missing role ",
                Strings.toHexString(uint256(ADMIN_ROLE), 32)
            )
        );
        gateway.setLockedThresholds(array(token), array(threshold));

        // check state
        assertEq(gateway.getWithdrawalLockedThreshold(token), 0);
    }

    function testRequestDeposit() public {
        uint256 amount = 1 * 10 ** 6;
        uint256 crossbellAmount = amount * 10 ** 12; // transformed amount

        vm.startPrank(alice);
        // approve token
        mainchainToken.approve(address(gateway), amount);
        // expect events
        expectEmit(CheckAll);
        emit Transfer(alice, address(gateway), amount);
        expectEmit(CheckAll);
        emit RequestDeposit(0, alice, address(crossbellToken), crossbellAmount);
        // requestDeposit
        gateway.requestDeposit(alice, address(mainchainToken), amount);
        vm.stopPrank();

        // check balances
        assertEq(mainchainToken.balanceOf(address(gateway)), amount);
        assertEq(mainchainToken.balanceOf(alice), INITIAL_AMOUNT_MAINCHAIN - amount);
        // check deposit count
        assertEq(gateway.getDepositCount(), 1);
    }

    function testRequestDepositFail() public {
        uint256 amount = 1 ether;
        address fakeToken = address(0x0001);

        // case 1: unmapped token
        vm.expectRevert(abi.encodePacked("UnsupportedToken"));
        vm.prank(alice);
        gateway.requestDeposit(alice, fakeToken, amount);

        // case 2: paused
        // pause gateway
        vm.prank(admin);
        gateway.pause();
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        vm.prank(alice);
        gateway.requestDeposit(alice, fakeToken, amount);

        // check balances
        assertEq(mainchainToken.balanceOf(address(gateway)), 0);
        assertEq(mainchainToken.balanceOf(alice), INITIAL_AMOUNT_MAINCHAIN);
        // check deposit count
        assertEq(gateway.getDepositCount(), 0);
    }

    // test case for successful withdrawal
    function testWithdraw() public {
        // mint tokens to mainchain gateway contract
        mainchainToken.mint(address(gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = bob;
        address token = address(mainchainToken);
        uint256 amount = 1 * 10 ** 6;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = keccak256(
            abi.encodePacked(
                gateway.TYPE_HASH(),
                chainId, // chainId
                withdrawalId, // withdrawId
                recipient,
                token,
                amount
            )
        );
        DataTypes.Signature[] memory signatures = _getTwoSignatures(hash);

        vm.prank(bob);
        vm.chainId(chainId); // set block.chainid
        // expect events
        expectEmit(CheckAll);
        emit Withdrew(withdrawalId, recipient, token, amount);
        gateway.withdraw(chainId, withdrawalId, recipient, token, amount, signatures);

        // check balances
        assertEq(mainchainToken.balanceOf(address(gateway)), INITIAL_AMOUNT_MAINCHAIN - amount);
        assertEq(mainchainToken.balanceOf(bob), amount);
        // check withdrawal hash
        assertEq(gateway.getWithdrawalHash(withdrawalId), hash);
    }

    function testWithdrawFail() public {
        uint256 amount = 1 ether;
        // mint tokens to mainchain gateway contract
        mainchainToken.mint(address(gateway), INITIAL_AMOUNT_MAINCHAIN);

        bytes32 hash = keccak256(
            abi.encodePacked(
                gateway.TYPE_HASH(),
                uint256(1001),
                uint256(1),
                alice,
                address(mainchainToken),
                amount
            )
        );

        // case 1: invalid chainId
        vm.expectRevert(abi.encodePacked("InvalidChainId"));
        vm.prank(alice);
        gateway.withdraw(
            uint256(1001),
            uint256(1),
            alice,
            address(mainchainToken),
            amount,
            _getTwoSignatures(hash)
        );
        // case 2: already  withdrawn
        // case 3: insufficient signatures number
        // case 4: invalid signer order
        // case 5: paused
    }

    function testVerifySignatures() public {
        bytes32 hash = keccak256(abi.encodePacked("testVerifySignatures"));

        // one validator signature, not enough signatures
        DataTypes.Signature[] memory signatures = _getOneSignature(hash);
        assertFalse(gateway.verifySignatures(hash, signatures));

        // two validator signature, enough signatures
        signatures = _getTwoSignatures(hash);
        assertTrue(gateway.verifySignatures(hash, signatures));

        // three validator signature, enough signatures
        signatures = _getThreeSignatures(hash);
        assertTrue(gateway.verifySignatures(hash, signatures));
    }

    function _getOneSignature(
        bytes32 hash
    ) internal view returns (DataTypes.Signature[] memory signatures) {
        signatures = new DataTypes.Signature[](1);
        signatures[0] = _getSignature(hash, validator1PrivateKey);
    }

    function _getTwoSignatures(
        bytes32 hash
    ) internal view returns (DataTypes.Signature[] memory signatures) {
        // note: for verifySignatures, signatures need to be arranged in ascending order of addresses
        // sorted address: validator1 > validator3 > validator2
        signatures = new DataTypes.Signature[](2);
        signatures[0] = _getSignature(hash, validator2PrivateKey);
        signatures[1] = _getSignature(hash, validator1PrivateKey);
    }

    function _getThreeSignatures(
        bytes32 hash
    ) internal view returns (DataTypes.Signature[] memory signatures) {
        // note: for verifySignatures, signatures need to be arranged in ascending order of addresses
        // sorted address: validator1 > validator3 > validator2
        signatures = new DataTypes.Signature[](3);
        signatures[0] = _getSignature(hash, validator2PrivateKey);
        signatures[1] = _getSignature(hash, validator3PrivateKey);
        signatures[2] = _getSignature(hash, validator1PrivateKey);
    }

    function _getSignature(
        bytes32 hash,
        uint256 privateKey
    ) internal pure returns (DataTypes.Signature memory signature) {
        bytes32 prefixedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        (signature.v, signature.r, signature.s) = vm.sign(privateKey, prefixedHash);
    }
}
