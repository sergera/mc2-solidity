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
    uint256 public initialMintAmount;

    function setUp() public {
        mockToken = new MockToken();
        strategyPool = new StrategyPool("Share", "SHARE", address(this), 10000);
        initialMintAmount = 10000 * 10 ** strategyPool.decimals();
    }

    function changeInitialDepositShareValue() public {
        uint256 initialBefore = strategyPool.initialDepositShareValue();
        assertEq(initialBefore, 10000 * 10 ** strategyPool.decimals());
        strategyPool.changeInitialDepositShareValue(5);
        uint256 initialAfter = strategyPool.initialDepositShareValue();
        assertEq(initialAfter, 5 * 10 ** strategyPool.decimals());
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

        strategyPool.deposit(newAssets, newAmounts, address(this));

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

        strategyPool.deposit(newAssets, newAmounts, address(this));

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

        strategyPool.deposit(newAssets, newAmounts, address(this));

        (
            IERC20[] memory afterAssets,
            uint256[] memory afterBalances
        ) = strategyPool.assetsAndBalances();

        assertEq(afterAssets.length, 1);
        assertEq(address(afterAssets[0]), address(mockToken));
        assertEq(afterBalances.length, 1);
        assertEq(afterBalances[0], 100);
    }

    function test_convertToShares() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        uint256 sharesBefore = strategyPool.convertToShares(
            newAssets,
            newAmounts
        );
        assertEq(sharesBefore, initialMintAmount);

        strategyPool.deposit(newAssets, newAmounts, address(this));

        uint256 sharesAfter = strategyPool.convertToShares(
            newAssets,
            newAmounts
        );
        assertEq(sharesAfter, initialMintAmount);
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

        strategyPool.deposit(newAssets, newAmounts, address(this));

        uint256 maxShares = strategyPool.maxMint();
        assertEq(maxShares, type(uint256).max - initialMintAmount);
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

        strategyPool.deposit(newAssets, newAmounts, address(this));

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

        strategyPool.deposit(newAssets, newAmounts, address(this));

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

        strategyPool.deposit(newAssets, newAmounts, address(this));

        (
            IERC20[] memory assetsAfter,
            uint256[] memory minAmountsAfter
        ) = strategyPool.minDeposit();
        assertEq(assetsAfter.length, 1);
        assertEq(address(assetsAfter[0]), address(mockToken));
        assertEq(minAmountsAfter.length, 1);
        assertEq(minAmountsAfter[0], 1);
    }

    function test_previewDeposit() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        uint256 sharesBefore = strategyPool.previewDeposit(
            newAssets,
            newAmounts
        );
        assertEq(sharesBefore, initialMintAmount);

        strategyPool.deposit(newAssets, newAmounts, address(this));

        uint256 sharesAfter = strategyPool.previewDeposit(
            newAssets,
            newAmounts
        );
        assertEq(sharesAfter, initialMintAmount);
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

        uint256 shares = strategyPool.deposit(
            newAssets,
            newAmounts,
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
        assertEq(shares, initialMintAmount);
        assertEq(strategyPool.balanceOf(address(this)), initialMintAmount);
        assertEq(strategyPool.totalSupply(), initialMintAmount);
        assertEq(mockToken.balanceOf(address(strategyPool)), 100);
        assertEq(
            mockToken.allowance(address(strategyPool), address(this)),
            100
        );
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

        strategyPool.deposit(newAssets, newAmounts, address(this));

        uint256 sharesAfter = strategyPool.maxRedeem(address(this));
        assertEq(sharesAfter, initialMintAmount);
    }

    function test_minRedeem() public {
        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(newAssets, newAmounts, address(this));

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

        (
            IERC20[] memory assetsBefore,
            uint256[] memory amountsBefore
        ) = strategyPool.previewRedeem(100);
        assertEq(assetsBefore.length, 0);
        assertEq(amountsBefore.length, 0);

        uint256 shares = strategyPool.deposit(
            newAssets,
            newAmounts,
            address(this)
        );

        (
            IERC20[] memory assetsAfter,
            uint256[] memory amountsAfter
        ) = strategyPool.previewRedeem(shares);
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

        uint256 shares = strategyPool.deposit(
            newAssets,
            newBalances,
            address(this)
        );

        (
            IERC20[] memory redeemedAssets,
            uint256[] memory redeemedAmounts
        ) = strategyPool.redeem(shares, address(this), address(this));

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
        assertEq(mockToken.allowance(address(strategyPool), address(this)), 0);
        assertEq(strategyPool.assets().length, 0);
        assertEq(strategyPool.assetBalances(IERC20(mockToken)), 0);
    }

    function test_changeStrategy() public {
        IERC20[] memory initialAssets = strategyPool.assets();
        assertEq(initialAssets.length, 0);

        mockToken.mint(address(this), 100);
        mockToken.approve(address(strategyPool), 100);

        IERC20[] memory newAssets = new IERC20[](1);
        newAssets[0] = mockToken;

        uint256[] memory newAmounts = new uint256[](1);
        newAmounts[0] = 100;

        strategyPool.deposit(newAssets, newAmounts, address(this));

        mockToken.transferFrom(address(strategyPool), address(this), 50);
        mockToken.burn(address(this), 50);
        MockToken mockToken2 = new MockToken();
        mockToken2.mint(address(this), 100);
        mockToken2.approve(address(strategyPool), 100);

        IERC20[] memory beforeAssets = new IERC20[](2);
        beforeAssets[0] = mockToken;
        beforeAssets[1] = mockToken2;

        int256[] memory beforeBalanceDeltas = new int256[](2);
        beforeBalanceDeltas[0] = -50;
        beforeBalanceDeltas[1] = 100;

        strategyPool.changeStrategy(beforeAssets, beforeBalanceDeltas);

        (
            IERC20[] memory afterAssets,
            uint256[] memory afterBalances
        ) = strategyPool.assetsAndBalances();

        assertEq(afterAssets.length, 2);
        assertEq(address(afterAssets[0]), address(mockToken));
        assertEq(address(afterAssets[1]), address(mockToken2));
        assertEq(afterBalances.length, 2);
        assertEq(afterBalances[0], 50);
        assertEq(afterBalances[1], 100);
        assertEq(strategyPool.balanceOf(address(this)), initialMintAmount);
        assertEq(strategyPool.totalSupply(), initialMintAmount);
        assertEq(mockToken.balanceOf(address(strategyPool)), 50);
        assertEq(mockToken.allowance(address(strategyPool), address(this)), 50);
        assertEq(mockToken2.balanceOf(address(strategyPool)), 100);
        assertEq(
            mockToken2.allowance(address(strategyPool), address(this)),
            100
        );
    }
}
