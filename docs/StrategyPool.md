# StrategyPool Contract Documentation

The MC²Fi `StrategyPool` contract holds multiple tokens according to a dynamic strategy.

## Owner's Functions
Owner's functions can only be called by the contract's owner, and are responsible for performing all of the Pool's entry functionalities and also to change the Pool's strategy (i.e. the Pool's distribution of underlying assets).

#### `deposit(IERC20[] assets, uint256[] amounts, uint256 poolTokens, address receiver)`

Mints Pool tokens to receiver by depositing amounts of underlying tokens.

_Parameters:_
- `assets`: Array of asset addresses.
- `amounts`: Corresponding amounts of each asset.
- `poolTokens`: Amount of poolTokens to be minted.
- `receiver`: Address of the recipient of minted tokens.

_Reverts if:_
- `assets` and `amounts` array length mismatch.
- any `amount` is zero.
- `poolTokens` > `maxMint()`.

_Description:_
Should be called by the owner in order to perform a deposit for a receiver. The assets and amounts must be approved the Pool before this call. Along with the mint, the underlying asset difference is recorded in the contract's internal balance controls. This function also emits the `Deposit` event, which can be listened to off-chain.

_NOTE:_
Pool tokens will be minted exactly as parameterized, there is no underlying multiplication (e.g. `poolTokens` * 10 ** decimals()), any share amount calculation must be done before the call.

---

#### `withdraw(address receiver, IERC20[] assets, uint256[] amounts)`

Sends assets of underlying tokens to receiver's account.

_Parameters:_
- `receiver`: Assets recipient account's address.
- `assets`: Array of asset addresses.
- `amounts`: Corresponding amounts of each asset.

_Reverts if:_
- any `asset` not currently owned by the Pool.
- any `amount` is zero.
- any `amount` > the Pool's owned balance of the asset.
- `receiver` is address 0.
- `assets` and `amounts` array length mismatch.

_Description:_
Should be called by the owner to transfer underlying assets to a user after reading a `redeem` call.The underlying asset difference is recorded in the contract's internal balance controls. This function also emits the `Withdraw` event, which can be listened to off-chain.

_NOTE:_
This function is locked when the contract is actively trading (i.e. between a `acquireAssetBeforeTrade` and a `giveBackAssetsAfterTrade` call), to protect users from redeeming less assets than they are entitled to.

---

#### `acquireAssetBeforeTrade(IERC20 asset, int256 amount)`

Transfers asset amount to owner.

_Parameters:_
- `asset`: Asset address of token to be traded.
- `amount`: Amount of asset to be traded.

_Reverts if:_
- `asset` not currently owned by the Pool.
- `amount` is zero.
- `amount` > the Pool's owned balance of the asset.
- `poolTokens` > `maxMint()`.

_Description:_
Should be called by the owner before performing a trade. This call will lock the `redeem` function, users should not be able to redeem assets during a strategy change because they would redeem less assets than they are entitled to. This call will lock this function, it cannot be called again until the trade is completed and `giveBackAssetsAfterTrade` is called. This call will lock any view functions with asset related queries to guarantee correctness, precision, and fairness of any calculation made externally, whether it's on-chain or off-chain. This function also emits the `AcquireBeforeTrade` event, which can be listened to off-chain.

The workflow is as follows:
- owner calls this function
- Pool locks this function and the `redeem` function, as well as any view functions with asset related queries to guarantee correctness, precision, and fairness of any calculation made externally, whether it's on-chain or off-chain.
- Pool transfers token amount to owner and updates its balance
- owner trades assets with itself as the receiver
- owner approves the Pool contract for tokens and amounts held after the trade
- owner calls `giveBackAssetsAfterTrade`with tokens and amounts held after the trade
- Pool transfers tokens after the trade to itself and updates its balances
- Pool unlocks this function, the `redeem` function, and the `withdraw` function, as well as any view functions with asset related queries.

---

#### `giveBackAssetsAfterTrade(IERC20[] assets, int256[] amounts)`

Transfer assets and amounts to Pool.

_Parameters:_
- `assets`: Array of asset addresses to give the Pool.
- `amounts`: Corresponding amounts of each asset remaining after trade.

_Reverts if:_
- `assets` and `amounts` array length mismatch.
- any `amount` is zero.

_Description:_
Should be called by the owner after performing a trade. This call will unlock the `acquireAssetBeforeTrade` and `redeem`functions. This function also emits the `GiveBackAfterTrade` event, which can be listened to off-chain.

_NOTE:_
This function unlocks all functions that were locked with a `acquireAssetBeforeTrade` call.

---

#### `migrateAsset(IERC20 oldAsset, IERC20 newAsset, uint256 newAmount)`

Changes asset address / amount in Strategy Pool storage.

_Parameters:_
- `oldAsset`: Asset address pertaining to the old asset contract.
- `newAsset`: Asset address pertaining to the new asset contract.
- `newAmount`: Amount of asset owned by Strategy Pool in the new contract.

_Reverts if:_
- `oldAsset` not currently owned by the Pool.
- `newAsset` currently owned by the Pool.
- `oldAsset` or `newAsset` is address 0.
- `newAmount` is zero.

_Description:_
Should be called by the owner in case that one the underlying assets migrate contracts, to update the Strategy Pool asset storage.

---

#### `rescueAssets(address receiver, IERC20[] assets, uint256[] amounts)`

Sends assets of underlying tokens to receiver's account.

_Parameters:_
- `receiver`: Assets recipient account's address.
- `assets`: Array of asset addresses.
- `amounts`: Corresponding amounts of each asset.

_Reverts if:_
- any `asset` not currently owned by the Pool.
- any `amount` is zero.
- any `amount` > the Pool's owned balance of the asset.
- `receiver` is address 0.
- `assets` and `amounts` array length mismatch.

_Description:_
Should be called by the owner in case of an emergency, e.g. something that requires the creation of another Strategy Pool.

---

### Public Functions
Public functions can be called by off-chain services or directly by users to redeem pool tokens, or just to acquire information on the Pool's status.


#### `redeem(address owner, address receiver, uint256 poolTokens)`

Burns exactly poolTokens from an owner account's balance. A call to this function will trigger a call to `withdraw` after backend processing, to transfer underlying pool assets to the user account.

_Parameters:_
- `owner`: Pool token owner account's address.
- `backer`: Address of the account registered as "backer" in the Strategy Wallet contract.
- `poolTokens`: Amount of pool tokens to be burned.
- `shouldProclaim`: Boolean indicating if the contract should call the event aggregator to emit an event on it.

_Reverts if:_
- `poolTokens` is zero.
- `poolTokens` > balance of `owner`.

_Description:_
Should be called by the Strategy Wallet contract to trigger backend to retrieve underlying assets by burning it's pool tokens. When the caller is the registered "backer" account "shouldProclaim" is true so the backend can listen to the self-redeem call, when the caller is the registered "admin" account (if there is one), "shouldProclaim" is false. Along with the burn. This function also emits the `Redeem` event, which can be listened to off-chain.

_NOTE:_
This function is locked when the contract is actively trading (i.e. between a `acquireAssetBeforeTrade` and a `giveBackAssetsAfterTrade` call), to protect users from redeeming less assets than they are entitled to.

_NOTE:_
This function calls `proclaimRedeem` in the StrategyPoolHerald contract when "shouldProclaim" is true (when the call is originally made by the backer directly), so that all self-`redeem` calls can be easily listened to.

---

#### `maxRedeem(address owner) returns (uint256 maxPoolTokens)`

Returns the maximum amount of Pool tokens that can be redeemed from a share owner account's balance in the Pool, through a redeem call.

_Parameters:_
- `owner`: Share owner account's address.

_Description:_
Should be called by the owner of the contract in order to perform a deposit for a receiver.

---

#### `assets() returns (IERC20[] assets)`

Returns the address of the underlying asset addresses used by the Pool for accounting, depositing, and withdrawing.

_Description:_
Should be called from off-chain by any service that requires the Pool's owned asset addresses.

_NOTE:_
This function is locked when the contract is actively trading (i.e. between a `acquireAssetBeforeTrade` and a `giveBackAssetsAfterTrade` call), to guarantee correctness, precision, and fairness of any external calculations.

---

#### `assetBalance(IERC20) returns (uint256 balance)`

Returns the total balance of one underlying asset managed by the Pool.

_Parameters:_
- `IERC20`: ERC-20 token contract.

_Description:_
Should be called from off-chain by any service that requires the Pool's balance of a given asset.

_NOTE:_
This function is locked when the contract is actively trading (i.e. between a `acquireAssetBeforeTrade` and a `giveBackAssetsAfterTrade` call), to guarantee correctness, precision, and fairness of any external calculations.

---

#### `assetsAndBalances() returns (IERC20[] assets, uint256[] balances)`

Returns the addresses and balances of all underlying assets managed by Pool.

_Description:_
Should be called from off-chain by any service that requires the Pool's current asset strategy, and to show a user the assets and balances held by a given Pool.

_NOTE:_
This function is locked when the contract is actively trading (i.e. between a `acquireAssetBeforeTrade` and a `giveBackAssetsAfterTrade` call), to guarantee correctness, precision, and fairness of any external calculations.

---

#### `maxMint() returns (uint256 maxPoolTokens)`

Returns the maximum amount of pool tokens that the Pool can mint without overflowing the totalSupply().

_Description:_
Should be called from off-chain in cases where the Pool is very popular to assess if there could be any problems with token issuance.

---
