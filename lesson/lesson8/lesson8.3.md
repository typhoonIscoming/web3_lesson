# 7. 最佳实践与常见错误

在实际开发中，遵循最佳实践可以避免很多问题。同时，了解常见错误可以帮助我们少踩坑。

## 7.1 最佳实践
1. 优先使用接口调用：

接口调用类型安全，代码可读性好，应该作为首选方案。只有在需要更高灵活性时才考虑使用底层调用方法。

```sol
// 推荐：使用接口调用
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract GoodExample {
    IERC20 public token;
    
    function transferTokens(address to, uint256 amount) external {
        require(token.transfer(to, amount), "Transfer failed");
    }
}

// 不推荐：直接使用call（除非必要）
contract BadExample {
    address public token;
    
    function transferTokens(address to, uint256 amount) external {
        (bool success, ) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(success, "Transfer failed");
    }
}
```
2. 使用检查-效果-交互模式：
这是防止重入攻击的金科玉律。先更新状态，再进行外部调用。
```sol
// 正确：遵循CEI模式
function withdraw(uint256 amount) external {
    // 1. Checks：检查条件
    require(balances[msg.sender] >= amount, "Insufficient balance");
    
    // 2. Effects：更新状态
    balances[msg.sender] -= amount;
    
    // 3. Interactions：外部调用
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
}

// 错误：外部调用在状态更新之前
function badWithdraw(uint256 amount) external {
    require(balances[msg.sender] >= amount, "Insufficient balance");
    
    // 危险：先进行外部调用
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
    
    // 状态更新在外部调用之后（重入风险）
    balances[msg.sender] -= amount;
}
```
3. 始终检查返回值：

无论是call、delegatecall还是staticcall，都要检查返回的success值。

```sol
// 正确：检查返回值
function callExternal(address target) external {
    (bool success, bytes memory data) = target.call(
        abi.encodeWithSignature("someFunction()")
    );
    require(success, "Call failed");
    // 处理返回数据...
}

// 错误：忽略返回值
function badCallExternal(address target) external {
    (bool success, ) = target.call(
        abi.encodeWithSignature("someFunction()")
    );
    // 如果success是false，代码继续执行，可能导致状态不一致
}
```
4. 使用重入锁：
对于涉及资金转移的关键函数，建议使用重入锁提供额外的保护。
```sol
// 推荐：使用重入锁
contract SecureContract {
    bool private locked;
    
    modifier noReentrant() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }
    
    function withdraw(uint256 amount) external noReentrant {
        // 安全地执行提现逻辑
    }
}
```
5. 理解执行上下文：

一定要清楚call、delegatecall、staticcall的区别，选择正确的调用方法。

```sol
// call：在被调用合约的上下文中执行
function useCall(address target) external {
    target.call(...);  // 修改target的状态
}

// delegatecall：在调用者的上下文中执行
function useDelegatecall(address target) external {
    target.delegatecall(...);  // 修改本合约的状态
}

// staticcall：只读，不能修改状态
function useStaticcall(address target) external view {
    target.staticcall(...);  // 只读取数据
}
```

## 7.2 常见错误

1. 忘记检查返回值：

这是最常见的错误之一。很多开发者调用外部合约后，没有检查success值，导致即使调用失败也继续执行。

```sol
// 错误：忘记检查返回值
function badTransfer(address to, uint256 amount) external {
    (bool success, ) = to.call{value: amount}("");
    // 如果success是false，代码继续执行
    // 可能导致状态不一致
}

// 正确：检查返回值
function goodTransfer(address to, uint256 amount) external {
    (bool success, ) = to.call{value: amount}("");
    require(success, "Transfer failed");
}
```

2. 忽视重入风险：

不少开发者认为自己的合约很简单，不会有重入问题。但实际上，只要有外部调用，就存在重入风险。

