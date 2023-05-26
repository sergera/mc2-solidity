# StrategyPoolFactory Contract Documentation

The MC²Fi `StrategyPoolFactory` creates new `StrategyPool`s and keeps their addresses.

## Owner's Functions
Owner's functions can only be called by the contract's owner, this contract only has one, which is responsible for creating new Pools.

#### `createPool(IERC20 token, address recipient, uint256 amount) returns (IStrategyPool pool)`

Creates a new `StrategyPool` contract, stores its address, and returns it.

_Parameters:_
- `name`: Name of the Pool's tokens.
- `symbol`: Symbol of the Pool's tokens.

_Description:_
Should be called by the owner in order to create a new Pool. The owner will also be the owner of the created Pool. This function also emits the `CreatePool` event, which can be listened to off-chain.

### Public Functions
Public functions can be called by off-chain services or directly by users to retrieve the addresses of created Pools.

#### `getPools() returns (IStrategyPool[] pools)`

Retrieves the addresses of all Pools created.

_Description:_
Should be called by any service that requires the created Pool addresses.

---

#### `getPool(uint256 index) returns (IStrategyPool pool)`

Retrieves an address of a created Pool by its index.

---