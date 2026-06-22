# 特殊类型与全局变量

**学习目标：深入理解address类型和转账方法、掌握全局变量的使用、学会枚举类型和状态机模式、理解constant和immutable的Gas优化**

# 1. address类型深入
## 1.1 address类型概述
address是Solidity特有的20字节类型，用于存储以太坊地址（160位）。
**地址格式：**
```sol
0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1
```
地址的组成：

* 以0x开头
* 后跟40个十六进制字符（每个字符4位，共160位）
* 总长度：42个字符

**地址来源**
```sol
contract AddressSources {
    // 1. 用户账户地址（EOA）
    address user = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    
    // 2. 合约地址
    address contractAddr = address(this);
    
    // 3. 全局变量
    address caller = msg.sender;
    
    // 4. 计算得出
    address predicted = address(uint160(uint(keccak256(...))));
}
```

## 1.2 address vs address payable
Solidity提供了两种address类型，它们有重要区别。

|特性|address|address payable|
|:--:|:--:|:--:|
|存储任何地址|支持|支持|
|查询余额(.balance)|支持|支持|
|查询代码(.code)|支持|支持|
|接收以太币|不支持|支持|
|transfer方法|不支持|支持|
|send方法|不支持|支持|
|call方法|支持|支持|

**代码示例**
```sol
contract AddressTypes {
    // 普通address：用于存储地址
    address public owner;
    address public contractAddress;
    // address payable：用于接收以太币
    address payable public recipient;
    address payable public treasury;
    
    constructor() {
        owner = msg.sender;  // msg.sender是address类型
        contractAddress = address(this);
    }
    
    function setRecipient(address _recipient) public {
        // 转换为payable类型
        recipient = payable(_recipient);
    }
}
```
**为什么区分两种类型？**
安全性考虑：

编译器可以在编译时检查类型，防止给不能接收以太币的地址转账。
```sol
contract SafetyDemo {
    address normalAddr;
    address payable payableAddr;
    
    function attemptTransfer() public {
        // 编译错误：address没有transfer方法
        // normalAddr.transfer(1 ether);
        
        // 正确：只有address payable有transfer方法
        payableAddr.transfer(1 ether);
    }
}
```
**类型转换：**
```sol
contract AddressConversion {
    // address → address payable
    function toPayable(address addr) public pure returns (address payable) {
        return payable(addr);
    }
    
    // address payable → address（自动转换）
    function toNormal(address payable addr) public pure returns (address) {
        return addr;  // 自动转换，无需显式转换
    }
    
    // 实际使用
    function sendEther(address recipient, uint amount) public {
        address payable payableRecipient = payable(recipient);
        payableRecipient.transfer(amount);
    }
}
```
## 1.3 address属性和方法
**balance - 查询余额**
```sol
contract BalanceQuery {
    // 查询任何地址的余额
    function getBalance(address account) public view returns (uint) {
        return account.balance;  // 单位：wei
    }
    
    // 查询合约自己的余额
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    // 查询调用者余额
    function getMyBalance() public view returns (uint) {
        return msg.sender.balance;
    }
    
    // 余额比较
    function hasEnoughBalance(address account, uint required) 
        public view returns (bool) 
    {
        return account.balance >= required;
    }
}
```
**重要提示：**

* balance的单位是wei
* 1 ether = 10^18 wei
* balance是实时的，随时可能变化

## code - 获取代码
```sol
contract CodeCheck {
    // 检查地址是否是合约
    function isContract(address account) public view returns (bool) {
        return account.code.length > 0;
    }
    
    // 获取合约字节码
    function getCode(address account) public view returns (bytes memory) {
        return account.code;
    }
    
    // 获取代码哈希
    function getCodeHash(address account) public view returns (bytes32) {
        return account.codehash;
    }
}
```
**应用场景**
```sol
contract SecurityCheck {
    // 防止合约调用（只允许EOA）
    function onlyEOA() public view {
        require(msg.sender.code.length == 0, "Contracts not allowed");
        // 只有外部账户（EOA）代码长度为0
    }
    
    // 确保是合约地址
    function onlyContract(address target) public view {
        require(target.code.length > 0, "Not a contract");
    }
}
```
**注意事项：**

在构造函数中，合约的code.length仍然是0，所以这个检查不是完全可靠的。

# 2. 三种转账方式

