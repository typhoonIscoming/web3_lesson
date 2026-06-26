# 5. 事件查询和监听
了解了事件的定义和最佳实践后，我们来看如何在实际应用中查询和监听这些事件。这对于构建前端DApp至关重要。

## 5.1 在Remix中查看事件
Remix提供了最直接的方式来查看和调试事件，非常适合开发和测试阶段。

步骤详解：

1. 部署合约

首先在Remix中编写、编译并部署你的合约：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EventDemo {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event DataUpdate(address indexed user, uint256 indexed id, string data, uint256 timestamp);
    
    mapping(address => uint256) public balances;
    
    constructor() {
        balances[msg.sender] = 1000;
    }
    
    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
    }
    
    function updateData(uint256 id, string memory data) public {
        emit DataUpdate(msg.sender, id, data, block.timestamp);
    }
}
```
2. 调用会触发事件的函数
在部署后的合约界面，调用transfer或updateData函数。

3. 查看事件日志
* 在Remix底部的控制台中，找到交易记录
* 点击交易旁边的下拉箭头展开详情
* 切换到"Events"选项卡

4. 事件详细信息

在Events选项卡中，你可以看到：

* 事件名称：Transfer或DataUpdate
* indexed参数：以单独字段显示（如from, to, user, id）
* 非indexed参数：在args字段中显示（如value, data, timestamp）
* 事件签名哈希：topics[0]的值
* 原始topics数组：完整的topics数据
* 原始data字段：ABI编码的数据

示例输出：
```sol
Events:
  Transfer (index_topic_1 address from, index_topic_2 address to, uint256 value)
    from: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    to: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    value: 100
```
调试技巧：

1. 使用不同账户测试：

* Remix提供多个测试账户
* 切换账户调用函数，观察事件中的地址变化

2. 测试边界条件：

* 尝试转账0金额
* 尝试超额转账（触发revert）
* 观察哪些情况会触发事件，哪些不会

3. 比较indexed和非indexed：

* 观察indexed参数如何显示在topics中
* 观察非indexed参数如何编码在data中

## 5.2 使用Web3.js监听事件
Web3.js是最早的以太坊JavaScript库之一，广泛用于前端DApp开发。

安装Web3.js：
```js
npm install web3
```

基本监听设置：
```sol
// 导入Web3
const Web3 = require('web3');

// 连接到以太坊节点
const web3 = new Web3('http://localhost:8545');  // 本地节点
// 或者连接到公共节点
// const web3 = new Web3('https://mainnet.infura.io/v3/YOUR-PROJECT-ID');

// 合约ABI（从Remix编译后获取）
const contractABI = [
    {
        "anonymous": false,
        "inputs": [
            {"indexed": true, "name": "from", "type": "address"},
            {"indexed": true, "name": "to", "type": "address"},
            {"indexed": false, "name": "value", "type": "uint256"}
        ],
        "name": "Transfer",
        "type": "event"
    }
];

// 合约地址
const contractAddress = '0x1234567890123456789012345678901234567890';

// 创建合约实例
const contract = new web3.eth.Contract(contractABI, contractAddress);
```
**方法1：实时监听新事件**
```sol
// 监听Transfer事件
const event = contract.events.Transfer();

// 注册回调函数
event.on("data", async (data) => {
    console.log('========== 新的Transfer事件 ==========');
    console.log('区块号:', data.blockNumber);
    console.log('交易哈希:', data.transactionHash);
    console.log('事件参数:');
    console.log('  from:', data.returnValues.from);
    console.log('  to:', data.returnValues.to);
    console.log('  value:', data.returnValues.value);
    console.log('=======================================');
    
    // 在这里可以更新UI，比如刷新余额显示
    await updateUI(data.returnValues);
});

// 监听错误
event.on("error", (error) => {
    console.error('事件监听错误:', error);
});

