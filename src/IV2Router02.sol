// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IV2Router02 {

    /**
     * @dev Uniswap function to swap exact tokens for other tokens
     * @param amountIn Input Amount
     * @param amountOutMin Minimum amount Out
     * @param path Array of token address for the swap
     * @param to Address to send the tokens
     * @param deadline Time allowed to expect for the swap
     * @return amounts Array of amounts
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    /**
     * @dev Add liquidity
     * @param tokenA Token A
     * @param tokenB Token B
     * @param amountADesired Amount expected from token A 
     * @param amountBDesired Amount expected from token B
     * @param amountAMin Minimum amount of token A
     * @param amountBMin Minimum amount of token B
     * @param to address to receive tokens
     * @param deadline Time allowed to expect for the transaction
     * @return amountA Input amount of token A
     * @return amountB Input amount of token B
     * @return liquidity 
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    /**
     * @dev Remove liquidity
     * @param tokenA Token A
     * @param tokenB Token B
     * @param liquidity liquidity
     * @param amountAMin Minimum amount of token A
     * @param amountBMin Minimum amount of token B
     * @param to Address to send tokens
     * @param deadline Time allowed to expect for the transaction
     * @return amountA Amount A received
     * @return amountB Amount B received
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    
}