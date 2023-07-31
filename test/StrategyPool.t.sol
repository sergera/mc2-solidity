// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, stdStorage, StdStorage} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {console} from "forge-std/console.sol";

import {StrategyPool} from "../src/StrategyPool.sol";
import {StrategyPoolHerald} from "../src/StrategyPoolHerald.sol";
import {MockToken} from "./MockToken.sol";

contract StrategyPoolTestBasic is Test {
    using stdStorage for StdStorage;
    using Math for uint256;

    StrategyPool public strategyPool;
    StrategyPoolHerald public herald;
    MockToken public mockToken;

    function setUp() public {
        mockToken = new MockToken();
        herald = new StrategyPoolHerald();
        strategyPool = new StrategyPool(
            "Share",
            "SHARE",
            address(this),
            herald
        );
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

        strategyPool.redeem(address(this), address(this), 100 * 10 ** 18);

        (
            IERC20[] memory afterAssets,
            uint256[] memory afterBalances
        ) = strategyPool.assetsAndBalances();

        assertEq(afterAssets.length, 1);
        assertEq(address(afterAssets[0]), address(mockToken));
        assertEq(afterBalances.length, 1);
        assertEq(afterBalances[0], 100);
        assertEq(strategyPool.balanceOf(address(this)), 0);
        assertEq(strategyPool.totalSupply(), 0);
        assertEq(mockToken.balanceOf(address(strategyPool)), 100);
    }

    function test_redeem_as_admin() public {
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

        strategyPool.redeemAsAdmin(address(this), 100 * 10 ** 18);

        (
            IERC20[] memory afterAssets,
            uint256[] memory afterBalances
        ) = strategyPool.assetsAndBalances();

        assertEq(afterAssets.length, 1);
        assertEq(address(afterAssets[0]), address(mockToken));
        assertEq(afterBalances.length, 1);
        assertEq(afterBalances[0], 100);
        assertEq(strategyPool.balanceOf(address(this)), 0);
        assertEq(strategyPool.totalSupply(), 0);
        assertEq(mockToken.balanceOf(address(strategyPool)), 100);
    }

    function test_withdraw() public {
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

        strategyPool.redeem(address(this), address(this), 100 * 10 ** 18);
        strategyPool.withdraw(address(this), newAssets, newBalances);

        (
            IERC20[] memory afterAssets,
            uint256[] memory afterBalances
        ) = strategyPool.assetsAndBalances();

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
    StrategyPoolHerald public herald;

    function setUp() public {
        mockToken = new MockToken();
        mockToken2 = new MockToken();
        herald = new StrategyPoolHerald();
        strategyPool = new StrategyPool(
            "Share",
            "SHARE",
            address(this),
            herald
        );
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
        strategyPool.redeem(address(this), address(this), 100 * 10 ** 18);

        mockToken.approve(address(strategyPool), 100);
        strategyPool.giveBackAssetsAfterTrade(newAssets, newAmounts);

        assertEq(mockToken.balanceOf(address(strategyPool)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);
        assertEq(strategyPool.assets().length, 1);
        assertEq(mockToken.balanceOf(address(this)), 0);

        strategyPool.redeem(address(this), address(this), 100 * 10 ** 18);

        assertEq(mockToken.balanceOf(address(strategyPool)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);
        assertEq(strategyPool.assets().length, 1);
        assertEq(mockToken.balanceOf(address(this)), 0);
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
    StrategyPoolHerald public herald;

    function setUp() public {
        mockToken = new MockToken();
        mockToken2 = new MockToken();
        herald = new StrategyPoolHerald();
        strategyPool = new StrategyPool(
            "Share",
            "SHARE",
            address(this),
            herald
        );
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

contract StrategyPoolTestRedeemWithdraw is Test {
    using stdStorage for StdStorage;
    using Math for uint256;

    StrategyPool public strategyPool;
    MockToken public mockToken;
    MockToken public mockToken2;
    StrategyPoolHerald public herald;

    function setUp() public {
        mockToken = new MockToken();
        mockToken2 = new MockToken();
        herald = new StrategyPoolHerald();
        strategyPool = new StrategyPool(
            "Share",
            "SHARE",
            address(this),
            herald
        );
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

        vm.expectRevert("StrategyPool: redeem 0 pool tokens");
        strategyPool.redeem(address(this), address(this), 0);
    }

    function test_zeroRedeemAsAdminReverts() public {
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

        vm.expectRevert("StrategyPool: redeem 0 pool tokens");
        strategyPool.redeemAsAdmin(address(this), 0);
    }

    function test_redeemEmitsRedeemEventInHerald() public {
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

        vm.recordLogs();
        strategyPool.redeem(address(this), address(this), 100 * 10 ** 18);
        VmSafe.Log[] memory logEntries = vm.getRecordedLogs();

        assertEq(logEntries.length, 3);
        assertEq(logEntries[0].topics.length, 3);
        assertEq(logEntries[1].topics.length, 3);
        assertEq(logEntries[2].topics.length, 4);
        /* ERC20 burn Transfer event */
        assertEq(
            logEntries[0].topics[0],
            keccak256("Transfer(address,address,uint256)")
        );
        assertEq(
            address(uint160(uint256(logEntries[0].topics[1]))),
            address(this)
        );
        assertEq(
            address(uint160(uint256(logEntries[0].topics[2]))),
            address(0)
        );
        assertEq(
            abi.decode(logEntries[0].data, (uint256)),
            uint256(100 * 10 ** 18)
        );
        /* strategy pool redeem event */
        assertEq(
            logEntries[1].topics[0],
            keccak256("Redeem(address,address,uint256)")
        );
        assertEq(
            address(uint160(uint256(logEntries[1].topics[1]))),
            address(this)
        );
        assertEq(
            address(uint160(uint256(logEntries[1].topics[2]))),
            address(this)
        );
        assertEq(
            abi.decode(logEntries[1].data, (uint256)),
            uint256(100 * 10 ** 18)
        );
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
            address(this)
        );
        assertEq(
            address(uint160(uint256(logEntries[2].topics[3]))),
            address(this)
        );
        assertEq(
            abi.decode(logEntries[2].data, (uint256)),
            uint256(100 * 10 ** 18)
        );
    }

    function test_redeemAsAdminDoesNotEmitEventInHerald() public {
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

        vm.recordLogs();
        strategyPool.redeemAsAdmin(address(this), 100 * 10 ** 18);
        VmSafe.Log[] memory logEntries = vm.getRecordedLogs();

        assertEq(logEntries.length, 2);
        assertEq(logEntries[0].topics.length, 3);
        assertEq(logEntries[1].topics.length, 3);
        /* ERC20 burn Transfer event */
        assertEq(
            logEntries[0].topics[0],
            keccak256("Transfer(address,address,uint256)")
        );
        assertEq(
            address(uint160(uint256(logEntries[0].topics[1]))),
            address(this)
        );
        assertEq(
            address(uint160(uint256(logEntries[0].topics[2]))),
            address(0)
        );
        assertEq(
            abi.decode(logEntries[0].data, (uint256)),
            uint256(100 * 10 ** 18)
        );
        /* strategy pool redeem event */
        assertEq(
            logEntries[1].topics[0],
            keccak256("Redeem(address,address,uint256)")
        );
        assertEq(
            address(uint160(uint256(logEntries[1].topics[1]))),
            address(this)
        );
        assertEq(
            address(uint160(uint256(logEntries[1].topics[2]))),
            address(this)
        );
        assertEq(
            abi.decode(logEntries[1].data, (uint256)),
            uint256(100 * 10 ** 18)
        );
    }

    function test_withdrawTransfersTokens() public {
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

        strategyPool.withdraw(address(this), newAssets, newAmounts);

        assertEq(mockToken.balanceOf(address(this)), 100);
        assertEq(mockToken.balanceOf(address(strategyPool)), 0);
    }

    function test_withdrawRemovesToken() public {
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

        strategyPool.withdraw(address(this), newAssets, newAmounts);

        assertEq(strategyPool.assets().length, 0);
        (
            IERC20[] memory assetsAfter,
            uint256[] memory balancesAfter
        ) = strategyPool.assetsAndBalances();
        assertEq(assetsAfter.length, 0);
        assertEq(balancesAfter.length, 0);
    }

    function test_withdrawRemovesTokens() public {
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

        strategyPool.withdraw(address(this), newAssets, newAmounts);

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

        strategyPool.redeem(address(this), address(this), 100 * 10 ** 18);

        assertEq(strategyPool.balanceOf(address(this)), 0);
        assertEq(strategyPool.totalSupply(), 0);
    }

    function test_redeemAsAdminBurnsShares() public {
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

        strategyPool.redeemAsAdmin(address(this), 100 * 10 ** 18);

        assertEq(strategyPool.balanceOf(address(this)), 0);
        assertEq(strategyPool.totalSupply(), 0);
    }
}
