# Strategy Pool Herald Contract Documentation

The MC²Fi `StrategyPoolHerald` contract aggregates important strategy pool event emissions into a single contract.

## Deployment Addresses

_Ethereum_:
0x2096ccFc2EfE5dF7Cc838cF39aa5528891666e51

_Goerli:_
0x64c1241aE01b245FBA90BA88e15DF78Da2a6a2D9

_BSC_:
0x115932B4D979E3d7b2b18066Af444663E7F25478

_BSC Testnet_:
0x85fC1F9EC12e16DA681EEd853464F9E162e3C036

### Public Functions
All functions in this contract are public, considering that the validity of the events can always be checked since they include the caller address.

#### `proclaimRedeem(address owner, uint256 amount)`

Emits the "Redeem" event containing the caller address, and the parameterized owner address and amount.

_Parameters:_
- `owner`: Address of the owner of pool tokens (should be a StrategyWallet contract).
- `receiver`: Address of the owner of pool tokens (should be the backer registered in the StrategyWallet).
- `amount`: Amount of pool tokens redeemed.

_Description:_
Is called by every StrategyPool contract in every `redeem` call. This function emits the `Redeem` event, which can be listened to off-chain.

---