// 监听连接状态
event.on("connected", (subscriptionId) => {
    console.log('事件订阅ID:', subscriptionId);
});
```
方法2：查询历史事件
```sol
// 查询过去的Transfer事件
async function queryPastEvents() {
    try {
        // 查询最近1000个区块的事件
        const currentBlock = await web3.eth.getBlockNumber();
        const events = await contract.getPastEvents('Transfer', {
            fromBlock: currentBlock - 1000,
            toBlock: 'latest'
        });
        
        console.log(`找到 ${events.length} 个Transfer事件`);
        
        events.forEach((event, index) => {
            console.log(`\n事件 #${index + 1}:`);
            console.log('  from:', event.returnValues.from);
            console.log('  to:', event.returnValues.to);
            console.log('  value:', event.returnValues.value);
            console.log('  区块号:', event.blockNumber);
        });
        
        return events;
    } catch (error) {
        console.error('查询事件失败:', error);
    }
}

// 调用查询
queryPastEvents();
```
**方法3：使用过滤器查询特定事件**
```sol
// 查询特定地址的转账
async function queryUserTransfers(userAddress) {
    try {
        // 查询该用户作为发送方的转账
        const sentEvents = await contract.getPastEvents('Transfer', {
            filter: { from: userAddress },  // 过滤条件
            fromBlock: 0,
            toBlock: 'latest'
        });
        
        // 查询该用户作为接收方的转账
        const receivedEvents = await contract.getPastEvents('Transfer', {
            filter: { to: userAddress },    // 过滤条件
            fromBlock: 0,
            toBlock: 'latest'
        });
        
        console.log(`用户 ${userAddress}:`);
        console.log(`  发送了 ${sentEvents.length} 笔转账`);
        console.log(`  接收了 ${receivedEvents.length} 笔转账`);
        
        return { sent: sentEvents, received: receivedEvents };
    } catch (error) {
        console.error('查询失败:', error);
    }
}

// 查询特定用户
const userAddress = '0xABCD...';
queryUserTransfers(userAddress);
```
**方法4：分页查询大量事件**
```sol
// 分批查询事件，避免一次查询过多
async function queryEventsInBatches(startBlock, endBlock, batchSize = 1000) {
    const allEvents = [];
    
    for (let fromBlock = startBlock; fromBlock <= endBlock; fromBlock += batchSize) {
        const toBlock = Math.min(fromBlock + batchSize - 1, endBlock);
        
        console.log(`查询区块 ${fromBlock} 到 ${toBlock}...`);
        
        const events = await contract.getPastEvents('Transfer', {
            fromBlock: fromBlock,
            toBlock: toBlock
        });
        
        allEvents.push(...events);
        console.log(`  找到 ${events.length} 个事件`);
    }
    
    console.log(`\n总共找到 ${allEvents.length} 个事件`);
    return allEvents;
}

// 查询最近10000个区块的事件，每批1000个区块
const currentBlock = await web3.eth.getBlockNumber();
queryEventsInBatches(currentBlock - 10000, currentBlock, 1000);
```
完整的钱包监听示例：
```sol
const Web3 = require('web3');
const web3 = new Web3('ws://localhost:8546');  // 使用WebSocket连接以支持订阅

const contractABI = [...];  // 你的合约ABI
const contractAddress = '0x...';
const contract = new web3.eth.Contract(contractABI, contractAddress);

// 用户地址
const userAddress = '0xYourAddress';

// 监听与用户相关的Transfer事件
async function startWalletMonitoring() {
    console.log(`开始监听地址 ${userAddress} 的转账...`);
    
    // 监听用户作为发送方的转账
    contract.events.Transfer({
        filter: { from: userAddress }
    })
    .on('data', (event) => {
        console.log('💸 发送转账:');
        console.log(`  发送给: ${event.returnValues.to}`);
        console.log(`  金额: ${event.returnValues.value}`);
        
        // 更新UI: 减少余额
        updateBalance(userAddress);
    });
    
    // 监听用户作为接收方的转账
    contract.events.Transfer({
        filter: { to: userAddress }
    })
    .on('data', (event) => {
        console.log('💰 接收转账:');
        console.log(`  来自: ${event.returnValues.from}`);
        console.log(`  金额: ${event.returnValues.value}`);
        
        // 更新UI: 增加余额
        updateBalance(userAddress);
    });
    
    console.log('监听已启动！');
}

// 更新余额显示
async function updateBalance(address) {
    const balance = await contract.methods.balances(address).call();
    console.log(`当前余额: ${balance}`);
    
    // 在实际应用中，这里会更新前端UI
    // document.getElementById('balance').innerText = balance;
}

