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
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {IEscrow} from "./INewEscrow.sol";

/**
 * @dev MC²Fi Escrow contract
 */
contract Escrow is Ownable, Pausable, ReentrancyGuard, IEscrow {
    address[] public blacklistedAddresses;
    mapping(address => uint256) private __blacklistedIndices;

    mapping(address => IERC20[]) public assetAddressesByProprietor;
    mapping(address => mapping(IERC20 => uint256))
        public assetBalancesByProprietor;
    mapping(address => mapping(IERC20 => uint256))
        private __assetIndicesByProprietor;

    /**
     * @dev Set owner, owner has the ability to move assets.
     */
    constructor(address _newOwner) {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Returns array of owned assets by proprietor.
     */
    function assets(
        address _proprietor
    ) external view override returns (IERC20[] memory) {
        require(
            !_addressIsBlacklisted(_msgSender()),
            "Escrow: caller is blacklisted"
        );
        return assetAddressesByProprietor[_proprietor];
    }

    /**
     * @dev Returns the currently owned balance of a single asset by proprietor.
     */
    function assetBalance(
        address _proprietor,
        IERC20 _asset
    ) external view override returns (uint256) {
        require(
            !_addressIsBlacklisted(_msgSender()),
            "Escrow: caller is blacklisted"
        );
        return assetBalancesByProprietor[_proprietor][_asset];
    }

    /**
     * @dev Returns an array of owned assets, and an array of respective balances by proprietor.
     */
    function assetsAndBalances(
        address _proprietor
    ) external view override returns (IERC20[] memory, uint256[] memory) {
        require(
            !_addressIsBlacklisted(_msgSender()),
            "Escrow: caller is blacklisted"
        );
        uint256 _length = assetAddressesByProprietor[_proprietor].length;

        uint256[] memory _amounts = new uint256[](_length);
        for (uint256 i = 0; i < _length; i++) {
            _amounts[i] = assetBalancesByProprietor[_proprietor][
                assetAddressesByProprietor[_proprietor][i]
            ];
        }

        return (assetAddressesByProprietor[_proprietor], _amounts);
    }

    /**
     * @dev Transfers pre-approved asset amount to this contract and registers it to caller.
     */
    function deposit(
        IERC20 _asset,
        uint256 _amount
    ) external override nonReentrant whenNotPaused {
        require(_amount > 0, "Escrow: deposit 0 amount");
        require(
            !_addressIsBlacklisted(_msgSender()),
            "Escrow: caller is blacklisted"
        );
        if (!_assetIsOwned(_msgSender(), _asset)) {
            _addAsset(_msgSender(), _asset);
        }
        SafeERC20.safeTransferFrom(
            _asset,
            _msgSender(),
            address(this),
            _amount
        );
        assetBalancesByProprietor[_msgSender()][_asset] += _amount;

        emit Deposit(_msgSender(), _asset, _amount);
    }

    /**
     * @dev Allows previously deposited assets to be withdrawn by the caller.
     */
    function withdraw(
        IERC20 _asset,
        uint256 _amount
    ) external override nonReentrant {
        require(_amount > 0, "Escrow: withdraw 0 amount");
        require(
            assetBalancesByProprietor[_msgSender()][_asset] >= _amount,
            "Escrow: amount exceeds owned balance of caller"
        );
        require(
            !_addressIsBlacklisted(_msgSender()),
            "Escrow: caller is blacklisted"
        );
        SafeERC20.safeTransfer(_asset, _msgSender(), _amount);
        assetBalancesByProprietor[_msgSender()][_asset] -= _amount;
        if (assetBalancesByProprietor[_msgSender()][_asset] == 0) {
            _removeAsset(_msgSender(), _asset);
        }

        emit Withdraw(_msgSender(), _asset, _amount);
    }

    /**
     * @dev Owner of the contract transfers asset from proprietor to another address.
     */
    function transferAssetFrom(
        address _proprietor,
        address _recipient,
        IERC20 _asset,
        uint256 _amount
    ) external override onlyOwner nonReentrant {
        require(_amount > 0, "Escrow: transfer 0 amount of proprietor asset");
        require(
            _assetIsOwned(_proprietor, _asset),
            "Escrow: transfer asset not owned by proprietor"
        );
        require(
            assetBalancesByProprietor[_proprietor][_asset] >= _amount,
            "Escrow: transfer more than proprietor balance of asset"
        );
        SafeERC20.safeTransfer(_asset, _recipient, _amount);
        assetBalancesByProprietor[_proprietor][_asset] -= _amount;
        if (assetBalancesByProprietor[_proprietor][_asset] == 0) {
            _removeAsset(_proprietor, _asset);
        }

        emit TransferAssetFrom(_proprietor, _recipient, _asset, _amount);
    }

    /**
     * @dev Owner of the contract gives back deposit amount to proprietor and fee amount to fee recipient.
     */
    function rejectDeposit(
        address _proprietor,
        IERC20 _asset,
        uint256 _depositAmount,
        address _feeRecipient,
        uint256 _feeAmount
    ) external override onlyOwner nonReentrant {
        require(_depositAmount + _feeAmount > 0, "Escrow: reject 0 amount");
        require(
            _assetIsOwned(_proprietor, _asset),
            "Escrow: reject asset not owned by proprietor"
        );
        require(
            assetBalancesByProprietor[_proprietor][_asset] >=
                _depositAmount + _feeAmount,
            "Escrow: reject more than proprietor balance of asset"
        );
        if (_depositAmount > 0) {
            SafeERC20.safeTransfer(_asset, _proprietor, _depositAmount);
        }
        if (_feeAmount > 0) {
            SafeERC20.safeTransfer(_asset, _feeRecipient, _feeAmount);
        }
        assetBalancesByProprietor[_proprietor][_asset] -=
            _depositAmount +
            _feeAmount;
        if (assetBalancesByProprietor[_proprietor][_asset] == 0) {
            _removeAsset(_proprietor, _asset);
        }

        emit RejectDeposit(
            _proprietor,
            _asset,
            _depositAmount,
            _feeRecipient,
            _feeAmount
        );
    }

    /**
     * @dev Adds address to blacklisted addresses.
     */
    function addBlacklistedAccount(
        address _blacklisted
    ) external override onlyOwner {
        require(_blacklisted != address(0), "Escrow: blacklist 0 address");
        if (!_addressIsBlacklisted(_blacklisted)) {
            _addBlacklisted(_blacklisted);
        }

        emit AddBlacklistedAccount(_blacklisted);
    }

    /**
     * @dev Removes address from blacklisted addresses.
     */
    function removeBlacklistedAccount(
        address _blacklisted
    ) external override onlyOwner {
        require(_blacklisted != address(0), "Escrow: unblacklist 0 address");
        if (_addressIsBlacklisted(_blacklisted)) {
            _removeBlacklisted(_blacklisted);
        }

        emit RemoveBlacklistedAccount(_blacklisted);
    }

    /**
     * @dev Returns a bool indicating if the address is currently blacklisted.
     */
    function accountIsBlacklisted(
        address _blacklisted
    ) external view override onlyOwner returns (bool) {
        _addressIsBlacklisted(_blacklisted);
    }

    /**
     * @dev Returns a bool indicating if the asset is currently owned by the proprietor.
     */
    function _assetIsOwned(
        address _proprietor,
        IERC20 _asset
    ) private view returns (bool) {
        return __assetIndicesByProprietor[_proprietor][_asset] != 0;
    }

    /**
     * @dev Adds a knowingly previously unowned asset by proprietor.
     * NOTE: should NOT be called on an owned asset by proprietor.
     */
    function _addAsset(address _proprietor, IERC20 _asset) private {
        assetAddressesByProprietor[_proprietor].push(_asset);
        _setAssetIndex(
            _proprietor,
            _asset,
            assetAddressesByProprietor[_proprietor].length - 1
        );
    }

    /**
     * @dev Removes a knowingly owned asset by proprietor.
     * NOTE: should NOT be called on an unowned asset by proprietor.
     */
    function _removeAsset(address _proprietor, IERC20 _asset) private {
        uint256 _index = _getAssetIndex(_proprietor, _asset);
        IERC20 _lastAsset = assetAddressesByProprietor[_proprietor][
            assetAddressesByProprietor[_proprietor].length - 1
        ];

        assetAddressesByProprietor[_proprietor][_index] = _lastAsset;
        assetAddressesByProprietor[_proprietor].pop();

        _setAssetIndex(_proprietor, _lastAsset, _index);

        delete __assetIndicesByProprietor[_proprietor][_asset];
    }

    /**
     * @dev Inserts an shifted index of the asset in "assetAddressesByProprietor" array into "__assetIndicesByProprietor" mapping.
     */
    function _setAssetIndex(
        address _proprietor,
        IERC20 _asset,
        uint256 _index
    ) private {
        __assetIndicesByProprietor[_proprietor][_asset] = _index + 1;
    }

    /**
     * @dev Gets the actual index of the asset in "assetAddressesByProprietor" array.
     */
    function _getAssetIndex(
        address _proprietor,
        IERC20 _asset
    ) private view returns (uint256) {
        return __assetIndicesByProprietor[_proprietor][_asset] - 1;
    }

    /**
     * @dev Returns a bool indicating if the proprietor is blacklisted.
     */
    function _addressIsBlacklisted(
        address _blacklisted
    ) private view returns (bool) {
        return __blacklistedIndices[_blacklisted] != 0;
    }

    /**
     * @dev Adds a knowingly previously non-blacklisted address.
     * NOTE: should NOT be called on a blacklisted address.
     */
    function _addBlacklisted(address _blacklisted) private {
        blacklistedAddresses.push(_blacklisted);
        _setBlacklistedIndex(_blacklisted, blacklistedAddresses.length - 1);
    }

    /**
     * @dev Removes a knowingly previously blacklisted address.
     * NOTE: should NOT be called on a non-blacklisted address.
     */
    function _removeBlacklisted(address _blacklisted) private {
        uint256 _index = _getBlacklistedIndex(_blacklisted);
        address _lastBlacklisted = blacklistedAddresses[
            blacklistedAddresses.length - 1
        ];

        blacklistedAddresses[_index] = _lastBlacklisted;
        blacklistedAddresses.pop();

        _setBlacklistedIndex(_lastBlacklisted, _index);

        delete __blacklistedIndices[_blacklisted];
    }

    /**
     * @dev Inserts a shifted index of the blacklisted address in "blacklistedAddresses" array into "__blacklistedIndices" mapping.
     */
    function _setBlacklistedIndex(
        address _blacklisted,
        uint256 _index
    ) private {
        __blacklistedIndices[_blacklisted] = _index + 1;
    }

    /**
     * @dev Gets the actual index of the blacklisted address in "blacklistedAddresses" array.
     */
    function _getBlacklistedIndex(
        address _blacklisted
    ) private view returns (uint256) {
        return __blacklistedIndices[_blacklisted] - 1;
    }
}
