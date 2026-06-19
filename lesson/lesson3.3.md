# 第3.2课：映射和结构体

## 1. Mapping基础概念

## 1.1 什么是Mapping
Mapping（映射）是Solidity中最常用的数据结构之一，类似于其他编程语言中的HashMap、Dictionary或关联数组。它提供了一种通过键（key）快速查找值（value）的方式。

基本概念：

* 键值对存储：每个键对应一个值
* 快速查找：O(1)时间复杂度
* 哈希存储：底层使用哈希表实现
* 永久存储：只能作为storage变量

## 1.2 Mapping的语法
```sol
mapping(keyType => valueType) 变量名;
```
支持的键类型：

* 值类型：uint, int, address, bool, bytes1到bytes32, enum
* 不支持：引用类型（数组、struct、mapping）

支持的值类型：

* 任何类型都可以作为值，包括：
    + 值类型：uint, bool, address等
    + 引用类型：string, bytes, array, struct, mapping

## 1.3 Mapping基本示例
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MappingBasics {
    // 地址到余额的映射
    mapping(address => uint256) public balances;
    
    // ID到名字的映射
    mapping(uint256 => string) public names;
    
    // 地址到白名单状态的映射
    mapping(address => bool) public whitelist;
    
    // 设置余额
    function setBalance(address user, uint256 amount) public {
        balances[user] = amount;
    }
    
    // 获取余额
    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }
    
    // 设置名字
    function setName(uint256 id, string calldata name) public {
        names[id] = name;
    }
    
    // 添加到白名单
    function addToWhitelist(address user) public {
        whitelist[user] = true;
    }
    
    // 检查白名单
    function isWhitelisted(address user) public view returns (bool) {
        return whitelist[user];
    }
}
```

## 1.4 Mapping的工作原理
**底层存储机制：**

Mapping并不像数组那样真正存储所有的键值对，而是通过哈希函数计算存储位置。

存储位置计算：
```sol
存储位置 = keccak256(abi.encode(key, mappingSlot))
```
其中：

* key：要查询的键
* mappingSlot：mapping在合约storage中的槽位

查找过程：
```sol
用户查询 balances[0x123...]
    ↓
计算：keccak256(0x123..., mappingSlot)
    ↓
得到storage位置：0xabcd...
    ↓
读取该位置的值
    ↓