// 启动监听
startWalletMonitoring();
```

## 5.3 使用ethers.js监听事件
ethers.js是一个更现代、更轻量的以太坊JavaScript库，API设计更简洁，类型安全性更好。

安装ethers.js：

```js
npm install ethers
```
基本监听设置：
```sol
const { ethers } = require('ethers');

// 连接到以太坊节点
const provider = new ethers.providers.JsonRpcProvider('http://localhost:8545');
// 或者连接到Infura
// const provider = new ethers.providers.InfuraProvider('mainnet', 'YOUR-API-KEY');

// 合约ABI和地址
const contractABI = [...];  // 你的合约ABI
const contractAddress = '0x...';

// 创建合约实例（只读）
const contract = new ethers.Contract(contractAddress, contractABI, provider);

// 如果需要写入，连接钱包
// const signer = provider.getSigner();
// const contract = new ethers.Contract(contractAddress, contractABI, signer);
```

**方法1：实时监听事件**
```sol
// 监听Transfer事件
contract.on("Transfer", (from, to, value, event) => {
    console.log('========== 新的Transfer事件 ==========');
    console.log('发送方:', from);
    console.log('接收方:', to);
    console.log('金额:', value.toString());
    console.log('区块号:', event.blockNumber);
    console.log('交易哈希:', event.transactionHash);
    console.log('=======================================');
});

console.log('开始监听Transfer事件...');
```
**方法2：使用过滤器监听特定事件**
```sol
// 创建过滤器：只监听发送到特定地址的转账
const userAddress = '0xYourAddress';
const filter = contract.filters.Transfer(null, userAddress);

// 使用过滤器监听
contract.on(filter, (from, to, value, event) => {
    console.log(`${from} 向你转账了 ${value.toString()}`);
    
    // 更新UI
    updateUserBalance();
});
```
**方法3：查询历史事件**
```sol
// 查询过去的Transfer事件
async function queryHistoricalEvents() {
    try {
        // 创建过滤器
        const filter = contract.filters.Transfer();
        
        // 查询最近1000个区块
        const currentBlock = await provider.getBlockNumber();
        const events = await contract.queryFilter(
            filter,
            currentBlock - 1000,
            currentBlock
        );
        
        console.log(`找到 ${events.length} 个Transfer事件`);
        
        events.forEach((event, index) => {
            console.log(`\n事件 #${index + 1}:`);
            console.log('  from:', event.args.from);
            console.log('  to:', event.args.to);
            console.log('  value:', event.args.value.toString());
            console.log('  区块号:', event.blockNumber);
        });
        
        return events;
    } catch (error) {
        console.error('查询失败:', error);
    }
}

// 执行查询
queryHistoricalEvents();
```
**方法4：查询特定用户的转账记录**

```js
// 查询某用户发送的所有转账
async function queryUserSentTransfers(userAddress) {
    try {
        // 创建过滤器：from = userAddress
        const filter = contract.filters.Transfer(userAddress, null);
        
        // 查询从创世区块到最新区块
        const events = await contract.queryFilter(filter, 0, 'latest');
        
        console.log(`用户 ${userAddress} 发送了 ${events.length} 笔转账:`);
        
        let totalSent = ethers.BigNumber.from(0);
        
        events.forEach((event, index) => {
            const value = event.args.value;
            totalSent = totalSent.add(value);
            
            console.log(`  ${index + 1}. 发送给 ${event.args.to}, 金额: ${value.toString()}`);
        });
        
        console.log(`总发送金额: ${totalSent.toString()}`);
        
        return events;
    } catch (error) {
        console.error('查询失败:', error);
    }
}

// 查询特定用户
queryUserSentTransfers('0xABCD...');
```
**方法5：组合多个过滤条件**
```js
// 查询两个特定地址之间的转账
async function queryTransfersBetweenAddresses(addressA, addressB) {
    try {
        // 创建过滤器：from = addressA, to = addressB
        const filter = contract.filters.Transfer(addressA, addressB);
        
        const events = await contract.queryFilter(filter, 0, 'latest');
        
        console.log(`从 ${addressA} 到 ${addressB} 的转账:`);
        console.log(`共 ${events.length} 笔`);
        
        events.forEach((event, index) => {
            console.log(`  ${index + 1}. 金额: ${event.args.value.toString()}, 区块: ${event.blockNumber}`);
        });
        
        return events;
    } catch (error) {
        console.error('查询失败:', error);
    }
}

