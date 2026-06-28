# 3. 自定义错误(0.8.4+)

## 3.1 自定义错误的定义
自定义错误是Solidity 0.8.4版本引入的重要特性，它允许开发者创建结构化的、可重用的错误类型。

基本语法：

```sol
// 定义自定义错误
error ErrorName(type1 param1, type2 param2, ...);

// 使用自定义错误
revert ErrorName(value1, value2, ...);
```

简单示例：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CustomErrorBasics {
    // 定义不带参数的错误
    error Unauthorized();
    
    // 定义带参数的错误
    error InsufficientBalance(uint256 available, uint256 required);
    
    // 定义带多个参数的错误
    error InvalidTransfer(address from, address to, uint256 amount, string reason);
    
    mapping(address => uint256) public balances;
    address public owner;
    
    constructor() {
        owner = msg.sender;
        balances[msg.sender] = 1000;
    }
    
    function transfer(address to, uint256 amount) public {
        // 使用不带参数的错误
        if (msg.sender != owner && amount > 100) {
            revert Unauthorized();
        }
        
        // 使用带参数的错误
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(balances[msg.sender], amount);
        }
        
        // 使用带多个参数的错误
        if (to == address(0)) {
            revert InvalidTransfer(msg.sender, to, amount, "接收地址不能为零地址");
        }
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
```
## 3.2 自定义错误的优势

1. Gas优化：

自定义错误比字符串错误消耗更少的Gas，这在高频交易场景下能带来显著的成本节省。
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract GasOptimization {
    uint256 public balance = 100;
    
    // 自定义错误
    error InsufficientBalance(uint256 available, uint256 required);
    
    // 使用字符串错误（Gas消耗较高）
    function withdrawString(uint256 amount) public {
        require(balance >= amount, "Insufficient balance: available balance is less than required");
        balance -= amount;
    }
    
    // 使用自定义错误（Gas消耗较低）
    function withdrawCustomError(uint256 amount) public {
        if (balance < amount) {
            revert InsufficientBalance(balance, amount);
        }
        balance -= amount;
    }
}
```



































































































