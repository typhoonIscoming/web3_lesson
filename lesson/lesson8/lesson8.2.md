# 4. 安全的外部调用
外部调用是合约开发中最危险的操作之一。如果处理不当，可能导致重入攻击等严重安全问题。让我们详细学习如何安全地进行外部调用。

## 4.1 重入攻击防范
重入攻击是智能合约中最常见和最危险的安全漏洞之一。2016年的The DAO攻击就是利用了这个漏洞，导致损失了价值5000万美元的以太币。

重入攻击的原理：

重入攻击发生在合约在执行外部调用之前没有更新状态的情况下。恶意合约可以在接收以太币时再次调用原函数，利用未更新的状态重复提取资金。

不安全的示例：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 存在重入漏洞的银行合约
contract VulnerableBank {
    mapping(address => uint256) public balances;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    // 存款函数
    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    // 危险！存在重入漏洞的提现函数
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");
        
        // 问题：先转账，后更新状态
        // 如果msg.sender是恶意合约，它可以在receive函数中再次调用withdraw
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        // 状态更新在外部调用之后，存在重入风险
        balances[msg.sender] = 0;
        
        emit Withdrawal(msg.sender, amount);
    }
    
    // 查询合约总余额
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

// 攻击合约：利用重入漏洞
contract Attacker {
    VulnerableBank public vulnerableBank;
    uint256 public attackCount;
    
    constructor(address _vulnerableBank) {
        vulnerableBank = VulnerableBank(_vulnerableBank);
    }
    
    // 接收以太币时触发重入攻击
    receive() external payable {
        // 限制攻击次数，避免Gas耗尽
        if (attackCount < 3 && address(vulnerableBank).balance > 0) {
            attackCount++;
            // 再次调用withdraw，此时balances[msg.sender]还没有被清零
            vulnerableBank.withdraw();
        }
    }
    
    // 发起攻击
    function attack() external payable {
        require(msg.value >= 1 ether, "Need at least 1 ether");
        attackCount = 0;
        
        // 步骤1：先存款
        vulnerableBank.deposit{value: msg.value}();
        
        // 步骤2：发起第一次提现
        vulnerableBank.withdraw();
        // 在receive函数中会触发多次重入调用
    }
    
    // 查询攻击者余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```
攻击流程：

```sol
1. 攻击者调用attack()，存入1 ether
2. 攻击者调用withdraw()
3. 合约向攻击者转账1 ether
4. 攻击者的receive()函数被触发
5. receive()中再次调用withdraw()
6. 此时balances[攻击者]还是1 ether（因为还没被清零）
7. 合约再次向攻击者转账1 ether
8. 重复步骤4-7，直到攻击次数达到限制
9. 最终攻击者提取了4 ether（1 ether本金 + 3 ether窃取）
```

安全的写法：

遵循"检查-效果-交互"（Checks-Effects-Interactions，CEI）模式：

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 安全的银行合约
contract SecureBank {
    mapping(address => uint256) public balances;
    
    // 重入锁：防止函数被重入调用
    bool private locked;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    // 重入锁修饰符
    modifier noReentrant() {
        require(!locked, "No reentrancy");
        locked = true;  // 设置锁
        _;              // 执行函数
        locked = false; // 释放锁
    }
    
    // 存款函数
    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    // 安全的提现函数：遵循CEI模式
    function withdraw() external noReentrant {
        // 1. Checks（检查）：验证所有条件
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");
        
        // 2. Effects（效果）：先更新状态
        // 这是关键：在外部调用之前更新状态
        balances[msg.sender] = 0;
        
        // 3. Interactions（交互）：然后进行外部调用
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount);
    }
    
    // 查询合约总余额
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```
**CEI模式的关键点：**

1. Checks（检查）：首先验证所有前置条件
2. Effects（效果）：然后更新合约状态
3. Interactions（交互）：最后进行外部调用

这样即使发生重入，状态已经更新，攻击无法成功。

## 4.2 防护措施

除了CEI模式，还有其他重要的防护措施：

1. 使用重入锁：

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ReentrancyGuard {
    // 使用布尔变量作为锁
    bool private locked;
    
    // 重入锁修饰符
    modifier noReentrant() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }
    
    // 在关键函数上使用修饰符
    function withdraw(uint256 amount) external noReentrant {
        // 安全地执行提现逻辑
    }
}
```

2. 限制Gas
在调用外部合约时，可以限制传递的Gas数量，防止被调用合约执行过于复杂的操作。

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract GasLimitExample {
    mapping(address => uint256) public balances;
    
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        
        // 限制Gas：最多使用50000 Gas
        // 如果被调用的合约需要更多Gas，调用会失败
        (bool success, ) = msg.sender.call{gas: 50000, value: amount}("");
        require(success, "Transfer failed");
    }
}
```

3. 检查返回值：

永远要检查外部调用的返回值，不检查返回值可能导致交易失败却不自知。

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ReturnValueCheck {
    // 危险：不检查返回值
    function badTransfer(address to, uint256 amount) external {
        (bool success, ) = to.call{value: amount}("");
        // 如果success是false，代码继续执行，可能导致状态不一致
    }
    
    // 正确：检查返回值
    function goodTransfer(address to, uint256 amount) external {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");
        // 如果失败，整个交易会回滚
    }
}
```

