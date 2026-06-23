// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {SwapApp} from "../src/SwapApp.sol";

contract SwapAppScript is Script {
    SwapApp public swapApp;

    address public feeReceiver = makeAddr("FEE_RECEIVER");
    address public addressUniSwapRouterV2 = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address public addressUniSwapFactory = 0xf1D7CC64Fb4452F05c498126312eBE29f30Fbcf9;
    address public USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; // USDT address un arbitrum mainnet
    address public DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1; // DAI address un arbitrum mainnet

    // function setUp() public {}

    function run() public returns(SwapApp, address) {
        vm.startBroadcast();

        swapApp = new SwapApp(feeReceiver, addressUniSwapRouterV2, addressUniSwapFactory, USDT, DAI);

        vm.stopBroadcast();

        return (swapApp, addressUniSwapRouterV2);
    }
}
