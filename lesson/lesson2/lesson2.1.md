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
**重要提示：整数除法**

Solidity没有浮点数类型，所有除法运算都是整数除法：
```sol
contract DivisionExample {
    function divide() public pure returns (uint) {
        uint result = 10 / 3;  // 结果是3，不是3.333...
        return result;
    }
    // 如果需要精度，需要使用定点数技巧
    function divideWithPrecision() public pure returns (uint) {
        uint numerator = 10 * 1000;  // 先乘以精度倍数
        uint denominator = 3;
        uint result = numerator / denominator;  // 3333
        // 实际值：3.333（需要在前端除以1000显示）
        return result;
    }
}
```
## 3.4 整数溢出保护
Solidity 0.8.0之前的问题：

在Solidity 0.8.0之前，整数运算可能发生溢出而不报错，这导致了很多安全漏洞。
```sol
// 0.8.0之前的危险代码
uint8 max = 255;
max = max + 1;  // 溢出到0（循环）
```
Solidity 0.8.0+的自动保护：

从0.8.0版本开始，Solidity自动检查整数溢出：
```sol
contract OverflowProtection {
    function testOverflow() public pure returns (uint8) {
        uint8 max = 255;
        // 下面这行会导致交易回退
        return max + 1;  // Error: Arithmetic operation underflowed or overflowed
    }
    function testUnderflow() public pure returns (uint8) {
        uint8 min = 0;
        // 下面这行会导致交易回退
        return min - 1;  // Error: Arithmetic operation underflowed or overflowed
    }
}
```
## unchecked关键字

在某些特殊情况下，如果你确定不会溢出，可以使用unchecked来节省gas：
```sol
contract UncheckedExample {
    // 使用unchecked（谨慎使用！）
    function incrementUnchecked(uint x) public pure returns (uint) {
        unchecked {
            return x + 1;  // 不检查溢出，节省gas
        }
    }
    // 典型应用场景：循环计数器
    function sumArray(uint[] memory arr) public pure returns (uint) {
        uint sum = 0;
        for (uint i = 0; i < arr.length; ) {
            sum += arr[i];
            unchecked {
                i++;  // i不可能溢出，使用unchecked节省gas
            }
        }
        return sum;
    }
}
```
**何时使用unchecked：**

1. 循环计数器（数组长度不可能达到uint256上限）
2. 已经检查过不会溢出的计算
3. 性能关键路径（需要节省gas）
**警告：不正确使用unchecked可能导致严重的安全漏洞！**

## 3.5 比较运算符
```sol
contract ComparisonOperators {
    function compare() public pure returns (bool, bool, bool, bool, bool, bool) {
        uint a = 10;
        uint b = 5;
        return (
            a == b,  // 等于：false
            a != b,  // 不等于：true
            a > b,   // 大于：true
            a < b,   // 小于：false
            a >= b,  // 大于等于：true
            a <= b   // 小于等于：false
        );
    }
}
```
# 4. 地址类型

## 4.1 地址类型基础

地址类型（address）是Solidity特有的类型，用于存储以太坊地址。一个地址是20字节（160位）的值。
```sol
contract AddressTypes {
    // 普通地址
    address public normalAddress;
    // 可支付地址
    address payable public payableAddress;
}
```
**两种地址的区别：**
|特性|address|address payable|
|:--:|:--:|:--:|
|接收ETH|不可以|可以|
|transfer方法|没有|有|
|send方法|没有|有|
|余额查询|可以|可以|
|转换|不能转为payable|可以转为普通address|

## 4.2 地址类型的常用功能
```sol
contract AddressFeatures {
    // 查询地址余额
    function getBalance(address addr) public view returns (uint) {
        return addr.balance;  // 返回该地址的ETH余额（单位：wei）
    }
    // 获取当前合约地址
    function getContractAddress() public view returns (address) {
        return address(this);
    }
    // 获取合约余额
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }
    // 检查是否为零地址
    function isZeroAddress(address addr) public pure returns (bool) {
        return addr == address(0);
        // address(0) = 0x0000000000000000000000000000000000000000
    }
}
```
## 4.3 特殊地址变量

Solidity提供了一些特殊的全局地址变量：
```sol
contract SpecialAddresses {
    function getSpecialAddresses() public view returns (address, address, address) {
        return (
            msg.sender,      // 当前调用者的地址
            tx.origin,       // 交易发起者的地址（最原始的调用者）
            address(this)    // 当前合约的地址
        );
    }
    // msg.sender vs tx.origin的区别
    function demonstrateDifference() public view returns (string memory) {
        // 用户 -> 合约A -> 合约B
        // 在合约B中：
        // msg.sender = 合约A的地址
        // tx.origin = 用户的地址
        if (msg.sender == tx.origin) {
            return "Called directly by user";
        } else {
            return "Called by another contract";
        }
    }
}
// 重要安全提示：不要使用tx.origin进行权限验证，因为它容易受到钓鱼攻击！始终使用msg.sender。
```
## 4.4 转账功能

