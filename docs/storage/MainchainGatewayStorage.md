# Solidity API

## MainchainGatewayStorage

_Storage of deposit and withdraw information._

### _domainSeparator

```solidity
bytes32 _domainSeparator
```

_Domain separator_

### _validator

```solidity
address _validator
```

_Validator contract address_

### _depositCounter

```solidity
uint256 _depositCounter
```

_Total deposit count_

### _withdrawalHash

```solidity
mapping(uint256 => bytes32) _withdrawalHash
```

_Mapping from withdrawal id => withdrawal hash_

### _dailyWithdrawalMaxQuota

```solidity
mapping(address => uint256) _dailyWithdrawalMaxQuota
```

for withdrawal restriction

_Mapping from mainchain token => daily max amount for withdrawal_

### _lastSyncedWithdrawal

```solidity
mapping(address => uint256) _lastSyncedWithdrawal
```

_Mapping from token address => today withdrawal amount_

### _lastDateSynced

```solidity
mapping(address => uint256) _lastDateSynced
```

_Mapping from token address => last date synced to record the `_lastSyncedWithdrawal`_

### _crossbellTokens

```solidity
mapping(address => struct DataTypes.MappedToken) _crossbellTokens
```

_Mapping from mainchain token => token address on crossbell network_

