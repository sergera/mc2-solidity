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

import {IStrategyPool} from "./IStrategyPool.sol";

/**
 * @dev Interface of the MC²Fi StrategyPoolFactory contract
 */
interface IStrategyPoolFactory {
    event CreatePool(address indexed sender, uint256 index, IStrategyPool indexed pool);

    /**
     * @dev Create a new Pool.
     *
     * - MUST emit the CreatePool event
     */
    function createPool(
        uint256 index,
        string memory name,
        string memory symbol
    ) external returns (IStrategyPool pool);

    /**
     * @dev Get Pool address by providing the Pool array index.
     */
    function getPool(uint256 index) external returns (IStrategyPool pool);

    /**
     * @dev Get all Pool addresses.
     */
    function getPools() external returns (IStrategyPool[] memory pools);
}
