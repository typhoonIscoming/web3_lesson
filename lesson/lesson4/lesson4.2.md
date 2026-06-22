# 5. 错误处理
## 5.1 require - 输入验证
require是最常用的错误处理机制，用于验证外部输入和前置条件。

语法：
```sol
require(条件, "错误消息");
```
**条件为false时：**

* 交易立即回滚
* 显示错误消息
* 返还剩余Gas
* 所有状态改变撤销

```sol
contract RequireExample {
    mapping(address => uint) public balances;
    
    function transfer(address to, uint amount) public {
        // 检查1：地址有效性
        require(to != address(0), "Cannot transfer to zero address");
        
        // 检查2：金额有效性
        require(amount > 0, "Amount must be positive");
        
        // 检查3：余额充足
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // 所有检查通过，执行转账
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
// 典型使用场景：
contract RequireUseCases {
    address public owner;
    bool public paused;
    
    constructor() {
        owner = msg.sender;
    }
    
    // 场景1：权限检查
    function ownerOnly() public view {
        require(msg.sender == owner, "Not the owner");
        // 操作...
    }
    
    // 场景2：状态检查
    function whenNotPaused() public view {
        require(!paused, "Contract is paused");
        // 操作...
    }
    
    // 场景3：参数验证
    function setAge(uint age) public pure {
        require(age > 0 && age < 150, "Invalid age");
        // 设置年龄...
    }
    
    // 场景4：余额检查
    function withdraw(uint amount) public view {
        require(address(this).balance >= amount, "Insufficient contract balance");
        // 提款...
    }
    
    // 场景5：时间条件
    function afterDeadline(uint deadline) public view {
        require(block.timestamp >= deadline, "Too early");
        // 操作...
    }
}
```

## 5.2 assert - 内部检查
assert用于检查不应该失败的条件，主要用于检测代码bug和不变量。
```sol
assert(条件);
```
**条件为false时：**

* 交易回滚
* 表示代码有bug
* 返还剩余Gas（Solidity 0.8.0+）
* 不支持错误消息
```sol
contract AssertExample {
    mapping(address => uint) public balances;
    uint public totalSupply;
    
    function transfer(address to, uint amount) public {
        // require：验证外部输入
        require(to != address(0), "Invalid address");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // 记录转账前，两个账户的余额总和
        uint balanceSumBefore = balances[msg.sender] + balances[to];
        
        // 执行转账
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        // assert：检查不变量
        // 逻辑上：转账后，两个账户的余额总和必须与转账前完全一致
        assert(balances[msg.sender] + balances[to] == balanceSumBefore);
        // 如果这个检查失败，说明余额计算逻辑出现了极其严重的 Bug（如溢出或赋值错误）
    }
    
    function mint(address to, uint amount) public {
        require(to != address(0), "Invalid address");
        
        uint supplyBefore = totalSupply;
        
        balances[to] += amount;
        totalSupply += amount;
        
        // 检查不变量：新的总供应 = 旧的 + 增发的
        assert(totalSupply == supplyBefore + amount);
    }
}
```
**require vs assert对比：**
|特性|require|assert|
|:--:|:--:|:--:|
|用途|外部验证|内部检查|
|失败原因|用户错误/外部条件|代码bug|
|错误消息|支持|不支持|
|Gas返还|是|是（0.8.0+）|
|使用频率|非常高（90%）|很低（10%）|
































































