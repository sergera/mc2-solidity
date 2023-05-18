// SPDX-License-Identifier: UNLICENSED
/*
Copyright (C) 2023 MC² Finance

All rights reserved. This program and the accompanying materials
are made available for use and disclosure in accordance with the terms of this copyright notice.
This notice does not constitute a license agreement. No part of this program may be used, reproduced, 
or transmitted in any form or by any means, electronic, mechanical, photocopying, recording, or otherwise, 
without the prior written permission of MC² Finance.
*/

pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the MC²Fi StrategyPool contract
 * - inspired by OpenZeppelin's ERC4626 "Tokenized Pool Standard" implementation v4.8.0
 * - EIP OpenZeppelin's implementation is based on: https://eips.ethereum.org/EIPS/eip-4626[ERC-4626]
 */
interface IStrategyPool is IERC20, IERC20Metadata {
    event Deposit(
        address indexed sender,
        address indexed owner,
        IERC20[] assets,
        uint256[] amounts,
        uint256 shares
    );

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        IERC20[] assets,
        uint256[] amounts,
        uint256 shares
    );

    event ChangeStrategy(
        address indexed sender,
        IERC20[] assetChanged,
        int256[] balanceChanges
    );

    /**
     * @dev Changes initial deposit share value, in case the Pool goes empty, and has to be initialized again.
     */
    function changeInitialDepositShareValue(uint256 newValue) external;

    /**
     * @dev Returns the address of the underlying tokens used by the Pool for accounting, depositing, and withdrawing.
     *
     * - MUST NOT revert.
     */
    function assets() external view returns (IERC20[] memory assets);

    /**
     * @dev Returns the total amount of one underlying asset managed by the Pool.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST return 0 if the asset is not owned by the Pool.
     * - MUST NOT revert.
     */
    function assetBalance(IERC20) external view returns (uint256 balance);

    /**
     * @dev Returns the addresses total amounts of all underlying assets managed by Pool.
     *
     * - MUST NOT revert.
     */
    function assetsAndBalances()
        external
        view
        returns (IERC20[] memory assets, uint256[] memory balances);

    /**
     * @dev Returns the amount of shares that the Pool would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT show any variations depending on the caller.
     * - MUST revert if input arrays have different lengths.
     * - MUST revert if Pool is initialized and any input token addresses are not owned by the Pool.
     * - MUST revert if Pool is initialized and any token address owned by the Pool is missing from input.
     */
    function convertToShares(
        IERC20[] memory assets,
        uint256[] memory amounts
    ) external view returns (uint256 shares);

    /**
     * @dev Returns the addresses and amounts of assets that the Pool would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT show any variations depending on the caller.
     */
    function convertToAssets(
        uint256 shares
    ) external view returns (IERC20[] memory assets, uint256[] memory amounts);

    /**
     * @dev Returns the maximum amount of shares that can be minted without overflowing totalSupply.
     *
     * - MUST NOT revert.
     */
    function maxMint() external view returns (uint256 maxShares);

    /**
     * @dev Returns the maximum amount of the underlying assets that can be withdrawn from the owner balance in the
     * Pool, through a redeem call with balanceOf(owner).
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(
        address owner
    )
        external
        view
        returns (IERC20[] memory assets, uint256[] memory maxAmounts);

    /**
     * @dev Returns the maximum amount of the underlying assets that can be deposited into the Pool through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST NOT revert.
     */
    function maxDeposit()
        external
        view
        returns (IERC20[] memory assets, uint256[] memory maxAmounts);

    /**
     * @dev Returns the minimum amount of underlying assets that can be deposited into the Pool to get a share.
     *
     * - MUST return empty arrays if the Pool is empty.
     * - MUST NOT revert.
     */
    function minDeposit()
        external
        view
        returns (IERC20[] memory assets, uint256[] memory minAmounts);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST NOT show any variations depending on the caller.
     * - MUST revert if input arrays have different lengths.
     * - MUST revert if any input token addresses are not owned by the Pool.
     * - MUST revert if a token address owned by the Pool is missing from input.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(
        IERC20[] memory assets,
        uint256[] memory amounts
    ) external view returns (uint256 shares);

    /**
     * @dev Mints shares Pool shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MUST revert if all of the assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Pool contract, etc).
     * - MUST revert if minted shares exceed maxMint().
     *
     * NOTE: most implementations will require pre-approval of the Pool with the Pool’s underlying asset tokens.
     */
    function deposit(
        IERC20[] memory assets,
        uint256[] memory amounts,
        address receiver
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Pool shares that can be redeemed from the owner balance in the Pool,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Returns the minimum amount of shares that can be redeemed to the Pool to get at least 1 of each asset.
     *
     * - MUST return 0 if the Pool is empty.
     * - MUST NOT revert.
     */
    function minRedeem() external view returns (uint256 minShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(
        uint256 shares
    ) external view returns (IERC20[] memory assets, uint256[] memory amounts);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Pool before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (IERC20[] memory assets, uint256[] memory amounts);

    /**
     * @dev Updates assets owned by the Pool.
     *
     * - MUST emit the ChangeStrategy event with any assets updated, and their balance changes.
     * - MUST revert if input arrays have different lengths.
     * - MUST revert if Pool is empty.
     * - MUST revert if all of the assets cannot be transfered (due to slippage, the account not
     *   approving enough underlying tokens to the Pool contract, etc).
     */
    function changeStrategy(
        IERC20[] calldata assets,
        int256[] calldata balanceChanges
    ) external;
}
