### 基础概念题

1. **`payable` 关键字的作用和使用场景**
- 作用：允许函数接收 ETH
- 使用场景：
````solidity
// 接收 ETH 的函数
function deposit() public payable {
    // 可以通过 msg.value 获取收到的 ETH 数量
}

// 可接收 ETH 的合约
contract Wallet {
    receive() external payable {}
    fallback() external payable {}
}
````

2. **`eth_call` 和 `eth_sendTransaction` 的区别**
- `eth_call`: 
  - 只读操作，不改变链上状态
  - 不消耗 gas
  - 立即返回结果
- `eth_sendTransaction`:
  - 写操作，会改变链上状态
  - 需要支付 gas
  - 需要等待交易被打包确认

3. **ABI (Application Binary Interface)**
- 作用：定义了如何调用合约函数，包括函数名、参数类型、返回值等
- 示例：
````json
[
    {
        "inputs": [
            {"name": "recipient", "type": "address"},
            {"name": "amount", "type": "uint256"}
        ],
        "name": "transfer",
        "outputs": [{"type": "bool"}],
        "stateMutability": "nonpayable",
        "type": "function"
    }
]
````

### 实践应用题

4. **监听合约事件完整示例**
````javascript
// 设置事件监听
contract.on("Transfer", (from, to, amount, event) => {
    console.log(`转账事件：`);
    console.log(`- 从: ${from}`);
    console.log(`- 到: ${to}`);
    console.log(`- 金额: ${ethers.utils.formatEther(amount)} ETH`);
    console.log(`- 区块号: ${event.blockNumber}`);
    
    // 错误处理
    try {
        // 处理事件数据
    } catch (error) {
        console.error("事件处理错误:", error);
    }
});

// 取消监听
contract.removeAllListeners("Transfer");
````

5. **gas 预估处理**
- 预估失败原因：
  - 合约状态变化导致实际执行条件不满足
  - 预估时的区块状态与实际执行时不同
- 处理方案：
````javascript
try {
    // 获取 gas 预估
    const gasEstimate = await contract.estimateGas.transfer(to, amount);
    
    // 添加 buffer (比如 20%)
    const gasLimit = gasEstimate.mul(120).div(100);
    
    // 发送交易
    const tx = await contract.transfer(to, amount, {
        gasLimit: gasLimit
    });
} catch (error) {
    console.error("Gas 预估失败:", error);
}
````

### 深度技术题

6. **Provider 和 Signer 的区别**
- Provider:
  - 只读操作接口
  - 用于查询区块链状态
  - 不需要私钥
````javascript
const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
const balance = await provider.getBalance(address);
````

- Signer:
  - 可进行签名操作
  - 用于发送交易
  - 需要私钥
````javascript
const wallet = new ethers.Wallet(privateKey, provider);
const tx = await wallet.sendTransaction({
    to: recipient,
    value: ethers.utils.parseEther("1.0")
});
````

7. **批量发送代币合约实现**
````solidity
contract BatchTransfer {
    IERC20 public token;
    
    constructor(address _token) {
        token = IERC20(_token);
    }
    
    function batchTransfer(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external {
        require(recipients.length == amounts.length, "长度不匹配");
        require(recipients.length <= 100, "批次过大"); // 防止 gas 超限
        
        uint256 totalAmount = 0;
        for(uint i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        
        // 先转入代币
        require(token.transferFrom(msg.sender, address(this), totalAmount), "转入失败");
        
        // 批量转出
        for(uint i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], amounts[i]), "转出失败");
        }
    }
}
````

### 安全相关题

8. **重入攻击防范完整方案**
- 使用 ReentrancyGuard
````solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SecureContract is ReentrancyGuard {
    mapping(address => uint) private balances;
    
    function withdraw() external nonReentrant {
        uint amount = balances[msg.sender];
        require(amount > 0, "余额不足");
        
        balances[msg.sender] = 0; // 先更新状态
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "转账失败");
    }
}
````

### 性能优化题

9. **DApp 性能优化方案**
- 前端优化：
  - 使用 Web3 缓存
  - 实现本地状态管理
  - 批量查询合约数据
````javascript
// 批量查询示例
const multicall = new Multicall({
    provider,
    multicallAddress: MULTICALL_ADDRESS
});

const calls = [
    {
        contract: tokenContract,
        method: 'balanceOf',
        params: [userAddress]
    },
    {
        contract: tokenContract,
        method: 'allowance',
        params: [userAddress, spenderAddress]
    }
];

const [balance, allowance] = await multicall.call(calls);
````

### 架构设计题

10. **DEX 核心设计要素**
- 核心合约架构：
````solidity
contract DEX {
    // 交易对信息
    struct Pair {
        address token0;
        address token1;
        uint112 reserve0;
        uint112 reserve1;
    }
    
    // 核心功能
    function addLiquidity() external {}
    function removeLiquidity() external {}
    function swap() external {}
    
    // 价格预言机
    function getPrice() external view returns (uint) {}
    
    // 闪电贷接口
    function flash() external {}
}
````

### 进阶挑战题

11. **跨链资产转移方案**
- 基于哈希时间锁定合约（HTLC）:
````solidity
contract HTLC {
    bytes32 public hash;
    uint public timelock;
    
    constructor(bytes32 _hash, uint _timelock) {
        hash = _hash;
        timelock = _timelock;
    }
    
    function withdraw(bytes32 secret) external {
        require(keccak256(abi.encodePacked(secret)) == hash, "密码错误");
        // 转移资产
    }
    
    function refund() external {
        require(block.timestamp >= timelock, "锁定期未到");
        // 退回资产
    }
}
````

12. **智能合约升级方案**
- 代理模式：
````solidity
contract Proxy {
    address public implementation;
    
    function upgrade(address newImplementation) external {
        implementation = newImplementation;
    }
    
    fallback() external payable {
        address impl = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
````

### 实战经验题

13. **链上事件重放和数据同步**
````javascript
class BlockchainSync {
    async syncEvents(fromBlock, toBlock) {
        try {
            // 获取事件
            const events = await contract.queryFilter(
                contract.filters.Transfer(),
                fromBlock,
                toBlock
            );
            
            // 批量处理
            await Promise.all(events.map(async event => {
                // 检查是否已处理
                const exists = await db.hasProcessed(event.transactionHash);
                if (!exists) {
                    await this.processEvent(event);
                }
            }));
            
        } catch (error) {
            console.error("同步失败:", error);
            // 实现重试机制
        }
    }
}
````

### 前沿技术题

14. **Rollup 方案对比**

Optimistic Rollup:
- 优势：
  - 兼容性好，支持 EVM
  - 开发简单
- 劣势：
  - 提款等待期长（通常7天）

ZK Rollup:
- 优势：
  - 安全性高
  - 快速提款
- 劣势：
  - 计算证明开销大
  - 开发难度高

这些答案涵盖了主要的技术点，建议在面试时结合自己的实际项目经验来展开说明。同时，也要注意及时更新知识，因为区块链技术发展很快。



tip: 不仅要准备答案，回答还要结合实际项目经验。