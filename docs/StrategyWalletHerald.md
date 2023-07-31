# Strategy Wallet Herald Contract Documentation

The MC²Fi `StrategyWalletHerald` contract aggregates important strategy wallet event emissions into a single contract.

## Deployment Addresses

_Ethereum_:
0x998FEfd555Ee7B4d7177FCA9eA738006B42bFaf3

_Goerli:_
0x0a774e2412D10DFa754Eb969d79157FF81939C96

_BSC_:
0x783eE283715F15Ec61fBE2233C47225364acd63b

_BSC Testnet_:
0x9BBd6eE629d3A28bbeAf5f8Bf9554137fDCE2700

### Public Functions
All functions in this contract are public, considering that the validity of the events can always be checked since they include the caller address.

#### `proclaimRevokeAdminship(address oldAdmin)`

Emits the "RevokeAdminship" event containing the caller address, and the parameterized old admin address.

_Parameters:_
- `oldAdmin`: Address of the previous admin account before revoking.

_Description:_
Is called by every StrategyWallet contract in every `revokeAdminship` call in which the caller is the registered "backer" account. This function emits the `RevokeAdminship` event, which can be listened to off-chain.

---
