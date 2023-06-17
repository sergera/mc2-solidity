// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, stdStorage, StdStorage} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {console} from "forge-std/console.sol";

import {StrategyPool} from "../src/StrategyPool.sol";
import {MockToken} from "./MockToken.sol";

contract StrategyPoolTestBasic is Test {
    using stdStorage for StdStorage;
    using Math for uint256;

    StrategyPool public strategyPool;
    MockToken public mockToken;

    function setUp() public {
        mockToken = new MockToken();
        strategyPool = new StrategyPool("Share", "SHARE", address(this));
    }

    function test_assets() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        IERC20[] memory afterAssets = strategyPool.assets();

        assertEq(afterAssets.length, 1);
        assertEq(address(afterAssets[0]), address(mockToken));
    }

    function test_assetBalance() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        uint256 afterBalance = strategyPool.assetBalance(IERC20(mockToken));
        assertEq(afterBalance, 100);
    }

    function test_assetsAndBalances() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        (
            IERC20[] memory afterAssets,
            uint256[] memory afterBalances
        ) = strategyPool.assetsAndBalances();

        assertEq(afterAssets.length, 1);
        assertEq(address(afterAssets[0]), address(mockToken));
        assertEq(afterBalances.length, 1);
        assertEq(afterBalances[0], 100);
    }

    function test_maxMint() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        uint256 maxShares = strategyPool.maxMint();
        assertEq(maxShares, type(uint256).max - 100 * 10 ** 18);
    }

    function test_maxWithdraw() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        (
            IERC20[] memory assetsAfter,
            uint256[] memory maxAmountsAfter
        ) = strategyPool.maxWithdraw(address(this));

        assertEq(assetsAfter.length, 1);
        assertEq(address(assetsAfter[0]), address(mockToken));
        assertEq(maxAmountsAfter.length, 1);
        assertEq(maxAmountsAfter[0], 100);
    }

    function test_maxDeposit() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        (
            IERC20[] memory assetsAfter,
            uint256[] memory maxAmountsAfter
        ) = strategyPool.maxDeposit();
        assertEq(assetsAfter.length, 1);
        assertEq(address(assetsAfter[0]), address(mockToken));
        assertEq(maxAmountsAfter.length, 1);
        assertEq(
            maxAmountsAfter[0],
            strategyPool.maxMint().mulDiv(
                strategyPool.assetBalances(IERC20(mockToken)),
                strategyPool.totalSupply()
            )
        );
    }

    function test_minDeposit() public {
        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        (
            IERC20[] memory assetsAfter,
            uint256[] memory minAmountsAfter
        ) = strategyPool.minDeposit();
        assertEq(assetsAfter.length, 1);
        assertEq(address(assetsAfter[0]), address(mockToken));
        assertEq(minAmountsAfter.length, 1);
        assertEq(minAmountsAfter[0], 1);
    }

    function test_deposit() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        (
            IERC20[] memory afterAssets,
            uint256[] memory afterBalances
        ) = strategyPool.assetsAndBalances();

        assertEq(afterAssets.length, 1);
        assertEq(address(afterAssets[0]), address(mockToken));
        assertEq(afterBalances.length, 1);
        assertEq(afterBalances[0], 100);
        assertEq(strategyPool.balanceOf(address(this)), 100 * 10 ** 18);
        assertEq(strategyPool.totalSupply(), 100 * 10 ** 18);
        assertEq(mockToken.balanceOf(address(strategyPool)), 100);
        assertEq(strategyPool.assetBalances(IERC20(mockToken)), 100);
    }

    function test_maxRedeem() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        uint256 sharesAfter = strategyPool.maxRedeem(address(this));
        assertEq(sharesAfter, 100 * 10 ** 18);
    }

    function test_minRedeem() public {
        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        uint256 minShares = strategyPool.minRedeem();
        uint256 expectedMinShares = strategyPool.totalSupply() /
            strategyPool.assetBalances(mockToken) +
            (
                strategyPool.totalSupply() %
                    strategyPool.assetBalances(mockToken) ==
                    0
                    ? 0
                    : 1
            );
        assertEq(minShares, expectedMinShares);
    }

    function test_previewRedeem() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        (
            IERC20[] memory assetsAfter,
            uint256[] memory amountsAfter
        ) = strategyPool.previewRedeem(100 * 10 ** 18);
        assertEq(assetsAfter.length, 1);
        assertEq(address(assetsAfter[0]), address(mockToken));
        assertEq(amountsAfter.length, 1);
        assertEq(amountsAfter[0], 100);
    }

    function test_redeem() public {
        IERC20[] memory assets = strategyPool.assets();
        assertEq(assets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newBalances = new uint256[](1);
        newBalances[0] = 100;

        strategyPool.deposit(
            newAssets,
            newBalances,
            100 * 10 ** 18,
            address(this)
        );

        (
            IERC20[] memory redeemedAssets,
            uint256[] memory redeemedAmounts
        ) = strategyPool.redeem(100 * 10 ** 18, address(this), address(this));

        (
            IERC20[] memory afterAssets,
            uint256[] memory afterBalances
        ) = strategyPool.assetsAndBalances();

        assertEq(redeemedAssets.length, 1);
        assertEq(address(redeemedAssets[0]), address(mockToken));
        assertEq(redeemedAmounts.length, 1);
        assertEq(redeemedAmounts[0], 100);
        assertEq(afterAssets.length, 0);
        assertEq(afterBalances.length, 0);
        assertEq(strategyPool.balanceOf(address(this)), 0);
        assertEq(strategyPool.totalSupply(), 0);
        assertEq(mockToken.balanceOf(address(strategyPool)), 0);
        assertEq(strategyPool.assets().length, 0);
        assertEq(strategyPool.assetBalances(IERC20(mockToken)), 0);
    }

    function test_acquireAssetBeforeTrade() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        assertEq(mockToken.balanceOf(address(strategyPool)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);
        assertEq(strategyPool.assets().length, 1);
        assertEq(mockToken.balanceOf(address(this)), 0);

        strategyPool.acquireAssetBeforeTrade(newAssets[0], newAmounts[0]);

        assertEq(mockToken.balanceOf(address(strategyPool)), 0);
        vm.expectRevert("Pausable: paused");
        strategyPool.assetBalance(mockToken); // = 0
        vm.expectRevert("Pausable: paused");
        strategyPool.assets().length; // = 0
        assertEq(mockToken.balanceOf(address(this)), 100);
    }

    function test_giveBackAssetsAfterTrade() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        assertEq(mockToken.balanceOf(address(strategyPool)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);
        assertEq(strategyPool.assets().length, 1);
        assertEq(mockToken.balanceOf(address(this)), 0);

        strategyPool.acquireAssetBeforeTrade(newAssets[0], newAmounts[0]);

        assertEq(mockToken.balanceOf(address(strategyPool)), 0);
        vm.expectRevert("Pausable: paused");
        strategyPool.assetBalance(mockToken); // = 0
        vm.expectRevert("Pausable: paused");
        strategyPool.assets().length; // = 0
        assertEq(mockToken.balanceOf(address(this)), 100);

        mockToken.approve(address(strategyPool), 100);
        strategyPool.giveBackAssetsAfterTrade(newAssets, newAmounts);

        assertEq(mockToken.balanceOf(address(strategyPool)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);
        assertEq(strategyPool.assets().length, 1);
        assertEq(mockToken.balanceOf(address(this)), 0);
    }
}

contract StrategyPoolTestChangeStrategy is Test {
    using stdStorage for StdStorage;
    using Math for uint256;

    StrategyPool public strategyPool;
    MockToken public mockToken;
    MockToken public mockToken2;

    function setUp() public {
        mockToken = new MockToken();
        mockToken2 = new MockToken();
        strategyPool = new StrategyPool("Share", "SHARE", address(this));
    }

    function test_cannotCallAcquireTwiceInSequence() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        assertEq(mockToken.balanceOf(address(strategyPool)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);
        assertEq(strategyPool.assets().length, 1);
        assertEq(mockToken.balanceOf(address(this)), 0);

        strategyPool.acquireAssetBeforeTrade(newAssets[0], newAmounts[0] / 2);

        assertEq(mockToken.balanceOf(address(strategyPool)), newAmounts[0] / 2);
        vm.expectRevert("Pausable: paused");
        strategyPool.assetBalance(mockToken); // = newAmounts[0] / 2
        vm.expectRevert("Pausable: paused");
        strategyPool.assets().length; // = 1
        assertEq(mockToken.balanceOf(address(this)), newAmounts[0] / 2);

        vm.expectRevert("Pausable: paused");
        strategyPool.acquireAssetBeforeTrade(newAssets[0], newAmounts[0] / 2);

        mockToken.approve(address(strategyPool), newAmounts[0] / 2);

        newAmounts[0] = newAmounts[0] / 2;
        strategyPool.giveBackAssetsAfterTrade(newAssets, newAmounts);

        assertEq(mockToken.balanceOf(address(strategyPool)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);
        assertEq(strategyPool.assets().length, 1);
        assertEq(mockToken.balanceOf(address(this)), 0);
    }

    function test_cannotRedeemWhileTrading() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        assertEq(mockToken.balanceOf(address(strategyPool)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);
        assertEq(strategyPool.assets().length, 1);
        assertEq(mockToken.balanceOf(address(this)), 0);

        strategyPool.acquireAssetBeforeTrade(newAssets[0], newAmounts[0]);

        assertEq(mockToken.balanceOf(address(strategyPool)), 0);
        vm.expectRevert("Pausable: paused");
        strategyPool.assetBalance(mockToken); // = 0
        vm.expectRevert("Pausable: paused");
        strategyPool.assets().length; // = 0
        assertEq(mockToken.balanceOf(address(this)), 100);

        vm.expectRevert("Pausable: paused");
        strategyPool.redeem(100 * 10 ** 18, address(this), address(this));

        mockToken.approve(address(strategyPool), 100);
        strategyPool.giveBackAssetsAfterTrade(newAssets, newAmounts);

        assertEq(mockToken.balanceOf(address(strategyPool)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);
        assertEq(strategyPool.assets().length, 1);
        assertEq(mockToken.balanceOf(address(this)), 0);

        strategyPool.redeem(100 * 10 ** 18, address(this), address(this));

        assertEq(mockToken.balanceOf(address(strategyPool)), 0);
        assertEq(strategyPool.assetBalance(mockToken), 0);
        assertEq(strategyPool.assets().length, 0);
        assertEq(mockToken.balanceOf(address(this)), 100);
    }

    function test_cannotCallGiveBackBeforeAcquire() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        assertEq(mockToken.balanceOf(address(strategyPool)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);
        assertEq(strategyPool.assets().length, 1);
        assertEq(mockToken.balanceOf(address(this)), 0);

        vm.expectRevert("Pausable: not paused");
        strategyPool.giveBackAssetsAfterTrade(newAssets, newAmounts);

        strategyPool.acquireAssetBeforeTrade(newAssets[0], newAmounts[0]);

        assertEq(mockToken.balanceOf(address(strategyPool)), 0);
        vm.expectRevert("Pausable: paused");
        strategyPool.assetBalance(mockToken); // = 0
        vm.expectRevert("Pausable: paused");
        strategyPool.assets().length; // = 0
        assertEq(mockToken.balanceOf(address(this)), 100);
    }

    function test_giveBackAddsExtraToken() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        assertEq(mockToken.balanceOf(address(strategyPool)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);
        assertEq(strategyPool.assets().length, 1);
        assertEq(mockToken.balanceOf(address(this)), 0);

        strategyPool.acquireAssetBeforeTrade(newAssets[0], newAmounts[0]);

        assertEq(mockToken.balanceOf(address(strategyPool)), 0);
        vm.expectRevert("Pausable: paused");
        strategyPool.assetBalance(mockToken); // = 0
        vm.expectRevert("Pausable: paused");
        strategyPool.assets().length; // = 0
        assertEq(mockToken.balanceOf(address(this)), 100);

        mockToken.burn(address(this), 50);
        mockToken2.mint(address(this), 300);

        mockToken.approve(address(strategyPool), 50);
        mockToken2.approve(address(strategyPool), 300);

        IERC20[] memory afterTradeAssets = new IERC20[](2);
        afterTradeAssets[0] = mockToken;
        afterTradeAssets[1] = mockToken2;
        uint256[] memory afterTradeAmounts = new uint256[](2);
        afterTradeAmounts[0] = 50;
        afterTradeAmounts[1] = 300;

        strategyPool.giveBackAssetsAfterTrade(
            afterTradeAssets,
            afterTradeAmounts
        );

        assertEq(mockToken.balanceOf(address(this)), 0);
        assertEq(mockToken2.balanceOf(address(this)), 0);
        assertEq(mockToken.balanceOf(address(strategyPool)), 50);
        assertEq(mockToken2.balanceOf(address(strategyPool)), 300);
        assertEq(strategyPool.assetBalance(mockToken), 50);
        assertEq(strategyPool.assetBalance(mockToken2), 300);
        assertEq(strategyPool.assets().length, 2);

        (
            IERC20[] memory afterAssets,
            uint256[] memory afterBalances
        ) = strategyPool.assetsAndBalances();
        assertEq(afterAssets.length, 2);
        assertEq(address(afterAssets[0]), address(mockToken));
        assertEq(address(afterAssets[1]), address(mockToken2));
        assertEq(afterBalances.length, 2);
        assertEq(afterBalances[0], 50);
        assertEq(afterBalances[1], 300);
    }
}

contract StrategyPoolTestDeposit is Test {
    using stdStorage for StdStorage;
    using Math for uint256;

    StrategyPool public strategyPool;
    MockToken public mockToken;
    MockToken public mockToken2;

    function setUp() public {
        mockToken = new MockToken();
        mockToken2 = new MockToken();
        strategyPool = new StrategyPool("Share", "SHARE", address(this));
    }

    function test_zeroDepositReverts() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 0;

        vm.expectRevert("StrategyPool: deposit 0 amount");
        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );
    }

    function test_depositTransfersTokens() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);
        assertEq(mockToken.balanceOf(address(this)), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        assertEq(mockToken.balanceOf(address(this)), 0);
        assertEq(mockToken.balanceOf(address(strategyPool)), 100);
    }

    function test_depositAddsToken() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        assertEq(strategyPool.assets().length, 1);
        assertEq(address(strategyPool.assets()[0]), address(mockToken));
        assertEq(strategyPool.assetBalances(mockToken), 100);

        (
            IERC20[] memory afterAssets,
            uint256[] memory afterBalances
        ) = strategyPool.assetsAndBalances();
        assertEq(afterAssets.length, 1);
        assertEq(address(afterAssets[0]), address(mockToken));
        assertEq(afterBalances.length, 1);
        assertEq(afterBalances[0], 100);
    }

    function test_depositAddsTokens() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);
        mockToken2.mint(address(this), 300);
        mockToken2.approve(address(strategyPool), 300);

        IERC20[] memory newAssets = new IERC20[](2);
        newAssets[0] = mockToken;
        newAssets[1] = mockToken2;

        uint256[] memory newAmounts = new uint256[](2);
        newAmounts[0] = 100;
        newAmounts[1] = 300;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        assertEq(strategyPool.assets().length, 2);
        assertEq(address(strategyPool.assets()[0]), address(mockToken));
        assertEq(address(strategyPool.assets()[1]), address(mockToken2));
        assertEq(strategyPool.assetBalances(mockToken), 100);
        assertEq(strategyPool.assetBalances(mockToken2), 300);

        (
            IERC20[] memory afterAssets,
            uint256[] memory afterBalances
        ) = strategyPool.assetsAndBalances();
        assertEq(afterAssets.length, 2);
        assertEq(address(afterAssets[0]), address(mockToken));
        assertEq(address(afterAssets[1]), address(mockToken2));
        assertEq(afterBalances.length, 2);
        assertEq(afterBalances[0], 100);
        assertEq(afterBalances[1], 300);
    }

    function test_depositMintsShares() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );
        assertEq(strategyPool.balanceOf(address(this)), 100 * 10 ** 18);
    }
}