4. 使用OpenZeppelin的ReentrancyGuard：
OpenZeppelin提供了经过审计的重入锁实现，可以直接使用：

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SecureContract is ReentrancyGuard {
    mapping(address => uint256) public balances;
    
    function withdraw(uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

## 4.3 Gas限制的最佳实践

关于Gas限制，需要注意以下几点：

1. 设置合理的Gas限制：

```sol
contract GasLimitBestPractice {
    mapping(address => uint256) public balances;
    
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        
        // 根据实际测试确定合适的Gas限制
        // 太低了会导致正常操作失败
        // 太高了会增加被攻击的风险
        (bool success, ) = msg.sender.call{gas: 50000, value: amount}("");
        require(success, "Transfer failed");
    }
}
```
2. 避免Gas限制过低：
Gas限制不能太低，否则正常的操作也无法完成。通常建议根据实际测试来确定合适的Gas限制值。

3. 考虑使用transfer或send：

对于简单的以太币转账，可以使用transfer或send，它们有固定的Gas限制（2300 Gas），更安全：

```sol
contract TransferExample {
    mapping(address => uint256) public balances;
    
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        
        // transfer有固定的2300 Gas限制，更安全
        payable(msg.sender).transfer(amount);
    }
}
```


# 5. 合约创建方式

在合约间调用的场景中，有时我们需要动态创建新的合约。Solidity提供了两种创建合约的方式：new关键字和create2。

## 5.1 new关键字
new是传统的创建方式，使用起来非常简单直接。

**new关键字的特点：**

1. 地址由创建者和nonce决定：

* 新合约地址 = f(创建者地址, nonce)
* nonce是创建者的交易计数
* 地址是随机的，无法提前知道

2. 立即部署：

* 创建后，合约会立即部署到链上
* 返回新合约的地址

3. 简单易用：

* 语法简单，一行代码即可创建

基本语法：
```sol
ContractType newContract = new ContractType(arg1, arg2, ...);
```
完整示例：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 简单的计数器合约
contract Counter {
    uint256 public count;
    address public owner;
    
    constructor(address _owner) {
        owner = _owner;
        count = 0;
    }
    
    function increment() external {
        require(msg.sender == owner, "Not owner");
        count++;
    }
}

// 工厂合约：使用new创建新合约
contract CounterFactory {
    // 记录所有创建的计数器地址
    address[] public counters;
    
    event CounterCreated(address indexed counterAddress, address owner);
    
    /**
     * @notice 使用new创建新的计数器合约
     * @return 新创建的计数器合约地址
     */
    function createCounter() external returns (address) {
        // 使用new关键字创建新合约
        // 构造函数参数是msg.sender（调用者地址）
        Counter newCounter = new Counter(msg.sender);
        
        // 获取新合约的地址
        address counterAddress = address(newCounter);
        
        // 记录新合约地址
        counters.push(counterAddress);
        
        // 触发事件
        emit CounterCreated(counterAddress, msg.sender);
        
        return counterAddress;
    }
    
    /**
     * @notice 查询所有创建的计数器数量
     */
    function getCounterCount() external view returns (uint256) {
        return counters.length;
    }
    
    /**
     * @notice 查询指定索引的计数器地址
     */
    function getCounter(uint256 index) external view returns (address) {
        require(index < counters.length, "Index out of range");
        return counters[index];
    }
}
```
使用示例：
```sol
// 部署工厂合约
CounterFactory factory = new CounterFactory();

// 创建第一个计数器
address counter1 = factory.createCounter();
// counter1的地址是随机的，无法提前知道

// 创建第二个计数器
address counter2 = factory.createCounter();
// counter2的地址也是随机的，与counter1不同
```
适用场景：

* 一般的合约创建需求
* 不需要预先知道合约地址的场景
* 简单的工厂模式
* 每次用户请求就创建一个新的合约实例

## 5.2 create2
create2是一个更高级的创建方式，它最大的特点是地址可预先计算。

create2的核心特点：

1. 地址可预先计算：

* 在合约部署之前，就可以计算出它将来会被部署到哪个地址
* 地址计算公式：address = keccak256(0xff, sender, salt, bytecode)

2. 通过salt控制地址：

* salt是一个你提供的随机数（bytes32类型）
* 通过改变salt，可以控制生成不同的地址
* 相同的salt、sender和bytecode会产生相同的地址

3. 确定性部署：

* 可以在多个链上部署相同地址的合约
* 便于跨链交互

基本语法：
```sol
ContractType newContract = new ContractType{salt: saltValue}(arg1, arg2, ...);
```
完整示例：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 简单的计数器合约
contract Counter {
    uint256 public count;
    address public owner;
    
    constructor(address _owner) {
        owner = _owner;
        count = 0;
    }
    
    function increment() external {
        require(msg.sender == owner, "Not owner");
        count++;
    }
}

// 工厂合约：使用create2创建确定性地址的合约
contract CounterFactory {
    event CounterCreated(address indexed counterAddress, bytes32 salt);
    
    /**
     * @notice 使用new创建（地址不可预测）
     */
    function createWithNew() external returns (address) {
        Counter counter = new Counter(msg.sender);
        return address(counter);
    }
    
    /**
     * @notice 使用create2创建（地址可预测）
     * @param salt 用于计算地址的盐值
     * @return 新创建的计数器合约地址
     */
    function createWithCreate2(bytes32 salt) external returns (address) {
        // 使用create2创建，指定salt值
        Counter counter = new Counter{salt: salt}(msg.sender);
        
        address counterAddress = address(counter);
        emit CounterCreated(counterAddress, salt);
        
        return counterAddress;
    }
    
    /**
     * @notice 预计算create2地址
     * @param salt 盐值
     * @param deployer 部署者地址（通常是本合约地址）
     * @return 预计算的合约地址
     */
    function computeAddress(bytes32 salt, address deployer) 
        external 
        view 
        returns (address) 
    {
        // 获取合约的创建字节码
        // type(Counter).creationCode 获取Counter合约的字节码
        // abi.encode(msg.sender) 编码构造函数参数
        bytes memory bytecode = abi.encodePacked(
            type(Counter).creationCode,
            abi.encode(msg.sender)
        );
        
        // 计算create2地址
        // 公式：keccak256(0xff + deployer + salt + keccak256(bytecode))
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                deployer,  // 工厂合约地址
                salt,      // 盐值
                keccak256(bytecode)  // 字节码的哈希
            )
        );
        
        // 将哈希转换为地址（取后20字节）
        return address(uint160(uint256(hash)));
    }
}
```
地址计算公式详解：
```sol
create2地址 = keccak256(
    0xff +                    // 固定前缀
    factory地址 +             // 创建者地址
    salt +                    // 盐值（32字节）
    keccak256(bytecode)       // 合约字节码的哈希
)
```
使用示例：
```sol
// 部署工厂合约
CounterFactory factory = new CounterFactory();

// 步骤1：选择一个salt值
bytes32 salt = 0x0000000000000000000000000000000000000000000000000000000000000001;

// 步骤2：预计算地址（在部署前就能知道地址）
address predictedAddress = factory.computeAddress(salt, address(factory));

// 步骤3：使用create2创建合约
address actualAddress = factory.createWithCreate2(salt);

// 步骤4：验证地址是否匹配
require(predictedAddress == actualAddress, "Address mismatch");
```
适用场景：

1. 状态通道：

* 链下计算好合约地址
* 用户可以先向地址转账
* 需要时再实际部署合约

2. 确定性部署：

* 多链部署相同地址的合约
* 便于跨链交互
* 简化地址管理

3. Uniswap V2的应用：

* 每个交易对的地址可以通过公式计算
* 用户可以在Pair未创建时就知道地址
* Router可以直接计算目标地址，无需查询

**create2 vs new对比：**

|特性|new|create2|
|:--:|:--:|:--:|
|地址可预测性|不可预测|完全可预测|
|地址计算|由nonce决定|由salt决定|
|适用场景|一般创建|高级应用|
|Gas消耗|较低|稍高|
|灵活性|高|中等|

# 6. 实际应用场景

学完理论知识，让我们看看这些技术在实际项目中是如何应用的。通过实际案例，我们可以更好地理解合约间调用的价值和应用方式。

## 6.1 代币交换合约
代币交换是DeFi中最常见的应用场景。在代币交换合约中，我们需要调用ERC20合约来实现代币的转移。

完整示例：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// ERC20接口定义
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

// 代币交换合约：使用接口调用实现代币交换
contract TokenSwap {
    // 声明两个代币接口变量
    IERC20 public tokenA;
    IERC20 public tokenB;
    
    // 交换比例（简化示例，使用固定比例）
    uint256 public exchangeRate = 1; // 1:1兑换
    
    // 事件：记录每次交换的详细信息
    event Swap(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    
    // 构造函数：初始化代币合约地址
    constructor(address _tokenA, address _tokenB) {
        // 将地址转换为接口类型，确保类型安全
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }
    
    /**
     * @notice 执行代币交换
     * @param amountA 要交换的tokenA数量
     * @dev 用户需要先调用tokenA的approve函数授权本合约
     */
    function swap(uint256 amountA) external {
        // 步骤1：检查合约是否有足够的tokenB用于交换
        // 使用接口的view函数查询余额，不消耗Gas
        uint256 contractBalanceB = tokenB.balanceOf(address(this));
        uint256 amountB = amountA * exchangeRate;
        require(contractBalanceB >= amountB, "Insufficient tokenB in contract");
        
        // 步骤2：从用户账户转移tokenA到本合约
        // transferFrom需要用户先调用tokenA.approve授权本合约
        // 使用接口调用，编译器会检查参数类型
        require(
            tokenA.transferFrom(msg.sender, address(this), amountA),
            "TokenA transfer failed"
        );
        
        // 步骤3：从本合约向用户转移tokenB
        // 使用接口调用，确保类型安全
        require(
            tokenB.transfer(msg.sender, amountB),
            "TokenB transfer failed"
        );
        
        // 步骤4：触发事件，记录交换信息
        // 前端应用可以监听这个事件来更新UI
        emit Swap(msg.sender, address(tokenA), address(tokenB), amountA, amountB);
    }
    
    /**
     * @notice 查询合约持有的代币余额
     */
    function getContractBalances() 
        external 
        view 
        returns (uint256 balanceA, uint256 balanceB) 
    {
        // 使用接口的view函数查询余额
        balanceA = tokenA.balanceOf(address(this));
        balanceB = tokenB.balanceOf(address(this));
    }
}
```
关键点：

* 通过接口调用确保了类型安全和代码可读性
* 清楚地知道token是一个IERC20合约，支持哪些操作一目了然
* 如果代币合约不符合ERC20标准，编译时就会报错

## 6.2 多签钱包
多签钱包是另一个常见的应用场景。它需要多个签名者确认后才能执行交易，使用call执行外部交易以实现灵活性。

**完整示例：**
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 多签钱包合约：使用call执行外部交易
contract MultiSigWallet {
    // 自定义错误
    error NotOwner();
    error TxNotExists();
    error TxAlreadyExecuted();
    error TxAlreadyConfirmed();
    error InsufficientConfirmations();
    error ExecutionFailed();
    
    // 所有者列表
    address[] public owners;
    mapping(address => bool) public isOwner;
    
    // 所需确认数
    uint256 public required;
    
    // 交易结构体
    struct Transaction {
        address to;        // 目标地址
        uint256 value;     // 发送的以太币数量
        bytes data;        // 调用数据
        bool executed;     // 是否已执行
        uint256 confirmations; // 确认数
    }
    
    // 交易列表
    Transaction[] public transactions;
    
    // 确认映射：交易ID => 所有者地址 => 是否已确认
    mapping(uint256 => mapping(address => bool)) public confirmations;
    
    // 事件
    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId);
    event Confirm(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);
    event ExecutionFailure(uint256 indexed txId);
    
    // 修饰符：只有所有者可以调用
    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }
    
    // 修饰符：交易必须存在
    modifier txExists(uint256 _txId) {
        if (_txId >= transactions.length) revert TxNotExists();
        _;
    }
    
    // 修饰符：交易未执行
    modifier notExecuted(uint256 _txId) {
        if (transactions[_txId].executed) revert TxAlreadyExecuted();
        _;
    }
    
    // 构造函数：初始化所有者和所需确认数
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners required");
        require(
            _required > 0 && _required <= _owners.length,
            "Invalid required"
        );
        
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Duplicate owner");
            
            isOwner[owner] = true;
            owners.push(owner);
        }
        
        required = _required;
    }
    
    // 接收以太币
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @notice 提交交易
     * @param _to 目标地址
     * @param _value 发送的以太币数量
     * @param _data 调用数据
     * @return 交易ID
     */
    function submit(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyOwner returns (uint256) {
        uint256 txId = transactions.length;
        
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            confirmations: 0
        }));
        
        emit Submit(txId);
        return txId;
    }
    
    /**
     * @notice 确认交易
     * @param _txId 交易ID
     */
    function confirm(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        if (confirmations[_txId][msg.sender]) revert TxAlreadyConfirmed();
        
        confirmations[_txId][msg.sender] = true;
        transactions[_txId].confirmations += 1;
        
        emit Confirm(msg.sender, _txId);
    }
    
    /**
     * @notice 执行交易（使用call执行外部调用）
     * @param _txId 交易ID
     * @dev 使用call方法实现灵活性，可以调用任意合约的任意函数
     */
    function execute(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        
        // 检查确认数是否足够
        if (transaction.confirmations < required) {
            revert InsufficientConfirmations();
        }
        
        // 标记为已执行（防止重入）
        transaction.executed = true;
        
        // 使用call执行外部交易
        // call方法提供了灵活性，可以调用任意合约的任意函数
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        
        if (success) {
            emit Execute(_txId);
        } else {
            // 执行失败，恢复状态
            transaction.executed = false;
            emit ExecutionFailure(_txId);
            revert ExecutionFailed();
        }
    }
}
```
关键点：

* 通过call方法实现了灵活性，可以调用任意合约的任意函数
* 无法提前知道目标合约的接口，所以使用call而不是接口调用
* 严格检查返回值，确保交易执行成功
* 在实际的多签钱包实现中，通常还会结合Gas限制、重入锁等安全措施


## 6.3 代理合约
代理合约是合约升级的核心技术，它使用delegatecall来实现合约逻辑的升级。

**完整示例：**
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 逻辑合约 V1：初始版本
contract ImplementationV1 {
    // 注意：存储布局必须与代理合约匹配
    uint256 public value;
    address public owner;
    
    /**
     * @notice 设置值
     * @param _value 要设置的值
     */
    function setValue(uint256 _value) external {
        // 这个函数会修改调用者合约（代理合约）的storage
        value = _value;
        // msg.sender是原始调用者，不是代理合约
        owner = msg.sender;
    }
    
    /**
     * @notice 获取值
     */
    function getValue() external view returns (uint256) {
        return value;
    }
}

// 逻辑合约 V2：升级版本（值翻倍）
contract ImplementationV2 {
    // 存储布局必须与V1和代理合约完全一致
    uint256 public value;
    address public owner;
    
    /**
     * @notice 设置值（新逻辑：值翻倍）
     * @param _value 要设置的值
     */
    function setValue(uint256 _value) external {
        // 新逻辑：值翻倍
        value = _value * 2;
        owner = msg.sender;
    }
    
    /**
     * @notice 获取值
     */
    function getValue() external view returns (uint256) {
        return value;
    }
    
    /**
     * @notice 新增功能：重置值
     * @dev V1没有这个函数，升级后可以使用
     */
    function reset() external {
        value = 0;
    }
}

// 代理合约：存储数据，通过delegatecall调用逻辑合约
contract Proxy {
    // 存储布局必须与逻辑合约完全一致
    address public implementation; // 逻辑合约地址
    uint256 public value;          // 与逻辑合约的value对应
    address public owner;           // 与逻辑合约的owner对应
    
    event Upgraded(address indexed newImplementation);
    
    // 构造函数：初始化逻辑合约地址
    constructor(address _implementation) {
        implementation = _implementation;
        owner = msg.sender;
    }
    
    /**
     * @notice 升级函数：更换逻辑合约
     * @param newImplementation 新的逻辑合约地址
     */
    function upgrade(address newImplementation) external {
        require(msg.sender == owner, "Not owner");
        implementation = newImplementation;
        emit Upgraded(newImplementation);
    }
    
    /**
     * @notice fallback函数：将所有调用转发到逻辑合约
     * @dev 使用delegatecall调用逻辑合约，逻辑合约的代码在代理合约的上下文中执行
     */
    fallback() external payable {
        address impl = implementation;
        require(impl != address(0), "Implementation not set");
        
        // 使用delegatecall调用逻辑合约
        // 逻辑合约的代码会在本合约（代理合约）的上下文中执行
        // 这意味着修改的是代理合约的storage，而不是逻辑合约的
        (bool success, bytes memory returnData) = impl.delegatecall(msg.data);
        
        if (!success) {
            // 如果调用失败，回滚
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        
        // 返回数据
        assembly {
            return(add(returnData, 0x20), mload(returnData))
        }
    }
    
    // 接收以太币
    receive() external payable {}
}
```

**工作原理：**
```sol
1. 用户调用 Proxy.setValue(50)
   ↓
2. Proxy的fallback函数被触发（因为Proxy没有setValue函数）
   ↓
3. fallback函数使用delegatecall调用 Implementation.setValue(50)
   ↓
4. Implementation的代码在Proxy的上下文中执行
   ↓
5. 修改的是Proxy的value（不是Implementation的）
   ↓
6. msg.sender仍然是原始用户（不是Proxy）
```
**升级流程：**

```sol
V1时期：
- Proxy.value = 0
- 调用setValue(50) → Proxy.value = 50（V1逻辑：直接赋值）

升级到V2：
- upgrade(V2地址) → 逻辑切换，但Proxy.value保持50

V2时期：
- 调用setValue(50) → Proxy.value = 100（V2逻辑：50*2=100）
- 调用reset() → Proxy.value = 0（V2新功能）
```

关键点：

* 通过delegatecall实现了调用，并且保持了msg.sender不变
* 在逻辑合约中，msg.sender仍然是原始的调用者，而不是代理合约
* 这对于权限控制非常重要
* 存储布局必须兼容，如果逻辑合约的存储布局发生变化，可能导致数据损坏























