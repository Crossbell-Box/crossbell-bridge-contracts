# Solidity API

## CrossbellGateway

_Logic to handle deposits and withdrawals on Crossbell._

### ADMIN_ROLE

```solidity
bytes32 ADMIN_ROLE
```

### ERC1820_REGISTRY

```solidity
contract IERC1820Registry ERC1820_REGISTRY
```

### TOKENS_RECIPIENT_INTERFACE_HASH

```solidity
bytes32 TOKENS_RECIPIENT_INTERFACE_HASH
```

### onlyValidator

```solidity
modifier onlyValidator()
```

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
| chainIds | uint256[] | The chain IDs of mainchain networks. |
| mainchainTokens | address[] | Addresses of mainchain tokens. |
| mainchainTokenDecimals | uint8[] | Decimals of mainchain tokens. |

### pause

```solidity
function pause() external
```

Pauses interaction with the gateway contract

### unpause

```solidity
function unpause() external
```

Resumes interaction with the gateway contract

### mapTokens

```solidity
function mapTokens(address[] crossbellTokens, uint256[] chainIds, address[] mainchainTokens, uint8[] mainchainTokenDecimals) external
```

Maps mainchain tokens to Crossbell network.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| crossbellTokens | address[] | Addresses of crossbell tokens. |
| chainIds | uint256[] | The chain IDs of mainchain networks. |
| mainchainTokens | address[] | Addresses of mainchain tokens. |
| mainchainTokenDecimals | uint8[] | Decimals of mainchain tokens. |

### batchAckDeposit

```solidity
function batchAckDeposit(uint256[] chainIds, uint256[] depositIds, address[] recipients, address[] tokens, uint256[] amounts, bytes32[] depositHashes) external
```

Tries bulk deposit.

### batchSubmitWithdrawalSignatures

```solidity
function batchSubmitWithdrawalSignatures(uint256[] chainIds, uint256[] withdrawalIds, bytes[] sigs) external
```

Tries bulk submit withdrawal signatures.
Note that the caller must be a validator.

### ackDeposit

```solidity
function ackDeposit(uint256 chainId, uint256 depositId, address recipient, address token, uint256 amount, bytes32 depositHash) external
```

Acknowledges a deposit.
Note that the caller must be a validator.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | The chain ID of mainchain network. |
| depositId | uint256 | Deposit identifier id. |
| recipient | address | Address to receive deposit on crossbell network. |
| token | address | Token address to deposit on crossbell network. |
| amount | uint256 | Token amount to deposit on crossbell network. |
| depositHash | bytes32 | Hash of deposit info. |

### requestWithdrawal

```solidity
function requestWithdrawal(uint256 chainId, address recipient, address token, uint256 amount, uint256 fee) external returns (uint256 withdrawalId)
```

Locks the assets and request withdrawal.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | The chain ID of mainchain network. |
| recipient | address | Address to receive withdrawal on mainchain network. |
| token | address | Token address to lock from crossbell network. |
| amount | uint256 | Token amount to lock from crossbell network. |
| fee | uint256 | Fee amount to pay. This is subtracted from the `amount`. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| withdrawalId | uint256 | The newly generated withdrawalId. |

### submitWithdrawalSignature

```solidity
function submitWithdrawalSignature(uint256 chainId, uint256 withdrawalId, bytes sig) external
```

Submits validator signature for withdrawal.
Note that the caller must be a validator.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | The chain ID of mainchain network. |
| withdrawalId | uint256 | WithdrawalId. |
| sig | bytes | Validator signature for the withdrawal. |

### getMainchainToken

```solidity
function getMainchainToken(uint256 chainId, address crossbellToken) external view returns (struct DataTypes.MappedToken token)
```

Returns mapped token on mainchain.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | The chain ID of mainchain network. |
| crossbellToken | address | Token address on crossbell. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | struct DataTypes.MappedToken | Mapped token on mainchain chain. |

### getValidatorAcknowledgementHash

```solidity
function getValidatorAcknowledgementHash(uint256 chainId, uint256 id, address validator) external view returns (bytes32)
```

Returns the acknowledge depositHash by validator.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | The chain ID of mainchain network. |
| id | uint256 | DepositId. |
| validator | address | Validator address. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | bytes32 depositHash if validator has acknowledged, otherwise 0. |