```sol
// 危险：存在重入风险
function vulnerableWithdraw(uint256 amount) external {
    require(balances[msg.sender] >= amount, "Insufficient balance");
    
    // 先转账，后更新状态
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
    
    balances[msg.sender] -= amount;  // 更新太晚
}

// 安全：遵循CEI模式
function safeWithdraw(uint256 amount) external {
    require(balances[msg.sender] >= amount, "Insufficient balance");
    
    // 先更新状态
    balances[msg.sender] -= amount;
    
    // 后转账
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
}
```

3. 使用call不检查返回值：

call方法即使失败也不会抛出异常，只会返回false。如果不检查返回值，失败的调用会被忽略。

```sol
// 错误：不检查返回值
function badCall(address target) external {
    target.call(...);  // 如果失败，不会抛出异常
    // 代码继续执行，可能导致问题
}

// 正确：检查返回值
function goodCall(address target) external {
    (bool success, ) = target.call(...);
    require(success, "Call failed");
}
```
4. delegatecall存储布局不匹配：

使用代理模式时，如果逻辑合约的存储布局与代理合约不一致，会导致数据混乱。

```sol
// 代理合约
contract Proxy {
    address public implementation;  // slot 0
    uint256 public value;           // slot 1
}

// 错误：存储布局不匹配
contract BadImplementation {
    uint256 public value;           // slot 0（错误！）
    address public implementation;  // slot 1（错误！）
    // 存储布局与代理合约不一致，会导致数据错乱
}

// 正确：存储布局匹配
contract GoodImplementation {
    address public implementation;  // slot 0（匹配）
    uint256 public value;           // slot 1（匹配）
    // 存储布局与代理合约一致
}
```

## 7.3 注意事项总结

1. 理解执行上下文：

* call在被调用合约执行
* delegatecall在调用者合约执行
* staticcall只读，不能修改状态

2. 注意Gas消耗：

* 外部调用会消耗额外的Gas
* 特别是跨合约调用
* 在设计时要考虑Gas优化

3. 安全是第一要务：

* 无论如何优化，都不能牺牲安全性
* 宁可多花一些Gas做安全检查
* 也不要留下安全隐患

在区块链世界，安全永远是第一位的。一旦出现安全问题，损失往往是不可逆的。


# 8. 实践练习

理论学习之后，实践是巩固知识的最好方式。以下是不同难度的练习题目。

## 8.1 练习1：代币交换合约（二星难度）
任务：实现一个简单的ERC20代币交换功能，使用接口调用。

要求：

1. 使用接口调用确保类型安全
2. 检查返回值，确保转账成功
3. 添加事件日志，记录每次交换
4. 实现1:1的交换比例

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenSwap {
    IERC20 public tokenA;
    IERC20 public tokenB;
    
    event Swap(
        address indexed user,
        uint256 amountA,
        uint256 amountB
    );
    
    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }
    
    function swap(uint256 amountA) external {
        require(
            tokenA.transferFrom(msg.sender, address(this), amountA),
            "Transfer A failed"
        );
        
        uint256 amountB = amountA; // 1:1兑换
        require(
            tokenB.transfer(msg.sender, amountB),
            "Transfer B failed"
        );
        
        emit Swap(msg.sender, amountA, amountB);
    }
}
```

## 8.2 练习2：多签钱包（三星难度）

任务：实现一个简单的多签名钱包，使用call执行交易。

要求：

1. 实现重入锁保护
2. 应用Gas限制，防止恶意调用
3. 支持多个所有者
4. 需要达到指定确认数才能执行

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MultiSigWallet {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required;
    
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }
    
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    
    bool private locked;
    
    modifier noReentrant() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }
    
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }
    
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid required");
        
        for (uint256 i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
        }
        required = _required;
    }
    
    function submit(address _to, uint256 _value, bytes memory _data) 
        external 
        onlyOwner 
        returns (uint256) 
    {
        uint256 txId = transactions.length;
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            confirmations: 0
        }));
        return txId;
    }
    
    function confirm(uint256 _txId) external onlyOwner {
        require(!confirmations[_txId][msg.sender], "Already confirmed");
        confirmations[_txId][msg.sender] = true;
        transactions[_txId].confirmations += 1;
    }
    
    function execute(uint256 _txId) external onlyOwner noReentrant {
        Transaction storage tx = transactions[_txId];
        require(!tx.executed, "Already executed");
        require(tx.confirmations >= required, "Insufficient confirmations");
        
        tx.executed = true;
        
        // 使用Gas限制
        (bool success, ) = tx.to.call{gas: 50000, value: tx.value}(tx.data);
        require(success, "Execution failed");
    }
}
```