返回结果
```
时间复杂度：

* 查找：O(1) 常数时间
* 插入：O(1) 常数时间
* 更新：O(1) 常数时间
* 删除：O(1) 常数时间

这就是为什么mapping如此高效的原因！

## 2. Mapping的特性和限制

## 2.1 Mapping的五大核心特性
**特性1：所有键都"存在"**
这是Mapping最重要也最容易混淆的特性。
```sol
contract MappingDefault {
    mapping(address => uint256) public balances;
    
    function testDefault() public view returns (uint256) {
        // 即使从未设置过这个地址的余额
        // 也会返回默认值0，而不是报错
        return balances[address(0x123)];  // 返回: 0
    }
}
```
重要理解：

* Mapping中所有可能的键都被认为"存在"
* 未设置的键返回该类型的默认值
* 不会抛出"键不存在"的错误

**不同类型的默认值：**
```sol
contract DefaultValues {
    mapping(address => uint256) uintMap;      // 默认: 0
    mapping(address => bool) boolMap;         // 默认: false
    mapping(address => address) addressMap;   // 默认: 0x0000...
    mapping(address => string) stringMap;     // 默认: ""
    mapping(address => int256) intMap;        // 默认: 0
    
    function showDefaults(address key) public view returns (
        uint256,
        bool,
        address,
        string memory,
        int256
    ) {
        return (
            uintMap[key],      // 0
            boolMap[key],      // false
            addressMap[key],   // 0x0000000000000000000000000000000000000000
            stringMap[key],    // ""
            intMap[key]        // 0
        );
    }
}
```
**问题：如何区分"值是0"和"从未设置"？**
稍后我们会在Mapping+Struct组合中解决这个问题。

**特性2：不存储键列表**
Mapping只存储值，不存储键的列表。
```sol
contract NoKeyStorage {
    mapping(address => uint256) public balances;
    
    // 错误：无法获取所有键
    // function getAllKeys() public view returns (address[] memory) {
    //     // 不可能实现！mapping不存储键列表
    // }
    
    // 错误：无法获取mapping的大小
    // function getSize() public view returns (uint256) {
    //     // mapping没有.length属性
    // }
}
// 为了节省存储空间和Gas成本，Solidity的mapping不维护键列表。
```
**特性3：不能遍历**
由于不存储键列表，mapping无法被遍历。
```sol
contract CannotIterate {
    mapping(address => uint256) public balances;
    
    // 错误：无法遍历
    // function sumAllBalances() public view returns (uint256) {
    //     uint256 total = 0;
    //     for(address user in balances) {  // 编译错误！
    //         total += balances[user];
    //     }
    //     return total;
    // }
}
// 解决方案：使用Mapping+Array组合（稍后讲解）
```
**特性4：只能用于Storage**
Mapping只能作为状态变量，不能在函数内创建。
```sol
contract StorageOnly {
    // 正确：作为状态变量
    mapping(address => uint256) public balances;
    
    function test() public {
        // 错误：不能在memory中创建mapping
        // mapping(address => uint256) memory localMap;  // 编译错误！
        
        // 错误：不能在calldata中使用mapping
        // mapping(address => uint256) calldata dataMap;  // 编译错误！
    }
}
```
为什么？

* Mapping的存储结构依赖于哈希计算
* Memory和calldata不支持这种存储方式
* Mapping必须在区块链上永久存储

**特性5：不能作为参数或返回值**
```sol
contract NoParameterReturn {
    mapping(address => uint256) public balances;
    
    // 错误：不能作为函数参数
    // function processMapping(
    //     mapping(address => uint256) storage map  // 编译错误！
    // ) public {
    //     // ...
    // }
    
    // 错误：不能作为返回值
    // function getMapping() public view 
    //     returns (mapping(address => uint256) storage)  // 编译错误！
    // {
    //     return balances;
    // }
}
```
原因：

* Mapping的大小不确定
* 无法复制整个mapping
* 传递mapping的成本无法预估

## 2.2 Mapping的限制总结
|操作|是否支持|说明|
|:--:|:--:|:--:|
|赋值|支持|map[key] = value|
|查询|支持|value = map[key]|
|删除单个值|支持|delete map[key]|
|删除整个mapping|不支持|无法清空整个mapping|
|遍历|不支持|没有键列表|
|获取长度|不支持|没有.length属性|
|作为参数|不支持|不能传递给函数|
|作为返回值|不支持|不能返回|
|Memory中使用|不支持|只能storage|

## 2.3 delete操作

虽然不能删除整个mapping，但可以删除单个键的值。
```sol
contract DeleteMapping {
    mapping(address => uint256) public balances;
    
    function setBalance(address user, uint256 amount) public {
        balances[user] = amount;
    }
    
    // 删除单个键的值
    function deleteBalance(address user) public {
        delete balances[user];
        // 将balances[user]重置为默认值0
    }
    
    function demonstrateDelete() public {
        address user = address(0x123);
        
        // 设置值
        balances[user] = 1000;
        // balances[user] = 1000
        
        // 删除
        delete balances[user];
        // balances[user] = 0（回到默认值）
    }
}
```
delete的效果：

* 将指定键的值重置为默认值
* 不是真正"删除"，而是"重置"
* 可以获得部分Gas退款

## 3. 嵌套Mapping
## 3.1 嵌套Mapping的概念
嵌套Mapping是指mapping的值本身也是一个mapping。
```sol
mapping(keyType1 => mapping(keyType2 => valueType)) 变量名;
```
理解方式：

* 外层mapping：第一级键值对
* 内层mapping：第二级键值对
* 类似于二维表或矩阵

## 3.2 嵌套Mapping示例
```sol
contract NestedMapping {
    // 用户地址 → 代币地址 → 余额数量
    mapping(address => mapping(address => uint256)) public tokenBalances;
    
    // 设置代币余额
    function setTokenBalance(
        address user,
        address token,
        uint256 amount
    ) public {
        tokenBalances[user][token] = amount;
    }
    
    // 获取代币余额
    function getTokenBalance(
        address user,
        address token
    ) public view returns (uint256) {
        return tokenBalances[user][token];
    }
    
    // 转账代币
    function transferToken(
        address token,
        address to,
        uint256 amount
    ) public {
        require(tokenBalances[msg.sender][token] >= amount, "Insufficient balance");
        
        tokenBalances[msg.sender][token] -= amount;
        tokenBalances[to][token] += amount;
    }
}
```
## 3.3 ERC20授权机制

嵌套Mapping最经典的应用是ERC20代币的授权机制。
```sol
contract ERC20Authorization {
    // 余额：地址 → 余额
    mapping(address => uint256) public balances;
    
    // 授权：所有者 → 被授权者 → 授权数量
    mapping(address => mapping(address => uint256)) public allowance;
    
    // 授权
    function approve(address spender, uint256 amount) public {
        allowance[msg.sender][spender] = amount;
        // msg.sender授权spender可以花费amount数量的代币
    }
    
    // 查询授权额度
    function getAllowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return allowance[owner][spender];
    }
    
    // 代他人转账
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public {
        // 检查授权额度
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");
        require(balances[from] >= amount, "Insufficient balance");
        
        // 扣除授权额度
        allowance[from][msg.sender] -= amount;
        
        // 转账
        balances[from] -= amount;
        balances[to] += amount;
    }
}
```
**ERC20授权流程：**
```sol
步骤1：Alice授权Bob可以花费100个代币
alice.approve(bob, 100)
    ↓
allowance[alice][bob] = 100

步骤2：Bob代Alice转账50个代币给Carol
bob.transferFrom(alice, carol, 50)
    ↓
检查：allowance[alice][bob] >= 50 ✓
    ↓
扣除授权：allowance[alice][bob] = 50
    ↓
转账：balances[alice] -= 50, balances[carol] += 50

结果：
- Alice余额减少50
- Carol余额增加50
- Bob剩余授权额度50
```
应用场景：

* DeFi协议（如Uniswap）代用户交易代币
* 交易所代用户充值
* 支付网关代用户支付

## 3.4 多层嵌套Mapping

理论上可以无限嵌套，但实际很少使用三层以上。
```sol
contract MultiLevelMapping {
    // 三层嵌套：用户 → 游戏 → 关卡 → 分数
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public gameScores;
    
    function setScore(
        uint256 gameId,
        uint256 level,
        uint256 score
    ) public {
        gameScores[msg.sender][gameId][level] = score;
    }
    
    function getScore(
        address player,
        uint256 gameId,
        uint256 level
    ) public view returns (uint256) {
        return gameScores[player][gameId][level];
    }
}
```
注意：

* 嵌套层数越多，代码可读性越差
* 通常不超过2-3层
* 考虑使用struct替代深层嵌套

# 4. Mapping与Array组合
## 4.1 为什么需要组合使用
**Mapping的问题：不能遍历**
**Array的问题：查找效率低（O(n)）**

解决方案：组合使用，发挥各自优势
|数据结构|优势|劣势|
|:--:|:--:|:--:|
|Mapping|O(1)查找|不能遍历|
|Array|可以遍历|O(n)查找|
|Mapping+Array|O(1)查找 + 可遍历|需要维护一致性|



