// 查询两个地址间的转账
queryTransfersBetweenAddresses('0xAAA...', '0xBBB...');
```
**方法6：监听多个事件**
```js
// 同时监听多个事件
function monitorAllEvents() {
    // 监听Transfer事件
    contract.on("Transfer", (from, to, value) => {
        console.log('📤 Transfer:', from, '→', to, 'Amount:', value.toString());
    });
    
    // 监听Approval事件（如果合约有的话）
    contract.on("Approval", (owner, spender, value) => {
        console.log('✅ Approval:', owner, '授权', spender, 'Amount:', value.toString());
    });
    
    // 监听自定义事件
    contract.on("DataUpdate", (user, id, data, timestamp) => {
        console.log('📝 DataUpdate:', user, 'ID:', id.toString(), 'Data:', data);
    });
    
    console.log('开始监听所有事件...');
}

monitorAllEvents();
```
**完整的DApp事件监听示例：**
```js
const { ethers } = require('ethers');

class EventMonitor {
    constructor(provider, contractAddress, contractABI) {
        this.provider = provider;
        this.contract = new ethers.Contract(contractAddress, contractABI, provider);
        this.listeners = [];
    }
    
    // 监听用户相关的所有事件
    monitorUserEvents(userAddress, callbacks) {
        // 监听用户发送的转账
        const sentFilter = this.contract.filters.Transfer(userAddress, null);
        const sentListener = this.contract.on(sentFilter, (from, to, value, event) => {
            if (callbacks.onSent) {
                callbacks.onSent({
                    from,
                    to,
                    value: value.toString(),
                    blockNumber: event.blockNumber,
                    transactionHash: event.transactionHash
                });
            }
        });
        this.listeners.push(sentListener);
        
        // 监听用户接收的转账
        const receivedFilter = this.contract.filters.Transfer(null, userAddress);
        const receivedListener = this.contract.on(receivedFilter, (from, to, value, event) => {
            if (callbacks.onReceived) {
                callbacks.onReceived({
                    from,
                    to,
                    value: value.toString(),
                    blockNumber: event.blockNumber,
                    transactionHash: event.transactionHash
                });
            }
        });
        this.listeners.push(receivedListener);
        
        console.log(`开始监听地址 ${userAddress} 的事件`);
    }
    
    // 获取用户的历史记录
    async getUserHistory(userAddress, fromBlock = 0) {
        const sentFilter = this.contract.filters.Transfer(userAddress, null);
        const receivedFilter = this.contract.filters.Transfer(null, userAddress);
        
        const [sentEvents, receivedEvents] = await Promise.all([
            this.contract.queryFilter(sentFilter, fromBlock, 'latest'),
            this.contract.queryFilter(receivedFilter, fromBlock, 'latest')
        ]);
        
        // 合并并按区块号排序
        const allEvents = [...sentEvents, ...receivedEvents]
            .sort((a, b) => a.blockNumber - b.blockNumber);
        
        return allEvents.map(event => ({
            type: event.args.from.toLowerCase() === userAddress.toLowerCase() ? 'sent' : 'received',
            from: event.args.from,
            to: event.args.to,
            value: event.args.value.toString(),
            blockNumber: event.blockNumber,
            transactionHash: event.transactionHash
        }));
    }
    
    // 停止所有监听
    stopMonitoring() {
        this.contract.removeAllListeners();
        this.listeners = [];
        console.log('已停止所有事件监听');
    }
}

// 使用示例
async function main() {
    const provider = new ethers.providers.JsonRpcProvider('http://localhost:8545');
    const contractAddress = '0x...';
    const contractABI = [...];
    
    const monitor = new EventMonitor(provider, contractAddress, contractABI);
    
    const userAddress = '0xYourAddress';
    
    // 开始实时监听
    monitor.monitorUserEvents(userAddress, {
        onSent: (data) => {
            console.log('💸 发送转账:', data);
            // 更新UI
        },
        onReceived: (data) => {
            console.log('💰 接收转账:', data);
            // 更新UI
        }
    });
    
    // 获取历史记录
    const history = await monitor.getUserHistory(userAddress);
    console.log(`历史记录 (${history.length} 笔):`);
    history.forEach((tx, i) => {
        console.log(`  ${i + 1}. ${tx.type}: ${tx.value} (区块 ${tx.blockNumber})`);
    });
}

