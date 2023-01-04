# Solidity API

## DataTypes

A standard library of data types.

### MappedToken

```solidity
struct MappedToken {
  address token;
  uint8 decimals;
}
```

### DepositEntry

```solidity
struct DepositEntry {
  uint256 chainId;
  address recipient;
  address token;
  uint256 amount;
}
```

### WithdrawalEntry

```solidity
struct WithdrawalEntry {
  uint256 chainId;
  address recipient;
  address token;
  uint256 transformedAmount;
  uint256 amount;
}
```

### Signature

```solidity
struct Signature {
  uint8 v;
  bytes32 r;
  bytes32 s;
}
```

### Status

```solidity
enum Status {
  NotApproved,
  FirstApproved,
  AlreadyApproved
}
```

