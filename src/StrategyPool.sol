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

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {IStrategyPoolHerald} from "./IStrategyPoolHerald.sol";

import {IStrategyPool} from "./IStrategyPool.sol";

/**
 * @dev MC²Fi StrategyPool contract
 * - inspired by OpenZeppelin's ERC4626 "Tokenized Pool Standard" implementation v4.8.0
 * - EIP OpenZeppelin's implementation is based on: https://eips.ethereum.org/EIPS/eip-4626[ERC-4626]
 * - allows for multiple underlying tokens
 * - keeps track of currently owned tokens
 * - represents a dynamic token strategy, owner can change the underlying tokens and their ratios
 */
contract StrategyPool is
    ERC20,
    Ownable,
    Pausable,
    ReentrancyGuard,
    IStrategyPool
{
    IERC20[] public assetAddresses;
    mapping(IERC20 => uint256) private __assetIndices;
    mapping(IERC20 => uint256) public assetBalances;
    IStrategyPoolHerald private __herald;

    /**
     * @dev Set owner, owner is solely responsible for deposits and updating assets.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _newOwner,
        IStrategyPoolHerald _herald
    ) ERC20(_name, _symbol) {
        require(
            _newOwner != address(0),
            "StrategyPool: new owner is the zero address"
        );
        require(
            address(_herald) != address(0),
            "StrategyPool: herald is the zero address"
        );
        _transferOwnership(_newOwner);
        __herald = _herald;
    }

    /**
     * @dev Returns array of owned assets.
     */
    function assets()
        external
        view
        override
        whenNotPaused
        returns (IERC20[] memory)
    {
        return assetAddresses;
    }

    /**
     * @dev Returns the currently owned balance of a single asset.
     */
    function assetBalance(
        IERC20 _asset
    ) external view override whenNotPaused returns (uint256) {
        return assetBalances[_asset];
    }

    /**
     * @dev Returns an array of owned assets, and an array of respective balances.
     */
    function assetsAndBalances()
        external
        view
        override
        whenNotPaused
        returns (IERC20[] memory, uint256[] memory)
    {
        uint256 _length = assetAddresses.length;

        uint256[] memory _amounts = new uint256[](_length);
        for (uint256 i = 0; i < _length; i++) {
            _amounts[i] = assetBalances[assetAddresses[i]];
        }

        return (assetAddresses, _amounts);
    }

    /**
     * @dev Returns the maximum amount of Pool tokens that can be minted without overflowing totalSupply.
     */
    function maxMint() public view override returns (uint256) {
        return type(uint256).max - totalSupply();
    }

    /**
     * @dev Mints poolTokens to receiver by depositing exactly amount of underlying assets.
     */
    function deposit(
        IERC20[] memory _assets,
        uint256[] memory _amounts,
        uint256 _poolTokens,
        address _receiver
    ) external override onlyOwner {
        require(
            _assets.length == _amounts.length,
            "StrategyPool: deposit arrays length mismatch"
        );
        require(
            _poolTokens <= maxMint(),
            "StrategyPool: deposit pool tokens more than max"
        );
        _deposit(_msgSender(), _receiver, _assets, _amounts, _poolTokens);
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(
        address _caller,
        address _receiver,
        IERC20[] memory _assets,
        uint256[] memory _amounts,
        uint256 _poolTokens
    ) internal nonReentrant {
        // If _asset is ERC777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the Pool, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the poolTokens are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth

        for (uint256 i = 0; i < _assets.length; i++) {
            require(_amounts[i] > 0, "StrategyPool: deposit 0 amount");
            if (!_assetIsOwned(_assets[i])) {
                _addAsset(_assets[i]);
            }
            SafeERC20.safeTransferFrom(
                _assets[i],
                _caller,
                address(this),
                _amounts[i]
            );
            assetBalances[_assets[i]] += _amounts[i];
        }
        _mint(_receiver, _poolTokens);

        emit Deposit(_caller, _receiver, _assets, _amounts, _poolTokens);
    }

    /**
     * @dev Returns the maximum amount of Pool tokens that can be redeemed from the owner balance in the Pool,
     * through a redeem call.
     */
    function maxRedeem(
        address _owner
    ) external view override returns (uint256) {
        return balanceOf(_owner);
    }

    /**
     * @dev Burns exactly poolTokens from owner.
     */
    function redeem(
        address _owner,
        address _backer,
        uint256 _poolTokens,
        bool _shouldProclaim
    ) external override whenNotPaused {
        require(_poolTokens > 0, "StrategyPool: redeem 0 pool tokens");
        require(
            _poolTokens <= balanceOf(_owner),
            "StrategyPool: redeem more than balance"
        );

        if (_msgSender() != _owner) {
            _spendAllowance(_owner, _msgSender(), _poolTokens);
        }

        _burn(_owner, _poolTokens);
        emit Redeem(_msgSender(), _owner, _poolTokens);
        if (_shouldProclaim) {
            __herald.proclaimRedeem(_owner, _backer, _poolTokens);
        }
    }

    /**
     * @dev Sends underlying assets to receiver.
     */
    function withdraw(
        address _receiver,
        IERC20[] memory _assets,
        uint256[] memory _amounts
    ) external override whenNotPaused nonReentrant onlyOwner {
        require(
            _receiver != address(0),
            "Strategy Pool: withdraw to 0 address"
        );
        require(
            _assets.length == _amounts.length,
            "Strategy Pool: array lengths do not match"
        );

        for (uint256 i = 0; i < _assets.length; i++) {
            require(_amounts[i] > 0, "Strategy Pool: withdraw 0 amount");
            require(
                _assetIsOwned(_assets[i]),
                "StrategyPool: withdraw unowned asset"
            );
            require(
                assetBalances[_assets[i]] >= _amounts[i],
                "StrategyPool: withdraw more than balance"
            );
            SafeERC20.safeTransfer(_assets[i], _receiver, _amounts[i]);
            assetBalances[_assets[i]] -= _amounts[i];
            if (assetBalances[_assets[i]] == 0) {
                _removeAsset(_assets[i]);
            }
        }

        emit Withdraw(_receiver, _assets, _amounts);
    }

    /**
     * @dev Owner acquires Pool's asset to perform trade / strategy change.
     */
    function acquireAssetBeforeTrade(
        IERC20 _asset,
        uint256 _amount
    ) external override onlyOwner nonReentrant whenNotPaused {
        _pause();
        require(_amount > 0, "StrategyPool: acquire 0 amount");
        require(_assetIsOwned(_asset), "StrategyPool: acquire unowned asset");
        require(
            assetBalances[_asset] >= _amount,
            "StrategyPool: acquire more than balance"
        );
        SafeERC20.safeTransfer(_asset, owner(), _amount);
        assetBalances[_asset] -= _amount;
        if (assetBalances[_asset] == 0) {
            _removeAsset(_asset);
        }

        emit AcquireBeforeTrade(_msgSender(), _asset, _amount);
    }

    /**
     * @dev Owner gives back assets after trade / strategy change.
     */
    function giveBackAssetsAfterTrade(
        IERC20[] calldata _assets,
        uint256[] calldata _amounts
    ) external override onlyOwner nonReentrant whenPaused {
        require(
            _assets.length == _amounts.length,
            "StrategyPool: give back arrays length mismatch"
        );

        for (uint256 i = 0; i < _assets.length; i++) {
            require(_amounts[i] > 0, "StrategyPool: give back 0 amount");
            if (_assetIsOwned(_assets[i])) {
                /* asset is already owned, acquire it, and add to its balance */
                SafeERC20.safeTransferFrom(
                    _assets[i],
                    owner(),
                    address(this),
                    _amounts[i]
                );
                assetBalances[_assets[i]] += _amounts[i];
            } else {
                /* asset is new, acquire it, add asset, and add to its balance */
                SafeERC20.safeTransferFrom(
                    _assets[i],
                    owner(),
                    address(this),
                    _amounts[i]
                );
                _addAsset(_assets[i]);
                assetBalances[_assets[i]] += _amounts[i];
            }
        }

        emit GiveBackAfterTrade(_msgSender(), _assets, _amounts);
        _unpause();
    }

    /**
     * @dev Owner changes asset address / amount directly.
     */
    function migrateAsset(
        IERC20 _oldAsset,
        IERC20 _newAsset,
        uint256 _newAmount
    ) external override onlyOwner {
        require(
            _oldAsset != IERC20(address(0)) && _newAsset != IERC20(address(0)),
            "StrategyPool: migrate asset with 0 address"
        );
        require(_newAmount > 0, "StrategyPool: migrate asset with 0 amount");
        require(
            _assetIsOwned(_oldAsset),
            "StrategyPool: migrate unowned asset"
        );
        require(
            !_assetIsOwned(_newAsset),
            "StrategyPool: migrate to owned asset"
        );
        _removeAsset(_oldAsset);
        assetBalances[_oldAsset] = 0;
        _addAsset(_newAsset);
        assetBalances[_newAsset] = _newAmount;
    }

    /**
     * @dev Owner rescues assets in case of emergency.
     */
    function rescueAssets(
        address _receiver,
        IERC20[] memory _assets,
        uint256[] memory _amounts
    ) external override onlyOwner {
        require(_receiver != address(0), "Strategy Pool: rescue to 0 address");
        require(
            _assets.length == _amounts.length,
            "Strategy Pool: array lengths do not match"
        );

        for (uint256 i = 0; i < _assets.length; i++) {
            require(_amounts[i] > 0, "Strategy Pool: rescue 0 amount");
            SafeERC20.safeTransfer(_assets[i], _receiver, _amounts[i]);
        }
    }

    /**
     * @dev Owner pauses contract manually.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @dev Owner unpauses contract manually.
     */
    function unpause() external override onlyOwner {
        _unpause();
    }

    /**
     * @dev Adds a knowingly previously unowned asset.
     * NOTE: should NOT be called on an owned asset.
     */
    function _addAsset(IERC20 _asset) private {
        assetAddresses.push(_asset);
        _setAssetIndex(_asset, assetAddresses.length - 1);
    }

    /**
     * @dev Removes a knowingly owned asset.
     * NOTE: should NOT be called on an unowned asset.
     */
    function _removeAsset(IERC20 _asset) private {
        uint256 _index = _getAssetIndex(_asset);
        IERC20 _lastAsset = assetAddresses[assetAddresses.length - 1];

        assetAddresses[_index] = _lastAsset;
        assetAddresses.pop();

        _setAssetIndex(_lastAsset, _index);

        delete __assetIndices[_asset];
    }

    /**
     * @dev Gets the actual index of the asset in "assets" array.
     */
    function _getAssetIndex(IERC20 _asset) private view returns (uint256) {
        return __assetIndices[_asset] - 1;
    }

    /**
     * @dev Inserts a shifted index of the asset in "assets" array into "__assetIndices" mapping.
     */
    function _setAssetIndex(IERC20 _asset, uint256 _index) private {
        __assetIndices[_asset] = _index + 1;
    }

    /**
     * @dev Returns a bool indicating if the asset is currently owned by the strategy pool.
     */
    function _assetIsOwned(IERC20 _asset) private view returns (bool) {
        return __assetIndices[_asset] != 0;
    }
}
