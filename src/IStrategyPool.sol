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

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

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
        uint256 poolTokens
    );

    event Redeem(
        address indexed sender,
        address indexed owner,
        uint256 poolTokens
    );

    event Withdraw(
        address indexed receiver,
        IERC20[] assets,
        uint256[] amounts
    );

    event AcquireBeforeTrade(
        address indexed sender,
        IERC20 asset,
        uint256 amount
    );

    event GiveBackAfterTrade(
        address indexed sender,
        IERC20[] assets,
        uint256[] amounts
    );

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
     * @dev Returns the maximum amount of Pool tokens that can be minted without overflowing totalSupply.
     *
     * - MUST NOT revert.
     */
    function maxMint() external view returns (uint256 maxPoolTokens);

    /**
     * @dev Mints poolTokens to receiver by depositing exactly amount of underlying assets.
     *
     * - MUST emit the Deposit event.
     * - MUST revert if any amount is 0.
     * - MUST revert if minted poolTokens exceed maxMint().
     * - MUST revert if all of the assets cannot be deposited,
     *	 i.e. caller not approving enough assets before the call.
     */
    function deposit(
        IERC20[] memory assets,
        uint256[] memory amounts,
        uint256 poolTokens,
        address receiver
    ) external;

    /**
     * @dev Returns the maximum amount of Pool tokens that can be redeemed from the owner balance in the Pool,
     * through a redeem call.
     *
     * - MUST return balanceOf(owner).
     * - MUST NOT revert.
     */
    function maxRedeem(
        address owner
    ) external view returns (uint256 maxPoolTokens);

    /**
     * @dev Burns exactly poolTokens from owner.
     *
     * - MUST emit the Redeem event.
     * - MUST revert if poolTokens is 0.
     * - MUST revert if all of poolTokens cannot be redeemed,
     *	 i.e. the owner not having enough poolTokens before the call.
     */
    function redeem(
        address owner,
        address receiver,
        uint256 poolTokens
    ) external;

    /**
     * @dev Sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MUST revert if all of assets cannot be withdrawn,
     *	 i.e. the pool not having enough assets before the call.
     */
    function withdraw(
        address receiver,
        IERC20[] memory assets,
        uint256[] memory amounts
    ) external;

    /**
     * @dev Owner acquires Pool's asset to perform trade / strategy change.
     *
     * - MUST emit the AcquireBeforeTrade event.
     * - MUST revert if asset is not owned by the Pool.
     * - MUST revert if amount is greater than the asset balance.
     * - MUST revert if amount is 0.
     */
    function acquireAssetBeforeTrade(IERC20 asset, uint256 amount) external;

    /**
     * @dev Owner gives back assets after trade / strategy change.
     *
     * - MUST emit the GiveBackAfterTrade event.
     * - MUST revert if input arrays have different lengths.
     * - MUST revert if any amount is 0.
     * - MUST revert if all of the assets cannot be transfered,
     *	 i.e. the account not approving enough assets before the call.
     */
    function giveBackAssetsAfterTrade(
        IERC20[] calldata assets,
        uint256[] calldata amounts
    ) external;
}
