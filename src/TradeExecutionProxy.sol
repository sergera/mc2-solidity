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
import "openzeppelin-contracts/contracts/proxy/Proxy.sol";

/**
 * @dev Proxy contract for the MC²Fi TradeExecution contract
 *
 * - variation on the Delegate Proxy pattern
 * - the proxy performs the calls itself and acts as the implementation to keep the address stable
 */
contract TradeExecutionProxy is Proxy, Ownable {
    address private implementation;

    constructor(address _initialImplementation) {
        implementation = _initialImplementation;
    }

    function _implementation() internal view override returns (address) {
        return implementation;
    }

    function upgradeImplementation(address newImplementation) public onlyOwner {
        implementation = newImplementation;
    }

    function _fallback() internal override onlyOwner {
        (bool success, ) = _implementation().call(msg.data);
        require(success, "call failed");
    }
}