### getAcknowledgementStatus

```solidity
function getAcknowledgementStatus(uint256 chainId, uint256 id, bytes32 hash) external view returns (enum DataTypes.Status)
```

Returns the acknowledge status of deposit by validators.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | The chain ID of mainchain network. |
| id | uint256 | DepositId. |
| hash | bytes32 | depositHash. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | enum DataTypes.Status | DataTypes.Status Acknowledgement status. |

### getAcknowledgementCount

```solidity
function getAcknowledgementCount(uint256 chainId, uint256 id, bytes32 hash) external view returns (uint256)
```

Returns the acknowledge count of deposit by validators.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | The chain ID of mainchain network. |
| id | uint256 | DepositId. |
| hash | bytes32 | depositHash. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 Acknowledgement count. |

### getWithdrawalSignatures

```solidity
function getWithdrawalSignatures(uint256 chainId, uint256 withdrawalId) external view returns (address[] signers, bytes[] sigs)
```

Returns withdrawal signatures.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | The chain ID of mainchain network. |
| withdrawalId | uint256 | Withdrawal Id to query. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| signers | address[] | Signer addresses. |
| sigs | bytes[] | Signer signatures. |

### getValidatorContract

```solidity
function getValidatorContract() external view returns (address)
```

Returns the address of the validator contract.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The validator contract address. |

### getDepositEntry

```solidity
function getDepositEntry(uint256 chainId, uint256 depositId) external view returns (struct DataTypes.DepositEntry)
```

Returns the deposit entry.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | The chain ID of mainchain network. |
| depositId | uint256 | Deposit Id to query. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct DataTypes.DepositEntry | DataTypes.DepositEntry Deposit entry. |

### getWithdrawalCount

```solidity
function getWithdrawalCount(uint256 chainId) external view returns (uint256)
```

Returns the withdrawal count of different mainchain networks.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | The chain ID of mainchain network. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Withdrawal count. |

### getWithdrawalEntry

```solidity
function getWithdrawalEntry(uint256 chainId, uint256 withdrawalId) external view returns (struct DataTypes.WithdrawalEntry)
```

Returns the withdrawal entry.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| chainId | uint256 | The chain ID of mainchain network. |
| withdrawalId | uint256 | Withdrawal Id to query. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct DataTypes.WithdrawalEntry | DataTypes.WithdrawalEntry Withdrawal entry. |

### tokensReceived

```solidity
function tokensReceived(address, address, address, uint256, bytes userData, bytes operatorData) external pure
```

_Called by an {IERC777} token contract whenever tokens are being
moved or created into a registered account (`to`). The type of operation
is conveyed by `from` being the zero address or not.

This call occurs _after_ the token contract's state is updated, so
{IERC777-balanceOf}, etc., can be used to query the post-operation state.

This function may revert to prevent the operation from being executed._

### _ackDeposit

```solidity
function _ackDeposit(uint256 chainId, uint256 depositId, address recipient, address token, uint256 amount, bytes32 depositHash) internal
```

### _mapTokens

```solidity
function _mapTokens(address[] crossbellTokens, uint256[] chainIds, address[] mainchainTokens, uint8[] mainchainTokenDecimals) internal
```

_Maps crossbell tokens to mainchain networks._

### _submitWithdrawalSignature

```solidity
function _submitWithdrawalSignature(uint256 chainId, uint256 withdrawalId, bytes sig) internal
```

### _acknowledge

```solidity
function _acknowledge(uint256 chainId, uint256 id, bytes32 hash, address validator) internal returns (enum DataTypes.Status)
```

### _sendToken

```solidity
function _sendToken(address recipient, address token, uint256 amount) internal
```

### _getWithdrawalSigners

```solidity
function _getWithdrawalSigners(uint256 chainId, uint256 withdrawalId) internal view returns (address[])
```

### _getMainchainToken

```solidity
function _getMainchainToken(uint256 chainId, address crossbellToken) internal view returns (struct DataTypes.MappedToken token)
```

### _convertToBase

```solidity
function _convertToBase(address token, uint256 amount, uint8 destDecimals) internal view returns (uint256 convertedAmount)
```

### _checkValidator

```solidity
function _checkValidator() internal view
```

