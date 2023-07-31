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

import {Context} from "openzeppelin-contracts/contracts/utils/Context.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import {IStrategyPool} from "./IStrategyPool.sol";
import {IStrategyWalletHerald} from "./IStrategyWalletHerald.sol";

contract StrategyWallet is Context, ReentrancyGuard {
    /**
     * @dev Backer address, receiver of any and all redeem calls
     * Can only be changed by the backer
     */
    address private __backer;

    /**
     * @dev Optional admin address, can call redeem in the name of backer
     * Can only be changed by the backer or the admin (if there is an admin)
     */
    address private __admin;

    IStrategyWalletHerald private __herald;

    event RedeemedFromStrategy(
        address indexed sender,
        IStrategyPool indexed strategy,
        address indexed backer,
        uint256 poolTokens
    );
    event BackershipTransferred(
        address indexed previousBacker,
        address indexed newBacker
    );
    event AdminshipTransferred(
        address indexed sender,
        address indexed previousAdmin,
        address indexed newAdmin
    );

    constructor(address _backer, address _admin, address _herald) {
        require(
            _backer != address(0),
            "StrategyWallet: backer is the zero address"
        );
        require(
            _herald != address(0),
            "StrategyWallet: herald is the zero address"
        );
        __backer = _backer;
        if (_admin != address(0)) {
            __admin = _admin;
        }
        __herald = _herald;
    }

    /**
     * @dev Redeems all Pool tokens from (`_strategy`).
     * Can only be called by the current backer or the current admin (if an admin exists).
     */
    function fullRedeemFromStrategy(
        IStrategyPool _strategy
    ) external onlyBackerOrAdmin nonReentrant {
        uint256 _poolTokens = _strategy.balanceOf(address(this));
        if (_msgSender() == backer()) {
            _strategy.redeem(address(this), backer(), _poolTokens);
        } else {
            _strategy.redeemAsAdmin(address(this), _poolTokens);
        }

        emit RedeemedFromStrategy(
            _msgSender(),
            _strategy,
            backer(),
            _poolTokens
        );
    }

    /**
     * @dev Redeems (`_poolTokens`) from (`_strategy`).
     * Can only be called by the current backer or the current admin (if an admin exists).
     */
    function redeemFromStrategy(
        IStrategyPool _strategy,
        uint256 _poolTokens
    ) external onlyBackerOrAdmin nonReentrant {
        if (_msgSender() == backer()) {
            _strategy.redeem(address(this), backer(), _poolTokens);
        } else {
            _strategy.redeemAsAdmin(address(this), _poolTokens);
        }

        emit RedeemedFromStrategy(
            _msgSender(),
            _strategy,
            backer(),
            _poolTokens
        );
    }

    /**
     * @dev Revoke any admin rights by changing the admin to the zero address.
     * Can only be called by the current backer.
     *
     * NOTE: Revoking adminship will leave the contract without an admin,
     * thereby any functionality that was available to both the backer and the admin
     * will be only available to the backer until the event that the backer calls `transferAdminship`
     * and adds another account as admin.
     */
    function revokeAdminship() external onlyBackerOrAdmin {
        __herald.proclaimRevokeAdminship(admin());
        _transferAdminship(address(0));
    }

    /**
     * @dev Transfers admin rights to a new account (`_newAdmin`).
     * Can only be called by the current backer or the current admin (if an admin exists).
     */
    function transferAdminship(address _newAdmin) external onlyAdmin {
        require(
            _newAdmin != address(0),
            "StrategyWallet: new admin is the zero address"
        );
        _transferAdminship(_newAdmin);
    }

    /**
     * @dev Transfers ownership of StrategyPool tokens to a new account (`_newBacker`).
     * Can only be called by the current backer.
     */
    function transferBackership(address _newBacker) external onlyBacker {
        require(
            _newBacker != address(0),
            "StrategyWallet: new backer is the zero address"
        );
        _transferBackership(_newBacker);
    }

    /**
     * @dev Transfers admin rights to a new account (`_newAdmin`).
     * Internal function without access restriction.
     */
    function _transferAdminship(address _newAdmin) private {
        address _oldAdmin = __admin;
        __admin = _newAdmin;
        emit AdminshipTransferred(_msgSender(), _oldAdmin, _newAdmin);
    }

    /**
     * @dev Transfers ownership of StrategyPool tokens to a new account (`_newBacker`).
     * Internal function without access restriction.
     */
    function _transferBackership(address _newBacker) private {
        address _oldBacker = __backer;
        __backer = _newBacker;
        emit BackershipTransferred(_oldBacker, _newBacker);
    }

    /**
     * @dev Throws if called by any account other than the current backer.
     */
    modifier onlyBacker() {
        _checkBacker();
        _;
    }

    /**
     * @dev Throws if called by any account other than the current admin (if an admin exists).
     */
    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    /**
     * @dev Throws if called by any account other than the current backer or the current admin (if an admin exists).
     */
    modifier onlyBackerOrAdmin() {
        _checkBackerOrAdmin();
        _;
    }

    /**
     * @dev Returns the address of the current backer.
     */
    function backer() public view returns (address) {
        return __backer;
    }

    /**
     * @dev Returns the address of the current admin.
     *
     * NOTE: If there is no admin, this function will return the zero address.
     */
    function admin() public view returns (address) {
        return __admin;
    }

    /**
     * @dev Throws if the sender is not the backer.
     */
    function _checkBacker() private view {
        require(
            backer() == _msgSender(),
            "StrategyWallet: caller is not the backer"
        );
    }

    /**
     * @dev Throws if the sender is not the admin or if there is no admin.
     */
    function _checkAdmin() private view {
        require(
            admin() != address(0) && admin() == _msgSender(),
            "StrategyWallet: caller is not the admin"
        );
    }

    /**
     * @dev Throws if the sender is not the backer nor the admin (if an admin exists).
     */
    function _checkBackerOrAdmin() private view {
        require(
            backer() == _msgSender() ||
                (admin() != address(0) && admin() == _msgSender()),
            "StrategyWallet: caller is not the backer nor the admin"
        );
    }
}
