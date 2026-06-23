// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IV2Router02} from "./IV2Router02.sol";
import {IFactory} from "./IFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SwapApp {

    using SafeERC20 for IERC20;

    address public s_FeeReceiver;
    address public s_V2Router02Address;
    address public s_UniswapFactoryAddress;
    address public USDT;
    address public DAI;

    uint256 private s_totalFeeReceived;
    uint256 private constant PERCENTAGE_BASIS = 1000;
    uint256 private s_feeBasisPoints = 25;

    event SwapTokens(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event AddLiquidity(address token0, address token1, uint256 lpTokenAmount);

    constructor(address _feeReceiver, address _V2Router02Address, address _uniswapFactoryAddress, address _usdt, address _dai) {
        s_FeeReceiver = _feeReceiver;
        s_V2Router02Address = _V2Router02Address;
        s_UniswapFactoryAddress = _uniswapFactoryAddress;
        USDT = _usdt;
        DAI = _dai;
    }

    function swapTokens(uint256 _amountIn, uint256 _amountOutMin, address[] memory _path, address _to, uint256 _deadline) public returns(uint256) {
        
        uint256 fee = (_amountIn * getFeeBasisPoints()) / getPercentageBasis();
        uint256 amountIn = _amountIn - fee;

        IERC20(_path[0]).safeTransferFrom(msg.sender, address(this), _amountIn);

        IERC20(_path[0]).approve(s_V2Router02Address, amountIn);

        uint[] memory amounts = IV2Router02(s_V2Router02Address).swapExactTokensForTokens(amountIn, _amountOutMin, _path, _to, _deadline);

        IERC20(_path[0]).safeTransfer(s_FeeReceiver, fee);
        
        s_totalFeeReceived += fee;
        
        uint256 amountOut = amounts[amounts.length - 1];

        emit SwapTokens(_path[0], _path[_path.length - 1], _amountIn, amountOut);
        return amountOut;

    }

    function addLiquidity(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        uint _amountAMin,
        uint _amountBMin,
        uint _deadline
    ) external returns (uint256) {

        IERC20(USDT).safeTransferFrom(msg.sender, address(this), _amountIn);

        uint256 half = _amountIn / 2;
        uint256 fee = (half * getFeeBasisPoints()) / getPercentageBasis();
        uint256 netSwap = half - fee;          // USDT to swap

        IERC20(USDT).approve(s_V2Router02Address, netSwap);
        uint[] memory amounts = IV2Router02(s_V2Router02Address).swapExactTokensForTokens(
            netSwap,
            _amountOutMin,
            _path,
            address(this),
            _deadline
        );
        uint256 swappedDAI = amounts[amounts.length - 1];

        IERC20(USDT).safeTransfer(s_FeeReceiver, fee);
        s_totalFeeReceived += fee;

        uint256 usdtForLP = half;

        IERC20(USDT).approve(s_V2Router02Address, usdtForLP);
        IERC20(DAI).approve(s_V2Router02Address, swappedDAI);

        (,, uint256 lpTokenAmount) = IV2Router02(s_V2Router02Address).addLiquidity(
            USDT,
            DAI,
            usdtForLP,
            swappedDAI,
            _amountAMin,
            _amountBMin,
            msg.sender,    // LP tokens go directly to user
            _deadline
        );

        emit AddLiquidity(USDT, DAI, lpTokenAmount);
        return lpTokenAmount;
    }

    function removeLiquidity(
        uint256 _liquidityAmount,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    ) external {
        address lpTokenAddress = IFactory(s_UniswapFactoryAddress).getPair(USDT, DAI);

        // Pull LP tokens from caller
        IERC20(lpTokenAddress).safeTransferFrom(msg.sender, address(this), _liquidityAmount);
        IERC20(lpTokenAddress).approve(s_V2Router02Address, _liquidityAmount);

        IV2Router02(s_V2Router02Address).removeLiquidity(
            USDT,
            DAI,
            _liquidityAmount,
            _amountAMin,
            _amountBMin,
            _to,
            _deadline
        );
    }

    function getTotalFeeReceived() external view returns(uint256 totalFeeReceived) {
        totalFeeReceived = s_totalFeeReceived;
    }

    function getFeeBasisPoints() public view returns(uint256 feeBasisPoints) {
        feeBasisPoints = s_feeBasisPoints;
    }

    function getPercentageBasis() public pure returns(uint256 percentageBasis) {
        percentageBasis = PERCENTAGE_BASIS;
    }
    
}