contract StrategyPoolTestRedeem is Test {
    using stdStorage for StdStorage;
    using Math for uint256;

    StrategyPool public strategyPool;
    MockToken public mockToken;
    MockToken public mockToken2;

    function setUp() public {
        mockToken = new MockToken();
        mockToken2 = new MockToken();
        strategyPool = new StrategyPool("Share", "SHARE", address(this));
    }

    function test_zeroRedeemReverts() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        vm.expectRevert("StrategyPool: redeem 0 shares");
        strategyPool.redeem(0, address(this), address(this));
    }

    function test_redeemTransfersTokens() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        assertEq(mockToken.balanceOf(address(this)), 100);
        assertEq(mockToken.balanceOf(address(strategyPool)), 0);

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        assertEq(mockToken.balanceOf(address(this)), 0);
        assertEq(mockToken.balanceOf(address(strategyPool)), 100);

        strategyPool.redeem(100 * 10 ** 18, address(this), address(this));

        assertEq(mockToken.balanceOf(address(this)), 100);
        assertEq(mockToken.balanceOf(address(strategyPool)), 0);
    }

    function test_redeemRemovesToken() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        assertEq(strategyPool.assets().length, 1);
        (
            IERC20[] memory assetsBefore,
            uint256[] memory balancesBefore
        ) = strategyPool.assetsAndBalances();
        assertEq(assetsBefore.length, 1);
        assertEq(balancesBefore.length, 1);

        strategyPool.redeem(100 * 10 ** 18, address(this), address(this));

        assertEq(strategyPool.assets().length, 0);
        (
            IERC20[] memory assetsAfter,
            uint256[] memory balancesAfter
        ) = strategyPool.assetsAndBalances();
        assertEq(assetsAfter.length, 0);
        assertEq(balancesAfter.length, 0);
    }

    function test_redeemRemovesTokens() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);
        mockToken2.mint(address(this), 300);
        mockToken2.approve(address(strategyPool), 300);

        IERC20[] memory newAssets = new IERC20[](2);
        newAssets[0] = mockToken;
        newAssets[1] = mockToken2;

        uint256[] memory newAmounts = new uint256[](2);
        newAmounts[0] = 100;
        newAmounts[1] = 300;

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        assertEq(strategyPool.assets().length, 2);
        (
            IERC20[] memory assetsBefore,
            uint256[] memory balancesBefore
        ) = strategyPool.assetsAndBalances();
        assertEq(assetsBefore.length, 2);
        assertEq(balancesBefore.length, 2);

        strategyPool.redeem(100 * 10 ** 18, address(this), address(this));

        assertEq(strategyPool.assets().length, 0);
        (
            IERC20[] memory assetsAfter,
            uint256[] memory balancesAfter
        ) = strategyPool.assetsAndBalances();
        assertEq(assetsAfter.length, 0);
        assertEq(balancesAfter.length, 0);
    }

    function test_redeemBurnsShares() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        assertEq(mockToken.balanceOf(address(this)), 100);

        strategyPool.deposit(
            newAssets,
            newAmounts,
            100 * 10 ** 18,
            address(this)
        );

        assertEq(strategyPool.balanceOf(address(this)), 100 * 10 ** 18);
        assertEq(strategyPool.totalSupply(), 100 * 10 ** 18);

        strategyPool.redeem(100 * 10 ** 18, address(this), address(this));

        assertEq(strategyPool.balanceOf(address(this)), 0);
        assertEq(strategyPool.totalSupply(), 0);
    }
}

