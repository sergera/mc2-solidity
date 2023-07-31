# Strategy Wallet Contract Documentation

The MC²Fi `StrategyWallet` contract holds backer's Pool tokens for all backed `StrategyPool`s.

It holds the address for a Backer account, and optionally, an Admin account, that can call certain functions in the Backer's name.

Both are parameterized in the constructor (`address(0)` for no Admin), and after contract creation the backer can:
- redeem Pool tokens from a `StrategyPool`
- revoke the Admin account
- change the Backer account

, and the Admin can:
- redeem Pool tokens from a `StrategyPool`
- revoke the Admin account
- change the Admin account

## Backer Only Functions
Functions that can only be called by the contract's backer (parameterized in the constructor), this contract only has one, which is responsible for changing the Backer account itself.

#### `transferBackership(address newBacker)`

Changes this contract's Backer account to another account. This means that the new account will the only one (other than the admin, if there is one) able to redeem this contract's Pool tokens from now on.

_Parameters:_
- `newBacker`: Address of new Backer account.

_Description:_
Should be called by the Backer in order to change the account that redeems Pool tokens this contract may own. This function also emits the `BackershipTransferred` event, which can be listened to off-chain.

---

## Admin Only Functions

#### `transferAdminship(address newAdmin)`

Changes this contract's Admin account to another account.

_Parameters:_
- `newAdmin`: Address of new Admin account.

_Description:_
Should be called by the Admin in order to change the account that, along with the Backer account, is able to call some of this contract's functions. This function also emits the `AdminshipTransferred` event, which can be listened to off-chain.

---

## Backer or Admin's Functions
Functions that can be called by the contract's backer or by the contract's Admin (in case there currently is one), they are related to redeem calls, and changing admin account.

#### `redeemFromStrategy(IStrategyPool strategy, uint256 poolTokens)`

Redeems an amount of Pool tokens of a given `StrategyPool` owned by this contract.

_Parameters:_
- `strategy`: Address of the `StrategyPool` contract.
- `poolTokens`: Amount to be redeemed.

_Description:_
Should be called by the Backer or the Admin in order to redeem Pool tokens. This function also emits the `RedeemedFromStrategy` event, which can be listened to off-chain.

---

#### `fullRedeemFromStrategy(IStrategyPool strategy)`

Redeems the total amount of Pool tokens of a given `StrategyPool` owned by this contract.

_Parameters:_
- `strategy`: Address of the `StrategyPool` contract.

_Description:_
Should be called by the Backer or the Admin in order to redeem Pool tokens. This function also emits the `RedeemedFromStrategy` event, which can be listened to off-chain.

---

#### `revokeAdminship()`

Removes any admin rights by setting the Admin account address to `address(0)`.

_Description:_
Should be called by the Backer or the Admin in order to remove any and all Admin permissions. This function also emits the `AdminshipTransferred` event, which can be listened to off-chain.

_NOTE:_
This function calls `proclaimRevokeAdminship` in the StrategyWalletHerald contract if the caller is the registered "backer" account, so that all user-driven `revokeAdminship` calls can be easily listened to.

---

### Public Functions
Public functions can be called by off-chain services or directly by users to query the Backer and the Admin address.

#### `backer()`

Returns the registered Backer account address.

---

#### `admin()`

Returns the registered Admin account address.

_NOTE:_
If there is no Admin currently, returns `address(0)`.

---