# 第5.1课：基础项目 - 简单代币合约

**学习目标：理解ERC20代币标准、掌握代币合约的完整实现、学会授权机制的使用、能够部署和测试代币合约**

# 1. ERC20代币标准概述
## 1.1 什么是ERC20
ERC20是以太坊上最广泛使用的代币标准。ERC20的全称是Ethereum Request for Comment 20，这是2015年由Fabian Vogelsteller提出的一个标准提案。

基本定义：

ERC20定义了可替代代币（Fungible Token）的统一接口。可替代代币意味着每个代币都是相同的，就像人民币一样，
一张100元纸币和另一张100元纸币价值完全相同，可以互换。

**规模和影响：**

* 以太坊上已有超过50万个ERC20代币
* 日交易量超过百亿美元
* 99%的代币项目使用ERC20标准
* 几乎所有DeFi协议都基于ERC20

**著名的ERC20代币：**

***示例**
```sol
contract TokenExample {
    uint256 public totalSupply;
    
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
}

// 调用示例
uint256 supply = token.totalSupply();
// 如果总发行量是100万个，返回：1000000
```
使用场景：

* 查看代币总量
* 计算市值（总量 × 价格）
* 通缩代币查看剩余供应
* DeFi协议计算占比

balanceOf - 查询余额

**函数签名：**
```sol
function balanceOf(address account) public view returns (uint256)
```
功能：返回指定地址的代币余额

参数：

* account：要查询的账户地址
返回：该地址持有的代币数量
```sol
contract BalanceExample {
    mapping(address => uint256) public balanceOf;
    
    function balanceOf(address account) public view returns (uint256) {
        return balanceOf[account];
    }
}

// 调用示例
uint256 balance = token.balanceOf(aliceAddress);
// Alice有500个代币，返回：500
// 如果账户没有代币，返回：0
```
**使用场景：**

* 钱包显示余额
* 检查是否有足够代币
* 验证转账后余额
* DApp显示用户资产

**allowance - 查询授权额度**
**函数签名**
```sol
function allowance(address owner, address spender) public view returns (uint256)
```
功能：返回被授权人可以使用授权人的代币数量

参数：

* owner：授权人的地址（代币所有者）
* spender：被授权人的地址（被允许使用代币的地址）
返回：授权的代币数量
```sol
contract AllowanceExample {
    mapping(address => mapping(address => uint256)) public allowance;
    
    function allowance(address owner, address spender) 
        public view returns (uint256) 
    {
        return allowance[owner][spender];
    }
}

// 调用示例
uint256 allowed = token.allowance(aliceAddress, uniswapAddress);
// Alice授权Uniswap使用50个代币，返回：50
// 如果没有授权，返回：0
```
使用场景：

* 检查剩余授权额度
* DApp显示授权状态
* 判断是否需要重新授权

## 2.2 操作类函数
操作类函数会改变合约状态，不能标记为view或pure。

transfer - 直接转账
**函数签名**
```sol
function transfer(address to, uint256 amount) public returns (bool)
```
功能：从调用者账户转移代币到指定地址

参数：

* to：接收地址
* amount：转账数量
返回：true表示成功
```sol
function transfer(address to, uint256 amount) public returns (bool) {
    require(to != address(0), "Cannot transfer to zero address");
    require(balanceOf[msg.sender] >= amount, "Insufficient balance");
    
    balanceOf[msg.sender] -= amount;
    balanceOf[to] += amount;
    
    emit Transfer(msg.sender, to, amount);
    
    return true;
}
```
**执行流程：**
```sol
Alice调用 transfer(Bob, 100)
    ↓
检查：Bob地址有效？ ✓
    ↓
检查：Alice余额 >= 100？ ✓
    ↓
Alice余额 -= 100
Bob余额 += 100
    ↓
触发Transfer事件
    ↓
返回true
```
**approve - 授权**
函数签名：
```sol
function approve(address spender, uint256 amount) public returns (bool)
```
**功能：授权指定地址使用调用者的代币**

参数：

* spender：被授权人地址
* amount：授权数量
返回：true表示成功
```sol
function approve(address spender, uint256 amount) public returns (bool) {
    require(spender != address(0), "Cannot approve zero address");
    
    allowance[msg.sender][spender] = amount;
    
    emit Approval(msg.sender, spender, amount);
    
    return true;
}
```
**重要特性：**

* 覆盖式授权：新授权会覆盖旧授权
* 不转移代币：只设置额度，代币还在原账户
* 可以取消：设置为0即可取消授权
* 需要谨慎：授权给恶意合约会丢失代币

