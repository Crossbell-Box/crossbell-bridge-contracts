// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "./helpers/utils.sol";
import "../contracts/MainchainGateway.sol";
import "../contracts/Validator.sol";
import "../contracts/mocks/MintableERC20.sol";
import "../contracts/upgradeability/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MainchainGatewayTest is Test, Utils {
    // events
    event TokenMapped(
        address[] mainchainTokens,
        address[] crossbellTokens,
        uint8[] crossbellTokensDecimals
    );
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
        uint256 amount,
        uint256 fee
    );
    event LockedThresholdsUpdated(address[] tokens, uint256[] thresholds);
    event DailyWithdrawalLimitsUpdated(address[] tokens, uint256[] limits);
    event WithdrawalLocked(uint256 indexed withdrawId);
    event WithdrawalUnlocked(uint256 indexed withdrawId);

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WITHDRAWAL_UNLOCKER_ROLE = keccak256("WITHDRAWAL_UNLOCKER_ROLE");

    address internal alice = address(0x111);
    address internal bob = address(0x222);
    address internal carol = address(0x333);
    address internal dave = address(0x444);
    address internal eve = address(0x555);
    address internal frank = address(0x666);

    address internal admin = address(0x777);
    address internal proxyAdmin = address(0x888);
    address internal withdrawalUnlocker = address(0x999);

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
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(gateway),
            proxyAdmin,
            ""
        );
        gateway = MainchainGateway(address(proxy));
        gateway.initialize(
            address(validator),
            admin,
            withdrawalUnlocker,
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
        assertEq(gateway.hasRole(ADMIN_ROLE, admin), true);
        assertEq(gateway.hasRole(WITHDRAWAL_UNLOCKER_ROLE, withdrawalUnlocker), true);
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
            withdrawalUnlocker,
            array(address(mainchainToken)),
            INITIAL_THRESHOLDS,
            array(address(crossbellToken)),
            decimals
        );

        // check status
        assertEq(gateway.getValidatorContract(), address(validator));
        assertEq(gateway.hasRole(ADMIN_ROLE, admin), true);
        assertEq(gateway.hasRole(WITHDRAWAL_UNLOCKER_ROLE, withdrawalUnlocker), true);
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
        address[] memory mainchainTokens = array(address(0x0001), address(0x0002));
        address[] memory crossbellTokens = array(address(0x0003), address(0x0004));
        uint8[] memory decimals = new uint8[](2);
        decimals[0] = 6;
        decimals[1] = 18;

        // expect events
        expectEmit(CheckAll);
        emit TokenMapped(mainchainTokens, crossbellTokens, decimals);
        vm.prank(admin);
        gateway.mapTokens(mainchainTokens, crossbellTokens, decimals);

        // check
        for (uint256 i = 0; i < mainchainTokens.length; i++) {
            DataTypes.MappedToken memory token = gateway.getCrossbellToken(mainchainTokens[i]);
            assertEq(token.token, crossbellTokens[i]);
            assertEq(token.decimals, decimals[i]);
        }
    }

    function testMapTokensFail() public {
        address[] memory mainchainTokens = array(address(0x0001), address(0x0002));
        address[] memory crossbellTokens = array(address(0x0003), address(0x0004));
        uint8[] memory decimals = new uint8[](2);
        decimals[0] = 6;
        decimals[1] = 18;

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(eve),
                " is missing role ",
                Strings.toHexString(uint256(ADMIN_ROLE), 32)
            )
        );
        vm.prank(eve);
        gateway.mapTokens(mainchainTokens, crossbellTokens, decimals);

        // check
        for (uint256 i = 0; i < mainchainTokens.length; i++) {
            DataTypes.MappedToken memory token = gateway.getCrossbellToken(mainchainTokens[i]);
            assertEq(token.token, address(0));
            assertEq(token.decimals, 0);
        }
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

    function testSetDailyWithdrawalLimits() public {
        address[] memory tokens = array(address(0x0001), address(0x0002));
        uint256[] memory limits = array(111, 222);

        // expect events
        expectEmit(CheckAll);
        emit DailyWithdrawalLimitsUpdated(tokens, limits);
        vm.prank(admin);
        gateway.setDailyWithdrawalLimits(tokens, limits);
        // check states
        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(gateway.getDailyWithdrawalLimit(tokens[i]), limits[i]);
        }

        // set new limits
        uint256[] memory newLimits = array(333, 444);
        vm.prank(admin);
        gateway.setDailyWithdrawalLimits(tokens, newLimits);
        // check states
        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(gateway.getDailyWithdrawalLimit(tokens[i]), newLimits[i]);
        }
    }

    function testSetDailyWithdrawalLimitsFail() public {
        address[] memory tokens = array(address(0x0001), address(0x0002));
        uint256[] memory limits = array(111, 222);

        // eve has no permission to set the daily withdrawal limit
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(address(eve)),
                " is missing role ",
                Strings.toHexString(uint256(ADMIN_ROLE), 32)
            )
        );
        vm.prank(eve);
        gateway.setDailyWithdrawalLimits(tokens, limits);

        // check states
        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(gateway.getDailyWithdrawalLimit(tokens[i]), 0);
        }
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
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = _hash(
            gateway.TYPE_HASH(),
            chainId,
            withdrawalId,
            recipient,
            token,
            amount,
            fee
        );
        DataTypes.Signature[] memory signatures = _getTwoSignatures(hash);

        vm.chainId(chainId); // set block.chainid
        // expect events
        expectEmit(CheckAll);
        emit Withdrew(withdrawalId, recipient, token, amount, fee);
        vm.prank(frank);
        gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);

        // check balances
        assertEq(mainchainToken.balanceOf(address(gateway)), INITIAL_AMOUNT_MAINCHAIN - amount);
        assertEq(mainchainToken.balanceOf(bob), amount - fee);
        assertEq(mainchainToken.balanceOf(frank), fee);
        // check withdrawal hash
        assertEq(gateway.getWithdrawalHash(withdrawalId), hash);
    }

    // case 1: invalid chainId
    function testWithdrawFailCase1() public {
        // mint tokens to mainchain gateway contract
        mainchainToken.mint(address(gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = eve;
        address token = address(mainchainToken);
        uint256 amount = 1 * 10 ** 6;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = _hash(
            gateway.TYPE_HASH(),
            chainId,
            withdrawalId,
            recipient,
            token,
            amount,
            fee
        );

        // case 1: invalid chainId
        vm.expectRevert(abi.encodePacked("InvalidChainId"));
        vm.prank(eve);
        gateway.withdraw(
            uint256(1001),
            uint256(1),
            eve,
            address(mainchainToken),
            amount,
            fee,
            _getTwoSignatures(hash)
        );

        // check balances
        assertEq(mainchainToken.balanceOf(address(gateway)), INITIAL_AMOUNT_MAINCHAIN);
        assertEq(mainchainToken.balanceOf(eve), 0);
        // check withdrawal hash
        assertEq(gateway.getWithdrawalHash(withdrawalId), bytes32(0));
    }

    // case 2: already withdrawn
    function testWithdrawFailCase2() public {
        // mint tokens to mainchain gateway contract
        mainchainToken.mint(address(gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = eve;
        address token = address(mainchainToken);
        uint256 amount = 1 * 10 ** 6;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = _hash(
            gateway.TYPE_HASH(),
            chainId,
            withdrawalId,
            recipient,
            token,
            amount,
            fee
        );
        DataTypes.Signature[] memory signatures = _getTwoSignatures(hash);

        vm.chainId(chainId); // set block.chainid
        gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);

        // case 2: already withdrawn
        vm.expectRevert(abi.encodePacked("NotNewWithdrawal"));
        gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);
    }

    // case 3: reached daily withdrawal limit
    function testWithdrawFailCase3() public {
        // mint tokens to mainchain gateway contract
        mainchainToken.mint(address(gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = eve;
        address token = address(mainchainToken);
        uint256 amount = 5 * 10 ** 6;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;

        vm.chainId(chainId); // set block.chainid

        for (uint256 i = 0; i < 20; i++) {
            withdrawalId = i;

            bytes32 hash = _hash(
                gateway.TYPE_HASH(),
                chainId,
                withdrawalId,
                recipient,
                token,
                amount,
                fee
            );
            DataTypes.Signature[] memory signatures = _getThreeSignatures(hash);

            if (i == 19) {
                // case 3: reached daily withdrawal limit
                vm.expectRevert(abi.encodePacked("DailyWithdrawalLimit"));
                gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);
                // check withdrawal hash
                assertEq(gateway.getWithdrawalHash(withdrawalId), bytes32(0));
            } else {
                // expect events
                expectEmit(CheckAll);
                emit Withdrew(withdrawalId, recipient, token, amount, fee);
                gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);
                // check withdrawal hash
                assertEq(gateway.getWithdrawalHash(withdrawalId), hash);
            }
        }
    }

    // case 4: insufficient signatures number
    function testWithdrawFailCase4() public {
        // mint tokens to mainchain gateway contract
        mainchainToken.mint(address(gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = eve;
        address token = address(mainchainToken);
        uint256 amount = 1 * 10 ** 6;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = _hash(
            gateway.TYPE_HASH(),
            chainId,
            withdrawalId,
            recipient,
            token,
            amount,
            fee
        );
        DataTypes.Signature[] memory signatures = _getOneSignature(hash);

        vm.chainId(chainId); // set block.chainid
        // case 4: insufficient signatures number
        vm.expectRevert(abi.encodePacked("InsufficientSignaturesNumber"));
        gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);

        // check balances
        assertEq(mainchainToken.balanceOf(address(gateway)), INITIAL_AMOUNT_MAINCHAIN);
        assertEq(mainchainToken.balanceOf(eve), 0);
        // check withdrawal hash
        assertEq(gateway.getWithdrawalHash(withdrawalId), bytes32(0));
    }

    // case 5: invalid signer order
    function testWithdrawFailCase5() public {
        // mint tokens to mainchain gateway contract
        mainchainToken.mint(address(gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = eve;
        address token = address(mainchainToken);
        uint256 amount = 1 * 10 ** 6;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = _hash(
            gateway.TYPE_HASH(),
            chainId,
            withdrawalId,
            recipient,
            token,
            amount,
            fee
        );

        // generate validator signatures
        DataTypes.Signature[] memory signatures = new DataTypes.Signature[](3);
        signatures[0] = _getSignature(hash, validator1PrivateKey);
        signatures[1] = _getSignature(hash, validator2PrivateKey);
        signatures[2] = _getSignature(hash, validator3PrivateKey);

        vm.chainId(chainId); // set block.chainid
        // case 5: invalid signer order
        vm.expectRevert(abi.encodePacked("InvalidSignerOrder"));
        gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);

        // check balances
        assertEq(mainchainToken.balanceOf(address(gateway)), INITIAL_AMOUNT_MAINCHAIN);
        assertEq(mainchainToken.balanceOf(eve), 0);
        // check withdrawal hash
        assertEq(gateway.getWithdrawalHash(withdrawalId), bytes32(0));
    }

    // case 6: paused
    function testWithdrawFailCase6() public {
        // mint tokens to mainchain gateway contract
        mainchainToken.mint(address(gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = eve;
        address token = address(mainchainToken);
        uint256 amount = 1 * 10 ** 6;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = _hash(
            gateway.TYPE_HASH(),
            chainId,
            withdrawalId,
            recipient,
            token,
            amount,
            fee
        );

        // generate validator signatures
        DataTypes.Signature[] memory signatures = _getThreeSignatures(hash);

        vm.chainId(chainId); // set block.chainid
        vm.prank(admin);
        gateway.pause();
        // case 6: paused
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);

        // check balances
        assertEq(mainchainToken.balanceOf(address(gateway)), INITIAL_AMOUNT_MAINCHAIN);
        assertEq(mainchainToken.balanceOf(eve), 0);
        // check withdrawal hash
        assertEq(gateway.getWithdrawalHash(withdrawalId), bytes32(0));
    }

    // case 7: gateway balance is insufficient
    function testWithdrawFailCase7() public {
        // withdrawal info
        address recipient = eve;
        address token = address(mainchainToken);
        uint256 amount = 1 * 10 ** 6;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = _hash(
            gateway.TYPE_HASH(),
            chainId,
            withdrawalId,
            recipient,
            token,
            amount,
            fee
        );

        // generate validator signatures
        DataTypes.Signature[] memory signatures = _getThreeSignatures(hash);

        vm.chainId(chainId); // set block.chainid
        // case 7: gateway balance is insufficient
        vm.expectRevert(abi.encodePacked("ERC20: transfer amount exceeds balance"));
        gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);

        // check balances
        assertEq(mainchainToken.balanceOf(address(gateway)), 0);
        assertEq(mainchainToken.balanceOf(eve), 0);
        // check withdrawal hash
        assertEq(gateway.getWithdrawalHash(withdrawalId), bytes32(0));
    }

    function testWithdrawWithDailyLimit() public {
        // mint tokens to mainchain gateway contract
        mainchainToken.mint(address(gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = eve;
        address token = address(mainchainToken);
        uint256 amount = DAILY_WITHDRAWLAL_LIMIT / 20;
        uint256 fee = amount / 100;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;

        vm.chainId(chainId); // set block.chainid

        vm.startPrank(frank);
        for (uint256 i = 0; i < 20; i++) {
            withdrawalId = i;

            bytes32 hash = _hash(
                gateway.TYPE_HASH(),
                chainId,
                withdrawalId,
                recipient,
                token,
                amount,
                fee
            );
            DataTypes.Signature[] memory signatures = _getThreeSignatures(hash);

            if (i == 19) {
                // the last withdrawal will reach the daily withdrawal limit
                vm.expectRevert(abi.encodePacked("DailyWithdrawalLimit"));
                gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);

                // 1 days later, the limit will restore
                skip(1 days);
            }
            // expect events
            expectEmit(CheckAll);
            emit Withdrew(withdrawalId, recipient, token, amount, fee);
            gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);
            // check withdrawal hash
            assertEq(gateway.getWithdrawalHash(withdrawalId), hash);
        }
        vm.stopPrank();

        // check balances
        assertEq(mainchainToken.balanceOf(frank), fee * 20);
        assertEq(mainchainToken.balanceOf(recipient), (amount - fee) * 20);
        assertEq(
            mainchainToken.balanceOf(address(gateway)),
            INITIAL_AMOUNT_MAINCHAIN - amount * 20
        );
    }

    // test case for locked withdrawal
    function testWithdrawLocked() public {
        // mint tokens to mainchain gateway contract
        mainchainToken.mint(address(gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = bob;
        address token = address(mainchainToken);
        uint256 amount = WITHDRAWLAL_THRESHOLD;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = _hash(
            gateway.TYPE_HASH(),
            chainId,
            withdrawalId,
            recipient,
            token,
            amount,
            fee
        );
        DataTypes.Signature[] memory signatures = _getTwoSignatures(hash);

        vm.prank(bob);
        vm.chainId(chainId); // set block.chainid
        // expect events
        expectEmit(CheckAll);
        emit WithdrawalLocked(withdrawalId);
        gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);

        // check locked state
        assertEq(gateway.getWithdrawalLocked(withdrawalId), true);
        // check balances
        assertEq(mainchainToken.balanceOf(address(gateway)), INITIAL_AMOUNT_MAINCHAIN);
        assertEq(mainchainToken.balanceOf(bob), 0);
        // check withdrawal hash
        assertEq(gateway.getWithdrawalHash(withdrawalId), bytes32(0));
    }

    function testReachedDailyWithdrawalLimit() public {}

    function testUnlockWithdrawal() public {
        // mint tokens to mainchain gateway contract
        mainchainToken.mint(address(gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = bob;
        address token = address(mainchainToken);
        uint256 amount = WITHDRAWLAL_THRESHOLD;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = _hash(
            gateway.TYPE_HASH(),
            chainId,
            withdrawalId,
            recipient,
            token,
            amount,
            fee
        );
        DataTypes.Signature[] memory signatures = _getTwoSignatures(hash);

        vm.chainId(chainId); // set block.chainid
        // locked when withdraw
        gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);

        // unlock withdrawal
        // expect events
        expectEmit(CheckAll);
        emit WithdrawalUnlocked(withdrawalId);
        expectEmit(CheckAll);
        emit Withdrew(withdrawalId, recipient, token, amount, fee);
        vm.prank(withdrawalUnlocker);
        gateway.unlockWithdrawal(chainId, withdrawalId, recipient, token, amount, fee);

        // check locked state
        assertEq(gateway.getWithdrawalLocked(withdrawalId), false);
        // check balances
        assertEq(mainchainToken.balanceOf(address(gateway)), INITIAL_AMOUNT_MAINCHAIN - amount);
        assertEq(mainchainToken.balanceOf(bob), amount - fee, "amount");
        assertEq(mainchainToken.balanceOf(withdrawalUnlocker), fee, "fee");
        // check withdrawal hash
        assertEq(gateway.getWithdrawalHash(withdrawalId), hash, "withdrawalHash");
    }

    // case 1: invalid chainId
    function testUnlockWithdrawalFailCase1() public {
        // withdrawal info
        address recipient = bob;
        address token = address(mainchainToken);
        uint256 amount = WITHDRAWLAL_THRESHOLD;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;

        // unlock withdrawal
        // case 1: invalid chainId
        vm.expectRevert(abi.encodePacked("InvalidChainId"));
        vm.prank(withdrawalUnlocker);
        gateway.unlockWithdrawal(chainId, withdrawalId, recipient, token, amount, fee);

        // check locked state
        assertEq(gateway.getWithdrawalLocked(withdrawalId), false);
        // check balances
        assertEq(mainchainToken.balanceOf(address(gateway)), 0);
        assertEq(mainchainToken.balanceOf(recipient), 0, "amount");
        assertEq(mainchainToken.balanceOf(withdrawalUnlocker), 0, "fee");
        // check withdrawal hash
        assertEq(gateway.getWithdrawalHash(withdrawalId), bytes32(0), "withdrawalHash");
    }

    // case 2: withdrawal not locked
    function testUnlockWithdrawalFailCase2() public {
        // withdrawal info
        address recipient = bob;
        address token = address(mainchainToken);
        uint256 amount = WITHDRAWLAL_THRESHOLD;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;

        // unlock withdrawal
        vm.chainId(chainId);
        // case 2:  withdrawal not locked
        vm.expectRevert(abi.encodePacked("WithdrawalNotLocked"));
        vm.prank(withdrawalUnlocker);
        gateway.unlockWithdrawal(chainId, withdrawalId, recipient, token, amount, fee);

        // check locked state
        assertEq(gateway.getWithdrawalLocked(withdrawalId), false);
        // check balances
        assertEq(mainchainToken.balanceOf(address(gateway)), 0);
        assertEq(mainchainToken.balanceOf(recipient), 0, "amount");
        assertEq(mainchainToken.balanceOf(withdrawalUnlocker), 0, "fee");
        // check withdrawal hash
        assertEq(gateway.getWithdrawalHash(withdrawalId), bytes32(0), "withdrawalHash");
    }

    // case 3: paused
    function testUnlockWithdrawalFailCase3() public {
        // withdrawal info
        address recipient = bob;
        address token = address(mainchainToken);
        uint256 amount = WITHDRAWLAL_THRESHOLD;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;

        // unlock withdrawal
        vm.prank(admin);
        gateway.pause();
        // case 3: paused
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        vm.prank(withdrawalUnlocker);
        gateway.unlockWithdrawal(chainId, withdrawalId, recipient, token, amount, fee);

        // check locked state
        assertEq(gateway.getWithdrawalLocked(withdrawalId), false);
        // check balances
        assertEq(mainchainToken.balanceOf(address(gateway)), 0);
        assertEq(mainchainToken.balanceOf(recipient), 0, "amount");
        assertEq(mainchainToken.balanceOf(withdrawalUnlocker), 0, "fee");
        // check withdrawal hash
        assertEq(gateway.getWithdrawalHash(withdrawalId), bytes32(0), "withdrawalHash");
    }

    // case 4: caller has no permission to unlock withdrawal
    function testUnlockWithdrawalFailCase4() public {
        // withdrawal info
        address recipient = bob;
        address token = address(mainchainToken);
        uint256 amount = WITHDRAWLAL_THRESHOLD;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;

        // unlock withdrawal
        // case 4: caller has no permission to unlock withdrawal
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(address(eve)),
                " is missing role ",
                Strings.toHexString(uint256(WITHDRAWAL_UNLOCKER_ROLE), 32)
            )
        );
        vm.prank(eve);
        gateway.unlockWithdrawal(chainId, withdrawalId, recipient, token, amount, fee);

        // check locked state
        assertEq(gateway.getWithdrawalLocked(withdrawalId), false);
        // check balances
        assertEq(mainchainToken.balanceOf(address(gateway)), 0);
        assertEq(mainchainToken.balanceOf(recipient), 0, "amount");
        assertEq(mainchainToken.balanceOf(withdrawalUnlocker), 0, "fee");
        // check withdrawal hash
        assertEq(gateway.getWithdrawalHash(withdrawalId), bytes32(0), "withdrawalHash");
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
        return signatures;
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
        return signatures;
    }

    function _getSignature(
        bytes32 hash,
        uint256 privateKey
    ) internal pure returns (DataTypes.Signature memory signature) {
        bytes32 prefixedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        (signature.v, signature.r, signature.s) = vm.sign(privateKey, prefixedHash);
        return signature;
    }

    function _hash(
        bytes32 typeHash,
        uint256 chainId,
        uint256 withdrawalId,
        address recipient,
        address token,
        uint256 amount,
        uint256 fee
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(typeHash, chainId, withdrawalId, recipient, token, amount, fee)
            );
    }
}
