# Escrow Contract Documentation

The MC²Fi `Escrow` contract allows users to deposit assets and withdraw assets, and transfers users escrows to the appropriate accounts.

## Deployment Addresses

_Ethereum_:
0x181871837C46109850dBafcbbA39a48FCDB997D3

_Goerli:_


_BSC_:


_BSC Testnet_:


## Owner's Functions
Owner's functions can only be called by the contract's owner, in this contract they are used to transfer assets deposited by users and to blacklist/unblacklist accounts.

#### `transferAssetFrom(address proprietor, address recipient, IERC20 asset, uint256 amount)`

Transfers a given asset amount owned by this contract to another account, and internally reduces amount from the asset balance of the user that deposited it in the first place.

_Parameters:_
- `proprietor`: Address of the account that deposited the asset to be transferred.
- `recipient`: Address of the recipient of the asset transfer.
- `asset`: Address of ERC20 token to be transferred.
- `amount`: Amount to be transferred.

_Description:_
Should be called by the owner in order to transfer assets owned by this contract to another account. This function also emits the `TransferAssetFrom` event, which can be listened to off-chain.

---

### Public Functions
This contract's public functions include deposit and withdraw by users, and view functions to query user's balance of assets.

#### `deposit(IERC20 asset, uint256 amount)`

Transfers a pre-approved amount of an asset from the caller to this contract, and internally increases amount of the asset balance of the caller.

_Parameters:_
- `asset`: Address of ERC20 token to be deposited.
- `amount`: Amount to be deposited.

_Description:_
Should be called by a user in order to transfer pre-approved asset amounts to this contract. This function also emits the `Deposit` event, which can be listened to off-chain.

---

#### `withdraw(IERC20 asset, uint256 amount)`

Transfers amount of an asset owned by this contract that was previously deposited by the caller back to the caller, and internally decreases amount of the asset balance of the caller.

_Parameters:_
- `asset`: Address of ERC20 token to be withdrawn.
- `amount`: Amount to be withdrawn.

_Description:_
Should be called by a user in order to transfer previously deposited asset amounts back to itself. This function also emits the `Withdraw` event, which can be listened to off-chain.

---


#### `assets(address proprietor) returns (IERC20[] assets)`

Returns the address of the deposited asset addresses by the proprietor address currently held by the contract.

_Parameters:_
- `proprietor`: Address of the account that deposited the assets.

_Description:_
Should be called from off-chain by any service that requires the assets deposited by the proprietor address.

---

#### `assetBalance(address proprietor, IERC20 asset) returns (uint256 balance)`

Returns total deposited amount of asset by proprietor address currently held by the contract.

_Parameters:_
- `proprietor`: Address of the account that deposited the assets.
- `asset`: Address of ERC20 token to query the balance.

_Description:_
Should be called from off-chain by any service that requires the balance of a given asset deposited by the proprietor address.

---

#### `assetsAndBalances(address proprietor) returns (IERC20[] assets, uint256[] balances)`

Returns the addresses and balances of all deposited assets by the proprietor address currently held by the contract.

_Parameters:_
- `proprietor`: Address of the account that deposited the assets.

_Description:_
Should be called from off-chain by any service that requires the assets and balances deposited by the proprietor address.

---