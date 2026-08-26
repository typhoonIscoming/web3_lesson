# DEX简介

为什么要学习DEX

1. 构建链上金融体系
    DEX作为Web3金融体系的重要组成部分，与其他DeFi协议相互协作，共同构建了一个完整的链上金融生态系统。它可以与借贷协议、保险协议、衍生品协议等进行集成，实现资产跨链跳转、协议间激励博弈等功能，为用户提供更加丰富和多元化的金融服务。

2. 推动行业创新与竞争
    DEX的发展促使整个Web3行业不断创新和竞争。为了吸引用户和流动性，各个DEX不断进行技术创新和功能优化，降低交易成本，提高交易效率和安全性。同时，DEX之间的竞争也推动了行业的发展，使得整个Web3金融市场更加健康和活跃。

# 什么是DEX

在加密世界中，Uniswap 和 Blur 是广为人知的两个去中心化交易所典型代表。通常情况下，Uniswap 主要进行代币交易，而 Blur 聚焦于 NFT 交易。不过，规则并非绝对，如今 Uniswap 也具备了交易 NFT 的功能。

- 如何定义去中心化交易所
那么，怎样判断一个交易所是去中心化交易所呢？其实，最关键的一点在于其交易是否通过智能合约处理，而非借助中心化的服务器。若交易由智能合约来处理，那么这个交易所就属于去中心化交易所。

以 Uniswap 为例，当用户进行代币交易时，网站会提示用户连接钱包，经用户使用钱包签名交易后，最终由智能合约完成整个交易过程。在这个流程里，Uniswap 不存在自己的服务器来处理交易，完全依靠智能合约运作。想象一下，即便 Uniswap 的网站服务器出现故障，用户依然能够通过调用智能合约来完成交易。

与去中心化交易所相对的，是像 币安、OKX 这类中心化交易所。在使用这类交易所时，用户需要完成邮箱注册、实名认证、绑定手机、设置密码等一系列操作，随后借助币安的服务器完成交易。由于这种交易所的服务器是中心化的，一旦币安的服务器出现问题，用户便无法正常交易。

- 去中心化交易所的必要性

    当下，中心化交易所貌似功能更强大，交易速度和效率更高。那么，为何还需要去中心化交易所呢？答案显然易见，除了能避免因服务器故障影响交易外，去中心化交易所还有诸多显著优势。

    + 安全性保障
        很多人首先会想到的就是安全性。在去中心化交易所中，资产由用户自行掌控，相对而言更加安全。这的确是一项重要优势，但并非唯一优势。就像 2022 年 11 月，全球第二大加密货币交易所 FTX 破产，这一事件震惊了整个行业。美国证券交易委员会（SEC）经过调查发现，自FTX创立起，其创始人就开始挪用客户资金。这种中心化控制下的安全问题，是去中心化交易所极力避免的。

    + 利率与手续费自主性
        除了安全问题，中心化交易所还存在利率和手续费控制方面的弊端。在大型的银行和金融机构，也会对金融体系实现一定程度的掌控。而 DeFi（去中心化金融）正是为了打破这种中心化控制而兴起，去中心化交易所正是 DeFi 中的关键组成部分。

    + 高效与透明性
        去中心化交易所具备更高的效率和透明度，它能够 24 小时不间断地运作，且交易公开透明。同时，它更容易与其他 DeFi 项目进行整合，例如与借贷协议整合，从而实现更多样化的金融服务。这些服务是通过开放且透明的智能合约来实现的，这不仅降低了搭建金融服务的成本，还大大提高了效率。

        举个例子，假如某个项目想要发行自己的资产供用户交易。在传统的中心化交易所，这可能需要与交易所签订繁琐的合同，并让研发人员与系统进行对接，整个流程复杂且不可靠。然而在去中心化交易所中，只需要简单两步即可。第一步，将资产通过智能合约发布到链上；第二步，把资产加入去中心化交易所的流动性池，这样用户就能进行交易了。

    + 塑造金融新格局
        随着 DeFi 的不断发展，金融服务将变得愈发便捷，区块链技术也必将重塑金融服务的格局。作为整个去中心化金融体系下的重要基础设施，去中心化交易所的重要性不言而喻。


