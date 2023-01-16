# Solidity API

## MiraToken

### BLOCK_ROLE

```solidity
bytes32 BLOCK_ROLE
```

### constructor

```solidity
constructor(string name_, string symbol_) public
```

### mint

```solidity
function mint(address to, uint256 amount) external
```

_Creates `amount` new tokens for `to`.
Requirements:
- the caller must have the `DEFAULT_ADMIN_ROLE`._

### _transfer

```solidity
function _transfer(address from, address to, uint256 amount) internal
```

_Blocks transfer from account `from` who has the `BLOCK_ROLE`._

### renounceRole

```solidity
function renounceRole(bytes32 role, address account) external
```

_Revokes `role` from the calling account.
Requirements:
- the caller must have the `DEFAULT_ADMIN_ROLE`._

