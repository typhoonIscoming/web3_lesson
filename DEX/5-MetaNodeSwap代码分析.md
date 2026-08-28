# MetaNodeSwap代码分析

### Factory

`createPool`

我们通过 `pool = address(new Pool{salt: salt}());` 这一行代码创建了一个新的 Pool 合约，并通过 `pools[token0][token1].push(pool);` 将它的地址保存到 pools 中。

这里需要注意的是，我们通过添加了 salt 来使用CREATE2的方式来创建合约，这样的好处是创建出来的合约地址是可预测的，地址生成的逻辑是 `新地址 = hash("0xFF",创建者地址, salt, initcode)`。

而在我们的代码中 salt 是通过 abi.encode(token0, token1, tickLower, tickUpper, fee) 计算出来的，这样的好处是只要我们知道了 token0 和 token1 的地址，以及 tickLower、tickUpper 和 fee 这三个参数，我们就可以预测出来新合约的地址。在我们的教程设计中，这样似乎并没有什么用。但是在实际的 DeFi 场景中，这样会带来很多好处。比如其他合约可以直接计算出我们 Pool 合约的地址，这样可以开发出和 Pool 合约交互的更多的功能。

当然，这样也会带来一个问题，这样会使得我们不能通过合约的构造函数传参来传递 Pool 合约的初始化参数，因为那样会导致上面新地址计算中的 initcode 发生变化。所以我们在代码中引入了 parameters 这个变量来保存 Pool 合约的初始化参数，这样我们就可以在 Pool 合约中通过 parameters 来获取到初始化参数。

### PoolManager

`getPairs`

可以看到我们设计了一个 getPairs 方法用于返回数据。可能会有一些同学有这样的疑问，为什么要设计一个函数方法用于返回，合约里面的变量不是会自动生成对应的 getter 方法用于获取其值的吗？

是的没有错，solidity 是会自动给合约里面定义的 public 变量生成对应的 getter 方法，开发者可以不用再额外设计获取值的方法，但是对于变量是数组这个特殊情况，solidity 生成的 getter 方法并不会返回整个数据，而是需要调用者指定索引，只返回索引对应的值。这么设计的原因是避免一次返回过多的数据，在别的合约使用这份数据时产生不可控的 gas 费。

因此，对于数组这个特殊情况，如果我们需要它返回全部的内容，就需要自己写一个合约方法将其返回。获取到的数据供前端的token列表用。

### getAllPools

由于池子的信息是在 Factory 合约中保存的，因此我们在返回全部池子信息的时候，还需要对 Factory 保存的信息进行处理，处理成我们想要的数据格式。

这部分的逻辑比较清晰，通过遍历全部的池子信息，做一些数据转换就行。

获取到的数据供前端展示所有的pool信息。

### createAndInitializePoolIfNecessary

在创建完成池子之后，我们需要维护 DEX 整体池子的信息，该信息包含两部份，DEX 支持的交易对种类以及交易对的具体信息。前者主要是为了提供我们的 DEX 支持哪些 Token 间进行交易，后者主要是提供完整的池子信息。

在 Factory 合约中，每次创建完成一个池子，都会记录下它的信息，因此这个信息我们不需要再记录，我们需要记录的是交易对的种类，即在获得一个新的交易对时，动态地维护一个 pairs 数组。

需要注意的是，虽然 createPool 的入参 tokenA 和 tokenB 没有顺序要求，但是在 createAndInitializePoolIfNecessary 中我们创建的时候要求 token0 < token1。因为在这个方法中需要传入初始化的价格，而在交易池中价格是按照 token0/token1 的方式计算的，做这个限制可以避免 LP 不小心初始化错误的价格。在后续的代码和测试中，我们也约定了 tokenA 和 tokenB 是未排序的，而 token0 和 token1 是排序的，这样也便于我们理解代码。

### Pool

`mint`

我们传入要添加流动性 amount，以及 data，这个 data 是用来在回调函数中传递参数的，后面会再讲。recipient 可以指定讲流动性的权益赋予谁。这里需要注意的是 amount 是流动性，而不是要 mint 的代币，至于流动性如何计算，我们在 PositionManager 的章节中讲解，这一讲中先不具体展开。但是在我们这一讲的实现中，我们需要基于传入的 amount 计算出 amount0 和 amount1，并返回这两个值。amount0 和 amount1 分别是两个代币的数量，另外还需要在 mint 方法中调用我们定义的回调函数 mintCallback，以及修改 Pool 合约中的一些状态。

amount0 和 amount1 计算完成后需要调用 mintCallback 回调方法，LP 需要在这个回调方法中将对应的代币转入到 Pool 合约中，所以调用 Pool 合约 mint 方法的也需要是一个合约，并且在合约中定义好 mintCallback 方法。


















































































































































