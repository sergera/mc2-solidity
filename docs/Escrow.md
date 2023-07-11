# Escrow Contract Documentation

The MC²Fi `Escrow` contract registers user asset transfers as deposits, refunds registered deposits, allows users to directly withdraw previously registered deposits of assets, and transfers users' accepted deposits to the appropriate accounts.

## Deployment Addresses

_Ethereum_:
0x708a6759da29d3a5D243D7426578d29Edd9Df974

_Goerli:_
0x3289004284864183cd59151067c66cd028BEbA35

_BSC_:
0x551f5868572bc1d43daa6BCB32aCDAa52451EF6c

_BSC Testnet_:
0xF4516FE3b3C0068a988D7CE3982499EecE9b4833

## Owner's Functions
Owner's functions can only be called by the contract's owner, in this contract they are used to register asset transfers as deposits, reject asset transfers, refund accepted deposits, transfer assets from accepted deposits, and to blacklist/unblacklist accounts.

#### `transferAssetFrom(address proprietor, IERC20 asset, uint256 amount, address recipient)`

Transfers asset amount owned by this contract to another account, and internally reduces amount from the asset balance of the proprietor that deposited it in the first place.

_Parameters:_
- `proprietor`: Addresses pertaining to the account that deposited the asset to be transferred.
- `amount`: Amount to be transferred from proprietor's registered deposit.
- `asset`: Address ERC20 token to be transferred.
- `recipient`: Address of the recipient of the asset transfer.


_Description:_
Should be called by the owner in order to transfer an asset owned by this contract to another account. This function also emits the `TransferAssetFrom` event, which can be listened to off-chain.

---

#### `acceptDeposit(address proprietor, IERC20 asset, uint256 amount)`

Registers transfer of asset and amount made to this contract by proprietor, and internally increases amount of the asset balance of the caller.

_Parameters:_
- `proprietor`: Address of account that transferred asset to this contract.
- `asset`: Address of ERC20 token that was transferred.
- `amount`: Amount that was transferred.

_Description:_
Should be called by the owner in order to register previously transferred asset amounts to this contract. This function also emits the `AcceptDeposit` event, which can be listened to off-chain.

---

#### `rejectDeposit(address proprietor, IERC20 asset, uint256 depositAmount, address feeRecipient, uint256 feeAmount)`

Transfers an asset amount transferred to this contract back to proprietor and fee amount to fee recipient.

_Parameters:_
- `proprietor`: Address of the account that transferred the asset.
- `asset`: Address of ERC20 token that was transferred.
- `depositAmount`: Amount of `asset` to be returned to `proprietor`.
- `feeRecipient`: Address of the recipient of the asset fee.
- `feeAmount`: Amount of `asset` to be transferred to `feeRecipient`.

_Description:_
Should be called by the owner in order to reject transfers to this contract either from non-whitelisted wallets, or which deposited non-allowed asset. This function also emits the `RejectDeposit` event, which can be listened to off-chain.

---

#### `refundAsset(address proprietor, IERC20 asset, uint256 amount)`

Transfers amount of previously accepted asset deposit back to proprietor, and internally reduces amount from the asset balance of the proprietor.

_Parameters:_
- `proprietor`: Address pertaining to the account that deposited the asset to be refunded.
- `asset`: Address of ERC20 token to be transferred.
- `amount`: Amount to be transferred back to proprietor.

_Description:_
Should be called by the owner in order to refund amount of a previously accepted deposit. This function also emits the `RefundAsset` event, which can be listened to off-chain.

---

#### `rescueAssets(address recipient, IERC20[] assets, uint256[] amounts)`

Transfers asset amounts owned by this contract to another account.

_Parameters:_
- `recipient`: Address of the recipient of the asset transfers.
- `assets`: Array of addresses ERC20 tokens to be transferred.
- `amounts`: Array of amounts to be transferred.

_Description:_
Should be called by the owner in order to transfer unregistered assets owned by this contract to another account. This function also emits the `RescueAssets` event, which can be listened to off-chain.

---

#### `addBlacklistedAccount(address blacklisted)`

Adds an address as blacklisted, which means the address won't be able to interact with any public function.

_Parameters:_
- `blacklisted`: Address of the account to be blacklisted.

_Description:_
Should be called by the owner in order to restrict bad actors. This function also emits the `AddBlacklistedAccount` event, which can be listened to off-chain.

---

#### `removeBlacklistedAccount(address blacklisted)`

Removes an address as blacklisted, which means the address won't be able to interact with any public function.

_Parameters:_
- `blacklisted`: Address of the account to be removed from the blacklist.

_Description:_
Should be called by the owner in order to unrestrict previously added bad actors in case of a mistake. This function also emits the `RemoveBlacklistedAccount` event, which can be listened to off-chain.

---

#### `accountIsBlacklisted(address blacklisted) returns (bool isBlacklisted)`

Returns a boolean that signifies if the parameterized address is blacklisted.

_Parameters:_
- `blacklisted`: Address of the account.

_Description:_
Should be called by the owner in order to find if an address is currently blacklisted.

---

#### `blacklistedAccounts() returns (address[] blacklistedAccounts)`

Returns a boolean that signifies if the parameterized address is blacklisted.

_Parameters:_
- `blacklisted`: Address of the account.

_Description:_
Should be called by the owner in order to find if an address is currently blacklisted.

---

### Public Functions
This contract's public functions include deposit and withdraw by users, and view functions to query user's balance of assets.

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