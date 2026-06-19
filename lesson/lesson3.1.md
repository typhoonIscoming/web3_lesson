# 第3.1课：数组（Arrays

学习目标：掌握Solidity中定长数组和动态数组的使用、理解数组操作的Gas优化技巧、学会安全地管理数组、避免常见的数组陷阱

# 1. 数组基础概念

数组是存储相同类型元素的集合，是智能合约开发中最常用的数据结构之一。数组允许我们在一个变量中存储多个同类型的值。

数组的基本特征：

1. 同质性：数组中所有元素必须是相同类型
2. 索引访问：通过索引（从0开始）访问元素
3. 顺序存储：元素按照添加顺序存储
4. 长度属性：可以通过length属性获取数组长度

## 1.2 数组的分类

**定长数组（Fixed-size Array）：**
```sol
uint[5] public fixedArray;  // 长度固定为5
```
**特点：**

1. 长度在声明时确定
2. 长度永远不可改变
3. 所有元素初始化为默认值（数字类型为0）
4. 不能使用push或pop方法

**动态数组（Dynamic Array）：**
```sol
uint[] public dynamicArray;  // 长度可变
```
**特点：**

1. 长度可以动态改变
2. 可以使用push添加元素
3. 可以使用pop删除最后一个元素
4. length是可变属性

## 1.3 数组类型对比
|特性|定长数组|动态数组|
|:--:|:--:|:--:|
|声明语法|uint[5]|uint[]|
|初始化|[1, 2, 3, 4, 5]|[1, 2, 3]|
|长度|固定不变|可以改变|
|push方法|不支持|支持|
|pop方法|不支持|支持|
|length属性|常量|可变|
|Gas成本|相对较低|相对较高|
|使用场景|固定数量元素|动态数量元素|

## 1.4 数组在区块链中的作用

**实际应用场景：**
```sol
// 用户列表管理：
address[] public members;  // 存储所有会员地址

// 历史记录追踪：
uint[] public prices;  // 记录价格历史

// 批量数据处理：
uint[] public pendingTransactions;  // 待处理交易列表

// 投票选项：
string[] public candidates;  // 候选人名单
```

# 2. 定长数组
## 2.1 定长数组的声明和初始化
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 基本声明：
contract FixedArrayExample {
    // 声明定长数组（未初始化，默认值为0）
    uint[5] public fixedArray;
    // 声明并初始化
    uint[3] public numbers = [1, 2, 3];
    // 其他类型的定长数组
    address[10] public addresses;
    bool[4] public flags = [true, false, true, false];
    bytes32[2] public hashes;
}
// 默认值：未初始化的定长数组元素都有默认值：
// uint类型：0
// bool类型：false
// address类型：0x0000000000000000000000000000000000000000
// bytes32类型：0x0000000000000000000000000000000000000000000000000000000000000000
```
## 2.2 访问和修改定长数组
```sol
contract FixedArrayOperations {
    uint[5] public numbers;
    constructor() {
        // 初始化数组
        numbers[0] = 10;
        numbers[1] = 20;
        numbers[2] = 30;
        numbers[3] = 40;
        numbers[4] = 50;
    }
    // 读取元素
    function getElement(uint index) public view returns (uint) {
        require(index < 5, "Index out of bounds");
        return numbers[index];
    }
    // 修改元素
    function setElement(uint index, uint value) public {
        require(index < 5, "Index out of bounds");
        numbers[index] = value;
    }
    // 获取整个数组
    function getAllNumbers() public view returns (uint[5] memory) {
        return numbers;
    }
    // 获取数组长度（始终为5）
    function getLength() public pure returns (uint) {
        uint[5] memory arr;
        return arr.length;  // 返回5
    }
}
```



























































