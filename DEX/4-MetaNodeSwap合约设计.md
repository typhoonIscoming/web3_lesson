# MetaNodeSwap合约设计

## 合约需求描述

MetaNodeSwap 设计每个池子都有一个价格范围，swap 只能在此价格范围内成交

1. 任何人都可以创建池子，创建池子可以指定当前价格、价格范围： [a, b] 和 费率 f；相同交易对和费率可以有多个池子；不能删除和修改池子；
2. 任何人都可以添加流动性，添加流动性只能在指定价格范围 [a, b]，不能自定义范围；
3. 流动性提供者可以减少添加的流动性，并提取减少流动性对应的两种代币；
4. 流动性提供者可以在任何人 swap 过程收取手续费，手续费为 f，按流动性贡献加权平分给流动性提供者；
5. 任何人都可以 swap，swap 需要指定某个池子，swap 可以指定输入（最大化输出）或者指定输出（最小化输入），如果指定的池子的流动性不足，则只会部分成交。

以上手续费的收取方式和 Uniswap 有所差异，做了简化，会在后续手续费实现的章节继续展开说明。

## 合约结构

以简单为原则，我们不按照 Uniswap V3 将合约分为 periphery 和 core 两个独立仓库，而是自顶向下分为以下四个合约。

- PoolManager.sol: 顶层合约，对应 Pool 页面，负责 Pool 的创建和管理。
- PositionManager.sol: 顶层合约，对应 Position 页面，负责 LP 头寸和流动性的管理。
- SwapRouter.sol: 顶层合约，对应 Swap 页面，负责预估价格和交易。
- Factory.sol: 底层合约，Pool 的工厂合约；
- Pool.sol: 最底层合约，对应一个交易池，记录了当前价格、头寸、流动性等信息。

下面是合约的 UML 图：

![](https://github.com/MetaNodeAcademy/Base2_Solidity_Dex/blob/main/img/uml.png)

## 合约接口设计

因为我们是自顶向下设计合约，因此我们首先分析前端页面（Pool 页面、Position 页面和 Swap 页面）需要哪些功能，并为此设计出顶层合约，再进一步分析细节，设计出底层合约。

### PoolManager

`PoolManager.sol` 对应 Pool 页面，我们首先来看 Pool 页面有哪些功能。

首先是展示所有的 pool ，对应前端页面如下：

![](https://github.com/MetaNodeAcademy/Base2_Solidity_Dex/blob/main/img/pool.png)

对应我们需要有接口支持 DApp 前端获取所有的交易池。在 Uniswap 中，这个接口是通过服务端提供的，服务端拉取链上的合约信息，然后返回给前端。但是我们的设计是直接调用合约获取当前可供交易的交易池，使得 DApp 不依赖于服务端（当然，对于实际项目来说，依赖服务端可能更合适）。为此，我们定义了 getAllPools 接口，用于获取所有的交易池，定义 PoolInfo 保存每个池子的信息。

```sol
struct PoolInfo {
    address token0;
    address token1;
    uint32 index;
    int24 fee;
    int24 tickLower;
    int24 tickUpper;
    int24 tick;
    uint160 sqrtPriceX96;
    uint128 liquidity;
}
function getAllPools() external view returns (PoolInfo[] memory poolsInfo);
```
每个 pool 的信息包括：
- token 对的符号以及数量；
- 费率;
- 价格范围；
- 当前价格；
- 流动性。

此外还有一个添加池子的操作，当添加头寸时如果发现还没有对应的池子，需要先创建一个池子。

参数包括：
- token0 的地址和数量；
- token1 的地址和数量；
- 费率（百分比）；
- 价格范围；
- 当前价格。

token0 的数量不为 0 或 token1 的数量不为 0 意味着添加初始流动性。

接口定义如下：
```sol
struct CreateAndInitializeParams {
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    uint160 sqrtPriceX96;
}

function createAndInitializePoolIfNecessary(
    CreateAndInitializeParams calldata params
) external payable returns (address pool);
```






































































