address payable类型支持转账功能：
```sol
contract TransferExample {
    // 接收ETH的函数需要payable修饰符
    receive() external payable {}
    // transfer方法（推荐，失败会回退）
    function transferETH(address payable recipient, uint amount) public {
        recipient.transfer(amount);  // 如果失败，整个交易回退
    }
    // send方法（不推荐，需要检查返回值）
    function sendETH(address payable recipient, uint amount) public returns (bool) {
        bool success = recipient.send(amount);  // 失败返回false，不回退
        require(success, "Send failed");
        return success;
    }
    // call方法（最灵活，推荐用于转账）
    function callTransfer(address payable recipient, uint amount) public {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```
**三种转账方法的对比**
|方法|Gas限制|失败处理|推荐程度|
|:--:|:--:|:--:|:--:|
|transfer|2300 gas|自动回退|中等|
|send|2300 gas|返回false|低|
|call|无限制|返回false|高（配合require）|

## 4.5 地址类型转换
```sol
contract AddressConversion {
    // address转为address payable
    function toPayable(address addr) public pure returns (address payable) {
        return payable(addr);
    }
    // uint160转为address
    function uintToAddress(uint160 num) public pure returns (address) {
        return address(num);
    }
    // address转为uint160
    function addressToUint(address addr) public pure returns (uint160) {
        return uint160(addr);
    }
    // 示例：使用转换
    function convertAndTransfer() public {
        address normalAddr = msg.sender;
        address payable payableAddr = payable(normalAddr);
        // 现在可以向payableAddr转账
    }
}
// 为什么只能和uint160转换？
// 因为地址是20字节 = 160位，所以只能和uint160进行转换。
```

# 5. 字节和字符串类型

## 5.1 固定大小字节数组

**固定大小字节数组有bytes1到bytes32，共32种类型：**
```sol
contract FixedBytes {
    bytes1 public b1 = 0x12;
    bytes4 public b4 = 0x12345678;
    bytes32 public b32 = 0x1234567890123456789012345678901234567890123456789012345678901234;
    // 获取长度（固定）
    function getLength() public pure returns (uint, uint, uint) {
        bytes1 a;
        bytes4 b;
        bytes32 c;
        return (a.length, b.length, c.length);  // 1, 4, 32
    }
    // 访问单个字节
    function accessByte() public view returns (bytes1) {
        return b32[0];  // 访问第一个字节
    }
}
// 常见用途
contract BytesUseCases {
    // 1. 存储哈希值
    bytes32 public fileHash;
    
    function storeHash(string memory data) public {
        fileHash = keccak256(bytes(data));
    }
    // 2. 存储签名
    bytes32 public r;
    bytes32 public s;
    uint8 public v;
    
    // 3. 紧凑数据存储
    bytes4 public functionSelector = 0x70a08231;  // balanceOf(address)的函数选择器
}
// bytes32最常用：
// 因为大多数哈希函数（如keccak256、SHA256）返回32字节的哈希值，所以bytes32是最常用的字节类型
```
## 5.2 动态字节数组
**bytes是动态长度的字节数组：**
```sol
contract DynamicBytes {
    bytes public data;
    // 添加字节
    function pushByte() public {
        data.push(0x12);
    }
    // 获取长度
    function getLength() public view returns (uint) {
        return data.length;
    }
    // 访问元素
    function getByte(uint index) public view returns (bytes1) {
        require(index < data.length, "Index out of bounds");
        return data[index];
    }
    // 删除最后一个元素
    function popByte() public {
        data.pop();
    }
}
```
## 5.3 字符串类型