- 实现去中心化交易所的关键考量

    要实现一个去中心化交易所，除了用户操作页面外，智能合约是重中之重。智能合约承担着处理用户交易请求、保障交易安全与透明的重任。对于负责交易处理的智能合约而言，最关键的就是如何在合适的时间以合适的价格，确保各种资产安全完成交易。

    像 Blur 这类专注于 NFT 交易的交易所，交易逻辑相对简单。卖方可以指定一个价格，授权合约进行出售，买方随后授权合约购买；或者买家出价，卖家出售，整个交易过程由智能合约保障，无需三方担保，由智能合约管理资金和资产，这就是订单薄交易所的模式。

    然而，这种模式对于 FT（同质化代币）交易来说就有些力不从心了。因为 FT 交易量大，对流动性的要求极高，需要更高效的交易模式。通过订单薄进行交易，无论是存储还是撮合等操作都需要执行合约，这会消耗大量 Gas（即区块链上执行合约所需的手续费）。

    所以，针对去中心化代币交易所，需要更高效的交易模式，也就是 AMM（自动化做市商）。从技术层面讲，AMM 就是智能合约要实现的交易逻辑，它负责处理用户交易请求、管理资金池、计算价格，并确保有足够的流动性来支撑交易。

    简单来讲，可以通过引入流动性提供者（Liquidity Provider）来实现。这些 LP 会将一对资产存入资金池，并给出初始定价。交易者无需像 NFT 交易那样等待买家，可直接在流动性池中随时买卖，而资产价格会随着持续的交易行为而变动。LP 在这个过程中能够获得相应激励。

# Uniswap 基本介绍
Uniswap 是以太坊上最大的去中心化交易所（DEX），我们在上一讲中提到了，Uniswap 这样的去中心化交易所采用的不是订单薄交易的方式，而是由 LP 提供流动性来交易，这个流动性池子中的代币如何定价则成为了去中心化交易所的关键。Uniswap 在其流动性池上构建了一种特定的自动做市商（AMM）机制。称为恒定乘积做市商（Constant Product Market Makers，CPMM）。顾名思义，其核心是一个非常简单的乘积公式： $$ x∗y=k $$ 流动性池是一个持有两种不同 token 的合约， x 和 y 分别代表 token0 的数目和 token1 的数目， k 是它们的乘积，当 swap 发生时，token0 和 token1 的数量都会发生变化，但二者乘积保持不变，仍然为 k 。

另外，我们一般说的 token0 的价格是指在流动性池中相对于 token1 的价格，价格与数量互为倒数，因此公式为： $$ P=y/x $$ 就比如说我作为 LP 在池子中放了 1 个 ETH(token0) 和 3000 个 USDT(token1)，那么 k 就是 1*3000=3000，ETH 价格就是 3000/1 = 3000U。那你作为交易方就可以把大概 30 USDT 放进去，拿出来 0.01 个 ETH。然后池子里面就变成了 3030 个 USDT 和 0.99 个 ETH，价格变 3030/0.99≈3030U。ETH 涨价了，这样是不是就解决了定价的问题，有人要换 ETH，ETH 变得稀缺，所以涨价了，下次要换 ETH 就需要更多的 USDT，只要保证池子中的 ETH * USDT 等于一个常量，这样自然就会此消彼长，当 ETH 变少时，你要通过 USDT 换取 ETH 时候就需要消耗更多 USDT，反之亦然。

当然上面的例子没有考虑滑点、手续费、取整等细节，实际合约实现时也有很多细节需要考虑。这里只是为了让大家理解基础逻辑，具体的细节会在后面展开。

Uniswap 到目前已经迭代了好几个版本，下面是各个版本的发展历程：

2018 年 11 月 Uniswap V1 发布，创新性地采用了上述 CPMM，支持 ERC-20 和 ETH 的兑换，为后续版本的 Uniswap 奠定了基础，并成为其他 AMM 协议的启示；

2020 年 5 月 Uniswap V2 发布， 在 V1 的基础上引入了 ERC-20 之间的兑换，以及时间加权平均价格（TWAP）预言机，增加交易对的灵活性，巩固了 Uniswap 在 DEX 的领先地位；