**transferFrom - 授权转账**
```sol
function transferFrom(address from, address to, uint256 amount) public returns (bool)
```
功能：使用授权额度，从授权人账户转移代币到指定地址

参数：

* from：代币所有者（授权人）
* to：接收者
* amount：转账数量

返回：true表示成功
```sol
function transferFrom(
    address from,
    address to,
    uint256 amount
) public returns (bool) {
    require(from != address(0), "From zero");
    require(to != address(0), "To zero");
    require(balanceOf[from] >= amount, "Insufficient balance");
    require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
    
    balanceOf[from] -= amount;
    balanceOf[to] += amount;
    allowance[from][msg.sender] -= amount;
    
    emit Transfer(from, to, amount);
    
    return true;
}
```
**执行流程：**
```sol
Uniswap调用 transferFrom(Alice, Pool, 300)
    ↓
检查：Alice和Pool地址有效？ ✓
    ↓
检查：Alice余额 >= 300？ ✓
    ↓
检查：allowance[Alice][Uniswap] >= 300？ ✓
    ↓
Alice余额 -= 300
Pool余额 += 300
allowance[Alice][Uniswap] -= 300
    ↓
触发Transfer事件
    ↓
返回true
```

## 2.3 必需事件

**Transfer事件**
**事件定义：**
```sol
event Transfer(address indexed from, address indexed to, uint256 value);
```
参数：

* from：发送方地址（indexed）
* to：接收方地址（indexed）
* value：转账数量

触发时机：

* 直接转账（transfer）
* 授权转账（transferFrom）
* 铸造代币（from = address(0)）
* 销毁代币（to = address(0)）

**indexed的作用：**
```sol
// indexed参数可以被索引和过滤
event Transfer(address indexed from, address indexed to, uint256 value);

// 查询示例（使用Web3.js）
// 查询所有发送给Alice的转账
const events = await contract.getPastEvents('Transfer', {
    filter: { to: aliceAddress },
    fromBlock: 0
});
```
**为什么使用indexed？**

* 提高查询效率
* 区块链浏览器可以按地址过滤
* 钱包可以监听特定地址的事件
* DApp可以跟踪用户的交易历史

**Approval事件**

**事件定义：**
```sol
event Approval(address indexed owner, address indexed spender, uint256 value);
```
参数：

* owner：授权人地址（indexed）
* spender：被授权人地址（indexed）
* value：授权数量

触发时机：

调用approve函数时触发

**使用场景：**
```sol
// DApp监听授权事件
contract.on('Approval', (owner, spender, value) => {
    console.log(`${owner} approved ${spender} to spend ${value}`);
});
```

# 3. 授权机制详解

## 3.1 授权机制的工作原理
授权机制（Approval Mechanism）是ERC20标准的核心设计，也是很多初学者容易困惑的地方。

为什么需要授权机制？

问题场景：

Alice想在Uniswap上用USDT购买ETH。这个过程中，Uniswap合约需要获取Alice的USDT。
**为什么不能用transfer？**
```sol
// transfer只能由代币持有者自己调用
function transfer(address to, uint256 amount) public returns (bool) {
    // msg.sender必须是代币持有者
    balanceOf[msg.sender] -= amount;
    // ...
}

// Uniswap合约无法调用Alice的transfer
// 因为msg.sender会是Uniswap合约地址，不是Alice
```
**问题的核心：**
智能合约无法主动获取用户的代币。如果没有授权机制，合约就无法代表用户操作代币。
**授权机制的解决方案：**
1. 用户主动授权合约
2. 合约代表用户操作
3. 用户通过控制授权额度保持控制权

这是一种**委托代理模式。**

## 3.2 授权流程详解
让我们通过一个完整的场景来理解授权机制。

**场景：Alice在Uniswap用USDT购买ETH**

**步骤1：Alice授权Uniswap**
```sol
// Alice调用USDT合约的approve函数
usdt.approve(uniswapAddress, 1000);

执行过程：
1. allowance[Alice][Uniswap] = 1000
2. 触发Approval事件
3. 返回true

状态变化：
- Alice的USDT余额：不变（仍然是2000）
- Uniswap的授权额度：1000
- 代币位置：仍在Alice账户中
```

关键点：approve只是设置授权额度，并不转移代币！