## 2.1 transfer - 最安全的转账
```sol
recipient.transfer(amount);
```
**特点：**

* 失败自动回退（交易失败）
* 固定2300 gas限制
* 最安全的转账方式
* 可能gas不足导致失败
```sol
contract TransferExample {
    mapping(address => uint) public balances;
    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        // 如果transfer失败，整个交易回滚
    }
    
    function sendToOwner(address payable owner) public {
        owner.transfer(1 ether);
    }
}
```
**优点：**

* 简单易用
* 失败自动回滚，安全
* 不需要检查返回值

缺点：

* 2300 gas限制可能不够
* 接收方如果是复杂合约可能失败
* 无法处理失败情况

## 2.2 send - 需要检查返回值
```sol
bool success = recipient.send(amount);
```
**特点：**

* 返回bool表示成功/失败
* 固定2300 gas限制
* 失败不会自动回滚
* 容易忘记检查返回值

```sol
contract SendExample {
    mapping(address => uint) public balances;
    
    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        
        bool success = payable(msg.sender).send(amount);
        require(success, "Transfer failed");
        // 必须检查返回值！
    }
}
```
**优点：**

* 可以处理失败情况
* 有返回值

缺点：

* 容易忘记检查返回值（危险）
* 2300 gas限制
* 不推荐使用

**危险示例**
```sol
contract DangerousSend {
    function badWithdraw(uint amount) public {
        balances[msg.sender] -= amount;
        // 危险：忘记检查返回值
        payable(msg.sender).send(amount);
        // 如果send失败，余额已扣除但ETH没发送
        // 资金永久丢失！
    }
}
```

## 2.3 call - 最灵活的方式
```sol
(bool success, bytes memory data) = recipient.call{value: amount}("");
```
**特点：**

* 无gas限制（转发所有可用gas）
* 最灵活
* 必须检查返回值
* 有重入攻击风险

```sol
// 示例
contract CallExample {
    mapping(address => uint) public balances;
    
    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;  // 先更新状态
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        // 必须检查返回值！
    }
    
    // 指定gas数量
    function withdrawWithGasLimit(uint amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        
        (bool success, ) = msg.sender.call{value: amount, gas: 10000}("");
        require(success, "Transfer failed");
    }
}
```
**优点：**

* 没有gas限制，更灵活
* 可以传递数据
* 可以调用其他函数
* 最推荐的转账方式（配合安全措施）

缺点：

* 必须手动检查返回值
* 有重入攻击风险
* 需要遵循CEI模式

## 2.4 三种方式对比
|方法|gas限制|失败处理|推荐度|使用场景|
|:--:|:--:|:--:|:--:|:--:|
|transfer|2300|自动回滚|中等|简单转账|
|send|2300|返回false|低|不推荐|
|call|无限制|返回false|高|配合ReentrancyGuard|

**当前推荐：**
**2024年后推荐使用：call + ReentrancyGuard**
```sol
contract RecommendedPattern {
    bool private locked;
    
    modifier noReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }
    
    function withdraw(uint amount) public noReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // Effects
        balances[msg.sender] -= amount;
        
        // Interactions
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

## 2.5 转账安全最佳实践

***CEI模式（Checks-Effects-Interactions）***

***这是智能合约安全的黄金法则！***
```sol
function withdraw(uint amount) public {
    // 1. Checks - 检查所有条件
    require(balances[msg.sender] >= amount, "Insufficient balance");
    require(amount > 0, "Amount must be positive");
    
    // 2. Effects - 更新状态变量
    balances[msg.sender] -= amount;
    
    // 3. Interactions - 调用外部合约/转账
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
}
```
**危险示例（重入攻击）：**
```sol
contract Vulnerable {
    mapping(address => uint) public balances;
    // 危险：先转账后更新
    function badWithdraw() public {
        uint amount = balances[msg.sender];
        // Interactions（外部调用在前）
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed");
        
        // Effects（状态更新在后）- 太晚了！
        balances[msg.sender] = 0;
        // 攻击者可以在收到钱后再次调用withdraw
    }
}
```
**攻击过程：**
```sol
1. 攻击者调用withdraw
2. 合约向攻击者转账
3. 攻击者合约的fallback被触发
4. 在fallback中再次调用withdraw
5. 因为余额还没清零，可以再次提取
6. 重复步骤2-5，直到合约被掏空
```
**安全做法：**
```sol
contract Safe {
    mapping(address => uint) public balances;
    
    // 安全：先更新后转账
    function safeWithdraw() public {
        uint amount = balances[msg.sender];
        require(amount > 0, "No balance");
        
        // Effects（先更新状态）
        balances[msg.sender] = 0;
        
        // Interactions（后转账）
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Transfer failed");
    }
}
```
**其他安全措施：**
```sol
// 1. 使用ReentrancyGuard
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SecureContract is ReentrancyGuard {
    function withdraw() public nonReentrant {
        // 自动防重入
    }
}

