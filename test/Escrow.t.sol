// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, stdStorage, StdStorage} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {console} from "forge-std/console.sol";

import {Escrow} from "../src/NewEscrow.sol";
import {MockToken} from "./MockToken.sol";
import {Utils} from "./Utils.sol";

contract EscrowTestBasic is Test {
    using stdStorage for StdStorage;
    using Math for uint256;

    Escrow public escrow;
    MockToken public mockToken;

    Utils public utils;
    address public alice;
    address public bob;

    function setUp() public {
        utils = new Utils();
        alice = utils.createAccount();
        bob = utils.createAccount();

        mockToken = new MockToken();
        escrow = new Escrow(address(this));
    }

    function test_Assets() public {
        IERC20[] memory initialAssets = escrow.assets(address(this));
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.transfer(address(escrow), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        escrow.acceptDeposit(address(this), newAssets[0], newAmounts[0]);

        IERC20[] memory afterAssets = escrow.assets(address(this));

        assertEq(afterAssets.length, 1);
        assertEq(address(afterAssets[0]), address(mockToken));
    }

    function test_AssetBalance() public {
        IERC20[] memory initialAssets = escrow.assets(address(this));
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.transfer(address(escrow), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        escrow.acceptDeposit(address(this), newAssets[0], newAmounts[0]);

        uint256 afterBalance = escrow.assetBalance(address(this), mockToken);
        assertEq(afterBalance, 100);
    }

    function test_AssetsAndBalances() public {
        IERC20[] memory initialAssets = escrow.assets(address(this));
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(escrow), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        escrow.acceptDeposit(address(this), newAssets[0], newAmounts[0]);

        (IERC20[] memory afterAssets, uint256[] memory afterBalances) = escrow
            .assetsAndBalances(address(this));

        assertEq(afterAssets.length, 1);
        assertEq(address(afterAssets[0]), address(mockToken));
        assertEq(afterBalances.length, 1);
        assertEq(afterBalances[0], 100);
    }

    function test_AcceptDeposit() public {
        IERC20[] memory initialAssets = escrow.assets(address(this));
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.transfer(address(escrow), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        escrow.acceptDeposit(address(this), newAssets[0], newAmounts[0]);

        (IERC20[] memory afterAssets, uint256[] memory afterBalances) = escrow
            .assetsAndBalances(address(this));

        assertEq(afterAssets.length, 1);
        assertEq(address(afterAssets[0]), address(mockToken));
        assertEq(afterBalances.length, 1);
        assertEq(afterBalances[0], 100);
        assertEq(mockToken.balanceOf(address(escrow)), 100);
    }

    function test_Withdraw() public {
        IERC20[] memory assets = escrow.assets(address(this));
        assertEq(assets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.transfer(address(escrow), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newBalances = new uint256[](1);
        newBalances[0] = 100;

        escrow.acceptDeposit(address(this), newAssets[0], newBalances[0]);
        escrow.withdraw(newAssets[0], newBalances[0]);

        (IERC20[] memory afterAssets, uint256[] memory afterBalances) = escrow
            .assetsAndBalances(address(this));

        assertEq(afterAssets.length, 0);
        assertEq(afterBalances.length, 0);
        assertEq(mockToken.balanceOf(address(escrow)), 0);
        assertEq(escrow.assets(address(this)).length, 0);
    }

    function test_TransferAssetFrom() public {
        IERC20[] memory initialAssets = escrow.assets(address(alice));
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(alice), 100);
        vm.prank(alice);
        mockToken.transfer(address(escrow), 100);

        assertEq(mockToken.balanceOf(address(alice)), 0);
        assertEq(mockToken.balanceOf(address(escrow)), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        escrow.acceptDeposit(address(alice), newAssets[0], newAmounts[0]);

        assertEq(mockToken.balanceOf(address(escrow)), 100);
        assertEq(escrow.assetBalance(address(alice), mockToken), 100);
        assertEq(escrow.assets(address(alice)).length, 1);
        assertEq(mockToken.balanceOf(address(alice)), 0);

        address[] memory proprietors = new address[](1);
        proprietors[0] = address(alice);

        escrow.transferAssetFrom(
            address(bob),
            newAssets[0],
            proprietors,
            newAmounts
        );

        assertEq(escrow.assetBalance(address(alice), mockToken), 0);
        assertEq(mockToken.balanceOf(address(escrow)), 0);
        assertEq(mockToken.balanceOf(address(bob)), 100);
    }

    function test_RejectDeposit() public {
        IERC20[] memory initialAssets = escrow.assets(address(alice));
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(alice), 100);

        assertEq(mockToken.balanceOf(address(alice)), 100);
        assertEq(mockToken.balanceOf(address(escrow)), 0);

        vm.prank(alice);
        mockToken.transfer(address(escrow), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        assertEq(mockToken.balanceOf(address(alice)), 0);
        assertEq(mockToken.balanceOf(address(escrow)), 100);

        escrow.rejectDeposit(alice, newAssets[0], 60, address(this), 40);

        assertEq(mockToken.balanceOf(address(this)), 40);
        assertEq(mockToken.balanceOf(address(alice)), 60);
        assertEq(mockToken.balanceOf(address(escrow)), 0);

        assertEq(escrow.assets(address(alice)).length, 0);

        (IERC20[] memory afterAssets, uint256[] memory afterBalances) = escrow
            .assetsAndBalances(address(alice));

        assertEq(afterAssets.length, 0);
        assertEq(afterBalances.length, 0);
        assertEq(escrow.assetBalance(address(alice), mockToken), 0);
    }

    function test_RefundAssets() public {
        IERC20[] memory initialAssets = escrow.assets(address(alice));
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(alice), 100);
        vm.prank(alice);
        mockToken.transfer(address(escrow), 100);

        assertEq(mockToken.balanceOf(address(alice)), 0);
        assertEq(mockToken.balanceOf(address(escrow)), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        escrow.acceptDeposit(address(alice), newAssets[0], newAmounts[0]);

        assertEq(mockToken.balanceOf(address(escrow)), 100);
        assertEq(escrow.assetBalance(address(alice), mockToken), 100);
        assertEq(escrow.assets(address(alice)).length, 1);
        assertEq(mockToken.balanceOf(address(alice)), 0);

        address[] memory proprietors = new address[](1);
        proprietors[0] = address(alice);

        escrow.refundAssets(proprietors, newAssets, newAmounts);

        assertEq(escrow.assetBalance(address(alice), mockToken), 0);
        assertEq(mockToken.balanceOf(address(escrow)), 0);
        assertEq(mockToken.balanceOf(address(alice)), 100);
    }

    function test_RescueAssets() public {
        IERC20[] memory initialAssets = escrow.assets(address(alice));
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(alice), 100);
        vm.prank(alice);
        mockToken.transfer(address(escrow), 100);

        assertEq(mockToken.balanceOf(address(alice)), 0);
        assertEq(mockToken.balanceOf(address(escrow)), 100);
        assertEq(mockToken.balanceOf(address(this)), 0);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        escrow.rescueAssets(address(this), newAssets, newAmounts);

        assertEq(escrow.assetBalance(address(alice), mockToken), 0);
        assertEq(mockToken.balanceOf(address(escrow)), 0);
        assertEq(mockToken.balanceOf(address(this)), 100);
    }
}

contract EscrowTestAcceptDeposit is Test {
    using stdStorage for StdStorage;
    using Math for uint256;

    Escrow public escrow;
    MockToken public mockToken;
    MockToken public mockToken2;

    Utils public utils;
    address public alice;
    address public bob;

    function setUp() public {
        utils = new Utils();
        alice = utils.createAccount();
        bob = utils.createAccount();

        mockToken = new MockToken();
        escrow = new Escrow(address(this));
        mockToken = new MockToken();
        mockToken2 = new MockToken();
    }

    function test_ZeroAcceptDepositReverts() public {
        IERC20[] memory initialAssets = escrow.assets(address(this));
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.transfer(address(escrow), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 0;

        vm.expectRevert("Escrow: accept 0 deposit amount");
        escrow.acceptDeposit(address(this), newAssets[0], newAmounts[0]);
    }

    function test_AcceptDepositAddsToken() public {
        IERC20[] memory initialAssets = escrow.assets(address(this));
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.transfer(address(escrow), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        escrow.acceptDeposit(address(this), newAssets[0], newAmounts[0]);

        assertEq(escrow.assets(address(this)).length, 1);
        assertEq(address(escrow.assets(address(this))[0]), address(mockToken));
        assertEq(escrow.assetBalance(address(this), mockToken), 100);

        assertEq(escrow.assets(address(alice)).length, 0);
        assertEq(escrow.assetBalance(address(alice), mockToken), 0);

        (IERC20[] memory afterAssets, uint256[] memory afterBalances) = escrow
            .assetsAndBalances(address(this));
        assertEq(afterAssets.length, 1);
        assertEq(address(afterAssets[0]), address(mockToken));
        assertEq(afterBalances.length, 1);
        assertEq(afterBalances[0], 100);
    }

    function test_AcceptDepositAddsTokens() public {
        IERC20[] memory initialAssets = escrow.assets(address(this));
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.transfer(address(escrow), 100);
        mockToken2.mint(address(this), 300);
        mockToken2.transfer(address(escrow), 300);

        IERC20[] memory newAssets = new IERC20[](2);
        newAssets[0] = mockToken;
        newAssets[1] = mockToken2;

        uint256[] memory newAmounts = new uint256[](2);
        newAmounts[0] = 100;
        newAmounts[1] = 300;

        escrow.acceptDeposit(address(this), newAssets[0], newAmounts[0]);
        escrow.acceptDeposit(address(this), newAssets[1], newAmounts[1]);

        assertEq(escrow.assets(address(this)).length, 2);
        assertEq(address(escrow.assets(address(this))[0]), address(mockToken));
        assertEq(address(escrow.assets(address(this))[1]), address(mockToken2));
        assertEq(escrow.assetBalance(address(this), mockToken), 100);
        assertEq(escrow.assetBalance(address(this), mockToken2), 300);

        assertEq(escrow.assets(address(alice)).length, 0);
        assertEq(escrow.assetBalance(address(alice), mockToken), 0);
        assertEq(escrow.assetBalance(address(alice), mockToken2), 0);

        (IERC20[] memory afterAssets, uint256[] memory afterBalances) = escrow
            .assetsAndBalances(address(this));
        assertEq(afterAssets.length, 2);
        assertEq(address(afterAssets[0]), address(mockToken));
        assertEq(address(afterAssets[1]), address(mockToken2));
        assertEq(afterBalances.length, 2);
        assertEq(afterBalances[0], 100);
        assertEq(afterBalances[1], 300);
    }
}

contract EscrowTestWithdraw is Test {
    using stdStorage for StdStorage;
    using Math for uint256;

    Escrow public escrow;
    MockToken public mockToken;
    MockToken public mockToken2;

    Utils public utils;
    address public alice;
    address public bob;

    function setUp() public {
        utils = new Utils();
        alice = utils.createAccount();
        bob = utils.createAccount();

        mockToken = new MockToken();
        escrow = new Escrow(address(this));
        mockToken = new MockToken();
        mockToken2 = new MockToken();
    }

    function test_WithdrawTransfersTokens() public {
        IERC20[] memory initialAssets = escrow.assets(address(this));
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.transfer(address(escrow), 100);

        assertEq(mockToken.balanceOf(address(this)), 0);
        assertEq(mockToken.balanceOf(address(escrow)), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        escrow.acceptDeposit(address(this), newAssets[0], newAmounts[0]);

        assertEq(mockToken.balanceOf(address(this)), 0);
        assertEq(mockToken.balanceOf(address(escrow)), 100);

        escrow.withdraw(newAssets[0], newAmounts[0]);

        assertEq(mockToken.balanceOf(address(this)), 100);
        assertEq(mockToken.balanceOf(address(escrow)), 0);
    }

    function test_WithdrawRemovesToken() public {
        IERC20[] memory initialAssets = escrow.assets(address(this));
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.transfer(address(escrow), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        escrow.acceptDeposit(address(this), newAssets[0], newAmounts[0]);

        assertEq(escrow.assets(address(this)).length, 1);
        (IERC20[] memory assetsBefore, uint256[] memory balancesBefore) = escrow
            .assetsAndBalances(address(this));
        assertEq(assetsBefore.length, 1);
        assertEq(balancesBefore.length, 1);
        assertEq(address(assetsBefore[0]), address(mockToken));
        assertEq(balancesBefore[0], 100);

        escrow.withdraw(newAssets[0], newAmounts[0]);

        assertEq(escrow.assets(address(this)).length, 0);
        (IERC20[] memory assetsAfter, uint256[] memory balancesAfter) = escrow
            .assetsAndBalances(address(this));
        assertEq(assetsAfter.length, 0);
        assertEq(balancesAfter.length, 0);
    }

    function test_WithdrawRemovesTokens() public {
        IERC20[] memory initialAssets = escrow.assets(address(this));
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.transfer(address(escrow), 100);
        mockToken2.mint(address(this), 300);
        mockToken2.transfer(address(escrow), 300);

        IERC20[] memory newAssets = new IERC20[](2);
        newAssets[0] = mockToken;
        newAssets[1] = mockToken2;

        uint256[] memory newAmounts = new uint256[](2);
        newAmounts[0] = 100;
        newAmounts[1] = 300;

        escrow.acceptDeposit(address(this), newAssets[0], newAmounts[0]);
        escrow.acceptDeposit(address(this), newAssets[1], newAmounts[1]);

        assertEq(escrow.assets(address(this)).length, 2);
        (IERC20[] memory assetsBefore, uint256[] memory balancesBefore) = escrow
            .assetsAndBalances(address(this));
        assertEq(assetsBefore.length, 2);
        assertEq(balancesBefore.length, 2);
        assertEq(address(assetsBefore[0]), address(mockToken));
        assertEq(address(assetsBefore[1]), address(mockToken2));
        assertEq(balancesBefore[0], 100);
        assertEq(balancesBefore[1], 300);

        escrow.withdraw(newAssets[0], newAmounts[0]);
        escrow.withdraw(newAssets[1], newAmounts[1]);

        assertEq(escrow.assets(address(this)).length, 0);
        (IERC20[] memory assetsAfter, uint256[] memory balancesAfter) = escrow
            .assetsAndBalances(address(this));
        assertEq(assetsAfter.length, 0);
        assertEq(balancesAfter.length, 0);
    }

    function test_UserCannotWithdrawFromAnotherUser() public {
        IERC20[] memory initialAssets = escrow.assets(address(this));
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.transfer(address(escrow), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        escrow.acceptDeposit(address(this), newAssets[0], newAmounts[0]);

        assertEq(escrow.assets(address(this)).length, 1);
        (IERC20[] memory assetsAfter, uint256[] memory balancesAfter) = escrow
            .assetsAndBalances(address(this));
        assertEq(assetsAfter.length, 1);
        assertEq(balancesAfter.length, 1);
        assertEq(address(assetsAfter[0]), address(mockToken));
        assertEq(balancesAfter[0], 100);

        mockToken.mint(alice, 300);
        vm.prank(alice);
        mockToken.transfer(address(escrow), 300);
        escrow.acceptDeposit(address(alice), newAssets[0], 300);

        vm.expectRevert("Escrow: amount exceeds owned balance of caller");
        escrow.withdraw(newAssets[0], 300);

        assertEq(escrow.assets(address(alice)).length, 1);
        (
            IERC20[] memory assetsAfterAlice,
            uint256[] memory balancesAfterAlice
        ) = escrow.assetsAndBalances(address(alice));
        assertEq(assetsAfterAlice.length, 1);
        assertEq(balancesAfterAlice.length, 1);
        assertEq(address(assetsAfterAlice[0]), address(mockToken));
        assertEq(balancesAfterAlice[0], 300);

        escrow.withdraw(newAssets[0], newAmounts[0]);

        assertEq(escrow.assets(address(this)).length, 0);
        (
            IERC20[] memory assetsAfterWithdraw,
            uint256[] memory balancesAfterWithdraw
        ) = escrow.assetsAndBalances(address(this));
        assertEq(assetsAfterWithdraw.length, 0);
        assertEq(balancesAfterWithdraw.length, 0);
        assertEq(escrow.assetBalance(address(this), mockToken), 0);

        assertEq(escrow.assets(address(alice)).length, 1);
        (
            IERC20[] memory assetsBeforeWithdrawAlice,
            uint256[] memory balancesBeforeWithdrawAlice
        ) = escrow.assetsAndBalances(address(alice));
        assertEq(assetsBeforeWithdrawAlice.length, 1);
        assertEq(balancesBeforeWithdrawAlice.length, 1);
        assertEq(address(assetsBeforeWithdrawAlice[0]), address(mockToken));
        assertEq(balancesBeforeWithdrawAlice[0], 300);

        vm.prank(alice);
        escrow.withdraw(newAssets[0], 300);

        assertEq(escrow.assets(address(alice)).length, 0);
        (
            IERC20[] memory assetsAfterWithdrawAlice,
            uint256[] memory balancesAfterWithdrawAlice
        ) = escrow.assetsAndBalances(address(alice));
        assertEq(assetsAfterWithdrawAlice.length, 0);
        assertEq(balancesAfterWithdrawAlice.length, 0);
        assertEq(escrow.assetBalance(address(alice), mockToken), 0);
    }
}

contract EscrowTestRejectDeposit is Test {
    using stdStorage for StdStorage;
    using Math for uint256;

    Escrow public escrow;
    MockToken public mockToken;
    MockToken public mockToken2;

    Utils public utils;
    address public alice;
    address public bob;

    function setUp() public {
        utils = new Utils();
        alice = utils.createAccount();
        bob = utils.createAccount();

        mockToken = new MockToken();
        escrow = new Escrow(address(this));
        mockToken = new MockToken();
        mockToken2 = new MockToken();
    }

    function test_RejectZeroDepositAmount() public {
        IERC20[] memory initialAssets = escrow.assets(address(alice));
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(alice), 100);
        vm.prank(alice);
        mockToken.transfer(address(escrow), 100);

        assertEq(mockToken.balanceOf(address(alice)), 0);
        assertEq(mockToken.balanceOf(address(escrow)), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        escrow.rejectDeposit(alice, newAssets[0], 0, address(this), 40);

        assertEq(mockToken.balanceOf(address(this)), 40);
        assertEq(mockToken.balanceOf(address(alice)), 0);
        assertEq(mockToken.balanceOf(address(escrow)), 60);

        assertEq(escrow.assets(address(alice)).length, 0);

        (IERC20[] memory afterAssets, uint256[] memory afterBalances) = escrow
            .assetsAndBalances(address(alice));

        assertEq(afterAssets.length, 0);
        assertEq(afterBalances.length, 0);
        assertEq(escrow.assetBalance(address(alice), mockToken), 0);
    }

    function test_RejectZeroFee() public {
        IERC20[] memory initialAssets = escrow.assets(address(alice));
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(alice), 100);
        vm.prank(alice);
        mockToken.transfer(address(escrow), 100);

        assertEq(mockToken.balanceOf(address(alice)), 0);
        assertEq(mockToken.balanceOf(address(escrow)), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        escrow.rejectDeposit(alice, newAssets[0], 60, address(this), 0);

        assertEq(mockToken.balanceOf(address(this)), 0);
        assertEq(mockToken.balanceOf(address(alice)), 60);
        assertEq(mockToken.balanceOf(address(escrow)), 40);

        assertEq(escrow.assets(address(alice)).length, 0);

        (IERC20[] memory afterAssets, uint256[] memory afterBalances) = escrow
            .assetsAndBalances(address(alice));

        assertEq(afterAssets.length, 0);
        assertEq(afterBalances.length, 0);
        assertEq(escrow.assetBalance(address(alice), mockToken), 0);
    }
}

contract EscrowTestBlacklist is Test {
    using stdStorage for StdStorage;
    using Math for uint256;

    Escrow public escrow;
    MockToken public mockToken;
    MockToken public mockToken2;

    Utils public utils;
    address public alice;
    address public bob;

    function setUp() public {
        utils = new Utils();
        alice = utils.createAccount();
        bob = utils.createAccount();

        mockToken = new MockToken();
        escrow = new Escrow(address(this));
        mockToken = new MockToken();
        mockToken2 = new MockToken();
    }

    function test_BlacklistCannotInteract() public {
        IERC20[] memory initialAssets = escrow.assets(address(alice));
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(alice), 100);
        vm.prank(alice);
        mockToken.transfer(address(escrow), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        assertEq(mockToken.balanceOf(address(alice)), 0);
        assertEq(mockToken.balanceOf(address(escrow)), 100);

        escrow.acceptDeposit(address(alice), newAssets[0], newAmounts[0]);

        escrow.addBlacklistedAccount(address(alice));

        vm.expectRevert("Escrow: caller is blacklisted");
        vm.prank(alice);
        escrow.withdraw(newAssets[0], newAmounts[0]);

        vm.expectRevert("Escrow: caller is blacklisted");
        vm.prank(alice);
        escrow.assets(address(alice));

        vm.expectRevert("Escrow: caller is blacklisted");
        vm.prank(alice);
        escrow.assetBalance(address(alice), mockToken);

        vm.expectRevert("Escrow: caller is blacklisted");
        vm.prank(alice);
        escrow.assetsAndBalances(address(alice));

        escrow.removeBlacklistedAccount(address(alice));
        vm.prank(alice);
        escrow.withdraw(newAssets[0], newAmounts[0]);

        vm.prank(alice);
        escrow.assets(address(alice));

        vm.prank(alice);
        escrow.assetBalance(address(alice), mockToken);

        vm.prank(alice);
        escrow.assetsAndBalances(address(alice));
    }

    function test_AddBlacklistAddress() public {
        assertEq(escrow.blacklistedAccounts().length, 0);

        escrow.addBlacklistedAccount(address(alice));

        assertEq(escrow.blacklistedAccounts()[0], address(alice));
    }

    function test_RemoveBlacklistAddress() public {
        assertEq(escrow.blacklistedAccounts().length, 0);

        escrow.addBlacklistedAccount(address(alice));

        assertEq(escrow.blacklistedAccounts()[0], address(alice));

        escrow.removeBlacklistedAccount(address(alice));

        assertEq(escrow.blacklistedAccounts().length, 0);
    }

    function test_MultipleBlacklistedAddresses() public {
        assertEq(escrow.blacklistedAccounts().length, 0);

        escrow.addBlacklistedAccount(address(alice));

        assertEq(escrow.blacklistedAccounts()[0], address(alice));

        escrow.addBlacklistedAccount(address(bob));

        assertEq(escrow.blacklistedAccounts()[0], address(alice));
        assertEq(escrow.blacklistedAccounts()[1], address(bob));

        escrow.removeBlacklistedAccount(address(bob));
        assertEq(escrow.blacklistedAccounts()[0], address(alice));
        assertEq(escrow.blacklistedAccounts().length, 1);

        escrow.addBlacklistedAccount(address(bob));

        assertEq(escrow.blacklistedAccounts()[0], address(alice));
        assertEq(escrow.blacklistedAccounts()[1], address(bob));

        escrow.removeBlacklistedAccount(address(alice));
        assertEq(escrow.blacklistedAccounts()[0], address(bob));
        assertEq(escrow.blacklistedAccounts().length, 1);

        escrow.addBlacklistedAccount(address(alice));

        assertEq(escrow.blacklistedAccounts()[0], address(bob));
        assertEq(escrow.blacklistedAccounts()[1], address(alice));
    }
}
