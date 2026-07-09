// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IFactory {

    /**
     * @dev Get the pair address for token A and token B
     * @param tokenA Token A
     * @param tokenB Token B
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    
}