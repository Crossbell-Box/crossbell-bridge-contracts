# Solidity API

## MainchainGateway

_Logic to handle deposits and withdrawals on mainchain._

### TYPE_HASH

```solidity
bytes32 TYPE_HASH
```

### ADMIN_ROLE

```solidity
bytes32 ADMIN_ROLE
```

### WITHDRAWAL_UNLOCKER_ROLE

```solidity
bytes32 WITHDRAWAL_UNLOCKER_ROLE
```

### initialize

```solidity
function initialize(address validator, address admin, address withdrawalAuditor, address[] mainchainTokens, uint256[] lockedThresholds, address[] crossbellTokens, uint8[] crossbellTokenDecimals) external
```

### pause

```solidity
function pause() external
```

Pause interaction with the gateway contract

### unpause

```solidity
function unpause() external
```

Resume interaction with the gateway contract

### requestDeposit

```solidity
function requestDeposit(address recipient, address token, uint256 amount) external returns (uint256 depositId)
```

Request deposit to crossbell chain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| recipient | address | Address to receive deposit on crossbell chain |
| token | address | Address of token to deposit |
| amount | uint256 | Amount of token to deposit |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| depositId | uint256 | Deposit id |

### withdraw

```solidity
function withdraw(uint256 chainId, uint256 withdrawalId, address recipient, address token, uint256 amount, bytes signatures) external returns (bool locked)
```

Withdraw based on the validator signatures.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | ChainId |
| withdrawalId | uint256 | Withdrawal ID from crossbell chain |
| recipient | address | Address to receive withdrawal on mainchain chain |
| token | address | Address of token to withdraw |
| amount | uint256 | Amount of token to withdraw |
| signatures | bytes | Validator signatures for withdrawal |

### unlockWithdrawal

```solidity
function unlockWithdrawal(uint256 chainId, uint256 withdrawalId, address recipient, address token, uint256 amount) external
```

Approves a specific withdrawal..
Note that the caller must have WITHDRAWAL_UNLOCKER_ROLE.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | ChainId |
| withdrawalId | uint256 | Withdrawal ID from crossbell chain |
| recipient | address | Address to receive withdrawal on mainchain chain |
| token | address | Address of token to withdraw |
| amount | uint256 | Amount of token to withdraw |

### setLockedThresholds

```solidity
function setLockedThresholds(address[] tokens, uint256[] thresholds) external
```

Sets the amount thresholds to lock withdrawal.

### verifySignatures

```solidity
function verifySignatures(bytes32 hash, bytes signatures) external view returns (bool)
```

Returns true if there is enough signatures from validators.

### getValidatorContract

```solidity
function getValidatorContract() external view returns (address)
```

Returns the address of the validator contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The validator contract address |

### getDepositCount

```solidity
function getDepositCount() external view returns (uint256)
```

Returns the deposit count of the gateway contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The deposit count |

### getWithdrawalHash

```solidity
function getWithdrawalHash(uint256 withdrawalId) external view returns (bytes32)
```

Returns the withdrawal hash by withdrawal id.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| withdrawalId | uint256 | WithdrawalId to query |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | The withdrawal hash |

### getCrossbellToken

```solidity
function getCrossbellToken(address mainchainToken) external view returns (struct DataTypes.MappedToken token)
```

Get mapped tokens from crossbell chain

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| mainchainToken | address | Token address on mainchain |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | struct DataTypes.MappedToken | Mapped token from crossbell chain |

### _verifySignatures

```solidity
function _verifySignatures(bytes32 hash, bytes signatures) internal view returns (bool)
```

### _setLockedThresholds

```solidity
function _setLockedThresholds(address[] tokens, uint256[] thresholds) internal
```

_Sets the amount thresholds to lock withdrawal.
Note that the array lengths must be equal._

### _lockedWithdrawalRequest

```solidity
function _lockedWithdrawalRequest(address token, uint256 amount) internal view returns (bool)
```

_Returns whether the withdrawal request is locked or not._

### _transformDepositAmount

```solidity
function _transformDepositAmount(address token, uint256 amount, uint8 destinationDecimals) internal view returns (uint256 transformedAmount)
```

### _getCrossbellToken

```solidity
function _getCrossbellToken(address mainchainToken) internal view returns (struct DataTypes.MappedToken token)
```

### _mapTokens

```solidity
function _mapTokens(address[] mainchainTokens, address[] crossbellTokens, uint8[] crossbellTokenDecimals) internal virtual
```

_Maps mainchain tokens to crossbell network._

