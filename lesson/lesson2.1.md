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






































