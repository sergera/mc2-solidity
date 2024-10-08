// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, stdStorage, StdStorage} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {console} from "forge-std/console.sol";

import {StrategyWallet} from "../src/StrategyWallet.sol";
import {StrategyWalletHerald} from "../src/StrategyWalletHerald.sol";
import {StrategyPool} from "../src/StrategyPool.sol";
import {StrategyPoolHerald} from "../src/StrategyPoolHerald.sol";
import {MockToken} from "./MockToken.sol";
import {Utils} from "./Utils.sol";

contract StrategyWalletTestBasic is Test {
    using stdStorage for StdStorage;
    using Math for uint256;

    Utils public utils;
    address public backer;
    address public admin;
    address public alice;
    address public bob;

    StrategyPool public strategyPool;
    StrategyPoolHerald public poolHerald;
    MockToken public mockToken;
    StrategyWallet public strategyWallet;
    StrategyWalletHerald public walletHerald;

    function setUp() public {
        utils = new Utils();
        backer = utils.createAccount();
        admin = utils.createAccount();
        alice = utils.createAccount();
        bob = utils.createAccount();

        walletHerald = new StrategyWalletHerald();
        strategyWallet = new StrategyWallet(backer, admin, walletHerald);

        mockToken = new MockToken();
        poolHerald = new StrategyPoolHerald();
        strategyPool = new StrategyPool(
            "Share",
            "SHARE",
            address(this),
            poolHerald
        );
        mockToken.mint(address(this), 100);

        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100,
            address(strategyWallet)
        );
    }

    function test_constructor() public {
        assertEq(strategyWallet.backer(), backer);
        assertEq(strategyWallet.admin(), admin);
    }

    function test_transferBackership() public {
        // only backer can transfer backer
        assertEq(strategyWallet.backer(), backer);
        vm.prank(backer);
        strategyWallet.transferBackership(alice);
        assertEq(strategyWallet.backer(), alice);

        // reset
        vm.prank(alice);
        strategyWallet.transferBackership(backer);
        assertEq(strategyWallet.backer(), backer);

        // admin cannot transfer backer
        vm.prank(admin);
        vm.expectRevert("StrategyWallet: caller is not the backer");
        strategyWallet.transferBackership(alice);
        assertEq(strategyWallet.backer(), backer);

        // someone else cannot transfer backer
        vm.prank(alice);
        vm.expectRevert("StrategyWallet: caller is not the backer");
        strategyWallet.transferBackership(bob);
        assertEq(strategyWallet.backer(), backer);
    }

    function test_transferAdminship() public {
        // admin can transfer admin
        vm.prank(admin);
        strategyWallet.transferAdminship(alice);
        assertEq(strategyWallet.admin(), alice);

        // reset
        vm.prank(alice);
        strategyWallet.transferAdminship(admin);
        assertEq(strategyWallet.admin(), admin);

        // backer cannot transfer admin
        assertEq(strategyWallet.admin(), admin);
        vm.prank(backer);
        vm.expectRevert("StrategyWallet: caller is not the admin");
        strategyWallet.transferAdminship(alice);

        // someone else cannot transfer admin
        vm.prank(alice);
        vm.expectRevert("StrategyWallet: caller is not the admin");
        strategyWallet.transferAdminship(bob);
        assertEq(strategyWallet.admin(), admin);
    }

    function test_revokeAdminshipAsAdmin() public {
        // backer can revoke admin
        vm.prank(admin);
        strategyWallet.revokeAdminship();
        assertEq(strategyWallet.admin(), address(0));
    }

    function test_revokeAdminshipAsBacker() public {
        // backer can revoke admin
        vm.prank(backer);
        strategyWallet.revokeAdminship();
        assertEq(strategyWallet.admin(), address(0));
    }

    function test_revokeAdminshipAsBackerEmitsRevokeInHerald() public {
        vm.recordLogs();
        vm.prank(backer);
        strategyWallet.revokeAdminship();
        assertEq(strategyWallet.admin(), address(0));

        VmSafe.Log[] memory logEntries = vm.getRecordedLogs();

        assertEq(logEntries.length, 2);
        /* strategy wallet AdminshipTransferred event */
        assertEq(
            logEntries[0].topics[0],
            keccak256("AdminshipTransferred(address,address,address)")
        );
        assertEq(
            address(uint160(uint256(logEntries[0].topics[1]))),
            address(backer)
        );
        assertEq(
            address(uint160(uint256(logEntries[0].topics[2]))),
            address(admin)
        );
        assertEq(
            address(uint160(uint256(logEntries[0].topics[3]))),
            address(0)
        );
        /* strategy wallet herald RevokeAdminship event */
        assertEq(
            logEntries[1].topics[0],
            keccak256("RevokeAdminship(address,address)")
        );
        assertEq(
            address(uint160(uint256(logEntries[1].topics[1]))),
            address(strategyWallet)
        );
        assertEq(
            address(uint160(uint256(logEntries[1].topics[2]))),
            address(admin)
        );
    }

    function test_revokeAdminshipAsAdminDoesNotEmitRevokeInHerald() public {
        vm.recordLogs();
        vm.prank(admin);
        strategyWallet.revokeAdminship();
        assertEq(strategyWallet.admin(), address(0));

        VmSafe.Log[] memory logEntries = vm.getRecordedLogs();

        assertEq(logEntries.length, 1);
        /* strategy wallet AdminshipTransferred event */
        assertEq(
            logEntries[0].topics[0],
            keccak256("AdminshipTransferred(address,address,address)")
        );
        assertEq(
            address(uint160(uint256(logEntries[0].topics[1]))),
            address(admin)
        );
        assertEq(
            address(uint160(uint256(logEntries[0].topics[2]))),
            address(admin)
        );
        assertEq(
            address(uint160(uint256(logEntries[0].topics[3]))),
            address(0)
        );
    }

    function test_redeemFromStrategy() public {
        assertEq(strategyPool.balanceOf(address(strategyWallet)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);
        assertEq(mockToken.balanceOf(backer), 0);

        // backer can redeem
        vm.prank(backer);
        strategyWallet.redeemFromStrategy(strategyPool, 10);
        assertEq(strategyPool.balanceOf(address(strategyWallet)), 90);

        // admin can redeem for backer
        vm.prank(admin);
        strategyWallet.redeemFromStrategy(strategyPool, 10);
        assertEq(strategyPool.balanceOf(address(strategyWallet)), 80);

        // someone else cannot redeem
        vm.prank(alice);
        vm.expectRevert(
            "StrategyWallet: caller is not the backer nor the admin"
        );
        strategyWallet.redeemFromStrategy(strategyPool, 10);
    }

    function test_redeemFromStrategyAsBackerEmitsRedeemEventInStrategyPoolHerald()
        public
    {
        assertEq(strategyPool.balanceOf(address(strategyWallet)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);
        assertEq(mockToken.balanceOf(backer), 0);

        vm.recordLogs();
        vm.prank(backer);
        strategyWallet.redeemFromStrategy(strategyPool, 10);
        assertEq(strategyPool.balanceOf(address(strategyWallet)), 90);

        VmSafe.Log[] memory logEntries = vm.getRecordedLogs();
        assertEq(logEntries.length, 4);
        /* ERC20 burn Transfer event */
        assertEq(
            logEntries[0].topics[0],
            keccak256("Transfer(address,address,uint256)")
        );
        assertEq(
            address(uint160(uint256(logEntries[0].topics[1]))),
            address(strategyWallet)
        );
        assertEq(
            address(uint160(uint256(logEntries[0].topics[2]))),
            address(0)
        );
        assertEq(abi.decode(logEntries[0].data, (uint256)), uint256(10));
        /* strategy pool redeem event */
        assertEq(
            logEntries[1].topics[0],
            keccak256("Redeem(address,address,uint256)")
        );
        assertEq(
            address(uint160(uint256(logEntries[1].topics[1]))),
            address(strategyWallet)
        );
        assertEq(
            address(uint160(uint256(logEntries[1].topics[2]))),
            address(strategyWallet)
        );
        assertEq(abi.decode(logEntries[1].data, (uint256)), uint256(10));
        /* strategy pool herald redeem event */
        assertEq(
            logEntries[2].topics[0],
            keccak256("Redeem(address,address,address,uint256)")
        );
        assertEq(
            address(uint160(uint256(logEntries[2].topics[1]))),
            address(strategyPool)
        );
        assertEq(
            address(uint160(uint256(logEntries[2].topics[2]))),
            address(strategyWallet)
        );
        assertEq(
            address(uint160(uint256(logEntries[2].topics[3]))),
            address(backer)
        );
        assertEq(abi.decode(logEntries[2].data, (uint256)), uint256(10));
        /* strategy wallet redeem from strategy event */
        assertEq(
            logEntries[3].topics[0],
            keccak256("RedeemedFromStrategy(address,address,address,uint256)")
        );
        assertEq(
            address(uint160(uint256(logEntries[3].topics[1]))),
            address(backer)
        );
        assertEq(
            address(uint160(uint256(logEntries[3].topics[2]))),
            address(strategyPool)
        );
        assertEq(
            address(uint160(uint256(logEntries[3].topics[3]))),
            address(backer)
        );
        assertEq(abi.decode(logEntries[3].data, (uint256)), uint256(10));
    }

    function test_redeemFromStrategyAsAdminDoesNotEmitRedeemEventInStrategyPoolHerald()
        public
    {
        assertEq(strategyPool.balanceOf(address(strategyWallet)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);
        assertEq(mockToken.balanceOf(backer), 0);

        vm.recordLogs();
        vm.prank(admin);
        strategyWallet.redeemFromStrategy(strategyPool, 10);
        assertEq(strategyPool.balanceOf(address(strategyWallet)), 90);

        VmSafe.Log[] memory logEntries = vm.getRecordedLogs();
        assertEq(logEntries.length, 3);
        /* ERC20 burn Transfer event */
        assertEq(
            logEntries[0].topics[0],
            keccak256("Transfer(address,address,uint256)")
        );
        assertEq(
            address(uint160(uint256(logEntries[0].topics[1]))),
            address(strategyWallet)
        );
        assertEq(
            address(uint160(uint256(logEntries[0].topics[2]))),
            address(0)
        );
        assertEq(abi.decode(logEntries[0].data, (uint256)), uint256(10));
        /* strategy pool redeem event */
        assertEq(
            logEntries[1].topics[0],
            keccak256("Redeem(address,address,uint256)")
        );
        assertEq(
            address(uint160(uint256(logEntries[1].topics[1]))),
            address(strategyWallet)
        );
        assertEq(
            address(uint160(uint256(logEntries[1].topics[2]))),
            address(strategyWallet)
        );
        assertEq(abi.decode(logEntries[1].data, (uint256)), uint256(10));
        /* strategy wallet redeem from strategy event */
        assertEq(
            logEntries[2].topics[0],
            keccak256("RedeemedFromStrategy(address,address,address,uint256)")
        );
        assertEq(
            address(uint160(uint256(logEntries[2].topics[1]))),
            address(admin)
        );
        assertEq(
            address(uint160(uint256(logEntries[2].topics[2]))),
            address(strategyPool)
        );
        assertEq(
            address(uint160(uint256(logEntries[2].topics[3]))),
            address(backer)
        );
        assertEq(abi.decode(logEntries[2].data, (uint256)), uint256(10));
    }

    function test_fullRedeemFromStrategyAsBacker() public {
        assertEq(strategyPool.balanceOf(address(strategyWallet)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);

        vm.prank(backer);
        strategyWallet.fullRedeemFromStrategy(strategyPool);

        assertEq(strategyPool.balanceOf(address(strategyWallet)), 0);
        assertEq(strategyPool.assetBalance(mockToken), 100);
    }

    function test_fullRedeemFromStrategyAsAdmin() public {
        assertEq(strategyPool.balanceOf(address(strategyWallet)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);

        vm.prank(admin);
        strategyWallet.fullRedeemFromStrategy(strategyPool);

        assertEq(strategyPool.balanceOf(address(strategyWallet)), 0);
        assertEq(strategyPool.assetBalance(mockToken), 100);
    }

    function test_fullRedeemFromStrategyAsBackerEmitsRedeemEventInStrategyPoolHerald()
        public
    {
        assertEq(strategyPool.balanceOf(address(strategyWallet)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);
        assertEq(mockToken.balanceOf(backer), 0);

        vm.recordLogs();
        vm.prank(backer);
        strategyWallet.fullRedeemFromStrategy(strategyPool);
        assertEq(strategyPool.balanceOf(address(strategyWallet)), 0);

        VmSafe.Log[] memory logEntries = vm.getRecordedLogs();
        assertEq(logEntries.length, 4);
        /* ERC20 burn Transfer event */
        assertEq(
            logEntries[0].topics[0],
            keccak256("Transfer(address,address,uint256)")
        );
        assertEq(
            address(uint160(uint256(logEntries[0].topics[1]))),
            address(strategyWallet)
        );
        assertEq(
            address(uint160(uint256(logEntries[0].topics[2]))),
            address(0)
        );
        assertEq(abi.decode(logEntries[0].data, (uint256)), uint256(100));
        /* strategy pool redeem event */
        assertEq(
            logEntries[1].topics[0],
            keccak256("Redeem(address,address,uint256)")
        );
        assertEq(
            address(uint160(uint256(logEntries[1].topics[1]))),
            address(strategyWallet)
        );
        assertEq(
            address(uint160(uint256(logEntries[1].topics[2]))),
            address(strategyWallet)
        );
        assertEq(abi.decode(logEntries[1].data, (uint256)), uint256(100));
        /* strategy pool herald redeem event */
        assertEq(
            logEntries[2].topics[0],
            keccak256("Redeem(address,address,address,uint256)")
        );
        assertEq(
            address(uint160(uint256(logEntries[2].topics[1]))),
            address(strategyPool)
        );
        assertEq(
            address(uint160(uint256(logEntries[2].topics[2]))),
            address(strategyWallet)
        );
        assertEq(
            address(uint160(uint256(logEntries[2].topics[3]))),
            address(backer)
        );
        assertEq(abi.decode(logEntries[2].data, (uint256)), uint256(100));
        /* strategy wallet redeem from strategy event */
        assertEq(
            logEntries[3].topics[0],
            keccak256("RedeemedFromStrategy(address,address,address,uint256)")
        );
        assertEq(
            address(uint160(uint256(logEntries[3].topics[1]))),
            address(backer)
        );
        assertEq(
            address(uint160(uint256(logEntries[3].topics[2]))),
            address(strategyPool)
        );
        assertEq(
            address(uint160(uint256(logEntries[3].topics[3]))),
            address(backer)
        );
        assertEq(abi.decode(logEntries[3].data, (uint256)), uint256(100));
    }

    function test_fullRedeemFromStrategyAsAdminDoesNotEmitRedeemEventInStrategyPoolHerald()
        public
    {
        assertEq(strategyPool.balanceOf(address(strategyWallet)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);
        assertEq(mockToken.balanceOf(backer), 0);

        vm.recordLogs();
        vm.prank(admin);
        strategyWallet.fullRedeemFromStrategy(strategyPool);
        assertEq(strategyPool.balanceOf(address(strategyWallet)), 0);

        VmSafe.Log[] memory logEntries = vm.getRecordedLogs();
        assertEq(logEntries.length, 3);
        /* ERC20 burn Transfer event */
        assertEq(
            logEntries[0].topics[0],
            keccak256("Transfer(address,address,uint256)")
        );
        assertEq(
            address(uint160(uint256(logEntries[0].topics[1]))),
            address(strategyWallet)
        );
        assertEq(
            address(uint160(uint256(logEntries[0].topics[2]))),
            address(0)
        );
        assertEq(abi.decode(logEntries[0].data, (uint256)), uint256(100));
        /* strategy pool redeem event */
        assertEq(
            logEntries[1].topics[0],
            keccak256("Redeem(address,address,uint256)")
        );
        assertEq(
            address(uint160(uint256(logEntries[1].topics[1]))),
            address(strategyWallet)
        );
        assertEq(
            address(uint160(uint256(logEntries[1].topics[2]))),
            address(strategyWallet)
        );
        assertEq(abi.decode(logEntries[1].data, (uint256)), uint256(100));
        /* strategy wallet redeem from strategy event */
        assertEq(
            logEntries[2].topics[0],
            keccak256("RedeemedFromStrategy(address,address,address,uint256)")
        );
        assertEq(
            address(uint160(uint256(logEntries[2].topics[1]))),
            address(admin)
        );
        assertEq(
            address(uint160(uint256(logEntries[2].topics[2]))),
            address(strategyPool)
        );
        assertEq(
            address(uint160(uint256(logEntries[2].topics[3]))),
            address(backer)
        );
        assertEq(abi.decode(logEntries[2].data, (uint256)), uint256(100));
    }
}
