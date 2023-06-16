// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Test} from "forge-std/Test.sol";

contract Utils is Test {
    bytes32 internal _nextAccount = keccak256(abi.encodePacked("eoa address"));

    function getNextAccountAddress() external returns (address payable) {
        address payable _account = payable(
            address(uint160(uint256(_nextAccount)))
        );
        _nextAccount = keccak256(abi.encodePacked(_nextAccount));
        return _account;
    }

    // create EOAs with 100 ETH balance each
    function createAccounts(
        uint256 _accountNum
    ) external returns (address payable[] memory) {
        address payable[] memory _accounts = new address payable[](_accountNum);
        for (uint256 i = 0; i < _accountNum; i++) {
            address payable _account = this.getNextAccountAddress();
            vm.deal(_account, 100 ether);
            _accounts[i] = _account;
        }

        return _accounts;
    }

    // create EOA with 100 ETH balance
    function createAccount() external returns (address payable) {
        address payable _account = this.getNextAccountAddress();
        vm.deal(_account, 100 ether);
        return _account;
    }

    // move block.number forward by a given number of blocks
    function mineBlocks(uint256 _numBlocks) external {
        uint256 _targetBlock = block.number + _numBlocks;
        vm.roll(_targetBlock);
    }
}
