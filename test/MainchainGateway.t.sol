// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "./helpers/Utils.sol";
import "../contracts/MainchainGateway.sol";
import "../contracts/Validator.sol";
import "../contracts/token/MintableERC20.sol";
import "../contracts/upgradeability/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MainchainGatewayTest is Test, Utils {
    using ECDSA for bytes32;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address public constant alice = address(0x111);
    address public constant bob = address(0x222);
    address public constant carol = address(0x333);
    address public constant dave = address(0x444);
    address public constant eve = address(0x555);
    address public constant frank = address(0x666);

    address public constant admin = address(0x777);
    address public constant proxyAdmin = address(0x888);

    // validators
    uint256 internal constant _validator1PrivateKey = 1;
    uint256 internal constant _validator2PrivateKey = 2;
    uint256 internal constant _validator3PrivateKey = 3;
    address internal _validator1 = vm.addr(_validator1PrivateKey);
    address internal _validator2 = vm.addr(_validator2PrivateKey);
    address internal _validator3 = vm.addr(_validator3PrivateKey);

    MainchainGateway internal _gateway;
    Validator internal _validator;

    MintableERC20 internal _mainchainToken;
    MintableERC20 internal _crossbellToken;

    // initial balances: 100 tokens
    uint256 public constant INITIAL_AMOUNT_MAINCHAIN = 200 * 10 ** 6;
    uint256 public constant INITIAL_AMOUNT_CROSSBELL = 200 * 10 ** 18;
    // withdrawal threshold: 10 tokens
    uint256 public constant WITHDRAWLAL_THRESHOLD = 10 * 10 ** 6;
    // daily withdrawal max quota: 100 tokens
    uint256 public constant DAILY_WITHDRAWLAL_MAX_QUOTA = 100 * 10 ** 6;

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
        uint256 indexed chainId,
        uint256 indexed depositId,
        address indexed recipient,
        address token,
        uint256 amount,
        bytes32 depositHash
    );
    event Withdrew(
        uint256 indexed chainId,
        uint256 indexed withdrawalId,
        address indexed recipient,
        address token,
        uint256 amount,
        uint256 fee
    );
    event DailyWithdrawalMaxQuotasUpdated(address[] tokens, uint256[] quotas);

    /* solhint-disable comprehensive-interface */
    function setUp() public {
        // setup ERC20 token
        _mainchainToken = new MintableERC20("mainchain ERC20", "ERC20", 6);
        _crossbellToken = new MintableERC20("crossbell ERC20", "ERC20", 18);

        uint8[] memory decimals = new uint8[](1);
        decimals[0] = 18;

        // init [validator1, validator2, validator3] as validators, with requiredNumber 2
        _validator = new Validator(array(_validator1, _validator2, _validator3), 2);

        // setup MainchainGateway
        _gateway = new MainchainGateway();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(_gateway),
            proxyAdmin,
            ""
        );
        _gateway = MainchainGateway(address(proxy));
        _gateway.initialize(
            address(_validator),
            admin,
            array(address(_mainchainToken)),
            array(DAILY_WITHDRAWLAL_MAX_QUOTA),
            array(address(_crossbellToken)),
            decimals
        );

        // mint tokens
        _mainchainToken.mint(alice, INITIAL_AMOUNT_MAINCHAIN);
        _crossbellToken.mint(alice, INITIAL_AMOUNT_CROSSBELL);
    }

    function testSetupState() public {
        // check status after initialization
        assertEq(_gateway.getValidatorContract(), address(_validator));
        assertEq(_gateway.hasRole(ADMIN_ROLE, admin), true);
        DataTypes.MappedToken memory token = _gateway.getCrossbellToken(address(_mainchainToken));
        assertEq(token.token, address(_crossbellToken));
        assertEq(token.decimals, 18);
    }

    function testReinitializeFail() public {
        uint8[] memory decimals = new uint8[](1);
        decimals[0] = 6;

        vm.expectRevert(abi.encodePacked("Initializable: contract is already initialized"));
        _gateway.initialize(
            address(_validator),
            bob,
            array(address(_mainchainToken)),
            array(DAILY_WITHDRAWLAL_MAX_QUOTA),
            array(address(_crossbellToken)),
            decimals
        );

        // check status
        assertEq(_gateway.getValidatorContract(), address(_validator));
        assertEq(_gateway.hasRole(ADMIN_ROLE, admin), true);
        DataTypes.MappedToken memory token = _gateway.getCrossbellToken(address(_mainchainToken));
        assertEq(token.token, address(_crossbellToken));
        assertEq(token.decimals, 18);
    }

    function testPause() public {
        // check paused
        assertFalse(_gateway.paused());

        // expect events
        expectEmit(CheckAll);
        emit Paused(admin);
        vm.prank(admin);
        _gateway.pause();

        // check paused
        assertEq(_gateway.paused(), true);
    }

    function testPauseFail() public {
        // check paused
        assertEq(_gateway.paused(), false);

        // case 1: caller is not admin
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(address(this)),
                " is missing role ",
                Strings.toHexString(uint256(ADMIN_ROLE), 32)
            )
        );
        _gateway.pause();
        // check paused
        assertEq(_gateway.paused(), false);

        // pause gateway
        vm.startPrank(admin);
        _gateway.pause();
        // case 2: gateway has been paused
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        _gateway.pause();
        vm.stopPrank();
    }

    function testUnpause() public {
        vm.prank(admin);
        _gateway.pause();
        // check paused
        assertEq(_gateway.paused(), true);

        // expect events
        expectEmit(CheckAll);
        emit Unpaused(admin);
        vm.prank(admin);
        _gateway.unpause();

        // check paused
        assertEq(_gateway.paused(), false);
    }

    function testUnpauseFail() public {
        assertEq(_gateway.paused(), false);
        // case 1: gateway not paused
        vm.expectRevert(abi.encodePacked("Pausable: not paused"));
        _gateway.unpause();
        // check paused
        assertEq(_gateway.paused(), false);

        // case 2: caller is not admin
        vm.prank(admin);
        _gateway.pause();
        // check paused
        assertEq(_gateway.paused(), true);
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(address(this)),
                " is missing role ",
                Strings.toHexString(uint256(ADMIN_ROLE), 32)
            )
        );
        _gateway.unpause();
        // check paused
        assertEq(_gateway.paused(), true);
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
        _gateway.mapTokens(mainchainTokens, crossbellTokens, decimals);

        // check
        for (uint256 i = 0; i < mainchainTokens.length; i++) {
            DataTypes.MappedToken memory token = _gateway.getCrossbellToken(mainchainTokens[i]);
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
        _gateway.mapTokens(mainchainTokens, crossbellTokens, decimals);

        // check
        for (uint256 i = 0; i < mainchainTokens.length; i++) {
            DataTypes.MappedToken memory token = _gateway.getCrossbellToken(mainchainTokens[i]);
            assertEq(token.token, address(0));
            assertEq(token.decimals, 0);
        }
    }

    function testSetDailyWithdrawalQuotas() public {
        address[] memory tokens = array(address(0x0001), address(0x0002));
        uint256[] memory quotas = array(111, 222);

        // expect events
        expectEmit(CheckAll);
        emit DailyWithdrawalMaxQuotasUpdated(tokens, quotas);
        vm.prank(admin);
        _gateway.setDailyWithdrawalMaxQuotas(tokens, quotas);
        // check states
        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(_gateway.getDailyWithdrawalMaxQuota(tokens[i]), quotas[i]);
        }

        // set new quotas
        uint256[] memory newQuotas = array(333, 444);
        vm.prank(admin);
        _gateway.setDailyWithdrawalMaxQuotas(tokens, newQuotas);
        // check states
        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(_gateway.getDailyWithdrawalMaxQuota(tokens[i]), newQuotas[i]);
        }
    }

    function testSetDailyWithdrawalQuotasFail() public {
        address[] memory tokens = array(address(0x0001), address(0x0002));
        uint256[] memory quotas = array(111, 222);

        // eve has no permission to set the daily withdrawal quota
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(address(eve)),
                " is missing role ",
                Strings.toHexString(uint256(ADMIN_ROLE), 32)
            )
        );
        vm.prank(eve);
        _gateway.setDailyWithdrawalMaxQuotas(tokens, quotas);

        // check states
        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(_gateway.getDailyWithdrawalMaxQuota(tokens[i]), 0);
        }
    }

    function testRequestDeposit(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < INITIAL_AMOUNT_MAINCHAIN);

        uint256 depositId = 0;
        address recipient = alice;
        uint256 transformedAmount = amount * 10 ** 12; // transformed amount
        bytes32 depositHash = keccak256(
            abi.encodePacked(
                block.chainid,
                depositId,
                recipient,
                address(_crossbellToken),
                transformedAmount
            )
        );

        vm.startPrank(recipient);
        // approve token
        _mainchainToken.approve(address(_gateway), amount);
        // expect events
        expectEmit(CheckAll);
        emit Transfer(recipient, address(_gateway), amount);
        expectEmit(CheckAll);
        emit RequestDeposit(
            block.chainid,
            0,
            recipient,
            address(_crossbellToken),
            transformedAmount,
            depositHash
        );
        // requestDeposit
        _gateway.requestDeposit(recipient, address(_mainchainToken), amount);
        vm.stopPrank();

        // check balances
        assertEq(_mainchainToken.balanceOf(address(_gateway)), amount);
        assertEq(_mainchainToken.balanceOf(recipient), INITIAL_AMOUNT_MAINCHAIN - amount);
        // check deposit count
        assertEq(_gateway.getDepositCount(), 1);
    }

    function testRequestDepositFail() public {
        uint256 amount = 1 ether;
        address fakeToken = address(0x0001);

        // case 1: ZeroAmount
        vm.expectRevert(abi.encodePacked("ZeroAmount"));
        vm.prank(alice);
        _gateway.requestDeposit(alice, fakeToken, 0);

        // case 2: unmapped token
        vm.expectRevert(abi.encodePacked("UnsupportedToken"));
        vm.prank(alice);
        _gateway.requestDeposit(alice, fakeToken, amount);

        // case 3: insufficient balance
        vm.startPrank(alice);
        // approve token
        _mainchainToken.approve(address(_gateway), type(uint256).max);
        uint256 depositAmount = _mainchainToken.balanceOf(alice) + 1;
        vm.expectRevert(abi.encodePacked("ERC20: transfer amount exceeds balance"));
        // deposit
        _gateway.requestDeposit(alice, address(_mainchainToken), depositAmount);
        vm.stopPrank();

        // case 4: paused
        // pause gateway
        vm.prank(admin);
        _gateway.pause();
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        vm.prank(alice);
        _gateway.requestDeposit(alice, fakeToken, amount);

        // check balances
        assertEq(_mainchainToken.balanceOf(address(_gateway)), 0);
        assertEq(_mainchainToken.balanceOf(alice), INITIAL_AMOUNT_MAINCHAIN);
        // check deposit count
        assertEq(_gateway.getDepositCount(), 0);
    }

    // test case for successful withdrawal
    function testWithdraw(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < WITHDRAWLAL_THRESHOLD);

        // mint tokens to mainchain gateway contract
        _mainchainToken.mint(address(_gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = bob;
        address token = address(_mainchainToken);
        uint256 fee = amount / 20;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = _hash(
            _gateway.getDomainSeparator(),
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
        emit Withdrew(chainId, withdrawalId, recipient, token, amount, fee);
        vm.prank(frank);
        _gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);

        // check balances
        assertEq(_mainchainToken.balanceOf(address(_gateway)), INITIAL_AMOUNT_MAINCHAIN - amount);
        assertEq(_mainchainToken.balanceOf(bob), amount - fee);
        assertEq(_mainchainToken.balanceOf(frank), fee);
        // check withdrawal hash
        assertEq(_gateway.getWithdrawalHash(withdrawalId), hash);
    }

    // case 1: invalid chainId
    function testWithdrawFail() public {
        // mint tokens to mainchain gateway contract
        _mainchainToken.mint(address(_gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = eve;
        address token = address(_mainchainToken);
        uint256 amount = 1 * 10 ** 6;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = _hash(
            _gateway.getDomainSeparator(),
            chainId,
            withdrawalId,
            recipient,
            token,
            amount,
            fee
        );
        DataTypes.Signature[] memory signatures = _getTwoSignatures(hash);

        // case 1: invalid chainId
        vm.expectRevert(abi.encodePacked("InvalidChainId"));
        vm.prank(eve);
        _gateway.withdraw(
            uint256(1001),
            withdrawalId,
            eve,
            address(_mainchainToken),
            amount,
            fee,
            signatures
        );

        // check balances
        assertEq(_mainchainToken.balanceOf(address(_gateway)), INITIAL_AMOUNT_MAINCHAIN);
        assertEq(_mainchainToken.balanceOf(eve), 0);
        // check withdrawal hash
        assertEq(_gateway.getWithdrawalHash(withdrawalId), bytes32(0));
    }

    // case 2: already withdrawn
    function testWithdrawFail2() public {
        // mint tokens to mainchain gateway contract
        _mainchainToken.mint(address(_gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = eve;
        address token = address(_mainchainToken);
        uint256 amount = 1 * 10 ** 6;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = _hash(
            _gateway.getDomainSeparator(),
            chainId,
            withdrawalId,
            recipient,
            token,
            amount,
            fee
        );
        DataTypes.Signature[] memory signatures = _getTwoSignatures(hash);

        vm.chainId(chainId); // set block.chainid
        _gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);

        // case 2: already withdrawn
        vm.expectRevert(abi.encodePacked("NotNewWithdrawal"));
        _gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);
    }

    // case 3: reached daily withdrawal max quota
    function testWithdrawFail3() public {
        // mint tokens to mainchain gateway contract
        _mainchainToken.mint(address(_gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = eve;
        address token = address(_mainchainToken);
        uint256 amount = 5 * 10 ** 6;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;

        vm.chainId(chainId); // set block.chainid

        for (uint256 i = 0; i < 20; i++) {
            withdrawalId = i;

            bytes32 hash = _hash(
                _gateway.getDomainSeparator(),
                chainId,
                withdrawalId,
                recipient,
                token,
                amount,
                fee
            );
            DataTypes.Signature[] memory signatures = _getThreeSignatures(hash);

            if (i == 19) {
                // case 3: reached daily withdrawal max quota
                vm.expectRevert(abi.encodePacked("DailyWithdrawalMaxQuota"));
                _gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);
                // check withdrawal hash
                assertEq(_gateway.getWithdrawalHash(withdrawalId), bytes32(0));
            } else {
                // expect events
                expectEmit(CheckAll);
                emit Withdrew(chainId, withdrawalId, recipient, token, amount, fee);
                _gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);
                // check withdrawal hash
                assertEq(_gateway.getWithdrawalHash(withdrawalId), hash);
            }
        }
    }

    // case 4: insufficient signatures number
    function testWithdrawFail4() public {
        // mint tokens to mainchain gateway contract
        _mainchainToken.mint(address(_gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = eve;
        address token = address(_mainchainToken);
        uint256 amount = 1 * 10 ** 6;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = _hash(
            _gateway.getDomainSeparator(),
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
        _gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);

        // check balances
        assertEq(_mainchainToken.balanceOf(address(_gateway)), INITIAL_AMOUNT_MAINCHAIN);
        assertEq(_mainchainToken.balanceOf(eve), 0);
        // check withdrawal hash
        assertEq(_gateway.getWithdrawalHash(withdrawalId), bytes32(0));
    }

    // case 5: invalid signer order
    function testWithdrawFail5() public {
        // mint tokens to mainchain gateway contract
        _mainchainToken.mint(address(_gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = eve;
        address token = address(_mainchainToken);
        uint256 amount = 1 * 10 ** 6;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = _hash(
            _gateway.getDomainSeparator(),
            chainId,
            withdrawalId,
            recipient,
            token,
            amount,
            fee
        );

        // generate validator signatures
        DataTypes.Signature[] memory signatures = new DataTypes.Signature[](3);
        signatures[0] = _getSignature(hash, _validator1PrivateKey);
        signatures[1] = _getSignature(hash, _validator2PrivateKey);
        signatures[2] = _getSignature(hash, _validator3PrivateKey);

        vm.chainId(chainId); // set block.chainid
        // case 5: invalid signer order
        vm.expectRevert(abi.encodePacked("InvalidSignerOrder"));
        _gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);

        // check balances
        assertEq(_mainchainToken.balanceOf(address(_gateway)), INITIAL_AMOUNT_MAINCHAIN);
        assertEq(_mainchainToken.balanceOf(eve), 0);
        // check withdrawal hash
        assertEq(_gateway.getWithdrawalHash(withdrawalId), bytes32(0));
    }

    // case 6: paused
    function testWithdrawFail6() public {
        // mint tokens to mainchain gateway contract
        _mainchainToken.mint(address(_gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = eve;
        address token = address(_mainchainToken);
        uint256 amount = 1 * 10 ** 6;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = _hash(
            _gateway.getDomainSeparator(),
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
        _gateway.pause();
        // case 6: paused
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        _gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);

        // check balances
        assertEq(_mainchainToken.balanceOf(address(_gateway)), INITIAL_AMOUNT_MAINCHAIN);
        assertEq(_mainchainToken.balanceOf(eve), 0);
        // check withdrawal hash
        assertEq(_gateway.getWithdrawalHash(withdrawalId), bytes32(0));
    }

    // case 7: gateway balance is insufficient
    function testWithdrawFail7() public {
        // withdrawal info
        address recipient = eve;
        address token = address(_mainchainToken);
        uint256 amount = 1 * 10 ** 6;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = _hash(
            _gateway.getDomainSeparator(),
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
        _gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);

        // check balances
        assertEq(_mainchainToken.balanceOf(address(_gateway)), 0);
        assertEq(_mainchainToken.balanceOf(eve), 0);
        // check withdrawal hash
        assertEq(_gateway.getWithdrawalHash(withdrawalId), bytes32(0));
    }

    // solhint-disable-next-line function-max-lines
    function testWithdrawWithDailyQuota() public {
        // mint tokens to mainchain gateway contract
        _mainchainToken.mint(address(_gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = bob;
        address token = address(_mainchainToken);
        uint256 amount = DAILY_WITHDRAWLAL_MAX_QUOTA / 20;
        uint256 fee = amount / 100;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;

        vm.chainId(chainId); // set block.chainid

        vm.startPrank(frank);
        for (uint256 i = 0; i < 20; i++) {
            withdrawalId = i;

            bytes32 hash = _hash(
                _gateway.getDomainSeparator(),
                chainId,
                withdrawalId,
                recipient,
                token,
                amount,
                fee
            );
            DataTypes.Signature[] memory signatures = _getThreeSignatures(hash);

            if (i == 19) {
                // the last withdrawal will reach the daily withdrawal max quota
                vm.expectRevert(abi.encodePacked("DailyWithdrawalMaxQuota"));
                _gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);

                // 1 days later, the max quota will restore
                skip(1 days);
            }
            // expect events
            expectEmit(CheckAll);
            emit Withdrew(chainId, withdrawalId, recipient, token, amount, fee);
            _gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);
            // check withdrawal hash
            assertEq(_gateway.getWithdrawalHash(withdrawalId), hash);
        }
        vm.stopPrank();

        // check balances
        assertEq(_mainchainToken.balanceOf(frank), fee * 20);
        assertEq(_mainchainToken.balanceOf(recipient), (amount - fee) * 20);
        assertEq(
            _mainchainToken.balanceOf(address(_gateway)),
            INITIAL_AMOUNT_MAINCHAIN - amount * 20
        );
    }

    function testGetDailyWithdrawalRemainingQuota() public {
        skip(10 days);

        address token = address(_mainchainToken);
        assertEq(
            _gateway.getDailyWithdrawalRemainingQuota(token),
            DAILY_WITHDRAWLAL_MAX_QUOTA,
            "1"
        );

        // mint tokens to mainchain gateway contract
        _mainchainToken.mint(address(_gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = eve;
        uint256 amount = 5 * 10 ** 6;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;

        uint256 remainingQuota = DAILY_WITHDRAWLAL_MAX_QUOTA;

        vm.chainId(chainId); // set block.chainid
        for (uint256 i = 0; i < 20; i++) {
            if (i == 19) {
                assertEq(_gateway.getDailyWithdrawalRemainingQuota(token), amount, "loop 19");
            } else {
                // withdraw
                bytes32 hash = _hash(
                    _gateway.getDomainSeparator(),
                    chainId,
                    i,
                    recipient,
                    token,
                    amount,
                    fee
                );
                DataTypes.Signature[] memory signatures = _getThreeSignatures(hash);
                _gateway.withdraw(chainId, i, recipient, token, amount, fee, signatures);

                // check remaining quota
                remainingQuota = remainingQuota - amount;
                assertEq(_gateway.getDailyWithdrawalRemainingQuota(token), remainingQuota, "loop");
            }
        }

        // 1 days later, the daily withdrawal max quota will be reset
        skip(1 days);
        assertEq(_gateway.getDailyWithdrawalRemainingQuota(token), DAILY_WITHDRAWLAL_MAX_QUOTA);
    }

    function _getOneSignature(
        bytes32 hash
    ) internal pure returns (DataTypes.Signature[] memory signatures) {
        signatures = new DataTypes.Signature[](1);
        signatures[0] = _getSignature(hash, _validator1PrivateKey);
    }

    function _getTwoSignatures(
        bytes32 hash
    ) internal pure returns (DataTypes.Signature[] memory signatures) {
        // note: for verifySignatures, signatures need to be arranged in ascending order of addresses
        // sorted address: validator1 > validator3 > validator2
        signatures = new DataTypes.Signature[](2);
        signatures[0] = _getSignature(hash, _validator2PrivateKey);
        signatures[1] = _getSignature(hash, _validator1PrivateKey);
        return signatures;
    }

    function _getThreeSignatures(
        bytes32 hash
    ) internal pure returns (DataTypes.Signature[] memory signatures) {
        // note: for verifySignatures, signatures need to be arranged in ascending order of addresses
        // sorted address: validator1 > validator3 > validator2
        signatures = new DataTypes.Signature[](3);
        signatures[0] = _getSignature(hash, _validator2PrivateKey);
        signatures[1] = _getSignature(hash, _validator3PrivateKey);
        signatures[2] = _getSignature(hash, _validator1PrivateKey);
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
        bytes32 domain,
        uint256 chainId,
        uint256 withdrawalId,
        address recipient,
        address token,
        uint256 amount,
        uint256 fee
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(domain, chainId, withdrawalId, recipient, token, amount, fee)
            );
    }
}
