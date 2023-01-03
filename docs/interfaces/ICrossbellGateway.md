# Solidity API

## ICrossbellGateway

### TokenMapped

```solidity
event TokenMapped(address[] crossbellTokens, uint256[] chainIds, address[] mainchainTokens, uint8[] crossbellTokensDecimals)
```

_Emitted when the tokens are mapped_

### Deposited

```solidity
event Deposited(uint256 chainId, uint256 depositId, address recipient, address token, uint256 amount)
```

_Emitted when the assets are deposited_

### AckDeposit

```solidity
event AckDeposit(uint256 chainId, uint256 depositId, address recipient, address token, uint256 amount)
```

_Emitted when the deposit is acknowledged by a validator_

### RequestWithdrawal

```solidity
event RequestWithdrawal(uint256 chainId, uint256 withdrawId, address recipient, address token, uint256 transformedAmount, uint256 originalAmount)
```

_Emitted when the withdrawal is requested_

### RequestWithdrawalSignatures

```solidity
event RequestWithdrawalSignatures(uint256 chainId, uint256 withdrawalId, address owner, address token, uint256 amount)
```

_Emitted when the withdrawal signatures is requested_

### initialize

```solidity
function initialize(address validator, address admin, address[] crossbellTokens, uint256[] chainIds, address[] mainchainTokens, uint8[] mainchainTokenDecimals) external
```

Initializes the CrossbellGateway.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| validator | address | Address of validator contract. |
| admin | address | Address of gateway admin. |
| crossbellTokens | address[] | Addresses of crossbell tokens. |
| chainIds | uint256[] | ChainIds of mainchain networks. |
| mainchainTokens | address[] | Addresses of mainchain tokens. |
| mainchainTokenDecimals | uint8[] | Decimals of mainchain tokens. |

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

### batchAckDeposit

```solidity
function batchAckDeposit(uint256[] chainIds, uint256[] depositIds, address[] recipients, address[] tokens, uint256[] amounts) external
```

Tries bulk deposit.

### batchSubmitWithdrawalSignatures

```solidity
function batchSubmitWithdrawalSignatures(uint256[] chainIds, uint256[] withdrawalIds, bool[] shouldReplaces, bytes[] sigs) external
```

Tries bulk submit withdrawal signatures.
Note that the caller must be a validator.

### ackDeposit

```solidity
function ackDeposit(uint256 chainId, uint256 depositId, address recipient, address token, uint256 amount) external
```

Acknowledges a deposit.
Note that the caller must be a validator.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | ChainId of mainchain network |
| depositId | uint256 |  |
| recipient | address | Address to receive deposit on crossbell network |
| token | address | Token address to deposit on crossbell network |
| amount | uint256 | Token amount to deposit on crossbell network |

### requestWithdrawal

```solidity
function requestWithdrawal(uint256 chainId, address recipient, address token, uint256 amount) external returns (uint256 withdrawId)
```

Locks the assets and request withdrawal.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | ChainId of mainchain network |
| recipient | address | Address to receive withdrawal on mainchain network |
| token | address | Token address to withdraw from crossbell network |
| amount | uint256 | Token amount to withdraw from crossbell network |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| withdrawId | uint256 | The newly generated withdrawId |

### requestWithdrawalSignatures

```solidity
function requestWithdrawalSignatures(uint256 chainId, uint256 withdrawalId) external
```

Request withdrawal signatures, in case the withdrawer didn't submit to mainchain in time and the set of the validator
has changed.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | ChainId |
| withdrawalId | uint256 | WithdrawalId |

### submitWithdrawalSignatures

```solidity
function submitWithdrawalSignatures(uint256 chainId, uint256 withdrawalId, bool shouldReplace, bytes sig) external
```

Submits validator signature for withdrawal.
Note that the caller must be a validator.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | ChainId of mainchain network |
| withdrawalId | uint256 | WithdrawalId |
| shouldReplace | bool | Whether the old signature should be replaced |
| sig | bytes | Validator signature for the withdrawal |

### getMainchainToken

```solidity
function getMainchainToken(uint256 chainId, address crossbellToken) external view returns (struct DataTypes.MappedToken token)
```

Returns mapped token on mainchain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | ChainId of mainchain |
| crossbellToken | address | Token address on crossbell |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | struct DataTypes.MappedToken | Mapped token on mainchain chain |

### getValidatorAcknowledgementHash

```solidity
function getValidatorAcknowledgementHash(uint256 chainId, uint256 id, address validator) external view returns (bytes32)
```

### getAcknowledgementStatus

```solidity
function getAcknowledgementStatus(uint256 chainId, uint256 id, bytes32 hash) external view returns (enum DataTypes.Status)
```

### getAcknowledgementCount

```solidity
function getAcknowledgementCount(uint256 chainId, uint256 id, bytes32 hash) external view returns (uint256)
```

### getWithdrawalSigners

```solidity
function getWithdrawalSigners(uint256 chainId, uint256 withdrawalId) external view returns (address[])
```

Returns withdrawal signers.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | ChainId of mainchain |
| withdrawalId | uint256 | Withdrawal Id to query |

### getWithdrawalSignatures

```solidity
function getWithdrawalSignatures(uint256 chainId, uint256 withdrawalId) external view returns (address[] signers, bytes[] sigs)
```

Returns withdrawal signatures.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | ChainId of mainchain |
| withdrawalId | uint256 | Withdrawal Id to query |

### getValidatorContract

```solidity
function getValidatorContract() external view returns (address)
```

Returns the address of the validator contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The validator contract address |

### getDepositEntry

```solidity
function getDepositEntry(uint256 chainId, uint256 depositId) external view returns (struct DataTypes.DepositEntry)
```

Returns the deposit entry.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | ChainId of mainchain |
| depositId | uint256 | Deposit Id to query |

### getWithdrawalCount

```solidity
function getWithdrawalCount(uint256 chainId) external view returns (uint256)
```

Returns the withdrawal count of different mainchain networks.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | ChainId of mainchain |

### getWithdrawalEntry

```solidity
function getWithdrawalEntry(uint256 chainId, uint256 withdrawalId) external view returns (struct DataTypes.WithdrawalEntry)
```

Returns the withdrawal entry.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | ChainId of mainchain |
| withdrawalId | uint256 | Withdrawal Id to query |