contract StrategyPoolTestMinRedeem is Test {
    using stdStorage for StdStorage;
    using Math for uint256;

    StrategyPool public strategyPool;
    MockToken public mockToken;

    function setUp() public {
        mockToken = new MockToken();
        strategyPool = new StrategyPool("Share", "SHARE", address(this));
    }

    function test_minRedeem_totalSupplyLargerThanBalance() public {
        uint256 hugeAmount = 10000000 * 10 ** 18;
        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(newAssets, newAmounts, hugeAmount, address(this));

        uint256 minShares = strategyPool.minRedeem();
        uint256 expectedMinShares = strategyPool.totalSupply() /
            strategyPool.assetBalances(mockToken) +
            (
                strategyPool.totalSupply() %
                    strategyPool.assetBalances(mockToken) ==
                    0
                    ? 0
                    : 1
            );
        assertEq(minShares, expectedMinShares);
    }

    function test_minRedeem_balanceLargerThanTotalSupply() public {
        uint256 hugeAmount = 10000000 * 10 ** 18;
        mockToken.mint(address(this), hugeAmount);
        mockToken.approve(address(strategyPool), hugeAmount);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = hugeAmount;

        strategyPool.deposit(newAssets, newAmounts, 100, address(this));

        uint256 minShares = strategyPool.minRedeem();
        assertEq(minShares, 1);
    }
}