**字符串（string）本质上是UTF-8编码的动态字节数组。**
```sol
contract StringExample {
    string public name = "Solidity";
    string public greeting;
    // 设置字符串
    function setGreeting(string memory _msg) public {
        greeting = _msg;
    }
    // 获取字符串
    function getGreeting() public view returns (string memory) {
        return greeting;
    }
}
```
**字符串的限制：**
```sol
contract StringLimitations {
    string public str1 = "Hello";
    string public str2 = "World";
    
    // 错误：不能直接比较
    // function compare() public view returns (bool) {
    //     return str1 == str2;  // 编译错误！
    // }
    
    // 错误：不能直接获取长度
    // function getLength() public view returns (uint) {
    //     return str1.length;  // 编译错误！
    // }
    
    // 错误：不能直接拼接（0.8.12之前）
    // function concat() public view returns (string memory) {
    //     return str1 + str2;  // 编译错误！
    // }
}
```
## 5.4 字符串操作
```sol
contract StringComparison {
    // 正确的字符串比较方法：比较哈希值
    function compareStrings(
        string memory a,
        string memory b
    ) public pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
    // 使用示例
    function testComparison() public pure returns (bool, bool) {
        return (
            compareStrings("Hello", "Hello"),  // true
            compareStrings("Hello", "World")   // false
        );
    }
}
```
**字符串拼接（Solidity 0.8.12+）：**
```sol
contract StringConcatenation {
    // 使用string.concat（0.8.12+）
    function concatenate(
        string memory a,
        string memory b
    ) public pure returns (string memory) {
        return string.concat(a, " ", b);
    }
    // 使用示例
    function testConcat() public pure returns (string memory) {
        return concatenate("Hello", "World");  // "Hello World"
    }
    // 拼接多个字符串
    function concatMultiple() public pure returns (string memory) {
        return string.concat("Hello", " ", "Solidity", " ", "World");
    }
}
```
**字符串与bytes转换：**
```sol
contract StringBytesConversion {
    // 字符串转bytes
    function stringToBytes(string memory str) public pure returns (bytes memory) {
        return bytes(str);
    }
    // 获取字符串长度（通过转换为bytes）
    function getStringLength(string memory str) public pure returns (uint) {
        return bytes(str).length;
    }
    // bytes转字符串
    function bytesToString(bytes memory data) public pure returns (string memory) {
        return string(data);
    }
}
```
# 6. 枚举类型
## 6.1 枚举基础

枚举（enum）用于定义一组命名的常量，提高代码可读性。
```sol
contract EnumExample {
    // 定义枚举
    enum Status {
        Pending,    // 0
        Approved,   // 1
        Rejected,   // 2
        Cancelled   // 3
    }
    // 使用枚举
    Status public currentStatus;
    // 构造函数中设置初始状态
    constructor() {
        currentStatus = Status.Pending;
    }
}
```
**枚举的特点：**

1. 枚举值从0开始自动编号
2. 枚举本质上是uint8类型
3. 可以显式转换为整数
4. 提高代码可读性和类型安全

## 6.2 枚举操作
```sol
contract EnumOperations {
    enum OrderStatus {
        Created,    // 0
        Paid,       // 1
        Shipped,    // 2
        Delivered,  // 3
        Cancelled   // 4
    }
    OrderStatus public status;
    // 设置状态
    function createOrder() public {
        status = OrderStatus.Created;
    }
    function payOrder() public {
        require(status == OrderStatus.Created, "Order not created");
        status = OrderStatus.Paid;
    }
    function shipOrder() public {
        require(status == OrderStatus.Paid, "Order not paid");
        status = OrderStatus.Shipped;
    }
    // 检查状态
    function isPaid() public view returns (bool) {
        return status == OrderStatus.Paid;
    }
    // 枚举转整数
    function getStatusAsUint() public view returns (uint) {
        return uint(status);
    }
    // 整数转枚举（需要检查范围）
    function setStatusFromUint(uint _status) public {
        require(_status <= uint(OrderStatus.Cancelled), "Invalid status");
        status = OrderStatus(_status);
    }
}
```
## 6.3 枚举的实际应用
```sol
contract Crowdfunding {
    enum ProjectStatus {
        Fundraising,  // 募资中
        Successful,   // 成功
        Failed        // 失败
    }
    ProjectStatus public status = ProjectStatus.Fundraising;
    uint public goal = 100 ether;
    uint public raised;
    
    function contribute() public payable {
        require(status == ProjectStatus.Fundraising, "Not fundraising");
        raised += msg.value;
    }
    function finalize() public {
        require(status == ProjectStatus.Fundraising, "Already finalized");
        
        if (raised >= goal) {
            status = ProjectStatus.Successful;
        } else {
            status = ProjectStatus.Failed;
        }
    }
}
```
## 6.4 枚举的优势
**1. 提高可读性：**
```sol
// 使用枚举（清晰）
if (status == OrderStatus.Paid) {
    // ...
}
// 使用数字（不清晰）
if (status == 1) {
    // ...
}
```
**2. 类型安全：**
```sol
contract TypeSafety {
    enum Status { Pending, Approved, Rejected }
    Status public status;
    // 只能赋值为枚举中定义的值
    function setStatus() public {
        status = Status.Approved;  // 正确
        // status = 10;  // 编译错误
    }
}
```
**3. 节省Gas：**

枚举本质是uint8，比使用string存储状态更省gas。











