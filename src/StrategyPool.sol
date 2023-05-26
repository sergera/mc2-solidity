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

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/utils/math/Math.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

import "./IStrategyPool.sol";

/**
 * @dev MC²Fi StrategyPool contract
 * - inspired by OpenZeppelin's ERC4626 "Tokenized Pool Standard" implementation v4.8.0
 * - EIP OpenZeppelin's implementation is based on: https://eips.ethereum.org/EIPS/eip-4626[ERC-4626]
 * - allows for multiple underlying tokens
 * - keeps track of currently owned tokens, no possible donation attacks
 * - represents a dynamic token strategy, owner can change the underlying tokens and their ratios
 * - gated-entry, only owner can deposit
 * - mints shares on deposit, enforcing a ratio of underlying assets
 * - burns shares on withdrawal
 * - for simplicity the only entry is deposit, and the only exit is redeem
 */
contract StrategyPool is ERC20, Ownable, ReentrancyGuard, IStrategyPool {
    using Math for uint256;

    IERC20[] public assetAddresses;
    mapping(IERC20 => uint256) private _assetIndices;
    mapping(IERC20 => uint256) public assetBalances;

    /**
     * @dev Set owner, owner is solely responsible for deposits and updating assets.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _newOwner
    ) ERC20(_name, _symbol) {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Returns array of owned assets.
     */
    function assets() external view override returns (IERC20[] memory) {
        return assetAddresses;
    }

    /**
     * @dev Returns the currently owned balance of a single asset.
     */
    function assetBalance(
        IERC20 _asset
    ) external view override returns (uint256) {
        return assetBalances[_asset];
    }

    /**
     * @dev Returns an array of owned assets, and an array of respective balances.
     */
    function assetsAndBalances()
        external
        view
        override
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
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     *
     * NOTE: the pool is meant to enforce a certain ratio of tokens that can only be changed by the owner,
     * so the share calculation compares each token's amount to the pool's and returns the lesser value of
     * "shares = (amount * totalShares) / totalAmountOwnedByPool", therefore if the caller does not
     * abide by the ratio owned by the pool, the caller will receive the least favorable bargain. That is also
     * why this call reverts if any inputted tokens are not owned by the pool, since that would make the denominator "1",
     * giving the caller the most favorable bargain.
     */
    function _convertToShares(
        IERC20[] memory _assets,
        uint256[] memory _amounts,
        Math.Rounding _rounding
    ) internal view returns (uint256) {
        /* use minimum ratio to calculate shares */
        uint256 _minShares = type(uint256).max;
        for (uint256 i = 0; i < _assets.length; i++) {
            require(
                _assetIndices[_assets[i]] > 0,
                "token is not currently owned by the contract"
            );

            uint256 _shares = _convertToSharesSingle(
                _assets[i],
                _amounts[i],
                _rounding
            );
            if (_shares < _minShares) {
                _minShares = _shares;
            }
        }
        return _minShares;
    }

    /**
     * @dev Internal conversion function (from single asset to shares) with support for rounding direction.
     */
    function _convertToSharesSingle(
        IERC20 _asset,
        uint256 _amount,
        Math.Rounding _rounding
    ) internal view returns (uint256) {
        return _amount.mulDiv(totalSupply(), assetBalances[_asset], _rounding);
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     *
     * NOTE: returns the amount of each token according to "amount = (shares * totalAmountOwnedByPool) / totalShares"
     */
    function _convertToAssets(
        uint256 _shares,
        Math.Rounding _rounding
    ) internal view returns (IERC20[] memory, uint256[] memory) {
        uint256 _length = assetAddresses.length;
        uint256[] memory _amounts = new uint256[](_length);
        for (uint256 i = 0; i < _length; i++) {
            _amounts[i] = _convertToAssetsSingle(
                assetAddresses[i],
                _shares,
                _rounding
            );
        }

        return (assetAddresses, _amounts);
    }

    /**
     * @dev Internal conversion function (from shares to single asset) with support for rounding direction.
     */
    function _convertToAssetsSingle(
        IERC20 _asset,
        uint256 _shares,
        Math.Rounding _rounding
    ) internal view returns (uint256) {
        return _shares.mulDiv(assetBalances[_asset], totalSupply(), _rounding);
    }

    /**
     * @dev Returns the maximum amount of shares that can be minted without overflowing totalSupply.
     */
    function maxMint() public view override returns (uint256) {
        return type(uint256).max - totalSupply();
    }

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Pool, through a withdraw call.
     */
    function maxWithdraw(
        address _owner
    ) external view override returns (IERC20[] memory, uint256[] memory) {
        return _convertToAssets(balanceOf(_owner), Math.Rounding.Down);
    }

    /**
     * @dev Returns the maximum amount of the underlying assets that can be deposited into the Pool through a deposit call.
     *
     * NOTE: returns the maximum amount of assets deposited without overflowing the totalSupply of shares.
     */
    function maxDeposit()
        external
        view
        override
        returns (IERC20[] memory, uint256[] memory)
    {
        return _convertToAssets(maxMint(), Math.Rounding.Down);
    }

    /**
     * @dev Returns the minimum amount of underlying assets that can be deposited into the Pool to get a share.
     */
    function minDeposit()
        external
        view
        override
        returns (IERC20[] memory, uint256[] memory)
    {
        uint256[] memory _minAmounts = new uint256[](assetAddresses.length);
        for (uint256 i = 0; i < assetAddresses.length; i++) {
            if (totalSupply() >= assetBalances[assetAddresses[i]]) {
                /* if total shares >= total assets, any assets amount will mint a share */
                _minAmounts[i] = 1;
            } else {
                /* if total assets > total shares, assets > total assets / total shares will mint a share */
                /* we add 1 if not perfectly divisible because the uint division will produce the floor */
                _minAmounts[i] =
                    assetBalances[assetAddresses[i]] /
                    totalSupply() +
                    (
                        assetBalances[assetAddresses[i]] % totalSupply() == 0
                            ? 0
                            : 1
                    );
            }
        }
        return (assetAddresses, _minAmounts);
    }

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * NOTE: if returned shares value > maxMint(), then the deposit will fail.
     */
    function previewDeposit(
        IERC20[] memory _assets,
        uint256[] memory _amounts
    ) external view override returns (uint256) {
        require(
            _assets.length == _amounts.length,
            "arrays must be of equal length"
        );

        require(
            _assets.length == assetAddresses.length,
            "all owned assets must be included"
        );

        require(assetAddresses.length > 0, "pool must be non-empty to preview");

        return _convertToShares(_assets, _amounts, Math.Rounding.Down);
    }

    /**
     * @dev Mints shares Pool shares to receiver by depositing exactly amount of underlying tokens.
     */
    function deposit(
        IERC20[] memory _assets,
        uint256[] memory _amounts,
        uint256 _shares,
        address _receiver
    ) external override onlyOwner {
        require(_shares <= maxMint(), "deposit more than max");
        if (assetAddresses.length == 0) {
            /* first deposit, add assets to the pool */
            for (uint256 i = 0; i < _assets.length; i++) {
                addAsset(_assets[i]);
            }
        }
        _deposit(_msgSender(), _receiver, _assets, _amounts, _shares);
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(
        address _caller,
        address _receiver,
        IERC20[] memory _assets,
        uint256[] memory _amounts,
        uint256 _shares
    ) internal nonReentrant {
        // If _asset is ERC777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the Pool, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth

        for (uint256 i = 0; i < _assets.length; i++) {
            SafeERC20.safeTransferFrom(
                _assets[i],
                _caller,
                address(this),
                _amounts[i]
            );
            SafeERC20.safeIncreaseAllowance(_assets[i], owner(), _amounts[i]);
            assetBalances[_assets[i]] += _amounts[i];
        }
        _mint(_receiver, _shares);

        emit Deposit(_caller, _receiver, _assets, _amounts, _shares);
    }

    /**
     * @dev Returns the maximum amount of Pool shares that can be redeemed from the owner balance in the Pool,
     * through a redeem call.
     */
    function maxRedeem(
        address _owner
    ) external view override returns (uint256) {
        return balanceOf(_owner);
    }

    /**
     * @dev Returns the minimum amount of shares that can be redeemed to the Pool to get at least 1 of each asset.
     */
    function minRedeem() external view override returns (uint256) {
        uint256 _minShares = 0;
        for (uint256 i = 0; i < assetAddresses.length; i++) {
            if (assetBalances[assetAddresses[i]] >= totalSupply()) {
                /* if total assets >= total shares, any shares amount will redeem an asset */
                if (_minShares < 1) {
                    _minShares = 1;
                }
            } else {
                /* if total shares > total assets, shares > total shares / total assets will redeem an asset */
                /* we add 1 if not perfectly divisible because the uint division will produce the floor */
                uint256 _minSharesForToken = totalSupply() /
                    assetBalances[assetAddresses[i]] +
                    (
                        totalSupply() % assetBalances[assetAddresses[i]] == 0
                            ? 0
                            : 1
                    );
                if (_minShares < _minSharesForToken) {
                    _minShares = _minSharesForToken;
                }
            }
        }
        return _minShares;
    }

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     */
    function previewRedeem(
        uint256 _shares
    ) external view override returns (IERC20[] memory, uint256[] memory) {
        require(
            _shares <= totalSupply(),
            "shares greater than available shares"
        );

        return _convertToAssets(_shares, Math.Rounding.Down);
    }

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     */
    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    ) external override returns (IERC20[] memory, uint256[] memory) {
        require(_shares <= balanceOf(_owner), "redeem more than max");

        (IERC20[] memory _assets, uint256[] memory _amounts) = _convertToAssets(
            _shares,
            Math.Rounding.Down
        );
        _withdraw(_msgSender(), _receiver, _owner, _assets, _amounts, _shares);

        return (_assets, _amounts);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address _caller,
        address _receiver,
        address _owner,
        IERC20[] memory _assets,
        uint256[] memory _amounts,
        uint256 _shares
    ) internal nonReentrant {
        if (_caller != _owner) {
            _spendAllowance(_owner, _caller, _shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the Pool, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(_owner, _shares);

        for (uint256 i = 0; i < _assets.length; i++) {
            SafeERC20.safeTransfer(_assets[i], _receiver, _amounts[i]);
            SafeERC20.safeDecreaseAllowance(_assets[i], owner(), _amounts[i]);
            assetBalances[_assets[i]] -= _amounts[i];
            if (assetBalances[_assets[i]] == 0) {
                removeAsset(_assets[i]);
            }
        }

        emit Withdraw(_caller, _receiver, _owner, _assets, _amounts, _shares);
    }

    /**
     * @dev Updates assets owned by the pool according owner's strategy.
     */
    function changeStrategy(
        IERC20[] calldata _assets,
        int256[] calldata _balanceDeltas
    ) external override onlyOwner {
        require(assetAddresses.length > 0, "pool is empty");
        require(
            _assets.length == _balanceDeltas.length,
            "arrays must be of equal length"
        );

        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 _absoluteBalanceDelta = abs(_balanceDeltas[i]);
            if (assetIsOwned(_assets[i])) {
                /* asset is already owned */
                if (_balanceDeltas[i] < 0) {
                    /* negative balance change */
                    assetBalances[_assets[i]] -= _absoluteBalanceDelta;
                    if (assetBalances[_assets[i]] == 0) {
                        /* new balance is 0, remove it from owned assets, and remove owner approval */
                        removeAsset(_assets[i]);
                        SafeERC20.safeApprove(_assets[i], owner(), 0);
                    } else {
                        /* new balance is non-zero, decrease allowance */
                        if (
                            _assets[i].allowance(address(this), owner()) ==
                            assetBalances[_assets[i]] + _absoluteBalanceDelta
                        ) {
                            /* TODO: decide if this check should be removed or not */
                            /* if contract has not spent allowance with owner's transferFrom call, decrease it */
                            /* transferFrom should have spent allowance, this might not be needed */
                            SafeERC20.safeDecreaseAllowance(
                                _assets[i],
                                owner(),
                                _absoluteBalanceDelta
                            );
                        }
                    }
                } else {
                    /* positive balance change, acquire balance change, and increase allowance */
                    assetBalances[_assets[i]] += uint256(_balanceDeltas[i]);
                    SafeERC20.safeTransferFrom(
                        _assets[i],
                        owner(),
                        address(this),
                        _absoluteBalanceDelta
                    );
                    SafeERC20.safeIncreaseAllowance(
                        _assets[i],
                        owner(),
                        _absoluteBalanceDelta
                    );
                }
            } else {
                require(
                    _balanceDeltas[i] > 0,
                    "can't add a asset with a negative or zero balance"
                );
                /* asset is new, add it to owned assets, acquire balance change, and approve allowance */
                addAsset(_assets[i]);
                assetBalances[_assets[i]] = _absoluteBalanceDelta;
                SafeERC20.safeTransferFrom(
                    _assets[i],
                    owner(),
                    address(this),
                    _absoluteBalanceDelta
                );
                SafeERC20.safeApprove(
                    _assets[i],
                    owner(),
                    _absoluteBalanceDelta
                );
            }
        }

        emit ChangeStrategy(_msgSender(), _assets, _balanceDeltas);
    }

    /**
     * @dev Adds a knowingly previously unowned asset.
     * NOTE: should NOT be called on an owned asset.
     */
    function addAsset(IERC20 _asset) private {
        assetAddresses.push(_asset);
        setAssetIndex(_asset, assetAddresses.length - 1);
    }

    /**
     * @dev Removes a knowingly owned asset.
     * NOTE: should NOT be called on an unowned asset.
     */
    function removeAsset(IERC20 _asset) private {
        uint256 _index = getAssetIndex(_asset);
        IERC20 _lastAsset = assetAddresses[assetAddresses.length - 1];

        assetAddresses[_index] = _lastAsset;
        assetAddresses.pop();

        setAssetIndex(_lastAsset, _index);

        delete _assetIndices[_asset];
    }

    /**
     * @dev Gets the actual index of the asset in "assets" array.
     */
    function getAssetIndex(IERC20 _asset) private view returns (uint256) {
        return _assetIndices[_asset] - 1;
    }

    /**
     * @dev Inserts an actual index of the asset in "assets" array into "_assetIndices" mapping.
     */
    function setAssetIndex(IERC20 _asset, uint256 _index) private {
        _assetIndices[_asset] = _index + 1;
    }

    /**
     * @dev Returns a bool indicating if the asset is currently owned by the strategy pool.
     */
    function assetIsOwned(IERC20 _asset) private view returns (bool) {
        return _assetIndices[_asset] != 0;
    }

    /**
     * @dev Returns the absolute uint256 representation of an int256.
     */
    function abs(int256 x) private pure returns (uint256) {
        return x >= 0 ? uint256(x) : uint256(-x);
    }
}
