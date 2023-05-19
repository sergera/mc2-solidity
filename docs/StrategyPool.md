# StrategyPool Contract Documentation

The MC²Fi `StrategyPool` contract holds multiple tokens according to a dynamic strategy.

## Owner's Functions
Owner's functions can only be called by the contract's owner, and are responsible for performing all of the Pool's entry functionalities and also to change the Pool's strategy (i.e. the Pool's distribution of underlying assets).

### `changeInitialDepositShareValue(uint256 newValue)`

Changes initial deposit share value, in case the Pool goes empty, and has to be initialized again.

_Parameters:_
- `newValue`: New value to set as the initial deposit share value.

_Description:_
Should be called in case that, after an initialized Pool goes empty, a user decides to deposit to it again with a different initial amount of stablecoins, which effectively will reinitialize the Pool, in such a case this function should be called before performing the deposit, informing the initial amount of Pool's tokens to be minted on initialization. Initial deposit share value is set up in the constructor, and is the amount of full shares to be minted on the initial deposit (share tokens have 18 decimals so full shares are shares * 1e18).

---

### `deposit(IERC20[] assets, uint256[] amounts, address receiver) returns (uint256 shares)`

Mints shares Pool shares to receiver by depositing exactly amount of underlying tokens.

_Parameters:_
- `assets`: Array of asset addresses.
- `amounts`: Corresponding amounts of each asset.
- `receiver`: Address of the recipient of minted tokens.

_Description:_
Should be called by the owner in order to perform a deposit for a receiver. Along with the mint, the underlying asset difference is recorded in the contract's internal balance controls, and the contract's owner allowance is increased by the difference for each asset. This function also emits the "Deposit" event, which can be listened to off-chain.

---

### `changeStrategy(IERC20[] assets, int256[] balanceChanges)`

Changes balances of the Pool's underlying assets.

_Description:_
Should be called by the contract's owner after performing a trade. The workflow is as follows: owner transfers to itself the underlying assets to be traded, trades assets with itself as the receiver, approves the Pool contract for all amounts, calls this function with the affected assets and balance differences, the Pool contract then transfers the gained amounts to itself, appropriately updates it's internal underlying asset balance controls, and approves owner for new amounts. This function also emits the "ChangeStrategy" event, which can be listened to off-chain.

---

## Public Functions
Public functions can be called by off-chain services or directly by users to redeem shares, or just to acquire information on the Pool's status.

### `assets() returns (IERC20[] assets)`

Returns the address of the underlying asset addresses used by the Pool for accounting, depositing, and withdrawing.

_Description:_
Should be called from off-chain by any service that requires the Pool's owned asset addresses.

---

### `assetBalance(IERC20) returns (uint256 balance)`

Returns the total balance of one underlying asset managed by the Pool.

_Parameters:_
- `IERC20`: ERC-20 token contract.

_Description:_
Should be called from off-chain by any service that requires the Pool's balance of a given asset.

---

### `assetsAndBalances() returns (IERC20[] assets, uint256[] balances)`

Returns the addresses and balances of all underlying assets managed by Pool.

_Description:_
Should be called from off-chain by any service that requires the Pool's current asset strategy, and to show a user the assets and balances held by a given Pool.

---

### `convertToShares(IERC20[] assets, uint256[] amounts) returns (uint256 shares)`

Returns the amount of shares that the Pool would exchange for the amount of assets provided, in an ideal scenario where all the conditions are met.

_Parameters:_
- `assets`: Array of asset addresses.
- `amounts`: Corresponding amounts of each asset.

_Description:_
Should be called from off-chain to show a user an estimation of how many shares would be acquired for a given deposit amount by doing estimations on how many assets could be swapped for the deposit.

---

### `convertToAssets(uint256 shares) returns (IERC20[] assets, uint256[] amounts)`

Returns the addresses and amounts of assets that the Pool would exchange for the amount of shares provided, in an ideal scenario where all the conditions are met.

_Parameters:_
- `shares`: Amount of shares.

_Description:_
Should be called from off-chain to show a user how many assets would be acquired for a given share amount.

---

### `maxMint() returns (uint256 maxShares)`

Returns the maximum amount of shares that the Pool can mint without overflowing the totalSupply().

_Description:_
Should be called from off-chain in cases where the Pool is very popular to assess if there could be any problems with token issuance.

---

### `maxWithdraw(address owner) returns (IERC20[] assets, uint256[] maxAmounts)`

Returns the addresses and maximum amounts of assets managed by the Pool that can be redeemed by a share owner's account.

_Parameters:_
- `owner`: Share owner account's address.

_Description:_
Should be called from off-chain to show a user his portion of the underlying assets of the Pool. This function will check the user's share balance and return the asset conversion for its full amount.

---

### `maxDeposit() returns (IERC20[] assets, uint256[] maxAmounts)`

Returns the maximum amount of the underlying assets that can be deposited into the Pool through a deposit call.

_Description:_
Should be called from off-chain to check if a deposit is too big. This function will internally check the maximum amount of tokens that can be deposited such that the minted shares will not overflow the totalSupply().

---

### `minDeposit() returns (IERC20[] assets, uint256[] minAmounts)`

Returns the minimum amount of the underlying assets that can be deposited into the Pool such that at least 1 share will be minted.

_Description:_
Should be called from off-chain to check if a deposit call is too small.

---

### `previewDeposit(IERC20[] assets, uint256[] amounts) returns (uint256 shares)`

Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given current on-chain conditions.

_Parameters:_
- `assets`: Array of asset addresses.
- `amounts`: Corresponding amounts of each asset.

_Description:_
Should be called from off-chain to show a user an estimation of how many shares would be acquired for a given deposit amount by doing estimations on how many assets could be swapped for the deposit.

---

### `maxRedeem(address owner) returns (uint256 maxShares)`

Returns the maximum amount of Pool shares that can be redeemed from a share owner account's balance in the Pool, through a redeem call.

_Parameters:_
- `owner`: Share owner account's address.

_Description:_
Should be called by the owner of the contract in order to perform a deposit for a receiver.

---

### `minRedeem() returns (uint256 minShares)`

Returns the minimum amount of shares that can be redeemed to the Pool to get at least 1 of each asset.

_Description:_
Should be called from off-chain to check if a redeem call is too small.

---

### `previewRedeem(uint256 shares) returns (IERC20[] assets, uint256[] amounts)`

Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block, given current on-chain conditions.

_Description:_
Should be called from off-chain to show a user how many assets would be acquired for a given share amount.

---

### `redeem(uint256 shares, address receiver, address owner) returns (IERC20[] assets, uint256[] amounts)`

Burns exactly shares from an owner account's balance and sends assets of underlying tokens to receiver's account.

_Parameters:_
- `shares`: Amount of shares to be burned.
- `receiver`: Assets recipient account's address.
- `owner`: Share owner account's address.

_Description:_
Should be called by a user to retrieve underlying assets by burning his shares. Along with the burn, the underlying asset difference is recorded in the contract's internal balance controls, and the allowance of the contract's owner is decreased by the difference for each asset. This function also emits the "Deposit" event, which can be listened to off-chain.

---
