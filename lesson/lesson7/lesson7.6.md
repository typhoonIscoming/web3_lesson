## 第7.2课：错误处理和自定义错误
学习目标：掌握Solidity中的三种错误处理机制、理解自定义错误的优势、学会使用try-catch捕获异常、能够在实际项目中正确应用错误处理最佳实践

# 1. 错误处理基础概念

## 1.1 为什么需要错误处理
在智能合约开发中，错误处理不仅仅是让程序正常运行的技术手段，更是保障合约安全、优化Gas消耗、提升用户体验的关键环节。

错误处理的重要性：

1. 保障合约安全：

* 防止非法输入破坏合约状态
* 防止整数溢出、下溢等运算错误
* 防止未经授权的操作
* 确保资金安全

2. 优化Gas消耗：

* 尽早检测错误可以避免不必要的计算
* 自定义错误比字符串错误更节省Gas
* 合理的错误处理可以减少失败交易的成本

3. 提升用户体验：

* 清晰的错误消息帮助用户理解失败原因
* 避免用户因为不明确的错误而困惑
* 便于前端应用提供友好的错误提示

4. 便于调试和维护：

* 明确的错误信息加速问题定位
* 结构化的错误类型便于分类处理
* 降低开发和维护成本

## 1.2 错误处理的基本原理

交易回滚机制：

当智能合约执行过程中遇到错误时，会触发交易回滚（Transaction Revert）。回滚意味着：

* 所有状态变更都会被撤销
* 合约状态恢复到交易执行前
* 已消耗的Gas不会退还（取决于错误类型）
* 可以返回错误信息给调用者
```sol
contract RevertExample {
    uint256 public balance = 100;
    
    function withdraw(uint256 amount) public {
        // 如果余额不足，这里会触发回滚
        require(balance >= amount, "余额不足");
        
        // 如果上面的require失败，下面的代码不会执行
        balance -= amount;
        // 状态不会被修改
    }
}
```
错误传播：

在Solidity中，错误会沿着调用链向上传播：

* 如果函数A调用函数B，函数B发生错误，错误会传播到函数A
* 除非使用try-catch捕获，否则错误会一直传播到外部调用者
* 整个交易会失败并回滚
```sol
contract ErrorPropagation {
    function functionA() public {
        functionB();  // 如果functionB失败，functionA也会失败
    }
    
    function functionB() public pure {
        require(false, "这个错误会传播到functionA");
    }
}
```
## 1.3 Solidity中的错误处理方式
Solidity提供了三种基本的错误处理机制：

1. require：用于验证条件，适合输入检查和状态验证
2. assert：用于检查不变量，适合内部一致性验证
3. revert：用于自定义错误处理，最灵活

此外，Solidity还支持：

* 自定义错误（0.8.4+）：结构化的错误类型
* try-catch：捕获外部调用的异常

# 2. require/assert/revert详解

## 2.1 require - 输入验证和条件检查

基本语法：
```sol
require(condition, "错误消息");
// 或者
require(condition);
```
核心特点：

1. 用于条件验证：检查输入参数、合约状态等
2. 交易可恢复：失败时状态回滚
3. Gas部分返还：未使用的Gas会退还给调用者
4. 可以带错误消息：便于调试和用户理解

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract RequireExample {
    mapping(address => uint256) public balances;
    address public owner;
    
    constructor() {
        owner = msg.sender;
        balances[msg.sender] = 1000;
    }
    
    // 场景1：输入参数验证
    function transfer(address to, uint256 amount) public {
        require(to != address(0), "接收地址不能为零地址");
        require(amount > 0, "转账金额必须大于0");
        require(balances[msg.sender] >= amount, "余额不足");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    
    // 场景2：权限检查
    function mint(address to, uint256 amount) public {
        require(msg.sender == owner, "只有所有者可以铸造");
        require(to != address(0), "接收地址不能为零地址");
        
        balances[to] += amount;
    }
    
    // 场景3：状态检查
    bool public paused = false;
    
    function withdraw(uint256 amount) public {
        require(!paused, "合约已暂停");
        require(balances[msg.sender] >= amount, "余额不足");
        
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
    
    // 场景4：时间检查
    uint256 public lockTime;
    
    function setLockTime(uint256 duration) public {
        require(msg.sender == owner, "只有所有者可以设置");
        lockTime = block.timestamp + duration;
    }
    
    function unlock() public {
        require(block.timestamp >= lockTime, "尚未到解锁时间");
        // 解锁操作...
    }
}
```













































































