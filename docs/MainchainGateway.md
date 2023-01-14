# Solidity API

## MainchainGateway

_Logic to handle deposits and withdrawals on mainchain._

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
function initialize(address validator, address admin, address withdrawalUnlocker, address[] mainchainTokens, uint256[][2] thresholds, address[] crossbellTokens, uint8[] crossbellTokenDecimals) external
```

Initializes the MainchainGateway.
Note that the thresholds contains:
 - thresholds[0]: lockedThresholds The amount thresholds to lock withdrawal.
 - thresholds[1]: dailyWithdrawalMaxQuota Daily withdrawal quotas for mainchain tokens.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| validator | address | Address of validator contract. |
| admin | address | Address of gateway admin. |
| withdrawalUnlocker | address | Address of operator who can unlock the locked withdrawals. |
| mainchainTokens | address[] | Addresses of mainchain tokens. |
| thresholds | uint256[][2] | The amount thresholds  for withdrawal. |
| crossbellTokens | address[] | Addresses of crossbell tokens. |
| crossbellTokenDecimals | uint8[] | Decimals of crossbell tokens. |

### getDomainSeparator

```solidity
function getDomainSeparator() external view virtual returns (bytes32)
```

Returns the domain separator for this contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 The domain separator. |

### pause

```solidity
function pause() external
```

Pause interaction with the gateway contract.
Requirements:
- The caller must have the ADMIN_ROLE.

### unpause

```solidity
function unpause() external
```

Resume interaction with the gateway contract.
Requirements:
- The caller must have the ADMIN_ROLE.

### mapTokens

```solidity
function mapTokens(address[] mainchainTokens, address[] crossbellTokens, uint8[] crossbellTokenDecimals) external
```

Maps Crossbell tokens to mainchain.
Emits the `TokenMapped` event.
Requirements:
- The caller must have the ADMIN_ROLE.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| mainchainTokens | address[] | Addresses of mainchain tokens. |
| crossbellTokens | address[] | Addresses of crossbell tokens. |
| crossbellTokenDecimals | uint8[] | Decimals of crossbell tokens. |

### requestDeposit

```solidity
function requestDeposit(address recipient, address token, uint256 amount) external returns (uint256 depositId)
```

Request deposit to crossbell chain.
Emits the `RequestDeposit` event.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| recipient | address | Address to receive deposit on crossbell chain |
| token | address | Address of token to deposit from mainchain network |
| amount | uint256 | Amount of token to deposit  from mainchain network |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| depositId | uint256 | Deposit id |

### withdraw

```solidity
function withdraw(uint256 chainId, uint256 withdrawalId, address recipient, address token, uint256 amount, uint256 fee, struct DataTypes.Signature[] signatures) external returns (bool locked)
```

Withdraw based on the validator signatures.
Emits the `WithdrawalLocked` event if withdrawal is locked, otherwise `Withdrew` event.
Requirements:
- The signatures should be sorted by signing addresses of validators in ascending order.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | The chain ID of mainchain network. |
| withdrawalId | uint256 | Withdrawal ID from crossbell chain |
| recipient | address | Address to receive withdrawal on mainchain chain |
| token | address | Address of token to withdraw |
| amount | uint256 | Amount of token to withdraw |
| fee | uint256 | The fee amount to pay for the withdrawal tx sender. This is subtracted from the `amount` |
| signatures | struct DataTypes.Signature[] | The list of signatures sorted by signing addresses of validators in ascending order. |

### unlockWithdrawal

```solidity
function unlockWithdrawal(uint256 chainId, uint256 withdrawalId, address recipient, address token, uint256 amount, uint256 fee) external
```

Approves a specific withdrawal.
Emits the `Withdrew` event.
Requirements:
- The caller must have the WITHDRAWAL_UNLOCKER_ROLE.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | The chain ID of mainchain network. |
| withdrawalId | uint256 | Withdrawal ID from crossbell chain |
| recipient | address | Address to receive withdrawal on mainchain chain |
| token | address | Address of token to withdraw |
| amount | uint256 | Amount of token to withdraw |
| fee | uint256 | The fee amount to pay for the withdrawal tx sender. This is subtracted from the `amount` |

### batchUnlockWithdrawal

```solidity
function batchUnlockWithdrawal(uint256[] chainIds, uint256[] withdrawalIds, address[] recipients, address[] tokens, uint256[] amounts, uint256[] fees) external
```

Tries bulk unlock withdrawals.

### setLockedThresholds

```solidity
function setLockedThresholds(address[] tokens, uint256[] thresholds) external
```

Sets the amount thresholds to lock withdrawal.
Emits the `LockedThresholdsUpdated` event.
Requirements:
- The caller must have the ADMIN_ROLE.
- The arrays have the same length.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokens | address[] | Addresses of token to set |
| thresholds | uint256[] | Thresholds corresponding to the tokens to set |

### setDailyWithdrawalQuotas

```solidity
function setDailyWithdrawalQuotas(address[] tokens, uint256[] quotas) external
```

Sets daily quotas for the withdrawals.
Emits the `DailyWithdrawalQuotasUpdated` event.
Requirements:
- The caller must have the ADMIN_ROLE.
- The arrays have the same length.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokens | address[] | Addresses of token to set |
| quotas | uint256[] | quotas corresponding to the tokens to set |

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

### isWithdrawalLocked

```solidity
function isWithdrawalLocked(uint256 withdrawalId) external view returns (bool)
```

Returns whether the withdrawal is locked or not.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| withdrawalId | uint256 | WithdrawalId to query |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | True if the withdrawal is locked |

### getWithdrawalLockedThreshold

```solidity
function getWithdrawalLockedThreshold(address token) external view returns (uint256)
```

Returns the amount thresholds to lock withdrawal.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | Token address |

### getDailyWithdrawalMaxQuota

```solidity
function getDailyWithdrawalMaxQuota(address token) external view returns (uint256)
```

Returns the daily withdrawal max quota.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | Token address |

### getDailyWithdrawalRemainingQuota

```solidity
function getDailyWithdrawalRemainingQuota(address token) external view returns (uint256)
```

Returns today's withdrawal remaining quota.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | Token address to query |

### getCrossbellToken

```solidity
function getCrossbellToken(address mainchainToken) external view returns (struct DataTypes.MappedToken token)
```

Returns mapped tokens from crossbell chain

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| mainchainToken | address | Token address on mainchain |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | struct DataTypes.MappedToken | Mapped token from crossbell chain |

### _updateDomainSeparator

```solidity
function _updateDomainSeparator() internal
```

_Update domain seperator._

### _verifySignatures

```solidity
function _verifySignatures(bytes32 hash, struct DataTypes.Signature[] signatures) internal view returns (bool)
```

### _setLockedThresholds

```solidity
function _setLockedThresholds(address[] tokens, uint256[] thresholds) internal
```

_Sets the amount thresholds to lock withdrawal.
Note that the array lengths must be equal._

### _setDailyWithdrawalQuotas

```solidity
function _setDailyWithdrawalQuotas(address[] tokens, uint256[] quotas) internal
```

_Sets daily quota for the withdrawals.
Note that the array lengths must be equal.
Emits the `DailyWithdrawalQuotasUpdated` event._

### _unlockWithdrawal

```solidity
function _unlockWithdrawal(uint256 chainId, uint256 withdrawalId, address recipient, address token, uint256 amount, uint256 fee) internal
```

_Approves a specific withdrawal._

### _recordWithdrawal

```solidity
function _recordWithdrawal(address token, uint256 amount) internal
```

_Record withdrawal token._

### _lockedWithdrawalRequest

```solidity
function _lockedWithdrawalRequest(address token, uint256 amount) internal view returns (bool)
```

_Returns whether the withdrawal request is locked or not._

### _reachedDailyWithdrawalQuota

```solidity
function _reachedDailyWithdrawalQuota(address token, uint256 amount) internal view returns (bool)
```

_Checks whether the withdrawal reaches the daily quota.
- Note that the daily withdrawal threshold should not apply for locked withdrawals._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | Token address to withdraw |
| amount | uint256 | Token amount to withdraw |

### _transformDepositAmount

```solidity
function _transformDepositAmount(address token, uint256 amount, uint8 destDecimals) internal view returns (uint256 transformedAmount)
```

### _getCrossbellToken

```solidity
function _getCrossbellToken(address mainchainToken) internal view returns (struct DataTypes.MappedToken token)
```

### _mapTokens

```solidity
function _mapTokens(address[] mainchainTokens, address[] crossbellTokens, uint8[] crossbellTokenDecimals) internal
```

_Maps Crossbell tokens to mainchain._

