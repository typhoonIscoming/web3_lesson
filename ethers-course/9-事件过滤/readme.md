
## **过滤器**

当合约创建日志（释放事件）时，它最多可以包含[4]条数据作为索引（`indexed`）。索引数据经过哈希处理并包含在<u>布隆过滤器</u>中，这是一种允许有效过滤的数据结构。因此，一个事件过滤器最多包含 `4` 个主题集，每个主题集是个条件，用于筛选目标事件。规则：

- 如果一个主题集为 `null`，则该位置的日志主题不会被过滤，任何值都匹配。
- 如果主题集是单个值，则该位置的日志主题必须与该值匹配。
- 如果主题集是数组，则该位置的日志主题至少与数组中其中一个匹配。

![](https://github.com/MetaNodeAcademy/Advanced4-frontend-upgrade/blob/main/Web3%E5%BC%80%E5%8F%91%E5%BA%93/ethers.js/09.%E4%BA%8B%E4%BB%B6%E8%BF%87%E6%BB%A4/static/Vu5Qbk7Zkok8JAxnhORcj2pbnEg.png)

## **构建过滤器**

`ethers.js` 中的合约类提供了 `contract.filters` 来简化过滤器的创建：

```javascript
const filter = contract.filters.EVENT_NAME( ...args )
```

其中 `EVENT_NAME` 为要过滤的事件名，`..args` 为主题集/条件。前面的规则有一点抽象，下面举几个例子。

1. 过滤来自 `myAddress` 地址的 `Transfer` 事件

```javascript
contract.filters.Transfer(myAddress)
```

2. 过滤所有发给 `myAddress` 地址的 `Transfer` 事件

```javascript
contract.filters.Transfer(null, myAddress)
```

3. 过滤所有从 `myAddress` 发给 `otherAddress` 的 `Transfer` 事件

```javascript
contract.filters.Transfer(myAddress, otherAddress)
```

4. 过滤所有发给 `myAddress` 或 `otherAddress` 的 `Transfer` 事件

```javascript
contract.filters.Transfer(null, [ myAddress, otherAddress ])
```

## **监听交易所的 USDT 转账**

5. 从币安交易所转出 USDT 的交易

监听 USDT 合约之前，我们需要先看懂交易日志 `Logs`，包括事件的 `topics` 和 `data`。我们先找到一笔从币安交易所转出 USDT 的交易，然后通过 hash 在 etherscan 查它的详情：

交易哈希：<u>0xab1f7b575600c4517a2e479e46e3af98a95ee84dd3f46824e02ff4618523fff5</u>

![](https://github.com/MetaNodeAcademy/Advanced4-frontend-upgrade/blob/main/Web3%E5%BC%80%E5%8F%91%E5%BA%93/ethers.js/09.%E4%BA%8B%E4%BB%B6%E8%BF%87%E6%BB%A4/static/FllubhLz4oMxNExRvG7ckuednsd.png)

该交易做了一件事：从 `binance14` （币安热钱包）向地址 `0x354de44bedba213d612e92d3248b899de17b0c58` 转账 `2983.98` USDT。

查看该事件日志 `Logs` 信息：

![](https://github.com/MetaNodeAcademy/Advanced4-frontend-upgrade/blob/main/Web3%E5%BC%80%E5%8F%91%E5%BA%93/ethers.js/09.%E4%BA%8B%E4%BB%B6%E8%BF%87%E6%BB%A4/static/UofsbNtUpohl9nxdaqmcOi4lnoh.png)

- `address`：USDT 合约地址
- `topics[0]`：事件哈希，`keccak256("Transfer(address,address,uint256)")`
- `topics[1]`：转出地址（币安交易所热钱包）。
- `topics[2]` 转入地址。
- `data`：转账数量。

6. 创建 `provider`，`abi`，和 `USDT` 合约变量：

```javascript
const provider = new ethers.JsonRpcProvider(ALCHEMY_MAINNET_URL);
// 合约地址
const addressUSDT = '0xdac17f958d2ee523a2206206994597c13d831ec7'
// 交易所地址
const accountBinance = '0x28C6c06298d514Db089934071355E5743bf21d60'
// 构建ABI
const abi = [
  "event Transfer(address indexed from, address indexed to, uint value)",
  "function balanceOf(address) public view returns(uint)",
];
// 构建合约对象
const contractUSDT = new ethers.Contract(addressUSDT, abi, provider);
```

7. 读取币安热钱包 USDT 余额。可以看到，当前币安热钱包有 1 亿多枚 USDT

```javascript
const balanceUSDT = await contractUSDT.balanceOf(accountBinance)
console.log(`USDT余额: ${ethers.formatUnits(balanceUSDT,6)}\n`)
```

![](https://github.com/MetaNodeAcademy/Advanced4-frontend-upgrade/blob/main/Web3%E5%BC%80%E5%8F%91%E5%BA%93/ethers.js/09.%E4%BA%8B%E4%BB%B6%E8%BF%87%E6%BB%A4/static/Ai7HbB1PDoEWJOxYFqGcxswpnSh.png)

8. 创建过滤器，监听 `USDT` 转入币安的事件。

```javascript
// 2. 创建过滤器，监听转移USDT进交易所
console.log("\n2. 创建过滤器，监听USDT转进交易所")
let filterBinanceIn = contractUSDT.filters.Transfer(null, accountBinance);
console.log("过滤器详情：")
console.log(filterBinanceIn);
contractUSDT.on(filterBinanceIn, (res) => {
  console.log('---------监听USDT进入交易所--------');
  console.log(
    `${res.args[0]} -> ${res.args[1]} ${ethers.formatUnits(res.args[2],6)}`
  )
})
```

![](https://github.com/MetaNodeAcademy/Advanced4-frontend-upgrade/blob/main/Web3%E5%BC%80%E5%8F%91%E5%BA%93/ethers.js/09.%E4%BA%8B%E4%BB%B6%E8%BF%87%E6%BB%A4/static/SNN4byxcqoCjyexL1qIcBx4FnIh.png)

9. 创建过滤器，监听 `USDT` 转出币安的交易。

```javascript
// 3. 创建过滤器，监听交易所转出USDT
  let filterToBinanceOut = contractUSDT.filters.Transfer(accountBinance);
  console.log("\n3. 创建过滤器，监听USDT转出交易所")
  console.log("过滤器详情：")
  console.log(filterToBinanceOut);
  contractUSDT.on(filterToBinanceOut, (res) => {
    console.log('---------监听USDT转出交易所--------');
    console.log(
      `${res.args[0]} -> ${res.args[1]} ${ethers.formatUnits(res.args[2],6)}`
    )
  }
  );
```

![](https://github.com/MetaNodeAcademy/Advanced4-frontend-upgrade/blob/main/Web3%E5%BC%80%E5%8F%91%E5%BA%93/ethers.js/09.%E4%BA%8B%E4%BB%B6%E8%BF%87%E6%BB%A4/static/HKQmburT7oJDaAx1dyzckNq5nAf.png)

## **总结**

这一讲，我们介绍了事件过滤器，并用它监听了与币安交易所热钱包相关的 `USDT` 交易。你可以用它监听任何你感兴趣的交易，发现 `smart money` 做了哪些新交易，`NFT` 大佬冲了哪些新项目，等等。