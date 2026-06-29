<div align="center">
  <h1>🔄 Dex Swap Application with Liquidity Pool</h1>
  <p><b>A high-performance, secure DeFi routing layer enabling automated asset swaps and dual-sided liquidity management via Uniswap V2 protocols.</b></p>
</div>

## 📖 About the Project

The **Dex Swap Application with Liquidity Pool** is a production-ready Web3 smart contract infrastructure built with **Solidity `0.8.30`** and engineered using the **Foundry** development framework. The system operates as an optimized routing wrapper around Uniswap V2 AMM architectures, enabling frictionless token swaps and automated liquidity management while maintaining a dedicated protocol monetization layer.

The core implementation addresses a common DeFi UX friction point: **Single-Asset Liquidity Provisioning**. Instead of forcing users to manually swap halves of their portfolios to supply a liquidity pool, this contract handles the structural split, asset conversion, protocol fee deduction, and Uniswap V2 interaction atomically within a single transaction block.

### Key Technical Highlights:
* **Solidity `0.8.30`:** Leverages modern EVM compiler features for absolute code clarity, safety, and optimal gas optimization.
* **OpenZeppelin Integration:** Implements industry-standard `IERC20` and `SafeERC20` libraries to defend against reentrancy, zero-address transfers, and idiosyncratic token behavior (such as USDT's non-standard return values).
* **Foundry Testing Suite:** Validated entirely using live mainnet-fork simulations via the Arbitrum network, ensuring real-world environment accuracy and precise pool slippage calculations.
* **Integrated Fee Engine:** Implements a transparent basis-point fee calculation framework that redirects a micro-percentage of transactional volume to a protocol treasury before protocol interaction.

---

## ⚙️ How It Works

The architecture relies on the interplay between the primary application layout (`SwapApp.sol`) and the external AMM ecosystem (`IV2Router02` and `IFactory`). The system accepts standard ERC20 inputs, applies mathematical fee transformations, handles the underlying router allowances, and completes the requested actions.

### Architecture Diagram

![Project Diagram](./images/diagram.png)

### Core Component File Paths
* [`SwapApp.sol`](./src/SwapApp.sol) — Primary business logic, fee accounting, and external protocol orchestration.
* [`IV2Router02.sol`](./src/IV2Router02.sol) — Structural interface wrapping Uniswap V2 router behaviors.
* [`IFactory.sol`](./src/IFactory.sol) — Factory interface utilizing cryptographic pair-matching algorithms.
* [`SwapAppScript.s.sol`](./script/SwapAppScript.s.sol) — Automated deployment and environment scripting.

---

## 💻 Technical Docs

The primary interaction surface of the application centers around three core routines: direct asset swapping, single-asset liquidity generation, and structural liquidity extraction.

### swapTokens
Allows users to swap an exact amount of input tokens for an alternative token asset along a specified route, extracting a protocol fee prior to execution.

```solidity
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
```

### addLiquidity
Accepts a single asset input (USDT), automatically splits it, swaps a precise half into the target asset (DAI), and supplies both symmetrically to the target Liquidity Pool—returning the resulting LP tokens directly to the caller.

```Solidity
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
        uint256 netSwap = half - fee;

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
```

### removeLiquidity
Pulls Uniswap V2 LP tokens from the user's wallet, authorizes the underlying V2 router, and unpacks the pool shares back into raw underlying asset balances delivered directly to the caller.

```Solidity
    function removeLiquidity(
        uint256 _liquidityAmount,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    ) external {
        address lpTokenAddress = IFactory(s_UniswapFactoryAddress).getPair(USDT, DAI);
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
```

🚀 Execution ExampleThe following scenario details how a user capitalizes on single-asset liquidity placement using this architecture:
- Step 1: Initialization & Infrastructure Mapping The SwapApp contract is deployed using SwapAppScript.s.sol. The deployment defines explicit Arbitrum mainnet coordinates for the Uniswap V2 Router (0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24), the Factory (0xf1D7CC64Fb4452F05c498126312eBE29f30Fbcf9), and the respective token contract targets.
- Step 2: Allowance Authorization A user wishes to inject 200 USDT into the liquidity pool. The user triggers an approve() command directly on the native USDT contract, granting the SwapApp contract permission to handle 200 * 10^6 units (accounting for USDT's 6 decimal format).
- Step 3: Atomic Request Dispatched The user calls addLiquidity() on the SwapApp. The contract safely transfers the 200 USDT into its own custody. It segments the funds into two 100 USDT parts.
- Step 4: Fee Application & Internal Asset Swap The contract calculates a 2.5% protocol fee ($25$ basis points) on the swapping half (100 USDT), sending 0.25 USDT directly to the feeReceiver registry. The remaining 99.75 USDT is automatically routed through Uniswap V2 to acquire its market equivalent in DAI (scaled to 18 decimals).
- Step 5: Liquidity Seeding Completed The contract approves the Uniswap V2 Router to spend the remaining 100 USDT and the newly acquired DAI balance. It triggers addLiquidity on the V2 router, which mints the pair's LP pool shares and forwards them seamlessly back to the user's wallet address.

⬆️ InstallationEnsure you have Foundry installed on your machine. Install the required project dependencies (OpenZeppelin Contracts and Forge Standard Library) using the command below:
```Bash
forge install OpenZeppelin/openzeppelin-contracts foundry-rs/forge-std
```

🧪 TestingTo execute the test suites, simulate live market mechanics, and run structural assertions against the Arbitrum mainnet deployment environment, run:
```Bash
forge test -vvvv --fork-url [https://arb1.arbitrum.io/rpc](https://arb1.arbitrum.io/rpc)
```

📊 Coverage To evaluate code path execution and calculate the explicit statement-by-statement testing metrics across the mainnet fork simulation environment, run:
```Bash
forge coverage --fork-url [https://arb1.arbitrum.io/rpc](https://arb1.arbitrum.io/rpc)
```

📜 Contract Addresses of the Target Network: Arbitrum One (Mainnet)
------------------------------------------------------------
- Uniswap V2 Router:  0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
- Uniswap V2 Factory: 0xf1D7CC64Fb4452F05c498126312eBE29f30Fbcf9
- USDT Contract:      0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9
- DAI Contract:       0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1
- SwapApp Contract:   [Deploy and paste your contract address here]