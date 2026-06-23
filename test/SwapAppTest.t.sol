// SPDX-License-Identifier: MIT
// forge test -vvvv --fork-url https://arb1.arbitrum.io/rpc
// chainlist.org

pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {SwapApp} from "../src/SwapApp.sol";
import {SwapAppScript} from "../script/SwapAppScript.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFactory} from "../src/IFactory.sol";

contract SwapAppTest is Test {
    SwapApp public swapApp;
    address public addressUniSwapRouterV2;
    address public user = makeAddr("user"); // use deal to give tokens for fork testing
    address public USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; // USDT address un arbitrum mainnet
    address public DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1; // DAI address un arbitrum mainnet

    // initial parameters in contract variables and contant
    address feeReceiver;
    uint256 constant feeReceived = 0;
    uint256 constant PERCENTAGE_BASIS = 1000;
    uint256 constant feeBasisPoints = 25;

    function setUp() public {
        SwapAppScript deployer = new SwapAppScript();
        (swapApp, addressUniSwapRouterV2) = deployer.run();
        feeReceiver = swapApp.s_FeeReceiver();
        deal(USDT, user, 5000 * 1e6, true);
    }

    function testHasBeenDeployedCorrectly() public view {
        assert(swapApp.s_V2Router02Address() == addressUniSwapRouterV2);
        assert(swapApp.s_FeeReceiver() == feeReceiver);
        assert(swapApp.getFeeBasisPoints() == feeBasisPoints);
        assert(swapApp.getPercentageBasis() == PERCENTAGE_BASIS);
        assert(swapApp.getTotalFeeReceived() == feeReceived);
    }

    function testSwapTokensCorrectly() public {
        vm.startPrank(user);
        uint256 amountIn = 20 * 1e6; // smart contract of USDT in arbitrum has 6 decimals
        uint256 fee = (amountIn * swapApp.getFeeBasisPoints()) / swapApp.getPercentageBasis(); // 6 decimals
        uint256 amountOutMin = (((amountIn - fee) * 1e18) / 1e6) - 2e18; // smart contract of DAI has 18 decimals in arbitrum
        
        IERC20(USDT).approve(address(swapApp), amountIn);
        uint256 _deadline = block.timestamp + 4 minutes;
        address[] memory _path = new address[](2);
        _path[0] = USDT;
        _path[1] = DAI;

        uint256 usdtBalanceBefore = IERC20(USDT).balanceOf(user);
        uint256 daiBalanceBefore = IERC20(DAI).balanceOf(user);
        console2.log("First DAI Balance: ", daiBalanceBefore);
        uint256 amount = swapApp.swapTokens(amountIn, amountOutMin, _path, user, _deadline);
        console2.log("Amount out on tokenSwap", amount);
        uint256 usdtBalanceAfter = IERC20(USDT).balanceOf(user);
        uint256 usdtBalanceFeeReceiver = IERC20(USDT).balanceOf(swapApp.s_FeeReceiver());
        uint256 theFeeReceived = swapApp.getTotalFeeReceived();
        uint256 daiBalanceAfter = IERC20(DAI).balanceOf(user);
        console2.log("DAI Balance before: ", daiBalanceAfter);

        assert(usdtBalanceAfter == usdtBalanceBefore - amountIn);
        assert(daiBalanceAfter > daiBalanceBefore);
        assert(theFeeReceived == fee);
        assert(usdtBalanceFeeReceiver == fee);

        vm.stopPrank();
    }

    function testAddLiquidityCorrectly() public {
        uint256 _amountIn = 200 * 1e6;             // 2000 USDT
        uint256 _amountOutMin = 50 * 1e18;        // ~1900 DAI (very safe)
        address[] memory _path = new address[](2);
        _path[0] = USDT;
        _path[1] = DAI;
        uint _deadline = block.timestamp + 4 minutes;

        vm.startPrank(user);
        IERC20(USDT).approve(address(swapApp), _amountIn);
        uint256 lp = swapApp.addLiquidity(
            _amountIn,
            _amountOutMin,
            _path,
            0,          // _amountAMin
            0,          // _amountBMin
            _deadline
        );
        console2.log("LP minted:", lp);
        assertGt(lp, 0);
        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        // 1. Add liquidity first
        uint256 addAmount = 2000 * 1e6;
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = DAI;
        uint256 deadline = block.timestamp + 4 minutes;

        vm.startPrank(user);
        IERC20(USDT).approve(address(swapApp), addAmount);
        uint256 lpTokens = swapApp.addLiquidity(addAmount, 700 * 1e18, path, 0, 0, deadline);
        require(lpTokens > 0, "Add liquidity failed");
        vm.stopPrank();

        // 2. Approve LP token for removal
        address lpTokenAddress = IFactory(swapApp.s_UniswapFactoryAddress()).getPair(USDT, DAI);
        vm.prank(user);
        IERC20(lpTokenAddress).approve(address(swapApp), lpTokens);

        // 3. Remove liquidity
        vm.startPrank(user);
        uint256 minUSDT = 900 * 1e6;   // ~ half of 2000 USDT minus small fee
        uint256 minDAI  = 700 * 1e18;
        swapApp.removeLiquidity(lpTokens, minUSDT, minDAI, user, deadline);
        vm.stopPrank();

        // After removal, user should have received both tokens
        assertGt(IERC20(USDT).balanceOf(user), 0);
        assertGt(IERC20(DAI).balanceOf(user), 0);
    }
}