main().catch(console.error);
```

## 5.4 事件查询最佳实践
在实际应用中查询事件时，有一些重要的最佳实践需要遵循。

1. 始终使用过滤条件
```js
// ❌ 不好：查询所有Transfer事件
const allEvents = await contract.queryFilter(
    contract.filters.Transfer(),  // 没有过滤条件
    0,
    'latest'
);
// 可能返回数百万个事件，非常慢且可能失败

// ✅ 好：使用过滤条件限制范围
const userEvents = await contract.queryFilter(
    contract.filters.Transfer(userAddress, null),  // 只查询特定用户
    fromBlock,
    toBlock
);
```
2. 分页查询大量数据
```js
// ❌ 不好：一次查询太多区块
const events = await contract.queryFilter(
    filter,
    0,              // 从创世区块
    'latest'        // 到最新区块
);
// 可能超时或被节点拒绝

// ✅ 好：分批查询
async function queryEventsPaginated(filter, startBlock, endBlock, batchSize = 1000) {
    const allEvents = [];
    
    for (let from = startBlock; from <= endBlock; from += batchSize) {
        const to = Math.min(from + batchSize - 1, endBlock);
        
        const events = await contract.queryFilter(filter, from, to);
        allEvents.push(...events);
        
        // 添加延迟，避免请求过快
        await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    return allEvents;
}

const events = await queryEventsPaginated(filter, 0, currentBlock, 1000);
```
3. 缓存查询结果
```js
class EventCache {
    constructor(contract) {
        this.contract = contract;
        this.cache = new Map();
        this.lastBlock = 0;
    }
    
    async getEvents(filter, fromBlock, toBlock) {
        const cacheKey = this.getCacheKey(filter, fromBlock, toBlock);
        
        // 检查缓存
        if (this.cache.has(cacheKey)) {
            console.log('从缓存返回');
            return this.cache.get(cacheKey);
        }
        
        // 查询事件
        console.log(`查询区块 ${fromBlock} 到 ${toBlock}`);
        const events = await this.contract.queryFilter(filter, fromBlock, toBlock);
        
        // 存入缓存
        this.cache.set(cacheKey, events);
        
        return events;
    }
    
    getCacheKey(filter, from, to) {
        return `${JSON.stringify(filter.topics)}_${from}_${to}`;
    }
    
    clearCache() {
        this.cache.clear();
    }
}

// 使用缓存
const cache = new EventCache(contract);
const events1 = await cache.getEvents(filter, 1000, 2000);  // 查询数据库
const events2 = await cache.getEvents(filter, 1000, 2000);  // 从缓存返回
```

4. 处理重组（Reorg）
区块链可能发生重组，导致某些事件被撤销。
```js
class SafeEventMonitor {
    constructor(contract, confirmations = 12) {
        this.contract = contract;
        this.confirmations = confirmations;  // 等待确认的区块数
        this.pendingEvents = new Map();
    }
    
    async monitorEvents(filter, callback) {
        this.contract.on(filter, async (event) => {
            const eventId = `${event.transactionHash}_${event.logIndex}`;
            
            // 添加到待确认列表
            this.pendingEvents.set(eventId, {
                event,
                blockNumber: event.blockNumber,
                confirmed: false
            });
            
            // 等待确认
            this.waitForConfirmation(eventId, callback);
        });
    }
    
    async waitForConfirmation(eventId, callback) {
        const eventData = this.pendingEvents.get(eventId);
        if (!eventData) return;
        
        // 获取当前区块号
        const provider = this.contract.provider;
        const currentBlock = await provider.getBlockNumber();
        
        // 检查是否已确认
        const confirmations = currentBlock - eventData.blockNumber;
        
        if (confirmations >= this.confirmations) {
            // 已确认，触发回调
            eventData.confirmed = true;
            callback(eventData.event);
            this.pendingEvents.delete(eventId);
        } else {
            // 未确认，继续等待
            setTimeout(() => {
                this.waitForConfirmation(eventId, callback);
            }, 15000);  // 15秒后再检查
        }
    }
}

// 使用示例
const safeMonitor = new SafeEventMonitor(contract, 12);

safeMonitor.monitorEvents(
    contract.filters.Transfer(),
    (event) => {
        console.log('事件已确认（12个区块确认）:', event);
        // 安全地更新UI或数据库
    }
);
```
5. 错误处理和重试
```js
async function queryEventsWithRetry(contract, filter, fromBlock, toBlock, maxRetries = 3) {
    let retries = 0;
    
    while (retries < maxRetries) {
        try {
            const events = await contract.queryFilter(filter, fromBlock, toBlock);
            return events;
        } catch (error) {
            retries++;
            console.error(`查询失败 (尝试 ${retries}/${maxRetries}):`, error.message);
            
            if (retries >= maxRetries) {
                throw error;
            }
            
            // 指数退避：等待时间随重试次数增加
            const delay = Math.pow(2, retries) * 1000;
            console.log(`等待 ${delay}ms 后重试...`);
            await new Promise(resolve => setTimeout(resolve, delay));
        }
    }
}

// 使用示例
try {
    const events = await queryEventsWithRetry(
        contract,
        filter,
        fromBlock,
        toBlock,
        3  // 最多重试3次
    );
    console.log(`成功查询到 ${events.length} 个事件`);
} catch (error) {
    console.error('查询失败，已达最大重试次数:', error);
}
```
6. 监控连接状态
```js
class RobustEventMonitor {
    constructor(provider, contract) {
        this.provider = provider;
        this.contract = contract;
        this.isConnected = false;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 10;
        
        this.setupConnectionMonitoring();
    }
    
    setupConnectionMonitoring() {
        // 监听提供者事件
        this.provider.on('error', (error) => {
            console.error('Provider错误:', error);
            this.isConnected = false;
            this.attemptReconnect();
        });
        
        this.provider.on('network', (newNetwork, oldNetwork) => {
            if (oldNetwork) {
                console.log('网络切换:', oldNetwork, '->', newNetwork);
                this.reconnect();
            }
        });
    }
    
    async attemptReconnect() {
        if (this.reconnectAttempts >= this.maxReconnectAttempts) {
            console.error('达到最大重连次数，放弃重连');
            return;
        }
        
        this.reconnectAttempts++;
        const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 30000);
        
        console.log(`${delay}ms 后尝试重连 (第 ${this.reconnectAttempts} 次)...`);
        
        await new Promise(resolve => setTimeout(resolve, delay));
        
        try {
            await this.provider.getBlockNumber();  // 测试连接
            this.isConnected = true;
            this.reconnectAttempts = 0;
            console.log('重连成功！');
            
            // 重新设置事件监听
            this.restartEventListeners();
        } catch (error) {
            console.error('重连失败:', error);
            this.attemptReconnect();
        }
    }
    
    reconnect() {
        console.log('重新连接...');
        this.isConnected = false;
        this.reconnectAttempts = 0;
        this.attemptReconnect();
    }
    
    restartEventListeners() {
        // 重新设置所有事件监听器
        console.log('重新设置事件监听器...');
        // 实现你的监听逻辑
    }
}
```
7. 使用indexed参数优化查询
```js
// ✅ 好：充分利用indexed参数
async function efficientQuery() {
    const userAddress = '0x123...';
    const tokenId = 456;
    
    // 使用indexed参数过滤
    const filter = contract.filters.NFTTransfer(
        userAddress,    // indexed from
        null,           // indexed to (任意)
        tokenId         // indexed tokenId
    );
    
    // 只返回匹配的事件，非常高效
    const events = await contract.queryFilter(filter);
    return events;
}

// ❌ 不好：查询所有事件后在客户端过滤
async function inefficientQuery() {
    const userAddress = '0x123...';
    const tokenId = 456;
    
    // 查询所有事件
    const allEvents = await contract.queryFilter(
        contract.filters.NFTTransfer()  // 没有过滤条件
    );
    
    // 在客户端过滤（慢且浪费带宽）
    const filtered = allEvents.filter(event => 
        event.args.from === userAddress && 
        event.args.tokenId.eq(tokenId)
    );
    
    return filtered;
}
```










































