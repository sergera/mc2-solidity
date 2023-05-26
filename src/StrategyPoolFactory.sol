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

import "openzeppelin-contracts/contracts/access/Ownable.sol";

import "./IStrategyPool.sol";
import "./StrategyPool.sol";

import "./IStrategyPoolFactory.sol";

/**
 * @dev Factory contract for the MC²Fi StrategyPool contract
 *
 * - creates strategy pools
 * - keeps track of strategy pool trader EOA addresses
 * - keeps track of strategy pool addresses
 */
contract StrategyPoolFactory is Ownable, IStrategyPoolFactory {
    IStrategyPool[] public pools;

    /**
     * @dev Set owner, owner is solely responsible for creating new Pools.
     */
    constructor(address _newOwner) {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Create a new Pool.
     */
    function createPool(
        string memory _name,
        string memory _symbol
    ) external override onlyOwner returns (IStrategyPool) {
        StrategyPool newPool = new StrategyPool(_name, _symbol, owner());
        pools.push(newPool);

        emit CreatePool(_msgSender(), newPool);

        return newPool;
    }

    /**
     * @dev Get Pool address by providing the Pool array index.
     */
    function getPool(
        uint256 _index
    ) external view override returns (IStrategyPool) {
        return pools[_index];
    }

    /**
     * @dev Returns array of trader addresses that have Pools.
     */
    function getPools()
        external
        view
        override
        returns (IStrategyPool[] memory)
    {
        return pools;
    }
}
