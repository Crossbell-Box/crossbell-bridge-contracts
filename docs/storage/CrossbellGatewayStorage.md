# Solidity API

## CrossbellGatewayStorage

_Storage of deposit and withdraw information._

### _deposits

```solidity
mapping(uint256 => mapping(uint256 => struct DataTypes.DepositEntry)) _deposits
```

### _withdrawalCounter

```solidity
mapping(uint256 => uint256) _withdrawalCounter
```

### _withdrawals

```solidity
mapping(uint256 => mapping(uint256 => struct DataTypes.WithdrawalEntry)) _withdrawals
```

### _withdrawalSig

```solidity
mapping(uint256 => mapping(uint256 => mapping(address => bytes))) _withdrawalSig
```

### _withdrawalSigners

```solidity
mapping(uint256 => mapping(uint256 => address[])) _withdrawalSigners
```

### _mainchainTokens

```solidity
mapping(address => mapping(uint256 => struct DataTypes.MappedToken)) _mainchainTokens
```

### _validator

```solidity
address _validator
```

### _validatorAck

```solidity
mapping(uint256 => mapping(uint256 => mapping(address => bytes32))) _validatorAck
```

### _ackCount

```solidity
mapping(uint256 => mapping(uint256 => mapping(bytes32 => uint256))) _ackCount
```

### _ackStatus

```solidity
mapping(uint256 => mapping(uint256 => mapping(bytes32 => enum DataTypes.Status))) _ackStatus
```

