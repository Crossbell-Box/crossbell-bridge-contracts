// SPDX-License-Identifier: MIT
// solhint-disable comprehensive-interface
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "./helpers/Utils.sol";
import "../contracts/libraries/DataTypes.sol";
import "../contracts/CrossbellGateway.sol";
import "../contracts/Validator.sol";
import "../contracts/token/MintableERC20.sol";
import "../contracts/token/MintableERC20.sol";
import "../contracts/token/MiraToken.sol";
import "../contracts/upgradeability/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CrossbellGatewayTest is Test, Utils {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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

    CrossbellGateway public gateway;
    Validator public validator;

    MintableERC20 public mainchainToken;
    MiraToken public crossbellToken;

    // initial balances: 100 tokens
    uint256 public constant INITIAL_AMOUNT_MAINCHAIN = 200 * 10 ** 6;
    uint256 public constant INITIAL_AMOUNT_CROSSBELL = 200 * 10 ** 18;

    uint256 public constant MAINCHAIN_CHAIN_ID = 1;

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
    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
    event Minted(
        address indexed operator,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
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
        address indexed validator,
        address recipient,
        address token,
        uint256 amount
    );
    event RequestWithdrawal(
        uint256 indexed chainId,
        uint256 indexed withdrawalId,
        address indexed recipient,
        address token,
        uint256 amount,
        uint256 fee
    );
    event SubmitWithdrawalSignature(
        uint256 indexed chainId,
        uint256 indexed withdrawalId,
        address indexed validator,
        bytes signature
    );

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
        decimals[0] = 6;

        // init [validator1, validator2, validator3] as validators, with requiredNumber 2
        validator = new Validator(array(validator1, validator2, validator3), 2);

        // setup CrossbellGateway
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

    // solhint-disable-next-line function-max-lines
    function testAckDeposit(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < INITIAL_AMOUNT_CROSSBELL);

        // mint tokens to gateway contract
        crossbellToken.mint(address(gateway), INITIAL_AMOUNT_CROSSBELL);

        uint256 chainId = 1337;
        uint256 depositId = 1;
        address recipient = bob;
        address token = address(crossbellToken);
        bytes32 depositHash = keccak256(
            abi.encodePacked(chainId, depositId, recipient, token, amount)
        );

        // validator1 acknowledges deposit (validator acknowledgement threshold 2/3)
        // expect events
        expectEmit(CheckAll);
        emit AckDeposit(chainId, depositId, validator1, recipient, token, amount);
        vm.prank(validator1);
        gateway.ackDeposit(chainId, depositId, recipient, token, amount, depositHash);
        // check state
        _checkAcknowledgementStatus(
            chainId,
            depositId,
            [validator1, validator2, validator3],
            [depositHash, bytes32(0), bytes32(0)],
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
        emit AckDeposit(chainId, depositId, validator2, recipient, token, amount);
        vm.prank(validator2);
        gateway.ackDeposit(chainId, depositId, recipient, token, amount, depositHash);
        // check state
        _checkAcknowledgementStatus(
            chainId,
            depositId,
            [validator1, validator2, validator3],
            [depositHash, depositHash, bytes32(0)],
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
        emit AckDeposit(chainId, depositId, validator3, recipient, token, amount);
        vm.prank(validator3);
        gateway.ackDeposit(chainId, depositId, recipient, token, amount, depositHash);
        // check state
        _checkAcknowledgementStatus(
            chainId,
            depositId,
            [validator1, validator2, validator3],
            [depositHash, depositHash, depositHash],
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

    // solhint-disable-next-line function-max-lines
    function testAckDepositWithMint(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < type(uint256).max - INITIAL_AMOUNT_MAINCHAIN * 2);

        // grant `DEFAULT_ADMIN_ROLE` to gateway
        crossbellToken.grantRole(DEFAULT_ADMIN_ROLE, address(gateway));

        uint256 chainId = 1337;
        uint256 depositId = 1;
        address recipient = bob;
        address token = address(crossbellToken);
        bytes32 depositHash = keccak256(
            abi.encodePacked(chainId, depositId, recipient, token, amount)
        );

        // validator1 acknowledges deposit (validator acknowledgement threshold 2/3)
        vm.prank(validator1);
        gateway.ackDeposit(chainId, depositId, recipient, token, amount, depositHash);
        // check state
        _checkAcknowledgementStatus(
            chainId,
            depositId,
            [validator1, validator2, validator3],
            [depositHash, bytes32(0), bytes32(0)],
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
        emit Minted(address(gateway), address(gateway), amount, "", "");
        expectEmit(CheckAll);
        emit Transfer(address(0), address(gateway), amount); // mint tokens to gateway
        expectEmit(CheckAll);
        emit Sent(address(gateway), address(gateway), recipient, amount, "", "");
        expectEmit(CheckAll);
        emit Transfer(address(gateway), recipient, amount); // transfer tokens from gateway to recipient
        expectEmit(CheckAll);
        emit Deposited(chainId, depositId, recipient, token, amount);
        expectEmit(CheckAll);
        emit AckDeposit(chainId, depositId, validator2, recipient, token, amount);
        vm.prank(validator2);
        gateway.ackDeposit(chainId, depositId, recipient, token, amount, depositHash);
        // check state
        _checkAcknowledgementStatus(
            chainId,
            depositId,
            [validator1, validator2, validator3],
            [depositHash, depositHash, bytes32(0)],
            DataTypes.Status.FirstApproved,
            2
        );
        // check balances
        // deposit is approved, so bob's balance is `amount`
        assertEq(crossbellToken.balanceOf(address(gateway)), 0, "gateway");
        assertEq(crossbellToken.balanceOf(address(recipient)), amount, "recipient");
    }

    function testAckDepositFail1(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < INITIAL_AMOUNT_MAINCHAIN);

        uint256 chainId = 1337;
        uint256 depositId = 1;
        address recipient = bob;
        address token = address(crossbellToken);
        bytes32 depositHash = keccak256(
            abi.encodePacked(chainId, depositId, recipient, token, amount)
        );

        // case 1: call is not validator
        vm.expectRevert(abi.encodePacked("NotValidator"));
        vm.prank(eve);
        gateway.ackDeposit(chainId, depositId, recipient, token, amount, depositHash);

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

    function testAckDepositFail2(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < INITIAL_AMOUNT_MAINCHAIN);

        uint256 chainId = 1337;
        uint256 depositId = 1;
        address recipient = bob;
        address token = address(crossbellToken);
        bytes32 depositHash = keccak256(
            abi.encodePacked(chainId, depositId, recipient, token, amount)
        );
        // case 2: paused
        vm.prank(admin);
        gateway.pause();
        // validator ackDeposit
        for (uint256 i = 0; i < 3; i++) {
            vm.expectRevert(abi.encodePacked("Pausable: paused"));
            vm.prank([validator1, validator2, validator3][i]);
            gateway.ackDeposit(chainId, depositId, recipient, token, amount, depositHash);
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
    function testAckDepositFail3(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < INITIAL_AMOUNT_MAINCHAIN);

        // mint tokens to gateway contract
        crossbellToken.mint(address(gateway), INITIAL_AMOUNT_CROSSBELL);

        uint256 chainId = 1337;
        uint256 depositId = 1;
        address recipient = bob;
        address token = address(crossbellToken);
        bytes32 depositHash = keccak256(
            abi.encodePacked(chainId, depositId, recipient, token, amount)
        );

        // case 3: validator already acknowledged
        vm.prank(validator1);
        gateway.ackDeposit(chainId, depositId, recipient, token, amount, depositHash);
        vm.expectRevert(abi.encodePacked("AlreadyAcknowledged"));
        vm.prank(validator1);
        gateway.ackDeposit(chainId, depositId, recipient, token, amount, depositHash);

        // check state
        _checkAcknowledgementStatus(
            chainId,
            depositId,
            [validator1, validator2, validator3],
            [depositHash, bytes32(0), bytes32(0)],
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

    // case 4: invalid depositHash
    function testAckDepositFail4(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < INITIAL_AMOUNT_MAINCHAIN);

        // mint tokens to gateway co   vm.assume(amount > 0);
        crossbellToken.mint(address(gateway), INITIAL_AMOUNT_CROSSBELL);

        uint256 chainId = 1337;
        uint256 depositId = 1;
        address recipient = bob;
        address token = address(crossbellToken);
        bytes32 depositHash = keccak256(
            abi.encodePacked(chainId, depositId, recipient, token, amount + 1)
        );

        // case 4: invalid depositHash
        vm.expectRevert(abi.encodePacked("InvalidHashCheck"));
        vm.prank(validator1);
        gateway.ackDeposit(chainId, depositId, recipient, token, amount, depositHash);

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
        assertEq(
            crossbellToken.balanceOf(address(gateway)),
            INITIAL_AMOUNT_CROSSBELL,
            "gateway balance"
        );
        assertEq(crossbellToken.balanceOf(address(recipient)), 0, "recipient balance ");
    }

    // solhint-disable-next-line function-max-lines
    function testBatchAckDeposit(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < INITIAL_AMOUNT_MAINCHAIN);

        // mint tokens to gateway contract
        crossbellToken.mint(address(gateway), INITIAL_AMOUNT_CROSSBELL);

        address token = address(crossbellToken);
        bytes32 hashBob = keccak256(abi.encodePacked(uint256(1), uint256(1), bob, token, amount));
        bytes32 hashCarol = keccak256(
            abi.encodePacked(uint256(1337), uint256(2), carol, token, amount)
        );

        // validator1 acknowledges deposit (validator acknowledgement threshold 2/3)
        // expect events
        expectEmit(CheckAll);
        emit AckDeposit(1, 1, validator1, bob, token, amount);
        expectEmit(CheckAll);
        emit AckDeposit(1337, 2, validator1, carol, token, amount);
        vm.prank(validator1);
        gateway.batchAckDeposit(
            array(1, 1337),
            array(1, 2),
            array(bob, carol),
            array(token, token),
            array(amount, amount),
            array(hashBob, hashCarol)
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
            array(amount, amount),
            array(hashBob, hashCarol)
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
        emit AckDeposit(1, 1, validator3, bob, token, amount);
        expectEmit(CheckAll);
        emit AckDeposit(1337, 2, validator3, carol, token, amount);
        vm.prank(validator3);
        gateway.batchAckDeposit(
            array(1, 1337),
            array(1, 2),
            array(bob, carol),
            array(token, token),
            array(amount, amount),
            array(hashBob, hashCarol)
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

    function testBatchAckDepositFail(uint256 amount) public {
        address token = address(crossbellToken);

        // case 1: InvalidArrayLength
        vm.expectRevert(abi.encodePacked("InvalidArrayLength"));
        vm.prank(validator1);
        gateway.batchAckDeposit(
            array(1, 1337),
            array(1, 2),
            array(bob, carol),
            array(token),
            array(amount, amount),
            array(bytes32(0), bytes32(0))
        );

        // case 2: call is not validator
        vm.expectRevert(abi.encodePacked("NotValidator"));
        vm.prank(eve);
        gateway.batchAckDeposit(
            array(1, 1337),
            array(1, 2),
            array(bob, carol),
            array(token),
            array(amount, amount),
            array(bytes32(0), bytes32(0))
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
            array(amount, amount),
            array(bytes32(0), bytes32(0))
        );

        // check balances
        assertEq(crossbellToken.balanceOf(eve), 0);
    }

    function testRequestWithdrawal(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < INITIAL_AMOUNT_CROSSBELL);

        uint256 chainId = 1;
        uint256 withdrawalId = 0;
        address recipient = alice;
        address token = address(crossbellToken);
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
    function testRequestWithdrawalFail(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < INITIAL_AMOUNT_MAINCHAIN);

        uint256 chainId = 1;
        address recipient = alice;
        address token = address(crossbellToken);
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
    function testRequestWithdrawalFail2() public {
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
    function testRequestWithdrawalFail3(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < INITIAL_AMOUNT_MAINCHAIN);

        uint256 chainId = 1;
        address recipient = alice;
        address token = address(crossbellToken);
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
    function testRequestWithdrawalFail4(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < INITIAL_AMOUNT_MAINCHAIN);

        uint256 chainId = 1;
        address recipient = alice;
        address token = address(0x000001);
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
    function testRequestWithdrawalFail5() public {
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
        vm.expectRevert(abi.encodePacked("ERC777: transfer amount exceeds balance"));
        gateway.requestWithdrawal(chainId, recipient, token, amount, fee);
        vm.stopPrank();

        // check state
        assertEq(gateway.getWithdrawalCount(chainId), 0);
        // check balances
        assertEq(crossbellToken.balanceOf(alice), INITIAL_AMOUNT_CROSSBELL);
        assertEq(crossbellToken.balanceOf(address(gateway)), 0);
    }

    function testSubmitWithdrawalSignature() public {
        uint256 chainId = 1;
        uint256 withdrawalId = 1;

        bytes memory sig1 = bytes("signature1");
        bytes memory sig2 = bytes("signature2");
        bytes memory sig3 = bytes("signature3");

        // submit withdrawal signatures
        // expect events
        expectEmit(CheckAll);
        emit SubmitWithdrawalSignature(chainId, withdrawalId, validator1, sig1);
        vm.prank(validator1);
        gateway.submitWithdrawalSignature(chainId, withdrawalId, sig1);
        expectEmit(CheckAll);
        emit SubmitWithdrawalSignature(chainId, withdrawalId, validator2, sig2);
        vm.prank(validator2);
        gateway.submitWithdrawalSignature(chainId, withdrawalId, sig2);
        expectEmit(CheckAll);
        emit SubmitWithdrawalSignature(chainId, withdrawalId, validator3, sig3);
        vm.prank(validator3);
        gateway.submitWithdrawalSignature(chainId, withdrawalId, sig3);

        // check state
        (address[] memory signers, bytes[] memory sigs) = gateway.getWithdrawalSignatures(
            chainId,
            withdrawalId
        );
        assertEq(signers, array(validator1, validator2, validator3));
        assertEq(sigs[0], bytes("signature1"));
        assertEq(sigs[1], bytes("signature2"));
        assertEq(sigs[2], bytes("signature3"));

        // validator3 replaces signature
        vm.prank(validator3);
        gateway.submitWithdrawalSignature(chainId, withdrawalId, bytes("signature333"));
        (signers, sigs) = gateway.getWithdrawalSignatures(chainId, withdrawalId);
        assertEq(signers, array(validator1, validator2, validator3));
        assertEq(sigs[0], bytes("signature1"));
        assertEq(sigs[1], bytes("signature2"));
        assertEq(sigs[2], bytes("signature333"));
    }

    function testSubmitWithdrawalSignatureFail() public {
        uint256 chainId = 1;
        uint256 withdrawalId = 1;

        // case 1: caller is not validator
        vm.expectRevert(abi.encodePacked("NotValidator"));
        vm.prank(eve);
        gateway.submitWithdrawalSignature(chainId, withdrawalId, bytes("signature1"));

        // case 2: paused
        vm.prank(admin);
        gateway.pause();
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        vm.prank(validator1);
        gateway.submitWithdrawalSignature(chainId, withdrawalId, bytes("signature1"));
    }

    function testBatchSubmitWithdrawalSignatures() public {
        bytes memory sig1 = bytes("signature1");
        bytes memory sig2 = bytes("signature2");
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = sig1;
        signatures[1] = sig2;

        // submit withdrawal signatures
        // expect events
        expectEmit(CheckAll);
        emit SubmitWithdrawalSignature(1, 3, validator1, sig1);
        expectEmit(CheckAll);
        emit SubmitWithdrawalSignature(2, 4, validator1, sig2);
        vm.prank(validator1);
        gateway.batchSubmitWithdrawalSignatures(array(1, 2), array(3, 4), signatures);

        // check state
        (address[] memory signers, bytes[] memory sigs) = gateway.getWithdrawalSignatures(1, 3);
        assertEq(signers, array(validator1));
        assertEq(sigs[0], sig1);

        (signers, sigs) = gateway.getWithdrawalSignatures(2, 4);
        assertEq(signers, array(validator1));
        assertEq(sigs[0], sig2);
    }

    function testBatchSubmitWithdrawalSignaturesFail() public {
        bytes memory sig1 = bytes("signature1");
        bytes memory sig2 = bytes("signature2");
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = sig1;
        signatures[1] = sig2;

        // case 1: InvalidArrayLength
        vm.expectRevert(abi.encodePacked("InvalidArrayLength"));
        vm.prank(validator1);
        gateway.batchSubmitWithdrawalSignatures(array(1, 2), array(4), signatures);

        // case 2: not validator
        vm.expectRevert(abi.encodePacked("NotValidator"));
        gateway.batchSubmitWithdrawalSignatures(array(1, 2), array(3, 4), signatures);

        // case 3: paused
        vm.prank(admin);
        gateway.pause();
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        gateway.batchSubmitWithdrawalSignatures(array(1, 2), array(3, 4), signatures);
    }

    function testTokensReceivedFail() public {
        vm.expectRevert(abi.encodePacked("ShouldRevertReceive"));
        vm.prank(alice);
        // solhint-disable-next-line check-send-result
        crossbellToken.send(address(gateway), 1 ether, abi.encode(uint256(1), address(alice)));
    }

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
