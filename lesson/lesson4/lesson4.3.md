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


































































