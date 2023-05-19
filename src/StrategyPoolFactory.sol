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

/**
 * @dev Factory contract for the MC²Fi StrategyPool contract
 *
 * - creates strategy pools
 * - keeps track of strategy pool trader EOA addresses
 * - keeps track of strategy pool addresses
 */
contract StrategyPoolFactory is Ownable {
    address public poolOwner;
    mapping(address => IStrategyPool) public traderToPool;
    address[] public traderAddresses;

    /**
     * @dev Set owner, owner is solely responsible for creating new Pools.
     */
    constructor(address _newOwner, address _poolOwner) {
        _transferOwnership(_newOwner);
        poolOwner = _poolOwner;
    }

    /**
     * @dev Create a new Pool.
     */
    function createPool(
        address _trader,
        string memory _name,
        string memory _symbol,
        uint256 _initialDepositShareValue
    ) external onlyOwner {
        require(
            traderToPool[_trader] == IStrategyPool(address(0)),
            "pool already exists for trader"
        );
        StrategyPool newPool = new StrategyPool(
            _name,
            _symbol,
            poolOwner,
            _initialDepositShareValue
        );
        traderToPool[_trader] = newPool;
        traderAddresses.push(_trader);
    }

    /**
     * @dev Get Pool address by providing the trader's EOA address.
     */
    function getPool(address _trader) external view returns (IStrategyPool) {
        return traderToPool[_trader];
    }
}
