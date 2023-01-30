# Solidity API

## IValidator

This is the interface for the validator contract.
You'll find all the events and external functions.

### ValidatorAdded

```solidity
event ValidatorAdded(address validator)
```

_Emitted when a new validator is added._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| validator | address | The validator address to add. |

### ValidatorRemoved

```solidity
event ValidatorRemoved(address validator)
```

_Emitted when a validator is removed._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| validator | address | The validator address to remove. |

### RequirementChanged

```solidity
event RequirementChanged(uint256 requirement, uint256 previousRequired)
```

_Emitted when a new required number is set._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| requirement | uint256 | The new required number to set. |
| previousRequired | uint256 | The previous required number. |

### addValidators

```solidity
function addValidators(address[] validators) external
```

Adds new validators. This function can only be called by the owner of validator contract.
Note that this reverts if new validators to add are already validators.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| validators | address[] | New validator addresses to add |

### removeValidators

```solidity
function removeValidators(address[] validators) external
```

Removes exist validators. This function can only be called by the owner of validator contract.
Note that this reverts if validators to remove are not validators.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| validators | address[] | Validator addresses to remove |

### changeRequiredNumber

```solidity
function changeRequiredNumber(uint256 newRequiredNumber) external
```

Change the required number of validators.
Requirements::
 1. the caller is owner of validator contract.
 2. new required number > validators length.
 3. new required number is zero.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newRequiredNumber | uint256 | New required number to set. |

### isValidator

```solidity
function isValidator(address addr) external view returns (bool)
```

Returns whether an address is validator or not.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | Address to query. |

### getValidators

```solidity
function getValidators() external view returns (address[] validators)
```

Returns all the validators.

### getRequiredNumber

```solidity
function getRequiredNumber() external view returns (uint256)
```

Returns current required number.

### checkThreshold

```solidity
function checkThreshold(uint256 voteCount) external view returns (bool)
```

Checks whether the `voteCount` passes the threshold.

