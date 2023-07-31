# Strategy Wallet Herald Contract Documentation

The MC²Fi `StrategyWalletHerald` contract aggregates important strategy wallet event emissions into a single contract.

## Deployment Addresses

_Ethereum_:


_Goerli:_


_BSC_:


_BSC Testnet_:


### Public Functions
All functions in this contract are public, considering that the validity of the events can always be checked since they include the caller address.

#### `proclaimRevokeAdminship(address oldAdmin)`

Emits the "RevokeAdminship" event containing the caller address, and the parameterized old admin address.

_Parameters:_
- `oldAdmin`: Address of the previous admin account before revoking.

_Description:_
Is called by every StrategyWallet contract in every `revokeAdminship` call in which the caller is the registered "backer" account. This function emits the `RevokeAdminship` event, which can be listened to off-chain.

---
