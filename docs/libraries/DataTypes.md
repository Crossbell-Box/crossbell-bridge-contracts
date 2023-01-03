# Solidity API

## DataTypes

### MappedToken

```solidity
struct MappedToken {
  address tokenAddr;
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

### Status

```solidity
enum Status {
  NotApproved,
  FirstApproved,
  AlreadyApproved
}
```

