// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "./helpers/utils.sol";
import "../contracts/libraries/DataTypes.sol";
import "../contracts/CrossbellGateway.sol";
import "../contracts/Validator.sol";
import "../contracts/mocks/MintableERC20.sol";
import "../contracts/upgradeability/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CrossbellGatewayTest is Test, Utils {
    // events
    event TokenMapped(
        address[] crossbellTokens,
        uint256[] chainIds,
        address[] mainchainTokens,
        uint8[] mainchainTokenDecimals
    );
    event Paused(address account);
    event Unpaused(address account);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Deposited(
        uint256 indexed chainId,
        uint256 indexed depositId,
        address indexed recipient,
        address token,
        uint256 amount
    );
    event AckDeposit(
        uint256 indexed chainId,
        uint256 indexed depositId,
        address indexed recipient,
        address token,
        uint256 amount
    );
    event RequestWithdrawal(
        uint256 indexed chainId,
        uint256 indexed withdrawId,
        address indexed recipient,
        address token,
        uint256 amount,
        uint256 fee
    );
    event RequestWithdrawalSignatures(
        uint256 indexed chainId,
        uint256 indexed withdrawId,
        address indexed recipient,
        address token,
        uint256 amount,
        uint256 fee
    );

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address internal alice = address(0x111);
    address internal bob = address(0x222);
    address internal carol = address(0x333);
    address internal dave = address(0x444);
    address internal eve = address(0x555);
    address internal frank = address(0x666);

    address internal admin = address(0x777);
    address internal proxyAdmin = address(0x888);

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
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(gateway),
            proxyAdmin,
            ""
        );
        gateway = CrossbellGateway(address(proxy));
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
        crossbellToken.mint(alice, INITIAL_AMOUNT_CROSSBELL);
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

    function testMapTokens() public {
        address[] memory crossbellTokens = array(address(0x0001), address(0x0002));
        uint256[] memory chainIds = array(1, 1337);
        address[] memory mainchainTokens = array(address(0x0003), address(0x0004));
        uint8[] memory decimals = new uint8[](2);
        decimals[0] = 18;
        decimals[1] = 6;

        // expect events
        expectEmit(CheckAll);
        emit TokenMapped(crossbellTokens, chainIds, mainchainTokens, decimals);
        vm.prank(admin);
        gateway.mapTokens(crossbellTokens, chainIds, mainchainTokens, decimals);

        // check
        for (uint256 i = 0; i < crossbellTokens.length; i++) {
            DataTypes.MappedToken memory token = gateway.getMainchainToken(
                chainIds[i],
                crossbellTokens[i]
            );
            assertEq(token.token, mainchainTokens[i], "token");
            assertEq(token.decimals, decimals[i], "decimals");
        }
    }

    function testMapTokensFail() public {
        address[] memory crossbellTokens = array(address(0x0001), address(0x0002));
        uint256[] memory chainIds = array(1, 1337);
        address[] memory mainchainTokens = array(address(0x0003), address(0x0004));
        uint8[] memory decimals = new uint8[](2);
        decimals[0] = 18;
        decimals[1] = 6;

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(eve),
                " is missing role ",
                Strings.toHexString(uint256(ADMIN_ROLE), 32)
            )
        );
        vm.prank(eve);
        gateway.mapTokens(crossbellTokens, chainIds, mainchainTokens, decimals);

        // check
        for (uint256 i = 0; i < crossbellTokens.length; i++) {
            DataTypes.MappedToken memory token = gateway.getMainchainToken(
                chainIds[i],
                mainchainTokens[i]
            );
            assertEq(token.token, address(0));
            assertEq(token.decimals, 0);
        }
    }

    function testAckDeposit() public {
        // mint tokens to gateway contract
        crossbellToken.mint(address(gateway), INITIAL_AMOUNT_CROSSBELL);

        uint256 chainId = 1337;
        uint256 depositId = 1;
        address recipient = bob;
        address token = address(crossbellToken);
        uint256 amount = 1 * 10 ** 18;
        bytes32 hash = keccak256(abi.encodePacked(chainId, depositId, recipient, token, amount));

        // validator1 acknowledges deposit (validator acknowledgement threshold 2/3)
        // expect events
        expectEmit(CheckAll);
        emit AckDeposit(chainId, depositId, recipient, token, amount);
        vm.prank(validator1);
        gateway.ackDeposit(chainId, depositId, recipient, token, amount);
        // check state
        _checkAcknowledgementStatus(
            chainId,
            depositId,
            [validator1, validator2, validator3],
            [hash, bytes32(0), bytes32(0)],
            DataTypes.Status.NotApproved,
            1
        );
        // check balances
        // deposit not approved, so bob's balance is 0
        assertEq(crossbellToken.balanceOf(address(gateway)), INITIAL_AMOUNT_CROSSBELL);
        assertEq(crossbellToken.balanceOf(address(recipient)), 0);

        // validator2 acknowledges deposit
        // expect events
        expectEmit(CheckAll);
        emit Transfer(address(gateway), recipient, amount);
        expectEmit(CheckAll);
        emit Deposited(chainId, depositId, recipient, token, amount);
        expectEmit(CheckAll);
        emit AckDeposit(chainId, depositId, recipient, token, amount);
        vm.prank(validator2);
        gateway.ackDeposit(chainId, depositId, recipient, token, amount);
        // check state
        _checkAcknowledgementStatus(
            chainId,
            depositId,
            [validator1, validator2, validator3],
            [hash, hash, bytes32(0)],
            DataTypes.Status.FirstApproved,
            2
        );
        // check balances
        // deposit is approved, so bob's balance is `amount`
        assertEq(crossbellToken.balanceOf(address(gateway)), INITIAL_AMOUNT_CROSSBELL - amount);
        assertEq(crossbellToken.balanceOf(address(recipient)), amount);

        // validator3 acknowledges deposit
        // expect events
        expectEmit(CheckAll);
        emit AckDeposit(chainId, depositId, recipient, token, amount);
        vm.prank(validator3);
        gateway.ackDeposit(chainId, depositId, recipient, token, amount);
        // check state
        _checkAcknowledgementStatus(
            chainId,
            depositId,
            [validator1, validator2, validator3],
            [hash, hash, hash],
            DataTypes.Status.AlreadyApproved,
            3
        );
        // check deposit entry
        DataTypes.DepositEntry memory entry = gateway.getDepositEntry(chainId, depositId);
        assertEq(entry.chainId, chainId);
        assertEq(entry.recipient, recipient);
        assertEq(entry.token, token);
        assertEq(entry.amount, amount);
        // check balances
        // deposit is AlreadyApproved, so bob's balance will not change
        assertEq(crossbellToken.balanceOf(address(gateway)), INITIAL_AMOUNT_CROSSBELL - amount);
        assertEq(crossbellToken.balanceOf(address(recipient)), amount);
    }

    function testAckDepositWithMint() public {
        // grant MINTER_ROLE to gateway
        crossbellToken.grantRole(MINTER_ROLE, address(gateway));

        uint256 chainId = 1337;
        uint256 depositId = 1;
        address recipient = bob;
        address token = address(crossbellToken);
        uint256 amount = 1 * 10 ** 18;
        bytes32 hash = keccak256(abi.encodePacked(chainId, depositId, recipient, token, amount));

        // validator1 acknowledges deposit (validator acknowledgement threshold 2/3)
        vm.prank(validator1);
        gateway.ackDeposit(chainId, depositId, recipient, token, amount);
        // check state
        _checkAcknowledgementStatus(
            chainId,
            depositId,
            [validator1, validator2, validator3],
            [hash, bytes32(0), bytes32(0)],
            DataTypes.Status.NotApproved,
            1
        );
        // check balances
        // deposit not approved, so bob's balance is 0
        assertEq(crossbellToken.balanceOf(address(gateway)), 0);
        assertEq(crossbellToken.balanceOf(address(recipient)), 0);

        // validator2 acknowledges deposit
        // expect events
        expectEmit(CheckAll);
        emit Transfer(address(0), address(gateway), amount); // mint tokens to gateway
        expectEmit(CheckAll);
        emit Transfer(address(gateway), recipient, amount); // transfer tokens from gateway to recipient
        expectEmit(CheckAll);
        emit Deposited(chainId, depositId, recipient, token, amount);
        expectEmit(CheckAll);
        emit AckDeposit(chainId, depositId, recipient, token, amount);
        vm.prank(validator2);
        gateway.ackDeposit(chainId, depositId, recipient, token, amount);
        // check state
        _checkAcknowledgementStatus(
            chainId,
            depositId,
            [validator1, validator2, validator3],
            [hash, hash, bytes32(0)],
            DataTypes.Status.FirstApproved,
            2
        );
        // check balances
        // deposit is approved, so bob's balance is `amount`
        assertEq(crossbellToken.balanceOf(address(gateway)), 0);
        assertEq(crossbellToken.balanceOf(address(recipient)), amount);
    }

    function testAckDepositFailCase1() public {
        uint256 chainId = 1337;
        uint256 depositId = 1;
        address recipient = bob;
        address token = address(crossbellToken);
        uint256 amount = 1 * 10 ** 18;

        // case 1: call is not validator
        vm.expectRevert(abi.encodePacked("NotValidator"));
        vm.prank(eve);
        gateway.ackDeposit(chainId, depositId, recipient, token, amount);

        // check state
        _checkAcknowledgementStatus(
            chainId,
            depositId,
            [validator1, validator2, validator3],
            [bytes32(0), bytes32(0), bytes32(0)],
            DataTypes.Status.NotApproved,
            0
        );
        // check balances
        // deposit not approved, so bob's balance is 0
        assertEq(crossbellToken.balanceOf(address(gateway)), 0);
        assertEq(crossbellToken.balanceOf(address(recipient)), 0);
    }

    function testAckDepositFailCase2() public {
        uint256 chainId = 1337;
        uint256 depositId = 1;
        address recipient = bob;
        address token = address(crossbellToken);
        uint256 amount = 1 * 10 ** 18;

        // case 2: paused
        vm.prank(admin);
        gateway.pause();
        // validator ackDeposit
        for (uint256 i = 0; i < 3; i++) {
            vm.expectRevert(abi.encodePacked("Pausable: paused"));
            vm.prank([validator1, validator2, validator3][i]);
            gateway.ackDeposit(chainId, depositId, recipient, token, amount);
        }

        // check state
        _checkAcknowledgementStatus(
            chainId,
            depositId,
            [validator1, validator2, validator3],
            [bytes32(0), bytes32(0), bytes32(0)],
            DataTypes.Status.NotApproved,
            0
        );
        // check balances
        // deposit not approved, so bob's balance is 0
        assertEq(crossbellToken.balanceOf(address(gateway)), 0);
        assertEq(crossbellToken.balanceOf(address(recipient)), 0);
    }

    // case 3: validator already acknowledged
    function testAckDepositFailCase3() public {
        // mint tokens to gateway contract
        crossbellToken.mint(address(gateway), INITIAL_AMOUNT_CROSSBELL);

        uint256 chainId = 1337;
        uint256 depositId = 1;
        address recipient = bob;
        address token = address(crossbellToken);
        uint256 amount = 1 * 10 ** 18;
        bytes32 hash = keccak256(abi.encodePacked(chainId, depositId, recipient, token, amount));

        // case 3: validator already acknowledged
        vm.prank(validator1);
        gateway.ackDeposit(chainId, depositId, recipient, token, amount);
        vm.expectRevert(abi.encodePacked("AlreadyAcknowledged"));
        vm.prank(validator1);
        gateway.ackDeposit(chainId, depositId, recipient, token, amount);

        // check state
        _checkAcknowledgementStatus(
            chainId,
            depositId,
            [validator1, validator2, validator3],
            [hash, bytes32(0), bytes32(0)],
            DataTypes.Status.NotApproved,
            1
        );
        // check balances
        // deposit not approved, so bob's balance is 0
        assertEq(
            crossbellToken.balanceOf(address(gateway)),
            INITIAL_AMOUNT_CROSSBELL,
            "gateway balance"
        );
        assertEq(crossbellToken.balanceOf(address(recipient)), 0, "recipient balance ");
    }

    function testBatchAckDepositx() public {
        // mint tokens to gateway contract
        crossbellToken.mint(address(gateway), INITIAL_AMOUNT_CROSSBELL);

        address token = address(crossbellToken);
        uint256 amount = 1 * 10 ** 18;
        bytes32 hashBob = keccak256(abi.encodePacked(uint256(1), uint256(1), bob, token, amount));
        bytes32 hashCarol = keccak256(
            abi.encodePacked(uint256(1337), uint256(2), carol, token, amount)
        );

        // validator1 acknowledges deposit (validator acknowledgement threshold 2/3)
        // expect events
        expectEmit(CheckAll);
        emit AckDeposit(1, 1, bob, token, amount);
        expectEmit(CheckAll);
        emit AckDeposit(1337, 2, carol, token, amount);
        vm.prank(validator1);
        gateway.batchAckDeposit(
            array(1, 1337),
            array(1, 2),
            array(bob, carol),
            array(token, token),
            array(amount, amount)
        );
        // check state
        _checkAcknowledgementStatus(
            1,
            1,
            [validator1, validator2, validator3],
            [hashBob, bytes32(0), bytes32(0)],
            DataTypes.Status.NotApproved,
            1
        );
        _checkAcknowledgementStatus(
            1337,
            2,
            [validator1, validator2, validator3],
            [hashCarol, bytes32(0), bytes32(0)],
            DataTypes.Status.NotApproved,
            1
        );
        // check balances
        // deposit not approved
        assertEq(crossbellToken.balanceOf(address(gateway)), INITIAL_AMOUNT_CROSSBELL);
        assertEq(crossbellToken.balanceOf(address(bob)), 0);
        assertEq(crossbellToken.balanceOf(address(carol)), 0);

        // validator2 acknowledges deposit
        vm.prank(validator2);
        gateway.batchAckDeposit(
            array(1, 1337),
            array(1, 2),
            array(bob, carol),
            array(token, token),
            array(amount, amount)
        );
        // check state
        _checkAcknowledgementStatus(
            1,
            1,
            [validator1, validator2, validator3],
            [hashBob, hashBob, bytes32(0)],
            DataTypes.Status.FirstApproved,
            2
        );
        _checkAcknowledgementStatus(
            1337,
            2,
            [validator1, validator2, validator3],
            [hashCarol, hashCarol, bytes32(0)],
            DataTypes.Status.FirstApproved,
            2
        );
        // check balances
        // deposit is approved
        assertEq(
            crossbellToken.balanceOf(address(gateway)),
            INITIAL_AMOUNT_CROSSBELL - amount - amount
        );
        assertEq(crossbellToken.balanceOf(address(bob)), amount);
        assertEq(crossbellToken.balanceOf(address(carol)), amount);

        // validator3 acknowledges deposit
        // expect events
        expectEmit(CheckAll);
        emit AckDeposit(1, 1, bob, token, amount);
        expectEmit(CheckAll);
        emit AckDeposit(1337, 2, carol, token, amount);
        vm.prank(validator3);
        gateway.batchAckDeposit(
            array(1, 1337),
            array(1, 2),
            array(bob, carol),
            array(token, token),
            array(amount, amount)
        );
        // check state
        _checkAcknowledgementStatus(
            1,
            1,
            [validator1, validator2, validator3],
            [hashBob, hashBob, hashBob],
            DataTypes.Status.AlreadyApproved,
            3
        );
        _checkAcknowledgementStatus(
            1337,
            2,
            [validator1, validator2, validator3],
            [hashCarol, hashCarol, hashCarol],
            DataTypes.Status.AlreadyApproved,
            3
        );
        // check balances
        // deposit is already approved
        assertEq(
            crossbellToken.balanceOf(address(gateway)),
            INITIAL_AMOUNT_CROSSBELL - amount - amount
        );
        assertEq(crossbellToken.balanceOf(address(bob)), amount);
        assertEq(crossbellToken.balanceOf(address(carol)), amount);

        // check deposit entry
        // check deposit entry for bob
        DataTypes.DepositEntry memory entry = gateway.getDepositEntry(1, 1);
        assertEq(entry.chainId, 1);
        assertEq(entry.recipient, bob);
        assertEq(entry.token, token);
        assertEq(entry.amount, amount);
        // check deposit entry for carol
        entry = gateway.getDepositEntry(1337, 2);
        assertEq(entry.chainId, 1337);
        assertEq(entry.recipient, carol);
        assertEq(entry.token, token);
        assertEq(entry.amount, amount);
    }

    function testBatchAckDepositFail() public {
        address token = address(crossbellToken);
        uint256 amount = 1 * 10 ** 18;

        // case 1: InvalidArrayLength
        vm.expectRevert(abi.encodePacked("InvalidArrayLength"));
        vm.prank(validator1);
        gateway.batchAckDeposit(
            array(1, 1337),
            array(1, 2),
            array(bob, carol),
            array(token),
            array(amount, amount)
        );

        // case 2: call is not validator
        vm.expectRevert(abi.encodePacked("NotValidator"));
        vm.prank(eve);
        gateway.batchAckDeposit(
            array(1, 1337),
            array(1, 2),
            array(bob, carol),
            array(token),
            array(amount, amount)
        );

        // case 3: paused
        vm.prank(admin);
        gateway.pause();
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        vm.prank(eve);
        gateway.batchAckDeposit(
            array(1, 1337),
            array(1, 2),
            array(bob, carol),
            array(token),
            array(amount, amount)
        );

        // check balances
        assertEq(crossbellToken.balanceOf(eve), 0);
    }

    function testRequestWithdrawal() public {
        uint256 chainId = 1;
        uint256 withdrawalId = 0;
        address recipient = alice;
        address token = address(crossbellToken);
        uint256 amount = INITIAL_AMOUNT_CROSSBELL / 100;
        uint256 fee = amount / 100;

        // transformed amount
        uint256 transformedAmount = amount / (10 ** 12);
        uint256 feeAmount = fee / (10 ** 12);
        DataTypes.MappedToken memory mapppedToken = gateway.getMainchainToken(chainId, token);

        // approve token
        vm.startPrank(recipient);
        crossbellToken.approve(address(gateway), amount);
        // request withdrawal
        // expect event
        expectEmit(CheckAll);
        emit Transfer(recipient, address(gateway), amount);
        expectEmit(CheckAll);
        emit RequestWithdrawal(
            chainId,
            withdrawalId,
            recipient,
            mapppedToken.token,
            transformedAmount,
            feeAmount
        );
        gateway.requestWithdrawal(chainId, recipient, token, amount, fee);
        vm.stopPrank();

        // check state
        assertEq(gateway.getWithdrawalCount(chainId), 1);
        // check withdrawal entry
        DataTypes.WithdrawalEntry memory entry = gateway.getWithdrawalEntry(chainId, withdrawalId);
        assertEq(entry.chainId, chainId);
        assertEq(entry.recipient, recipient);
        assertEq(entry.token, mapppedToken.token);
        assertEq(entry.amount, transformedAmount);
        assertEq(entry.fee, feeAmount);
        // check balances
        assertEq(crossbellToken.balanceOf(alice), INITIAL_AMOUNT_CROSSBELL - amount);
        assertEq(crossbellToken.balanceOf(address(gateway)), amount);
    }

    // case 1: paused
    function testRequestWithdrawalFailCase1() public {
        uint256 chainId = 1;
        address recipient = alice;
        address token = address(crossbellToken);
        uint256 amount = INITIAL_AMOUNT_CROSSBELL / 100;
        uint256 fee = amount / 100;

        // case 1: paused
        vm.prank(admin);
        gateway.pause();
        // request withdrawal
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        gateway.requestWithdrawal(chainId, recipient, token, amount, fee);
        vm.stopPrank();

        // check state
        assertEq(gateway.getWithdrawalCount(chainId), 0);
        // check balances
        assertEq(crossbellToken.balanceOf(alice), INITIAL_AMOUNT_CROSSBELL);
        assertEq(crossbellToken.balanceOf(address(gateway)), 0);
    }

    // case 2: ZeroAmount
    function testRequestWithdrawalFailCase2() public {
        uint256 chainId = 1;
        address recipient = alice;
        address token = address(crossbellToken);
        uint256 amount = 0;
        uint256 fee = amount / 100;

        // case 2: ZeroAmount
        // request withdrawal
        vm.expectRevert(abi.encodePacked("ZeroAmount"));
        gateway.requestWithdrawal(chainId, recipient, token, amount, fee);
        vm.stopPrank();

        // check state
        assertEq(gateway.getWithdrawalCount(chainId), 0);
        // check balances
        assertEq(crossbellToken.balanceOf(alice), INITIAL_AMOUNT_CROSSBELL);
        assertEq(crossbellToken.balanceOf(address(gateway)), 0);
    }

    // case 3: FeeExceedAmount
    function testRequestWithdrawalFailCase3() public {
        uint256 chainId = 1;
        address recipient = alice;
        address token = address(crossbellToken);
        uint256 amount = INITIAL_AMOUNT_CROSSBELL / 100;
        uint256 fee = amount + 1;

        // case 2: FeeExceedAmount
        // request withdrawal
        vm.expectRevert(abi.encodePacked("FeeExceedAmount"));
        gateway.requestWithdrawal(chainId, recipient, token, amount, fee);
        vm.stopPrank();

        // check state
        assertEq(gateway.getWithdrawalCount(chainId), 0);
        // check balances
        assertEq(crossbellToken.balanceOf(alice), INITIAL_AMOUNT_CROSSBELL);
        assertEq(crossbellToken.balanceOf(address(gateway)), 0);
    }

    // case 4: UnsupportedToken
    function testRequestWithdrawalFailCase4() public {
        uint256 chainId = 1;
        address recipient = alice;
        address token = address(0x000001);
        uint256 amount = INITIAL_AMOUNT_CROSSBELL / 100;
        uint256 fee = amount / 100;

        // case 4: UnsupportedToken
        // request withdrawal
        vm.expectRevert(abi.encodePacked("UnsupportedToken"));
        gateway.requestWithdrawal(chainId, recipient, token, amount, fee);
        vm.stopPrank();

        // check state
        assertEq(gateway.getWithdrawalCount(chainId), 0);
        // check balances
        assertEq(crossbellToken.balanceOf(alice), INITIAL_AMOUNT_CROSSBELL);
        assertEq(crossbellToken.balanceOf(address(gateway)), 0);
    }

    // case 5: balance insufficient
    function testRequestWithdrawalFailCase5() public {
        uint256 chainId = 1;
        address recipient = alice;
        address token = address(crossbellToken);
        uint256 amount = INITIAL_AMOUNT_CROSSBELL + 1; // amount > balanceOf(alice)
        uint256 fee = amount / 100;

        // case 5: balance insufficient
        // approve token
        vm.startPrank(recipient);
        crossbellToken.approve(address(gateway), amount);
        // request withdrawal
        vm.expectRevert(abi.encodePacked("ERC20: transfer amount exceeds balance"));
        gateway.requestWithdrawal(chainId, recipient, token, amount, fee);
        vm.stopPrank();

        // check state
        assertEq(gateway.getWithdrawalCount(chainId), 0);
        // check balances
        assertEq(crossbellToken.balanceOf(alice), INITIAL_AMOUNT_CROSSBELL);
        assertEq(crossbellToken.balanceOf(address(gateway)), 0);
    }

    function testRequestWithdrawalSignatures() public {}

    function testRequestWithdrawalSignaturesFail() public {}

    function testSubmitWithdrawalSignatures() public {}

    function testSubmitWithdrawalSignaturesFail() public {}

    function testBatchSubmitWithdrawalSignatures() public {}

    function testBatchSubmitWithdrawalSignaturesFail() public {}

    function _checkAcknowledgementStatus(
        uint256 chainId,
        uint256 depositId,
        address[3] memory validators,
        bytes32[3] memory acknowledgementHashes,
        DataTypes.Status status,
        uint256 ackCount
    ) internal {
        // check acknowledgementHash
        assertEq(
            gateway.getValidatorAcknowledgementHash(chainId, depositId, validators[0]),
            acknowledgementHashes[0],
            "validator1Hash"
        );
        assertEq(
            gateway.getValidatorAcknowledgementHash(chainId, depositId, validators[1]),
            acknowledgementHashes[1],
            "validator2Hash"
        );
        assertEq(
            gateway.getValidatorAcknowledgementHash(chainId, depositId, validators[2]),
            acknowledgementHashes[2],
            "validator3Hash"
        );

        // check acknowledgementStatus
        assertEq(
            uint256(gateway.getAcknowledgementStatus(chainId, depositId, acknowledgementHashes[0])),
            uint256(status),
            "ackStatus"
        );

        // check acknowledgementCount
        assertEq(
            gateway.getAcknowledgementCount(chainId, depositId, acknowledgementHashes[0]),
            ackCount,
            "ackCount"
        );
    }
}