## 8.3 练习3：代理合约（四星难度）

任务：使用delegatecall实现一个代理模式，支持升级功能。

要求：

1. 存储布局要匹配，确保升级时数据不会损坏
2. 实现升级功能，可以切换不同的逻辑合约
3. 使用fallback函数转发调用

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Implementation {
    address public implementation;  // 必须与Proxy的存储布局匹配
    uint256 public value;
    address public owner;
    
    function setValue(uint256 _value) external {
        value = _value;
        owner = msg.sender;
    }
    
    function getValue() external view returns (uint256) {
        return value;
    }
}

contract Proxy {
    address public implementation;
    uint256 public value;
    address public owner;
    
    constructor(address _implementation) {
        implementation = _implementation;
        owner = msg.sender;
    }
    
    function upgrade(address newImplementation) external {
        require(msg.sender == owner, "Not owner");
        implementation = newImplementation;
    }
    
    fallback() external payable {
        address impl = implementation;
        require(impl != address(0), "Implementation not set");
        
        (bool success, bytes memory returnData) = impl.delegatecall(msg.data);
        
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        
        assembly {
            return(add(returnData, 0x20), mload(returnData))
        }
    }
    
    receive() external payable {}
}
```

## 8.4 练习4：create2工厂（三星难度）

任务：使用create2创建确定性地址的合约实例。

要求：

1. 实现地址预计算，在部署前就能知道合约地址
2. 完成salt值管理，确保不同的实例有不同的地址
3. 验证预计算的地址与实际部署的地址一致

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

contract CounterFactory {
    event CounterCreated(address indexed counterAddress, bytes32 salt);
    
    function createWithCreate2(bytes32 salt) external returns (address) {
        Counter counter = new Counter{salt: salt}(msg.sender);
        address counterAddress = address(counter);
        emit CounterCreated(counterAddress, salt);
        return counterAddress;
    }
    
    function computeAddress(bytes32 salt, address deployer) 
        external 
        view 
        returns (address) 
    {
        bytes memory bytecode = abi.encodePacked(
            type(Counter).creationCode,
            abi.encode(msg.sender)
        );
        
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                deployer,
                salt,
                keccak256(bytecode)
            )
        );
        
        return address(uint160(uint256(hash)));
    }
}
```

# 9. 学习检查清单

完成本课后，你应该能够：

基础概念：

* 理解为什么需要合约间调用
* 知道合约间调用的各种方式
* 理解调用上下文的重要性

接口调用：

* 会定义接口
* 理解接口调用的优势
* 能够在实际项目中使用接口调用

底层调用方法：

* 理解call、delegatecall、staticcall的区别
* 知道何时使用哪种调用方法
* 理解执行上下文的影响

安全的外部调用：

* 理解重入攻击的原理
* 会使用CEI模式防止重入攻击
* 会使用重入锁
* 会检查返回值
* 会设置Gas限制

合约创建：

* 会使用new关键字创建合约
* 会使用create2创建确定性地址的合约
* 理解create2的地址计算公式

实际应用：

* 能够在代币交换中使用接口调用
* 能够在多签钱包中使用call
* 能够实现代理模式

最佳实践：

* 优先使用接口调用
* 遵循CEI模式
* 始终检查返回值
* 理解执行上下文