// 2. 零地址检查
function sendEther(address payable to, uint amount) public {
    require(to != address(0), "Cannot send to zero address");
    to.transfer(amount);
}

// 3. 余额检查
function sendEther(address payable to, uint amount) public {
    require(address(this).balance >= amount, "Insufficient contract balance");
    to.transfer(amount);
}
```

# 3. 全局变量详解
## 3.1 全局变量概览
全局变量是Solidity内置的特殊变量，提供区块链、交易、调用的信息。

三大类别：

msg对象 - 消息/调用信息：

* msg.sender：调用者地址（最常用）
* msg.value：发送的ETH数量（最常用）
* msg.data：完整调用数据
* msg.sig：函数选择器

block对象 - 区块信息：

* block.timestamp：当前区块时间戳（常用）
* block.number：当前区块号（常用）
* block.gaslimit：区块gas限制
* block.coinbase：矿工/验证者地址
* blockhash(n)：获取区块哈希

tx对象 - 交易信息：

* tx.origin：交易发起者（危险，不要用于权限检查）
* tx.gasprice：交易gas价格

其他重要函数：

* gasleft()：剩余gas
* keccak256()：哈希函数
* abi.encode()：编码函数

## 3.2 msg.sender - 调用者地址
msg.sender是最重要的全局变量，几乎每个合约都会用到。

**基本定义：**

* 类型：address
* 含义：当前函数的直接调用者
* 可以是：外部账户（EOA）或合约地址

**核心用途：权限控制**
```sol
contract Ownable {
    address public owner;
    
    constructor() {
        owner = msg.sender;  // 部署者成为owner
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    function sensitiveOperation() public onlyOwner {
        // 只有owner可以执行
    }
}
```
**其他用途：**
```sol
contract MsgSenderUses {
    mapping(address => uint) public balances;
    mapping(address => bool) public registered;
    
    // 记录操作者
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    
    // 身份验证
    function register() public {
        require(!registered[msg.sender], "Already registered");
        registered[msg.sender] = true;
    }
    
    // 转账发送方
    function transfer(address to, uint amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
```
**重要理解：调用链中的msg.sender**
```sol
contract A {
    function callB(address b) public {
        B(b).someFunction();
    }
}

contract B {
    function someFunction() public view returns (address) {
        return msg.sender;  // 返回合约A的地址，不是用户地址
    }
}
```
调用链：用户 → 合约A → 合约B

在合约B中：

* msg.sender = 合约A的地址（直接调用者）
* 不是用户地址

## 3.3 msg.value - 发送的ETH数量
基本定义：

* 类型：uint（单位：wei）
* 含义：随调用发送的以太币数量
* 只在payable函数中有意义

```sol
contract PaymentContract {
    uint public totalReceived;
    mapping(address => uint) public contributions;
    
    // 接收支付
    function contribute() public payable {
        require(msg.value > 0, "Must send ETH");
        
        contributions[msg.sender] += msg.value;
        totalReceived += msg.value;
    }
    
    // 精确金额要求
    function buyItem() public payable {
        require(msg.value == 0.1 ether, "Must send exactly 0.1 ETH");
        // 购买逻辑
    }
    
    // 最小金额要求
    function invest() public payable {
        require(msg.value >= 1 ether, "Minimum 1 ETH");
        // 投资逻辑
    }
    
    // 范围检查
    function donate() public payable {
        require(msg.value >= 0.01 ether, "Too low");
        require(msg.value <= 10 ether, "Too high");
        // 捐款逻辑
    }
}
```
**重要提示：**

1. 单位是wei：1 ether = 10^18 wei
2. 只有payable函数可接收：非payable函数msg.value必须为0
3. 自动增加余额：msg.value会自动加到合约余额

**常见错误：**
```sol
contract CommonMistakes {
    // 错误1：非payable函数尝试接收ETH
    // function deposit() public {
    //     // 如果调用时发送ETH，交易会失败
    // }
    
    // 错误2：在非payable函数中访问msg.value
    // function getValue() public view returns (uint) {
    //     return msg.value;  // 编译错误！
    // }
    
    // 正确：payable函数
    function correctDeposit() public payable {
        // 可以接收ETH
        // 可以访问msg.value
    }
}
```
## 3.4 block.timestamp - 时间戳
基本定义：

* 类型：uint
* 单位：秒（Unix时间戳）
* 含义：当前区块被打包的时间

时间单位：

Solidity提供了方便的时间单位：
```sol
1 seconds = 1
1 minutes = 60 seconds = 60
1 hours = 60 minutes = 3600
1 days = 24 hours = 86400
1 weeks = 7 days = 604800
```
注意：没有months和years，因为它们的长度不固定。

**使用示例**
```sol
contract TimeExample {
    uint public deadline;
    uint public startTime;
    
    constructor(uint durationDays) {
        startTime = block.timestamp;
        deadline = block.timestamp + (durationDays * 1 days);
    }
    
    // 检查是否过期
    function isExpired() public view returns (bool) {
        return block.timestamp > deadline;
    }
    
    // 检查是否在有效期内
    function isActive() public view returns (bool) {
        return block.timestamp >= startTime && 
               block.timestamp <= deadline;
    }
    
    // 剩余时间
    function timeRemaining() public view returns (uint) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }
    
    // 已经过时间
    function timePassed() public view returns (uint) {
        return block.timestamp - startTime;
    }
}
```
**实战案例：时间锁**
```sol
contract TimeLock {
    mapping(address => uint) public lockedUntil;
    mapping(address => uint) public balances;
    
    // 存款并锁定
    function deposit(uint lockDuration) public payable {
        require(msg.value > 0, "Must deposit ETH");
        require(
            lockDuration >= 1 days && lockDuration <= 365 days,
            "Duration must be 1-365 days"
        );
        
        balances[msg.sender] += msg.value;
        lockedUntil[msg.sender] = block.timestamp + lockDuration;
    }
    
    // 提现
    function withdraw() public {
        require(balances[msg.sender] > 0, "No balance");
        require(
            block.timestamp >= lockedUntil[msg.sender],
            "Still locked"
        );
        
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        lockedUntil[msg.sender] = 0;
        
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Transfer failed");
    }
    
    // 查询剩余锁定时间
    function timeRemaining() public view returns (uint) {
        if (block.timestamp >= lockedUntil[msg.sender]) {
            return 0;
        }
        return lockedUntil[msg.sender] - block.timestamp;
    }
}
```
**安全警告：**
```sol
矿工可以操纵block.timestamp约15秒范围

适合使用：
✅ 较长时间间隔（小时、天）
✅ 时间锁
✅ 截止日期

不适合使用：
❌ 关键随机性
❌ 精确到秒的需求
❌ 高频交易时间戳
```
## 3.5 block.number - 区块号
基本定义：

* 类型：uint
* 含义：当前区块在链上的序号
* 以太坊主网：平均12-14秒/块，每天约6400个块

**使用示例**
```sol
contract BlockNumber {
    uint public startBlock;
    uint public endBlock;
    
    constructor(uint durationInBlocks) {
        startBlock = block.number;
        endBlock = block.number + durationInBlocks;
    }
    
    // 检查是否在有效期内
    function isActive() public view returns (bool) {
        return block.number >= startBlock && 
               block.number <= endBlock;
    }
    
    // 剩余区块数
    function blocksRemaining() public view returns (uint) {
        if (block.number >= endBlock) {
            return 0;
        }
        return endBlock - block.number;
    }
    
    // 计算经过的区块数
    function blocksPassed() public view returns (uint) {
        return block.number - startBlock;
    }
}
```
**基于区块的奖励系统**
```sol
contract BlockRewards {
    uint public constant BLOCKS_PER_DAY = 6400;
    uint public constant REWARD_PER_BLOCK = 10;
    
    uint public lastRewardBlock;
    mapping(address => uint) public stakes;
    mapping(address => uint) public rewards;
    
    function stake() public payable {
        require(msg.value > 0, "Must stake");
        stakes[msg.sender] += msg.value;
        lastRewardBlock = block.number;
    }
    
    function claimRewards() public {
        uint stakeAmount = stakes[msg.sender];
        require(stakeAmount > 0, "No stake");
        
        uint blocksPassed = block.number - lastRewardBlock;
        uint reward = blocksPassed * REWARD_PER_BLOCK;
        
        rewards[msg.sender] += reward;
        lastRewardBlock = block.number;
    }
}
```
## 3.6 tx.origin - 危险，不要用！

基本定义：

* 类型：address
* 含义：交易的原始发起者（必定是EOA，不可能是合约）

msg.sender vs tx.origin：
```sol
调用链：用户 → 合约A → 合约B

在合约B中：
- msg.sender = 合约A（直接调用者）
- tx.origin = 用户（交易发起者）
```
**危险案例：钓鱼攻击**
```sol
// 受害合约（有漏洞）
contract Vulnerable {
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    // 危险：使用tx.origin检查权限
    function transferOwnership(address newOwner) public {
        require(tx.origin == owner, "Not owner");  // 漏洞！
        owner = newOwner;
    }
}

// 攻击合约
contract Attack {
    Vulnerable public victim;
    address public attacker;
    
    constructor(address _victim) {
        victim = Vulnerable(_victim);
        attacker = msg.sender;
    }
    
    function attack() public {
        // 转移所有权到攻击者
        victim.transferOwnership(attacker);
    }
}

// 攻击流程：
// 1. 攻击者诱导owner访问恶意网站
// 2. owner点击按钮，调用Attack.attack()
// 3. Attack调用Vulnerable.transferOwnership()
// 4. 在Vulnerable中，tx.origin是owner，检查通过！
// 5. owner被修改为attacker
// 6. 合约被攻击者控制
```
**正确做法：**
```sol
contract Safe {
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    // 安全：使用msg.sender
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "Not owner");  // 安全
        owner = newOwner;
    }
}
```
**tx.origin的唯一合法用途：**

**检查调用链中是否包含EOA（很少使用）**
```sol
function isOriginEOA() public view returns (bool) {
    return tx.origin == msg.sender;
    // true：直接由EOA调用
    // false：通过合约调用
}
```
安全原则：

永远不要使用tx.origin进行权限验证！

## 3.7 其他全局变量

**gasleft() - 剩余gas**
```sol
contract GasTracking {
    function expensiveOperation() public view returns (uint gasUsed) {
        uint gasBefore = gasleft();
        
        // 执行操作
        uint sum = 0;
        for (uint i = 0; i < 100; i++) {
            sum += i;
        }
        
        gasUsed = gasBefore - gasleft();
        return gasUsed;
    }
    
    function checkSufficientGas() public view {
        require(gasleft() >= 10000, "Insufficient gas");
        // 继续执行
    }
}
```
## keccak256() - 哈希函数
```sol
contract HashExample {
    // 生成唯一ID
    function generateId(address user, uint nonce) 
        public pure returns (bytes32) 
    {
        return keccak256(abi.encodePacked(user, nonce));
    }
    
    // 验证密码
    bytes32 public passwordHash;
    
    function setPassword(string memory password) public {
        passwordHash = keccak256(bytes(password));
    }
    
    function checkPassword(string memory password) 
        public view returns (bool) 
    {
        return keccak256(bytes(password)) == passwordHash;
    }
    
    // 生成随机数（不够安全，仅示例）
    function randomNumber() public view returns (uint) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                block.timestamp,
                block.difficulty,
                msg.sender
            )
        );
        return uint(hash);
    }
}
```
## blockhash() - 区块哈希
```sol
contract BlockHashExample {
    // 获取最近区块的哈希
    function getRecentBlockHash(uint blockNumber) 
        public view returns (bytes32) 
    {
        require(
            blockNumber < block.number,
            "Block not yet mined"
        );
        require(
            block.number - blockNumber <= 256,
            "Block too old"
        );
        
        return blockhash(blockNumber);
    }
    
    // 简单随机数（不够安全）
    function simpleRandom() public view returns (uint) {
        bytes32 hash = blockhash(block.number - 1);
        return uint(hash) % 100;  // 0-99的随机数
    }
}
```
**限制：**

* 只能获取最近256个块的哈希
* 更早的块返回bytes32(0)
* 不要用于重要的随机性（推荐Chainlink VRF）

















