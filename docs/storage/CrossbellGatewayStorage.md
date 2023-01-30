# Solidity API

## CrossbellGatewayStorage

_Storage of deposit and withdraw information._

### _deposits

```solidity
mapping(uint256 => mapping(uint256 => struct DataTypes.DepositEntry)) _deposits
```

_Mapping from chainId => depositId => DepositEntry_

### _withdrawalCounter

```solidity
mapping(uint256 => uint256) _withdrawalCounter
```

_Mapping from chainId => withdrawCount_

### _withdrawals

```solidity
mapping(uint256 => mapping(uint256 => struct DataTypes.WithdrawalEntry)) _withdrawals
```

_Mapping from chainId =>  withdrawalId => WithdrawalEntry_

### _withdrawalSig

```solidity
mapping(uint256 => mapping(uint256 => mapping(address => bytes))) _withdrawalSig
```

_Mapping from chainId => withdrawalId  => signature_

### _withdrawalSigners

```solidity
mapping(uint256 => mapping(uint256 => address[])) _withdrawalSigners
```

_Mapping from chainId => withdrawalId => address[]_

### _mainchainTokens

```solidity
mapping(address => mapping(uint256 => struct DataTypes.MappedToken)) _mainchainTokens
```

_Mapping from token address => chain id => mainchain token address_

### _validator

```solidity
address _validator
```

### _validatorAck

```solidity
mapping(uint256 => mapping(uint256 => mapping(address => bytes32))) _validatorAck
```

_Mapping from chainId => id => validator => data hash_

### _ackCount

```solidity
mapping(uint256 => mapping(uint256 => mapping(bytes32 => uint256))) _ackCount
```

_Mapping from chainId => id => data hash => ack count_

### _ackStatus

```solidity
mapping(uint256 => mapping(uint256 => mapping(bytes32 => enum DataTypes.Status))) _ackStatus
```

_Mapping from chainId => id => data hash => ack status_

