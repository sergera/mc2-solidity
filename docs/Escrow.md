# StrategyPool Contract Documentation

The MC²Fi `Escrow` contract transfers users escrows to the appropriate accounts.

## Owner's Functions
Owner's functions can only be called by the contract's owner, this contract only has one, which is responsible for transferring escrow funds.

#### `transferTokenTo(IERC20 token, address recipient, uint256 amount)`

Transfers a given token owned by this contract to another account.

_Parameters:_
- `token`: Address of ERC20 token to be transferred.
- `amount`: Amount to be transferred.
- `recipient`: Address of the recipient.

_Description:_
Should be called by the owner in order to transfer tokens owned by this contract to another account. This function also emits the `TransferTokenTo` event, which can be listened to off-chain.

### Public Functions
This contract has no public functions.
