// SPDX-License-Identifier: MIT
// solhint-disable comprehensive-interface
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "./helpers/Utils.sol";
import "../contracts/MainchainGateway.sol";
import "../contracts/Validator.sol";
import "../contracts/token/MintableERC20.sol";
import "../contracts/token/MiraToken.sol";
import "../contracts/upgradeability/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

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
    uint256 public constant validator1PrivateKey = 1;
    uint256 public constant validator2PrivateKey = 2;
    uint256 public constant validator3PrivateKey = 3;
    address public validator1 = vm.addr(validator1PrivateKey);
    address public validator2 = vm.addr(validator2PrivateKey);
    address public validator3 = vm.addr(validator3PrivateKey);

    MainchainGateway public gateway;
    Validator public validator;

    MintableERC20 public mainchainToken;
    MiraToken public crossbellToken;

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

    function setUp() public {
        // deploy ERC20 token
        mainchainToken = new MintableERC20("mainchain ERC20", "ERC20", 6);
        // deploy erc1820
        vm.etch(
            address(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24),
            bytes( // solhint-disable-next-line max-line-length
                hex"608060405234801561001057600080fd5b50600436106100a5576000357c010000000000000000000000000000000000000000000000000000000090048063a41e7d5111610078578063a41e7d51146101d4578063aabbb8ca1461020a578063b705676514610236578063f712f3e814610280576100a5565b806329965a1d146100aa5780633d584063146100e25780635df8122f1461012457806365ba36c114610152575b600080fd5b6100e0600480360360608110156100c057600080fd5b50600160a060020a038135811691602081013591604090910135166102b6565b005b610108600480360360208110156100f857600080fd5b5035600160a060020a0316610570565b60408051600160a060020a039092168252519081900360200190f35b6100e06004803603604081101561013a57600080fd5b50600160a060020a03813581169160200135166105bc565b6101c26004803603602081101561016857600080fd5b81019060208101813564010000000081111561018357600080fd5b82018360208201111561019557600080fd5b803590602001918460018302840111640100000000831117156101b757600080fd5b5090925090506106b3565b60408051918252519081900360200190f35b6100e0600480360360408110156101ea57600080fd5b508035600160a060020a03169060200135600160e060020a0319166106ee565b6101086004803603604081101561022057600080fd5b50600160a060020a038135169060200135610778565b61026c6004803603604081101561024c57600080fd5b508035600160a060020a03169060200135600160e060020a0319166107ef565b604080519115158252519081900360200190f35b61026c6004803603604081101561029657600080fd5b508035600160a060020a03169060200135600160e060020a0319166108aa565b6000600160a060020a038416156102cd57836102cf565b335b9050336102db82610570565b600160a060020a031614610339576040805160e560020a62461bcd02815260206004820152600f60248201527f4e6f7420746865206d616e616765720000000000000000000000000000000000604482015290519081900360640190fd5b6103428361092a565b15610397576040805160e560020a62461bcd02815260206004820152601a60248201527f4d757374206e6f7420626520616e204552433136352068617368000000000000604482015290519081900360640190fd5b600160a060020a038216158015906103b85750600160a060020a0382163314155b156104ff5760405160200180807f455243313832305f4143434550545f4d4147494300000000000000000000000081525060140190506040516020818303038152906040528051906020012082600160a060020a031663249cb3fa85846040518363ffffffff167c01000000000000000000000000000000000000000000000000000000000281526004018083815260200182600160a060020a0316600160a060020a031681526020019250505060206040518083038186803b15801561047e57600080fd5b505afa158015610492573d6000803e3d6000fd5b505050506040513d60208110156104a857600080fd5b5051146104ff576040805160e560020a62461bcd02815260206004820181905260248201527f446f6573206e6f7420696d706c656d656e742074686520696e74657266616365604482015290519081900360640190fd5b600160a060020a03818116600081815260208181526040808320888452909152808220805473ffffffffffffffffffffffffffffffffffffffff19169487169485179055518692917f93baa6efbd2244243bfee6ce4cfdd1d04fc4c0e9a786abd3a41313bd352db15391a450505050565b600160a060020a03818116600090815260016020526040812054909116151561059a5750806105b7565b50600160a060020a03808216600090815260016020526040902054165b919050565b336105c683610570565b600160a060020a031614610624576040805160e560020a62461bcd02815260206004820152600f60248201527f4e6f7420746865206d616e616765720000000000000000000000000000000000604482015290519081900360640190fd5b81600160a060020a031681600160a060020a0316146106435780610646565b60005b600160a060020a03838116600081815260016020526040808220805473ffffffffffffffffffffffffffffffffffffffff19169585169590951790945592519184169290917f605c2dbf762e5f7d60a546d42e7205dcb1b011ebc62a61736a57c9089d3a43509190a35050565b600082826040516020018083838082843780830192505050925050506040516020818303038152906040528051906020012090505b92915050565b6106f882826107ef565b610703576000610705565b815b600160a060020a03928316600081815260208181526040808320600160e060020a031996909616808452958252808320805473ffffffffffffffffffffffffffffffffffffffff19169590971694909417909555908152600284528181209281529190925220805460ff19166001179055565b600080600160a060020a038416156107905783610792565b335b905061079d8361092a565b156107c357826107ad82826108aa565b6107b85760006107ba565b815b925050506106e8565b600160a060020a0390811660009081526020818152604080832086845290915290205416905092915050565b6000808061081d857f01ffc9a70000000000000000000000000000000000000000000000000000000061094c565b909250905081158061082d575080155b1561083d576000925050506106e8565b61084f85600160e060020a031961094c565b909250905081158061086057508015155b15610870576000925050506106e8565b61087a858561094c565b909250905060018214801561088f5750806001145b1561089f576001925050506106e8565b506000949350505050565b600160a060020a0382166000908152600260209081526040808320600160e060020a03198516845290915281205460ff1615156108f2576108eb83836107ef565b90506106e8565b50600160a060020a03808316600081815260208181526040808320600160e060020a0319871684529091529020549091161492915050565b7bffffffffffffffffffffffffffffffffffffffffffffffffffffffff161590565b6040517f01ffc9a7000000000000000000000000000000000000000000000000000000008082526004820183905260009182919060208160248189617530fa90519096909550935050505056fea165627a7a72305820377f4a2d4301ede9949f163f319021a6e9c687c292a5e2b2c4734c126b524e6c0029"
            )
        );
        // deploy Mira token
        crossbellToken = new MiraToken("crossbell Mira", "MIRA", address(this));

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
            array(address(mainchainToken)),
            array(DAILY_WITHDRAWLAL_MAX_QUOTA),
            array(address(crossbellToken)),
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
            array(address(mainchainToken)),
            array(DAILY_WITHDRAWLAL_MAX_QUOTA),
            array(address(crossbellToken)),
            decimals
        );

        // check status
        assertEq(gateway.getValidatorContract(), address(validator));
        assertEq(gateway.hasRole(ADMIN_ROLE, admin), true);
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

    function testSetDailyWithdrawalQuotas() public {
        address[] memory tokens = array(address(0x0001), address(0x0002));
        uint256[] memory quotas = array(111, 222);

        // expect events
        expectEmit(CheckAll);
        emit DailyWithdrawalMaxQuotasUpdated(tokens, quotas);
        vm.prank(admin);
        gateway.setDailyWithdrawalMaxQuotas(tokens, quotas);
        // check states
        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(gateway.getDailyWithdrawalMaxQuota(tokens[i]), quotas[i]);
        }

        // set new quotas
        uint256[] memory newQuotas = array(333, 444);
        vm.prank(admin);
        gateway.setDailyWithdrawalMaxQuotas(tokens, newQuotas);
        // check states
        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(gateway.getDailyWithdrawalMaxQuota(tokens[i]), newQuotas[i]);
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
        gateway.setDailyWithdrawalMaxQuotas(tokens, quotas);

        // check states
        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(gateway.getDailyWithdrawalMaxQuota(tokens[i]), 0);
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
                address(crossbellToken),
                transformedAmount
            )
        );

        vm.startPrank(recipient);
        // approve token
        mainchainToken.approve(address(gateway), amount);
        // expect events
        expectEmit(CheckAll);
        emit Transfer(recipient, address(gateway), amount);
        expectEmit(CheckAll);
        emit RequestDeposit(
            block.chainid,
            0,
            recipient,
            address(crossbellToken),
            transformedAmount,
            depositHash
        );
        // requestDeposit
        gateway.requestDeposit(recipient, address(mainchainToken), amount);
        vm.stopPrank();

        // check balances
        assertEq(mainchainToken.balanceOf(address(gateway)), amount);
        assertEq(mainchainToken.balanceOf(recipient), INITIAL_AMOUNT_MAINCHAIN - amount);
        // check deposit count
        assertEq(gateway.getDepositCount(), 1);
    }

    function testRequestDepositFail() public {
        uint256 amount = 1 ether;
        address fakeToken = address(0x0001);

        // case 1: ZeroAmount
        vm.expectRevert(abi.encodePacked("ZeroAmount"));
        vm.prank(alice);
        gateway.requestDeposit(alice, fakeToken, 0);

        // case 2: unmapped token
        vm.expectRevert(abi.encodePacked("UnsupportedToken"));
        vm.prank(alice);
        gateway.requestDeposit(alice, fakeToken, amount);

        // case 3: insufficient balance
        vm.startPrank(alice);
        // approve token
        mainchainToken.approve(address(gateway), type(uint256).max);
        uint256 depositAmount = mainchainToken.balanceOf(alice) + 1;
        vm.expectRevert(abi.encodePacked("ERC20: transfer amount exceeds balance"));
        // deposit
        gateway.requestDeposit(alice, address(mainchainToken), depositAmount);
        vm.stopPrank();

        // case 4: paused
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
    function testWithdraw(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < WITHDRAWLAL_THRESHOLD);

        // mint tokens to mainchain gateway contract
        mainchainToken.mint(address(gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = bob;
        address token = address(mainchainToken);
        uint256 fee = amount / 20;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = _hash(
            gateway.getDomainSeparator(),
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
        gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);

        // check balances
        assertEq(mainchainToken.balanceOf(address(gateway)), INITIAL_AMOUNT_MAINCHAIN - amount);
        assertEq(mainchainToken.balanceOf(bob), amount - fee);
        assertEq(mainchainToken.balanceOf(frank), fee);
        // check withdrawal hash
        assertEq(gateway.getWithdrawalHash(withdrawalId), hash);
    }

    // case 1: invalid chainId
    function testWithdrawFail() public {
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
            gateway.getDomainSeparator(),
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
        gateway.withdraw(
            uint256(1001),
            withdrawalId,
            eve,
            address(mainchainToken),
            amount,
            fee,
            signatures
        );

        // check balances
        assertEq(mainchainToken.balanceOf(address(gateway)), INITIAL_AMOUNT_MAINCHAIN);
        assertEq(mainchainToken.balanceOf(eve), 0);
        // check withdrawal hash
        assertEq(gateway.getWithdrawalHash(withdrawalId), bytes32(0));
    }

    // case 2: already withdrawn
    function testWithdrawFail2() public {
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
            gateway.getDomainSeparator(),
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

    // case 3: reached daily withdrawal max quota
    function testWithdrawFail3() public {
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
                gateway.getDomainSeparator(),
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
                gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);
                // check withdrawal hash
                assertEq(gateway.getWithdrawalHash(withdrawalId), bytes32(0));
            } else {
                // expect events
                expectEmit(CheckAll);
                emit Withdrew(chainId, withdrawalId, recipient, token, amount, fee);
                gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);
                // check withdrawal hash
                assertEq(gateway.getWithdrawalHash(withdrawalId), hash);
            }
        }
    }

    // case 4: insufficient signatures number
    function testWithdrawFail4() public {
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
            gateway.getDomainSeparator(),
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
    function testWithdrawFail5() public {
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
            gateway.getDomainSeparator(),
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
    function testWithdrawFail6() public {
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
            gateway.getDomainSeparator(),
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
    function testWithdrawFail7() public {
        // withdrawal info
        address recipient = eve;
        address token = address(mainchainToken);
        uint256 amount = 1 * 10 ** 6;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;
        bytes32 hash = _hash(
            gateway.getDomainSeparator(),
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

    // solhint-disable-next-line function-max-lines
    function testWithdrawWithDailyQuota() public {
        // mint tokens to mainchain gateway contract
        mainchainToken.mint(address(gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = bob;
        address token = address(mainchainToken);
        uint256 amount = DAILY_WITHDRAWLAL_MAX_QUOTA / 20;
        uint256 fee = amount / 100;
        uint256 chainId = 1337;
        uint256 withdrawalId = 1;

        vm.chainId(chainId); // set block.chainid

        vm.startPrank(frank);
        for (uint256 i = 0; i < 20; i++) {
            withdrawalId = i;

            bytes32 hash = _hash(
                gateway.getDomainSeparator(),
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
                gateway.withdraw(chainId, withdrawalId, recipient, token, amount, fee, signatures);

                // 1 days later, the max quota will restore
                skip(1 days);
            }
            // expect events
            expectEmit(CheckAll);
            emit Withdrew(chainId, withdrawalId, recipient, token, amount, fee);
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

    function testGetDailyWithdrawalRemainingQuota() public {
        skip(10 days);

        address token = address(mainchainToken);
        assertEq(gateway.getDailyWithdrawalRemainingQuota(token), DAILY_WITHDRAWLAL_MAX_QUOTA, "1");

        // mint tokens to mainchain gateway contract
        mainchainToken.mint(address(gateway), INITIAL_AMOUNT_MAINCHAIN);

        // withdrawal info
        address recipient = eve;
        uint256 amount = 5 * 10 ** 6;
        uint256 fee = 1 * 10 ** 5;
        uint256 chainId = 1337;

        uint256 remainingQuota = DAILY_WITHDRAWLAL_MAX_QUOTA;

        vm.chainId(chainId); // set block.chainid
        for (uint256 i = 0; i < 20; i++) {
            if (i == 19) {
                assertEq(gateway.getDailyWithdrawalRemainingQuota(token), amount, "loop 19");
            } else {
                // withdraw
                bytes32 hash = _hash(
                    gateway.getDomainSeparator(),
                    chainId,
                    i,
                    recipient,
                    token,
                    amount,
                    fee
                );
                DataTypes.Signature[] memory signatures = _getThreeSignatures(hash);
                gateway.withdraw(chainId, i, recipient, token, amount, fee, signatures);

                // check remaining quota
                remainingQuota = remainingQuota - amount;
                assertEq(gateway.getDailyWithdrawalRemainingQuota(token), remainingQuota, "loop");
            }
        }

        // 1 days later, the daily withdrawal max quota will be reset
        skip(1 days);
        assertEq(gateway.getDailyWithdrawalRemainingQuota(token), DAILY_WITHDRAWLAL_MAX_QUOTA);
    }

    function _getOneSignature(
        bytes32 hash
    ) internal pure returns (DataTypes.Signature[] memory signatures) {
        signatures = new DataTypes.Signature[](1);
        signatures[0] = _getSignature(hash, validator1PrivateKey);
    }

    function _getTwoSignatures(
        bytes32 hash
    ) internal pure returns (DataTypes.Signature[] memory signatures) {
        // note: for verifySignatures, signatures need to be arranged in ascending order of addresses
        // sorted address: validator1 > validator3 > validator2
        signatures = new DataTypes.Signature[](2);
        signatures[0] = _getSignature(hash, validator2PrivateKey);
        signatures[1] = _getSignature(hash, validator1PrivateKey);
        return signatures;
    }

    function _getThreeSignatures(
        bytes32 hash
    ) internal pure returns (DataTypes.Signature[] memory signatures) {
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