contract StrategyPoolTestMinDeposit is Test {
    using stdStorage for StdStorage;
    using Math for uint256;

    StrategyPool public strategyPool;
    MockToken public mockToken;

    function setUp() public {
        mockToken = new MockToken();
        strategyPool = new StrategyPool("Share", "SHARE", address(this));
    }

    function test_minDeposit_totalSupplyLargerThanBalance() public {
        uint256 hugeAmount = 10000000 * 10 ** 18;
        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(newAssets, newAmounts, hugeAmount, address(this));

        (
            IERC20[] memory assetsAfter,
            uint256[] memory minAmountsAfter
        ) = strategyPool.minDeposit();
        assertEq(assetsAfter.length, 1);
        assertEq(address(assetsAfter[0]), address(mockToken));
        assertEq(minAmountsAfter.length, 1);
        assertEq(minAmountsAfter[0], 1);
    }

    function test_minDeposit_balanceLargerThanTotalSupply() public {
        uint256 hugeAmount = 10000000 * 10 ** 18;
        mockToken.mint(address(this), hugeAmount);
        mockToken.approve(address(strategyPool), hugeAmount);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = hugeAmount;

        strategyPool.deposit(newAssets, newAmounts, 100, address(this));

        (
            IERC20[] memory assetsAfter,
            uint256[] memory minAmountsAfter
        ) = strategyPool.minDeposit();
        assertEq(assetsAfter.length, 1);
        assertEq(address(assetsAfter[0]), address(mockToken));
        assertEq(minAmountsAfter.length, 1);
        uint256 expectedMinAmount = hugeAmount /
            strategyPool.totalSupply() +
            (hugeAmount % strategyPool.totalSupply() == 0 ? 0 : 1);
        assertEq(minAmountsAfter[0], expectedMinAmount);
    }
}