**步骤2：Uniswap使用授权**
```sol
// Uniswap合约调用transferFrom
usdt.transferFrom(Alice, Pool, 500);

执行过程：
1. 检查：Alice余额 >= 500？ ✓（2000 >= 500）
2. 检查：allowance[Alice][Uniswap] >= 500？ ✓（1000 >= 500）
3. Alice余额 -= 500（2000 → 1500）
4. Pool余额 += 500
5. allowance[Alice][Uniswap] -= 500（1000 → 500）
6. 触发Transfer事件
7. 返回true

最终状态：
- Alice的USDT余额：1500（减少了500）
- Pool的USDT余额：500（增加了500）
- 剩余授权额度：500（被消耗了500）
```
关键点：授权额度会被消耗，不是一次性使用全部！
**完整流程图：**
```sol
初始状态：
Alice余额：2000 USDT
Pool余额：0 USDT
授权额度：0

    ↓ approve(Uniswap, 1000)

状态1：
Alice余额：2000 USDT
Pool余额：0 USDT
授权额度：1000 ←（已授权）

    ↓ transferFrom(Alice, Pool, 500)

最终状态：
Alice余额：1500 USDT ←（减少500）
Pool余额：500 USDT ←（增加500）
授权额度：500 ←（消耗500）
```
## 3.3 授权机制的实际应用

**应用场景1：去中心化交易所（Uniswap）**

```sol
用户想用USDT买ETH：
1. 用户授权Uniswap使用USDT
2. Uniswap调用transferFrom从用户账户取USDT
3. Uniswap给用户发送ETH
```

**应用场景2：流动性挖矿**
```sol
用户想质押代币挖矿：
1. 用户授权挖矿合约使用代币
2. 挖矿合约调用transferFrom锁定用户代币
3. 用户获得挖矿奖励
```
**应用场景3：NFT购买**
```sol
用户想用USDT购买NFT：
1. 用户授权NFT市场合约使用USDT
2. 市场合约调用transferFrom扣除USDT
3. 市场合约转移NFT给用户
```

**应用场景4：借贷协议（Compound/Aave）**
```sol
用户想抵押代币借款：
1. 用户授权借贷合约使用代币
2. 借贷合约调用transferFrom锁定抵押品
3. 用户获得借款
```

## 3.4 授权安全注意事项

**危险做法：无限授权**
```sol
// 危险：授权最大值
token.approve(contract, type(uint256).max);
// 相当于把全部代币的控制权交给了合约
```
问题：

* 如果合约有漏洞，所有代币都可能被盗
* 授权一次永久有效，风险持续存在
* 恶意合约可以随时转走全部代币

**安全做法：按需授权**
```sol
// 安全：只授权需要的数量
token.approve(uniswap, 100);  // 只授权本次交易需要的100个

// 使用后撤销授权
token.approve(uniswap, 0);    // 撤销授权
```

**授权安全原则：**

1. **最小授权**：只授权实际需要的数量
2. **使用后撤销**：完成操作后立即撤销授权
3. **只授权可信合约**：只对经过审计的知名合约授权
4. **定期检查**：定期检查并撤销不再需要的授权
5. **使用授权管理工具**：使用Revoke.cash等工具管理授权

**真实案例：**

许多用户因为无限授权损失了资金：

* 2021年某DeFi协议被攻击，用户损失数百万美元
* 攻击者利用用户的无限授权转走代币
* 只有撤销授权的用户幸免

教训：永远不要给不熟悉的合约无限授权！

# 4. 代币合约实现

## 4.1 合约结构设计
**完整的ERC20代币合约结构：**
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MyToken {
    // 1. 代币基本信息
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    // 2. 状态变量
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    // 3. 所有者（用于权限控制）
    address public owner;
    
    // 4. 事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // 5. 修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }
    
    // 6. 构造函数
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * 10**_decimals;
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    // 7. 核心函数（见下文）
}
```

## 4.2 状态变量详解
**代币基本信息：**
```sol
string public name;      // 代币名称，如："My Token"
string public symbol;    // 代币符号，如："MTK"
uint8 public decimals;   // 小数位数，通常为18
uint256 public totalSupply;  // 总供应量
```

**为什么decimals通常是18？**
1. 与ETH一致：1 ETH = 10^18 wei
2. 精度足够：18位小数可以表示非常小的金额
3. 行业惯例：大多数代币都用18
4. 简化计算：与ETH保持一致便于计算

例外情况：

* USDT：6位小数（与美元的分单位一致）
* USDC：6位小数（同上）
* WBTC：8位小数（与比特币一致）

**余额映射**
```sol
mapping(address => uint256) public balanceOf;
```
这个映射存储了每个地址的代币余额：

* 键（key）：地址
* 值（value）：该地址拥有的代币数量

**授权映射（双层映射）：**
```sol
mapping(address => mapping(address => uint256)) public allowance;
```








































