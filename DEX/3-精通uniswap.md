Uniswap是DeFi中最著名的协议之一，Uniswap本质是一个自动化做市商（AMM），它舍弃了传统订单薄的撮合方式，采用流动池加恒定乘积公式算法(`x×y=k`)为不同加密资产提供即时报价和兑换服务。

# 什么是Uniswap
关于什么是Uniswap，先看一下Uniswap白皮书中的定义：

> Uniswap is a protocol for automated token exchange on Ethereum. It is designed around ease-of-use, gas efficiency, censorship resistance, and zero rent extraction.

Uniswap是一个基于以太坊的自动代币交换协议，它的设计目标是：易用性、gas高利用率、抗审查性和零抽租。

- ease-of-use（易用性）：Token A换Token B，在Uniswap也只要发出一笔交易就能完成兑换，在其它交易所中可能需要发两笔交易：第一笔将Token A换成某种媒介货币，如ETH, DAI 等，然后再发第二笔交易换成Token B。
- gas efficiency（gas高利用率）：在Uniswap上消耗的gas量是以太坊上的几家主流去中化交易所中最低的，也就代表在Uniswap交易要付的矿工费最少。

![](https://github.com/MetaNodeAcademy/Base2_Solidity_Dex/blob/main/uni-img/70.png)

- censorship resistance（抗审查性）：抗审查性体现在Uniswap上架新Token没有门槛，任何人都能在Uniswap上架任何Token。这在去中心交易所中很少见，虽然大多数的去中心化交易所不会像中心化交易所那样向你收取上币费，但还是需要提交上币申请，通过审查后运营团队才会让你的Token可以在他们的交易所上交易。下面是各去中心化交易所上币规则的详情：

- KyberSwap上币规则：https://developer.kyber.network/docs/Reserves-ListingProcess/

- EtherDelta上币规则：https://steemit.com/cryptocurrency/@mindseye69/new-etherdelta-coin-listing-rules

- IDEX上币规则：https://medium.com/@forrestwhaling/idex-token-listing-guidelines-eae00785fdd2

- Uniswap上币规则：https://uniswap.org/docs/v1/frontend-integration/token-listing/

- zero rent extraction（零抽租）:在Uniswap协议设计中，开发团队不会从交易中抽取费用，交易中的所有费用都归还给流动性提供者。

## 自动化做市商（AMM）

传统的交易所有一个订单薄(Order Book)，订单薄上记录着买卖方向，数量和出价，交易所负责对买卖双方进行配对，一旦订单薄中最高价格低于或等于最低价格，就会促成交易，同时会产生一个新的成交价，传统交易所有以下特点：

- 市场上必须要有用户进行挂单，要有一定量的订单（市场流动）。
- 订单必须重叠才能成交，即买价高于或等于卖价。
- 需要将资产存储在交易所。

![](https://github.com/MetaNodeAcademy/Base2_Solidity_Dex/blob/main/uni-img/80.jpeg)

在订单薄模型市场中，买家期望用最低的价格买到想要的资产，而卖家则是期望用最高价格卖出同一项资产，如果交易要成立，买卖双方必须要在价格上达成共识，一是买家提高出价，二是卖家降低出价，如果双方都不要改变出价，这时候就要依靠做市商的参与，简单来说，做市商是一个促进交易的实体，它会在买卖两个方向上挂单，让想要交易的参与方只要跟做市商的订单撮合就能完成交易，而不需要等待对手方出现才能交易，极大的提高了市场的流动性。

为什么Uniswap不采用订单薄模型？

Uniswap部署在以太坊上，而以太坊每秒可以出来15笔左右的交易，这对于订单薄交易所来不可行，主要原因是：“订单薄模型依赖一个或多个外部做市商对某项资产一直不断的做市，而以太坊的TPS过低不支持做市商高频的交易，如果缺少了做市商，那么交易所的流动性立刻会降低，对于用户来说这样的交易所体验很差。”

Uniswap采用流动池加恒定乘法公式这种自动化做市商（AMM）模式实现了资产的交换，自动化做市商模式方式不需要买卖双方进行挂单，也不要买卖双方的订单重叠，可以进行自由买卖。

- 流动池：使用流动池来提供买卖双方交易，做市商只要把资金放入流动池即可
- 恒定乘法公式：按照流动池中Token的数量，自动计算买卖价格

## 流动池

流动池就是锁定在智能合约中所有的代币以及资金的总称，流动是资金转为代币，或代币转为资金的意思。

一个完整的流动池分为2个部份，分别表示不同的货币，成为一个交易对，在Uniswap V1中就是ETH及ERC20代币，在Uniswap V2中是支持不同ERC20代币直接交换，所以在Uniswap V2中的流动池可以允许两边是不相同的ERC20代币，其中ETH会自动转换成以WETH代币。为了简化，直接以ETH-ERC20交易对作为例子。

如下图所示，Uniswap将所有做市商的ETH集合在一起放在流动池左边， 将所有ERC20集合在一起放在流动池的右边。如果有用户要买ERC20代币，就从流动池的右边将ERC20代币转给用户，同时将用户支付的ETH添加的流动池的左边，然后重新计算流动池中的价格，等待下次交易。

![](https://github.com/MetaNodeAcademy/Base2_Solidity_Dex/blob/main/uni-img/70.1.jpeg)

Uniswap是无法自己变出钱来，因此需要依赖外部资金向合约中提供流动性，向Uniswap流动池中提供流动性的用户被称为流动性提供者，当流动性提供者向Uniswap中注入流动性的时候，Uniswap会铸造出一个流动性代币(LP)，铸出LP代币数量是与用户注入的资金所占流动池中的资金比例相关,动性提供者可以选择在任何时间销毁自己持有的流动性代币。为了鼓励用于向Uniswap的流动池中提供更多的流动性，Uniswap会从每笔交易总额中抽取0.3%当成交易手续费，并将手续费全额交给那些将注资金到Uniswap资金池提供流动性的流动性提供者。

## 恒定乘积公式

假设在Uniswap中存在一个ETH-DAI交易对的流动池，用户在使用DAI与ETH兑换时需要一个方法来决定交易价格。

Uniswap定价模型非常简洁，它的核心思想是一个恒定乘积公式$x×y=k$。其中x和 y分别代表流动池中两种资产的数量，k是两种资产数量的乘积。

`x×y=k`的函数图像如下

假设乘积k是一个固定不变的常量，当用户使用x资产从流动池中兑换y资产时，流动池中x资产的数量会增加，y资产的数量会减少。由于k是恒定的，所以当x增长$\Delta X$时，需要将y减少$\Delta Y$才能保持等式的恒定。

```text
(x + ΔX) × (y − ΔY) = k
```

这里没有考虑到手续费的问题，如果要计算手续费的话，公式如下：

$(x+\Delta X \gamma ) × (y-\Delta Y)=k'$

$k′ > k$

其中：$\rho =0.3%$ ，$\gamma =1- \rho$

ΔXγ 表示扣除手续费后加入到流动池中的资产。由于在流动池中增加了手续费所以计算出来的k'会大于k，详细过程会在后面推导。

接下来会有一些数学公式的推导，为了方便理解，我们先对不含手续费的情况进行推导，包含手续费的推导过程放在最后。

## 不含手续费

## 交易价格计算

交易价格的计算分成两种：
- InputPrice：向流动池中放入$\Delta X$个Token可以兑换出多少个$\Delta Y$ Token
- OutputPrice：从流动池中取出$\Delta Y$ 个Token，需要向流动池中放入多少个$\Delta X$ Token

$x'=x+\Delta x=(1+ \alpha )x = \frac{1}{1-\beta } x$

$y'=y-\Delta y=\frac{1}{1+\alpha }y=(1-\beta )y$

$xy=x'y'=k$

其中：$\alpha=\frac{\Delta x}{x}$，$\beta =\frac{\Delta y}{y}$
































































































