2021 年 5 月 Uniswap V3 发布，引入了集中流动性（Concentrated Liquidity），允许 LP 在交易对中定义特定的价格范围，以实现更精确的价格控制，提升了 LP 的资产利用率；

2023 年 6 月 Uniswap V4 公开了白皮书的草稿版本，引入了 Hook、Singleton、Flash Accounting 和原生 ETH 等多个优化，其中 Hook 是最重要的创新机制，给开发者提供了高度自定义性。

2025年1月Uniswap V4 发布，V4 版本在算法上并没有改变，依然还是采用集中流动性，但通过 Hooks 实现了可定制的池，单例合约和闪电记账大幅度降低了 gas 成本，对原生 ETH 的支持也同样减少了 gas，还有对动态费用的支持、ERC1155 的支持等，都大大提高了 Uniswap 的灵活性、可扩展性。

# Uniswap V3 代码解析
如上所说，Uniswap 核心就是要基于 CPMM 来实现一个自动化做市商，除了用户调用的交易合约外，还需要有提供给 LP 管理流动性池子的合约，以及对流动性的管理。这些功能在不同的合约中实现，在 Uniswap 的架构中，Uniswap V3 的合约大概被分为两类，分别存储在不同的仓库中：

[uniawap v3白皮书](https://github.com/adshao/publications/blob/master/uniswap/dive-into-uniswap-v3-whitepaper/README_zh.md)

![](https://github.com/WTFAcademy/WTF-Dapp/blob/main/P002_WhatIsUniswap/img/uniswapv3.jpg)

- Uniswap v3-periphery
    面向用户的接口代码，如头寸管理、swap 路由等功能，Uniswap 的前端界面与 periphery 合约交互，主要包含三个合约：
        + NonfungiblePositionManager.sol：对应头寸管理功能，包含交易池（又称为流动性池或池子，后文统一用交易池表示）创建以及流动性的添加删除；
        + NonfungibleTokenPositionDescriptor.sol：对头寸的描述信息；
        + SwapRouter.sol：对应 swap 路由的功能，包含单交易池 swap 和多交易池 swap。

- Uniswap v3-core
    Uniswap v3 的核心代码，实现了协议定义的所有功能，外部合约可直接与 core 合约交互，主要包含三个合约；
        + UniswapV3Factory.sol：工厂合约，用来创建交易池，设置 Owner 和手续费等级；
        + UniswapV3PoolDeployer.sol：工厂合约的基类，封装了部署交易池合约的功能；
        + UniswapV3Pool.sol：交易池合约，持有实际的 Token，实现价格和流动性的管理，以及在当前交易池中 swap 的功能。

我们主要解析核心流程，包括以下：
1. 部署交易池；
2. 创建/添加/减少流动性；
3. swap。

其中 1 和 2 都是合约提供给 LP 操作的功能，通过部署交易池和管理流动性来提供和管理流动性。而 3 则是提供给普通用户使用 Uniswap 的核心功能（甚至可以说是唯一的功能）swap，也就是交易。接下来我们将依次讲解 Uniswap 中的相关代码。

## 部署交易池

在 Uniswap V3 中，通过合约 [UniswapV3Pool](https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Pool.sol#L30) 来定义一个交易池子，Uniswap 最核心的交易功能在最底层就是调用了该合约的 swap 方法。

而不同的交易对，以及不同的费率和价格区间（后面会具体讲到 tickSpacing）都会部署不同的 UniswapV3Pool 合约实例来负责交易。部署交易池则是针对某一对 token 以及指定费率的和价格区间来部署一个对应的交易池，当部署完成后再次出现同样条件下的交易池则不再需要重复部署了。

部署交易池调用的是 NonfungiblePositionManager 合约的 [createAndInitializePoolIfNecessary](https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/PoolInitializer.sol#L13)，参数为：

- token0：token0 的地址，需要小于 token1 的地址且不为零地址；
- token1：token1 的地址；
- fee：以 1,000,000 为基底的手续费费率，Uniswap v3 前端界面支持四种手续费费率（0.01%，0.05%、0.30%、1.00%），对于一般的交易对推荐 0.30%，fee 取值即 3000；
- sqrtPriceX96：当前交易对价格的算术平方根左移 96 位的值，目的是为了方便合约中的计算。

代码为：
```sol
/// @inheritdoc IPoolInitializer
function createAndInitializePoolIfNecessary(
    address token0,
    address token1,
    uint24 fee,
    uint160 sqrtPriceX96
) external payable override returns (address pool) {
    require(token0 < token1);
    pool = IUniswapV3Factory(factory).getPool(token0, token1, fee);

    if (pool == address(0)) {
        pool = IUniswapV3Factory(factory).createPool(token0, token1, fee);
        IUniswapV3Pool(pool).initialize(sqrtPriceX96);
    } else {
        (uint160 sqrtPriceX96Existing, , , , , , ) = IUniswapV3Pool(pool).slot0();
        if (sqrtPriceX96Existing == 0) {
            IUniswapV3Pool(pool).initialize(sqrtPriceX96);
        }
    }
}
```
逻辑非常直观，首先将 token0，token1 和 fee 作为三元组取出交易池的地址 pool，如果取出的是零地址则创建交易池然后初始化，否则继续判断是否初始化过（当前价格），未初始化过则初始化。

我们分别看创建交易池的方法和初始化交易池的方法。

创建交易池

创建交易池调用的是 UniswapV3Factory 合约的 [createPool](https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Factory.sol#L35)，参数为：

- token0：token0 的地址
- token1 地址：token1 的地址；
- fee：手续费费率。

代码为：
```sol
/// @inheritdoc IUniswapV3Factory
function createPool(
    address token0,
    address token1,
    uint24 fee
) external override noDelegateCall returns (address pool) {
    require(token0 != token1);
    (address token0, address token1) = token0 < token1 ? (token0, token1) : (token1, token0);
    require(token0 != address(0));
    int24 tickSpacing = feeAmountTickSpacing[fee];
    require(tickSpacing != 0);
    require(getPool[token0][token1][fee] == address(0));
    pool = deploy(address(this), token0, token1, fee, tickSpacing);
    getPool[token0][token1][fee] = pool;
    // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
    getPool[token1][token0][fee] = pool;
    emit PoolCreated(token0, token1, fee, tickSpacing, pool);
}
```
通过 fee 获取对应的 tickSpacing，要解释 tickSpacing 必须先解释 tick。
```sol
int24 tickSpacing = feeAmountTickSpacing[fee];
```
tick 是 V3 中价格的表示，如下图所示：

![](https://github.com/MetaNodeAcademy/Base2_Solidity_Dex/blob/main/img/tick.webp)

在 V3，整个价格区间由离散的、均匀分布的 ticks 进行标定。因为在 Uniswap V3 中 LP 添加流动性时都会提供一个价格的范围（为了 LP 可以更好的管理头寸），要让不同价格范围的流动性可以更好的管理和利用，需要 ticks 来将价格划分为一个一个的区间，每个 tick 有一个 index 和对应的价格： $$ P(i)=1.0001i $$ P(i) 即为 tick 在 i 位置的价格. 后一个价格点的价格是前一个价格点价格基础上浮动万分之一。我们可以得到关于 i 的公式： $$ i=log1.0001⁡(P(i)) $$ V3 规定只有被 tickSpacing 整除的 tick 才允许被初始化，tickSpacing 越大，每个 tick 流动性越多，tick 之间滑点越大，但会节省跨 tick 操作的 gas。

随后确认对应的交易池合约尚未被创建，调用 [deploy](https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3PoolDeployer.sol#L27)，参数为工厂合约地址，token0 地址，token1 地址，fee，以及上面提到的 tickSpacing。
```sol
pool = deploy(address(this), token0, token1, fee, tickSpacing);
```

## 初始化交易池

初始化交易池调用的是 UniswapV3Factory 合约的 [initialize](https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Pool.sol#L271)，参数为当前价格 sqrtPriceX96，含义上面已经介绍过了

代码如下：
```sol
/// @inheritdoc IUniswapV3PoolActions
/// @dev not locked because it initializes unlocked
function initialize(uint160 sqrtPriceX96) external override {
    require(slot0.sqrtPriceX96 == 0, 'AI');

    int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

    (uint16 cardinality, uint16 cardinalityNext) = observations.initialize(_blockTimestamp());

    slot0 = Slot0({
        sqrtPriceX96: sqrtPriceX96,
        tick: tick,
        observationIndex: 0,
        observationCardinality: cardinality,
        observationCardinalityNext: cardinalityNext,
        feeProtocol: 0,
        unlocked: true
    });

    emit Initialize(sqrtPriceX96, tick);
}
```
首先从 sqrtPriceX96 换算出 tick 的值。
```sol
int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
```
然后初始化预言机，cardinality 表示当前预言机的观测点数组容量， cardinalityNext 表示预言机扩容后的观测点数组容量，这里不详细解释。
```sol
(uint16 cardinality, uint16 cardinalityNext) = observations.initialize(_blockTimestamp());
```
最后初始化 slot0 变量，用于记录交易池的全局状态，这里主要就是记录价格和预言机的状态。
```sol
slot0 = Slot0({
    sqrtPriceX96: sqrtPriceX96,
    tick: tick,
    observationIndex: 0,
    observationCardinality: cardinality,
    observationCardinalityNext: cardinalityNext,
    feeProtocol: 0,
    unlocked: true
});
```
[Slot0](https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Pool.sol#L56)结构如下，源码中已经有了详细的注释。
```sol
struct Slot0 {
    // the current price
    uint160 sqrtPriceX96;
    // the current tick
    int24 tick;
    // the most-recently updated index of the observations array
    uint16 observationIndex;
    // the current maximum number of observations that are being stored
    uint16 observationCardinality;
    // the next maximum number of observations to store, triggered in observations.write
    uint16 observationCardinalityNext;
    // the current protocol fee as a percentage of the swap fee taken on withdrawal
    // represented as an integer denominator (1/x)%
    uint8 feeProtocol;
    // whether the pool is locked
    bool unlocked;
}
```
至此完成了交易池合约的初始化。

## 创建流动性

创建流动性调用的是 NonfungiblePositionManager 合约的 [mint](https://github.com/Uniswap/v3-periphery/blob/main/contracts/NonfungiblePositionManager.sol#L128)。

参数如下：
```sol
struct MintParams {
    address token0; // token0 地址
    address token1; // token1 地址
    uint24 fee; // 费率
    int24 tickLower; // 流动性区间下界
    int24 tickUpper; // 流动性区间上界
    uint256 amount0Desired; // 添加流动性中 token0 数量
    uint256 amount1Desired; // 添加流动性中 token1 数量
    uint256 amount0Min; // 最小添加 token0 数量
    uint256 amount1Min; // 最小添加 token1 数量
    address recipient; // 头寸接受者的地址
    uint256 deadline; // 过期的区块号
}
```
代码如下：

```sol
/// @inheritdoc INonfungiblePositionManager
function mint(MintParams calldata params)
    external
    payable
    override
    checkDeadline(params.deadline)
    returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    )
{
    IUniswapV3Pool pool;
    (liquidity, amount0, amount1, pool) = addLiquidity(
        AddLiquidityParams({
            token0: params.token0,
            token1: params.token1,
            fee: params.fee,
            recipient: address(this),
            tickLower: params.tickLower,
            tickUpper: params.tickUpper,
            amount0Desired: params.amount0Desired,
            amount1Desired: params.amount1Desired,
            amount0Min: params.amount0Min,
            amount1Min: params.amount1Min
        })
    );

    _mint(params.recipient, (tokenId = _nextId++));

    bytes32 positionKey = PositionKey.compute(address(this), params.tickLower, params.tickUpper);
    (, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, , ) = pool.positions(positionKey);

    // idempotent set
    uint80 poolId =
        cachePoolKey(
            address(pool),
            PoolAddress.PoolKey({token0: params.token0, token1: params.token1, fee: params.fee})
        );

    _positions[tokenId] = Position({
        nonce: 0,
        operator: address(0),
        poolId: poolId,
        tickLower: params.tickLower,
        tickUpper: params.tickUpper,
        liquidity: liquidity,
        feeGrowthInside0LastX128: feeGrowthInside0LastX128,
        feeGrowthInside1LastX128: feeGrowthInside1LastX128,
        tokensOwed0: 0,
        tokensOwed1: 0
    });

    emit IncreaseLiquidity(tokenId, liquidity, amount0, amount1);
}
```
梳理下整体逻辑，首先是 addLiquidity 添加流动性，然后调用 _mint 发送凭证（NFT）给头寸接受者，接着计算一个自增的 poolId，跟交易池地址互相索引，最后将所有信息记录到头寸的结构体中。

addLiquidity 方法定义在[这里](https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/LiquidityManagement.sol#L51)，核心是计算出 liquidity 然后调用交易池合约 mint 方法。

```sol
(amount0, amount1) = pool.mint(
    params.recipient,
    params.tickLower,
    params.tickUpper,
    liquidity,
    abi.encode(MintCallbackData({poolKey: poolKey, payer: msg.sender}))
);
```
liquidity ，即流动性，跟 tick 一样，也是 V3 中的重要概念。

在 V2 中，如果我们设定乘积 k=L2， L 就是我们常说的流动性，得出如下公式： $$ L=x∗y $$ V2 流动性池的流动性是分布在 0 到正无穷，如下图所示：
![](https://github.com/MetaNodeAcademy/Base2_Solidity_Dex/blob/main/img/liquidity.webp)

在 v3 中，每个头寸提供了一个价格区间，假设 token0 的价格在价格上界 a 和价格下界 b 之间波动，为了实现集中流动性，那么曲线必须在 x/y 轴进行平移，使得 a/b 点和 x/y 轴重合，如下图：
![](https://github.com/MetaNodeAcademy/Base2_Solidity_Dex/blob/main/img/liquidityv3.webp)

我们忽略推导过程，直接给出数学公式： $$ (x+L/Pb)∗(y+L∗Pa)=L^2 $$ 我们将图中的曲线分为两部分：起始点左边和起始点右边。在swap过程中，当前价格会朝着某个方向移动：升高或降低。对于价格的移动，仅有一种 token 会起作用：当前价格升高时，swap仅需要 token0；当前价格降低时，swap仅需要 token1。

当流动性提供者提供了 Δx 个 token0 时，意味着向起始点左边添加了如下流动性： $$ L=ΔxPb∗Pc/(Pb−Pc) $$ 当流动性提供者提供了 Δy 个 token1 时，意味着向起始点右边添加了如下流动性： $$ L=Δy/(Pc−Pa) $$ 如果当前价格超过价格区间属于只能添加单边流动性的情况。

当前价格小于下界 b 时，只有 Δy 个 token1 起作用，意味着向 b 点右边添加了如下流动性： $$ L=Δy/(Pb−Pa) $$ 当前价格大于上界 a 时，只有 Δx 个 token0 起作用，意味着向 a 点左边添加了如下流动性： $$ L=ΔxPb∗Pa/(Pb−Pa) $$ 回到代码，计算 liquidity 的步骤如下：
    1. 如果价格在价格区间内，分别计算出两边流动性然后取最小值；
    2. 如果当前价格超过价格区间则是计算出单边流动性。

交易池合约的 [mint](https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Pool.sol#L457)方法。

参数为：
- recipient：头寸接收者地址
- tickLower：流动性区间下界
- tickUpper：流动性区间上界
- amount：流动性数量
- data：回调参数

代码为：
```sol
/// @inheritdoc IUniswapV3PoolActions
/// @dev noDelegateCall is applied indirectly via _modifyPosition
function mint(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    uint128 amount,
    bytes calldata data
) external override lock returns (uint256 amount0, uint256 amount1) {
    require(amount > 0);
    (, int256 amount0Int, int256 amount1Int) =
        _modifyPosition(
            ModifyPositionParams({
                owner: recipient,
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: int256(amount).toInt128()
            })
        );

    amount0 = uint256(amount0Int);
    amount1 = uint256(amount1Int);

    uint256 balance0Before;
    uint256 balance1Before;
    if (amount0 > 0) balance0Before = balance0();
    if (amount1 > 0) balance1Before = balance1();
    IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(amount0, amount1, data);
    if (amount0 > 0) require(balance0Before.add(amount0) <= balance0(), 'M0');
    if (amount1 > 0) require(balance1Before.add(amount1) <= balance1(), 'M1');

    emit Mint(msg.sender, recipient, tickLower, tickUpper, amount, amount0, amount1);
}
```
首先调用 _modifyPosition 方法修改当前价格区间的流动性，这个方法相对复杂，放到后面专门讲。其返回的 amount0Int 和 amount1Int 表示 amount 流动性对应的 token0 和 token1 的代币数量。

调用 mint 方法的合约需要实现 IUniswapV3MintCallback 接口完成代币的转入操作：
```sol
IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(amount0, amount1, data);
```
IUniswapV3MintCallback 的实现在 periphery 仓库的 LiquidityManagement.sol 中。目的是通知调用方向交易池合约转入 amount0 个 token0 和 amount1 个 token2。
```sol
/// @inheritdoc IUniswapV3MintCallback
function uniswapV3MintCallback(
    uint256 amount0Owed,
    uint256 amount1Owed,
    bytes calldata data
) external override {
    MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));
    CallbackValidation.verifyCallback(factory, decoded.poolKey);

    if (amount0Owed > 0) pay(decoded.poolKey.token0, decoded.payer, msg.sender, amount0Owed);
    if (amount1Owed > 0) pay(decoded.poolKey.token1, decoded.payer, msg.sender, amount1Owed);
}
```
回调完成后会检查交易池合约的对应余额是否发生变化，并且增量应该大于 amount0 和 amount1：这意味着调用方确实转入了所需的资产。
```sol
if (amount0 > 0) require(balance0Before.add(amount0) <= balance0(), 'M0');
if (amount1 > 0) require(balance1Before.add(amount1) <= balance1(), 'M1');
```
至此完成了流动性的创建。

## 增加流动性

添加流动性调用的是 NonfungiblePositionManager 合约的 [increaseLiquidity](https://github.com/Uniswap/v3-periphery/blob/main/contracts/NonfungiblePositionManager.sol#L198)。

参数如下：
```sol
struct IncreaseLiquidityParams {
    uint256 tokenId; // 头寸 id
    uint256 amount0Desired; // 添加流动性中 token0 数量
    uint256 amount1Desired; // 添加流动性中 token1 数量
    uint256 amount0Min; // 最小添加 token0 数量
    uint256 amount1Min; // 最小添加 token1 数量
    uint256 deadline; // 过期的区块号
}
```
代码如下：
```sol
/// @inheritdoc INonfungiblePositionManager
function increaseLiquidity(IncreaseLiquidityParams calldata params)
    external
    payable
    override
    checkDeadline(params.deadline)
    returns (
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    )
{
    Position storage position = _positions[params.tokenId];

    PoolAddress.PoolKey memory poolKey = _poolIdToPoolKey[position.poolId];

    IUniswapV3Pool pool;
    (liquidity, amount0, amount1, pool) = addLiquidity(
        AddLiquidityParams({
            token0: poolKey.token0,
            token1: poolKey.token1,
            fee: poolKey.fee,
            tickLower: position.tickLower,
            tickUpper: position.tickUpper,
            amount0Desired: params.amount0Desired,
            amount1Desired: params.amount1Desired,
            amount0Min: params.amount0Min,
            amount1Min: params.amount1Min,
            recipient: address(this)
        })
    );

    bytes32 positionKey = PositionKey.compute(address(this), position.tickLower, position.tickUpper);

    // this is now updated to the current transaction
    (, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, , ) = pool.positions(positionKey);

    position.tokensOwed0 += uint128(
        FullMath.mulDiv(
            feeGrowthInside0LastX128 - position.feeGrowthInside0LastX128,
            position.liquidity,
            FixedPoint128.Q128
        )
    );
    position.tokensOwed1 += uint128(
        FullMath.mulDiv(
            feeGrowthInside1LastX128 - position.feeGrowthInside1LastX128,
            position.liquidity,
            FixedPoint128.Q128
        )
    );

    position.feeGrowthInside0LastX128 = feeGrowthInside0LastX128;
    position.feeGrowthInside1LastX128 = feeGrowthInside1LastX128;
    position.liquidity += liquidity;

    emit IncreaseLiquidity(params.tokenId, liquidity, amount0, amount1);
}
```

























