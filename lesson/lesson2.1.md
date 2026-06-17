# Solidity智能合约开发知识
---
**第2.1课：数据类型基础**

学习目标：掌握Solidity中的各种数据类型、理解值类型和引用类型的区别、学会使用运算符、掌握类型转换的安全方法

# 1. 数据类型概览

## 1.1 Solidity数据类型分类

在Solidity中，数据类型分为两大类：值类型（Value Types）和引用类型（Reference Types）。理解它们的区别对于编写高效、安全的智能合约至关重要。

**值类型（Value Types）**

值类型在赋值或传递时会创建一个完整的独立副本。修改副本不会影响原始值。

包含的类型：

- bool：布尔类型
- int / uint：整数类型
- address：地址类型
- bytes1 到 bytes32：固定大小字节数组
- enum：枚举类型

**引用类型（Reference Types）**

引用类型在赋值或传递时传递的是引用（内存地址），而不是完整的数据副本。修改引用会影响原始数据。

包含的类型：

- array：数组
- string：字符串
- struct：结构体
- mapping：映射
- bytes：动态字节数组

## 1.2 值类型与引用类型的对比
```sol
// 值类型示例
uint a = 10;
uint b = a;  // 创建了a的副本
b = 20;      // 修改b不影响a
// 结果：a = 10, b = 20
// 引用类型示例
uint[] memory arr1 = new uint[](1);
arr1[0] = 10;
uint[] memory arr2 = arr1;  // arr2指向arr1的同一块内存
arr2[0] = 20;               // 修改arr2会影响arr1
// 结果：arr1[0] = 20, arr2[0] = 20
```
**值类型与引用类型的关键区别：**
|特性|值类型|引用类型|
|:--:|:--:|:--:|
|赋值方式|复制完整的值|传递引用（地址）|
|内存占用|每个变量独立占用内存|多个变量可能指向同一内存|
|修改影响|互不影响|修改一个会影响其他|
|Gas消耗|相对较低|相对较高|
|默认存储位置|无需指定|需要指定（storage/memory/calldata|

# 2. 布尔类型

## 2.1 布尔类型基础

布尔类型（bool）是最简单的数据类型，只有两个可能的值：true（真）和 false（假）。
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BoolExample {
    bool public isActive = true;
    bool public isPaused = false;
    
    // 布尔类型的默认值是false
    bool public defaultBool;  // 值为false
}
```
## 2.2 布尔运算符

Solidity支持以下布尔运算符：
```sol
// 逻辑运算符
contract BoolOperators {
    function logicalOperators() public pure returns (bool, bool, bool, bool, bool) {
        bool a = true;
        bool b = false;
        
        return (
            !a,      // 逻辑非：false
            a && b,  // 逻辑与：false
            a || b,  // 逻辑或：true
            a == b,  // 等于：false
            a != b   // 不等于：true
        );
    }
}
```
## 2.3 布尔类型的实际应用
```sol
contract AccessControl {
    bool public isActive = true;
    bool public isPaused = false;
    // 检查系统状态
    function checkActive() public view returns (bool) {
        return isActive && !isPaused;
    }
    // 切换状态
    function toggleActive() public {
        isActive = !isActive;
    }
    // 条件判断
    function executeIfActive() public view returns (string memory) {
        if (isActive && !isPaused) {
            return "System is active";
        } else {
            return "System is not active";
        }
    }
}
```
# 3. 整数类型

## 3.1 整数类型概览

**Solidity提供了两种整数类型：有符号整数（int）和无符号整数（uint）。**

无符号整数（uint）：

无符号整数只能表示零和正数，不能表示负数。
```sol
uint8   // 0 到 255
uint16  // 0 到 65,535
uint32  // 0 到 4,294,967,295
uint64  // 0 到 18,446,744,073,709,551,615
uint128 // 0 到 2^128-1
uint256 // 0 到 2^256-1
// uint 等同于 uint256
uint public count;  // 等同于 uint256 public count;
```

有符号整数（int）：

有符号整数可以表示负数、零和正数。
```sol
int8    // -128 到 127
int16   // -32,768 到 32,767
int32   // -2,147,483,648 到 2,147,483,647
int64   // -2^63 到 2^63-1
int128  // -2^127 到 2^127-1
int256  // -2^255 到 2^255-1
// int 等同于 int256
int public balance;  // 等同于 int256 public balance;
```
## 3.2 为什么uint256最常用

很多初学者会疑惑：既然有uint8、uint16等更小的类型，为什么不用它们来节省空间？

答案：EVM的设计特性

以太坊虚拟机（EVM）是按照256位设计的，这意味着：

1. EVM原生处理256位数据：EVM内部的所有操作都是基于256位的
2. 使用较小类型需要额外操作：当使用uint8、uint16等类型时，EVM需要进行额外的截断和转换操作
3. 截断操作消耗更多gas：这些额外操作反而会增加gas消耗
```sol
// 实际测试对比：
contract GasComparison {
    uint256 public value256;  // Gas: ~43,724
    uint128 public value128;  // Gas: ~43,746 (更多！)
    uint8 public value8;      // Gas: ~43,770 (最多！)
}
```
什么时候使用较小的整数类型？

只有在以下情况下才考虑使用较小的整数类型：
```sol
contract PackingExample {
    // 变量打包：多个小类型变量可以打包到同一个storage槽位
    uint128 public a;  // 占用前128位
    uint128 public b;  // 占用后128位
    // a和b共享同一个256位storage槽位，节省存储成本
    // 但如果单独使用，uint256更好
    uint256 public c;  // 推荐
}
```
结论：

- 默认使用 uint256
- 需要负数时使用 int256
- 只有在变量打包优化时才考虑使用较小类型

## 3.3 整数运算

**Solidity支持所有标准的算术运算：**
```sol
contract IntegerOperations {
    function arithmeticOperations() public pure returns (uint, uint, uint, uint, uint, uint) {
        uint a = 10;
        uint b = 3;
        return (
            a + b,   // 加法：13
            a - b,   // 减法：7
            a * b,   // 乘法：30
            a / b,   // 除法：3 (注意：只取整数部分)
            a % b,   // 取模：1 (余数)
            a ** b   // 幂运算：1000 (10的3次方)
        );
    }
}
```






































