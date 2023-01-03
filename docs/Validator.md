# Solidity API

## Validator

### _validators

```solidity
struct EnumerableSet.AddressSet _validators
```

### _requiredNumber

```solidity
uint256 _requiredNumber
```

### constructor

```solidity
constructor(address[] validators, uint256 requiredNumber) public
```

Initializes the validators and required number.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| validators | address[] | Validators to set. |
| requiredNumber | uint256 | Required number to set. |

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

Change the required number of validators. This function can only be called by the owner of validator contract.
Note that this reverts if:
 1. new required number > validators length.
 2. new required number is zero.

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

### _isValidator

```solidity
function _isValidator(address addr) internal view returns (bool)
```

### _addValidator

```solidity
function _addValidator(address validator) internal
```

### _removeValidator

```solidity
function _removeValidator(address validator) internal
```

