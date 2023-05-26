// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
// import "openzeppelin-contracts/contracts/utils/math/Math.sol";
import "forge-std/console.sol";
import "../src/StrategyPool.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}

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
        assertEq(strategyPool.assetBalance(mockToken), 0);
        assertEq(strategyPool.assets().length, 0);
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
        assertEq(strategyPool.assetBalance(mockToken), 0);
        assertEq(strategyPool.assets().length, 0);
        assertEq(mockToken.balanceOf(address(this)), 100);

        mockToken.approve(address(strategyPool), 100);
        strategyPool.giveBackAssetsAfterTrade(newAssets, newAmounts);

        assertEq(mockToken.balanceOf(address(strategyPool)), 100);
        assertEq(strategyPool.assetBalance(mockToken), 100);
        assertEq(strategyPool.assets().length, 1);
        assertEq(mockToken.balanceOf(address(this)), 0);
    }
}
