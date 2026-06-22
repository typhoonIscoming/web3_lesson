## 第4.1课：控制流语句
**学习目标：掌握条件语句和循环语句的使用、理解循环的Gas成本问题、掌握错误处理机制、学会设计安全的控制流程**

**三种基本控制结构：**
1. 顺序结构：
```sol
// 从上到下依次执行
uint a = 10;
uint b = 20;
uint c = a + b;  // 先执行上面的代码，再执行这行
```
2. 选择结构：
```sol
// 根据条件选择分支
if (balance > 100) {
    // 条件为true时执行
} else {
    // 条件为false时执行
}
```
3. 循环结构：
```sol
// 重复执行代码块
for (uint i = 0; i < 10; i++) {
    // 这段代码会执行10次
}
```
## 1.2 Solidity中的特殊考虑
**在传统编程中，控制流主要考虑逻辑正确性。但在Solidity智能合约开发中，还需要特别注意：**

Gas成本问题：

* 每个操作都消耗Gas
* 循环会导致Gas成本线性或指数增长
* Gas超过区块限制会导致交易失败

状态修改的原子性：

* 交易要么全部成功，要么全部失败
* 中间状态不会保存
* 错误会导致整个交易回滚

安全性考虑：

* 循环可能被恶意利用（DoS攻击）
* 条件判断需要覆盖所有情况
* 外部调用可能失败或重入

不可变性：

* 代码部署后无法修改
* 逻辑漏洞无法修复
* 必须在开发阶段就保证正确性

# 2. 条件语句
## 2.1 if语句
if语句是最基本的条件控制语句。

**基本语法：**
```sol
if (条件) {
    // 条件为true时执行
}

// 示例
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IfStatement {
    // 简单if语句
    function checkAge(uint age) public pure returns (bool) {
        if (age >= 18) {
            return true;
        }
        return false;
    }
    // 多个条件检查
    function checkEligibility(uint age, uint balance) 
        public pure returns (bool) 
    {
        if (age >= 18) {
            if (balance >= 1000) {
                return true;
            }
        }
        return false;
    }
    // 使用逻辑运算符
    function checkWithLogic(uint age, uint balance) 
        public pure returns (bool) 
    {
        if (age >= 18 && balance >= 1000) {
            return true;
        }
        return false;
    }
}
```
**条件表达式：**

if语句的条件必须是布尔值：
```sol
contract ConditionalExpressions {
    uint public value = 100;
    address public owner;
    
    function examples() public view {
        // 正确：比较运算
        if (value > 50) { }
        if (value >= 100) { }
        if (value == 100) { }
        if (value != 0) { }
        
        // 正确：逻辑运算
        if (value > 50 && value < 150) { }
        if (value == 100 || value == 200) { }
        if (!(value == 0)) { }
        
        // 正确：地址比较
        if (msg.sender == owner) { }
        if (owner != address(0)) { }
        
        // 错误：不是布尔值
        // if (value) { }  // 编译错误！
        // if (owner) { }  // 编译错误！
    }
}
```
## 2.2 if-else语句
if-else语句提供了两个互斥的执行分支。
```sol
contract IfElseStatement {
    // 基本if-else
    function checkValue(uint value) 
        public pure returns (string memory) 
    {
        if (value > 100) {
            return "High";
        } else {
            return "Low";
        }
    }
    // 多重检查
    function checkBalance(uint balance) 
        public pure returns (string memory) 
    {
        if (balance == 0) {
            return "Empty";
        } else {
            if (balance < 1000) {
                return "Low";
            } else {
                return "Good";
            }
        }
    }
}
```
**执行流程：**
```sol
开始
  ↓
检查条件
  ↓
条件为true？
  ├─ 是 → 执行if块 → 结束
  └─ 否 → 执行else块 → 结束
```
**特点：**

* 二选一的逻辑
* 必定执行其中一个分支
* 适合简单的二分判断

## 2.3 else if链
```sol
contract ElseIfChain {
    // 评分系统
    function getGrade(uint score) 
        public pure returns (string memory) 
    {
        if (score >= 90) {
            return "A";
        } else if (score >= 80) {
            return "B";
        } else if (score >= 70) {
            return "C";
        } else if (score >= 60) {
            return "D";
        } else {
            return "F";
        }
    }
    // 会员等级判断
    function getMemberLevel(uint points) 
        public pure returns (string memory) 
    {
        if (points >= 10000) {
            return "Diamond";
        } else if (points >= 5000) {
            return "Platinum";
        } else if (points >= 1000) {
            return "Gold";
        } else if (points >= 100) {
            return "Silver";
        } else {
            return "Bronze";
        }
    }
}
```
## 2.4 三元运算符
三元运算符是if-else的简化写法，适合简单的条件赋值。

语法：
```sol
条件 ? 值1 : 值2
```

































