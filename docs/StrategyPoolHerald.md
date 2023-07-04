# Strategy Pool Herald Contract Documentation

The MC²Fi `StrategyPoolHerald` contract aggregates important strategy pool event emissions into a single contract.

## Deployment Addresses

_Ethereum_:
0x8C47839e82243cF5E2EE784B115F68e95f3C2ce1

_Goerli:_
0x14837279c5FC572B0175e078732fb0694287bf53

_BSC_:
0x52f47C22F0138f8c6251b6A4dD6E93ee693116e1

_BSC Testnet_:
0x0893abEB433C1a3D63C60F7034c2582Fc7dc8c52

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
