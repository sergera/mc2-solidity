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
import "openzeppelin-contracts/contracts/access/Ownable.sol";

import "./IEscrow.sol";

/**
 * @dev MC²Fi Escrow contract
 *
 * - entry point for funds directed at a MC²Fi StrategyPool contract
 * - will immediately return native tokens that get sent to this contract
 */

contract Escrow is Ownable, IEscrow {
    /**
     * @dev Set owner, owner is solely responsible for transferring funds.
     */
    constructor(address _newOwner) {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfer funds to a recipient.
     */
    function transferTokenTo(
        IERC20 _token,
        address _recipient,
        uint256 _amount
    ) external override onlyOwner {
        _token.transfer(_recipient, _amount);
    }

    /**
     * @dev Return native tokens, if ever sent to this contract.
     */
    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}
