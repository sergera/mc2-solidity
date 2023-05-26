# StrategyPool Contract Documentation

The MC²Fi `StrategyPool` contract holds multiple tokens according to a dynamic strategy.

## Owner's Functions
Owner's functions can only be called by the contract's owner, and are responsible for performing all of the Pool's entry functionalities and also to change the Pool's strategy (i.e. the Pool's distribution of underlying assets).

#### `deposit(IERC20[] assets, uint256[] amounts, address receiver) returns (uint256 shares)`

Mints shares Pool shares to receiver by depositing amounts of underlying tokens.

_Parameters:_
- `assets`: Array of asset addresses.
- `amounts`: Corresponding amounts of each asset.
- `shares`: Amount of shares to be minted.
- `receiver`: Address of the recipient of minted tokens.

_Reverts if:_
- `assets` and `amounts` array length mismatch.
- any `amount` is zero.
- `shares` > `maxMint()`.

_Description:_
Should be called by the owner in order to perform a deposit for a receiver. The assets and amounts must be approved the Pool before this call. Along with the mint, the underlying asset difference is recorded in the contract's internal balance controls. This function also emits the `Deposit` event, which can be listened to off-chain.

_NOTE:_
Shares will be minted exactly as parameterized, there is no underlying multiplication (e.g. shares * 10 ** decimals()), any share amount calculation must be done before the call.

---

#### `acquireAssetBeforeTrade(IERC20 asset, int256 amount)`

Transfers asset amount to owner.

_Parameters:_
- `asset`: Asset address of token to be traded.
- `amount`: Amount of asset to be traded.

_Reverts if:_
- `asset` is not currently owned by the Pool.
- `amount` is zero.
- `amount` > the Pool's owned balance of the asset.
- `shares` > `maxMint()`.

_Description:_
Should be called by the owner before performing a trade. This call will lock the `redeem` function, users should not be able to redeem assets during a strategy change because they would redeem less assets than they are entitled to. This call will lock this function, it cannot be called again until the trade is completed and `giveBackAssetsAfterTrade` is called. This function also emits the `AcquireBeforeTrade` event, which can be listened to off-chain.

The workflow is as follows:
- owner calls this function
- Pool locks this function and the `redeem` function
- Pool transfers token amount to owner and updates its balance
- owner trades assets with itself as the receiver
- owner approves the Pool contract for tokens and amounts held after the trade
- owner calls `giveBackAssetsAfterTrade`with tokens and amounts held after the trade
- Pool transfers tokens after the trade to itself and updates its balances
- Pool unlocks this function and the `redeem` function

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

---

### Public Functions
Public functions can be called by off-chain services or directly by users to redeem shares, or just to acquire information on the Pool's status.


#### `redeem(uint256 shares, address receiver, address owner) returns (IERC20[] assets, uint256[] amounts)`

Burns exactly shares from an owner account's balance and sends assets of underlying tokens to receiver's account.

_Parameters:_
- `shares`: Amount of shares to be burned.
- `receiver`: Assets recipient account's address.
- `owner`: Share owner account's address.

_Reverts if:_
- `shares` is zero.
- `shares` > balance of `owner`.

_Description:_
Should be called by a user to retrieve underlying assets by burning his shares. Along with the burn, the underlying asset difference is recorded in the contract's internal balance controls. This function also emits the `Withdraw` event, which can be listened to off-chain.

---

#### `maxRedeem(address owner) returns (uint256 maxShares)`

Returns the maximum amount of Pool shares that can be redeemed from a share owner account's balance in the Pool, through a redeem call.

_Parameters:_
- `owner`: Share owner account's address.

_Description:_
Should be called by the owner of the contract in order to perform a deposit for a receiver.

---

#### `minRedeem() returns (uint256 minShares)`

Returns the minimum amount of shares that can be redeemed to the Pool to get at least 1 of each asset.

_Description:_
Should be called from off-chain to check if a redeem call is too small.

---

#### `previewRedeem(uint256 shares) returns (IERC20[] assets, uint256[] amounts)`

Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block, given current on-chain conditions.

_Parameters:_
- `shares`: Number of shares to simulate a `redeem` call with.

_Reverts if:_
- `shares` > `totalSupply()`.

_Description:_
Should be called from off-chain to show a user how many assets would be acquired for a given share amount.

---


#### `maxDeposit() returns (IERC20[] assets, uint256[] maxAmounts)`

Returns the maximum amount of the underlying assets that can be deposited into the Pool through a deposit call.

_Description:_
Should be called from off-chain to check if a deposit is too big. This function will internally check the maximum amount of tokens that can be deposited such that the minted shares will not overflow the `totalSupply()`.

_NOTE:_
This assumes the share calculation to be 'shares = (assets * totalShares) / totalAssets'.

---

#### `minDeposit() returns (IERC20[] assets, uint256[] minAmounts)`

Returns the minimum amount of the underlying assets that can be deposited into the Pool such that at least 1 share will be minted.

_Description:_
Should be called from off-chain to check if a deposit call is too small.

_NOTE:_
This assumes the share calculation to be 'shares = (assets * totalShares) / totalAssets'.

---

#### `assets() returns (IERC20[] assets)`

Returns the address of the underlying asset addresses used by the Pool for accounting, depositing, and withdrawing.

_Description:_
Should be called from off-chain by any service that requires the Pool's owned asset addresses.

---

#### `assetBalance(IERC20) returns (uint256 balance)`

Returns the total balance of one underlying asset managed by the Pool.

_Parameters:_
- `IERC20`: ERC-20 token contract.

_Description:_
Should be called from off-chain by any service that requires the Pool's balance of a given asset.

---

#### `assetsAndBalances() returns (IERC20[] assets, uint256[] balances)`

Returns the addresses and balances of all underlying assets managed by Pool.

_Description:_
Should be called from off-chain by any service that requires the Pool's current asset strategy, and to show a user the assets and balances held by a given Pool.

---

#### `maxMint() returns (uint256 maxShares)`

Returns the maximum amount of shares that the Pool can mint without overflowing the totalSupply().

_Description:_
Should be called from off-chain in cases where the Pool is very popular to assess if there could be any problems with token issuance.

---

#### `maxWithdraw(address owner) returns (IERC20[] assets, uint256[] maxAmounts)`

Returns the addresses and maximum amounts of assets managed by the Pool that can be redeemed by a share owner's account.

_Parameters:_
- `owner`: Share owner account's address.

_Description:_
Should be called from off-chain to show a user his portion of the underlying assets of the Pool. This function will check the user's share balance and return the asset conversion for its full amount.

---
