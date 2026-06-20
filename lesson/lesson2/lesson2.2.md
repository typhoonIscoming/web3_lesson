# 7. 运算符详解

## 7.1 算术运算符
```sol
contract ArithmeticOperators {
    function arithmetic() public pure returns (uint, uint, uint, uint, uint, uint) {
        uint a = 10;
        uint b = 3;
        return (
            a + b,   // 加法：13
            a - b,   // 减法：7
            a * b,   // 乘法：30
            a / b,   // 除法：3
            a % b,   // 取模：1
            a ** b   // 幂运算：1000
        );
    }
    // 复合赋值运算符
    function compoundAssignment() public pure returns (uint) {
        uint x = 10;
        x += 5;  // 等同于 x = x + 5
        x -= 3;  // 等同于 x = x - 3
        x *= 2;  // 等同于 x = x * 2
        x /= 4;  // 等同于 x = x / 4
        x %= 3;  // 等同于 x = x % 3
        return x;
    }
}
```
## 7.2 比较运算符
```sol
contract ComparisonOperators {
    function comparison() public pure returns (bool, bool, bool, bool, bool, bool) {
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
## 7.3 逻辑运算符
```sol
contract LogicalOperators {
    function logical() public pure returns (bool, bool, bool) {
        bool a = true;
        bool b = false;
        return (
            a && b,  // 逻辑与：false
            a || b,  // 逻辑或：true
            !a       // 逻辑非：false
        );
    }
}
```
## 7.4 位运算符
```sol
// 位运算符直接操作整数的二进制位：
contract BitwiseOperators {
    function bitwise() public pure returns (uint, uint, uint, uint, uint, uint) {
        uint a = 5;   // 二进制：0101
        uint b = 3;   // 二进制：0011
        
        return (
            a & b,   // 按位与：1（0001）
            a | b,   // 按位或：7（0111）
            a ^ b,   // 按位异或：6（0110）
            ~a,      // 按位非：uint256最大值-5
            a << 1,  // 左移：10（1010）
            a >> 1   // 右移：2（0010）
        );
    }
    // 位运算的实际应用
    function checkBit(uint value, uint position) public pure returns (bool) {
        // 检查某一位是否为1
        return (value & (1 << position)) != 0;
    }
    function setBit(uint value, uint position) public pure returns (uint) {
        // 将某一位设置为1
        return value | (1 << position);
    }
    function clearBit(uint value, uint position) public pure returns (uint) {
        // 将某一位设置为0
        return value & ~(1 << position);
    }
}
```
## 7.5 短路运算

**逻辑与（&&）和逻辑或（||）支持短路运算：**
```sol
contract ShortCircuit {
    // 逻辑与的短路
    function andShortCircuit(uint x, uint y) public pure returns (bool) {
        // 如果x == 0，不会执行y / x（避免除零错误）
        if (x != 0 && y / x > 5) {
            return true;
        }
        return false;
    }
    // 逻辑或的短路
    function orShortCircuit(bool condition1, bool condition2) public pure returns (bool) {
        // 如果condition1是true，不会检查condition2
        return condition1 || condition2;
    }
    // 短路运算的实际应用
    function safeTransfer(address recipient, uint amount) public view returns (bool) {
        // 先检查简单条件，再检查复杂条件（优化gas）
        return recipient != address(0) && amount > 0 && address(this).balance >= amount;
    }
}
```
**短路运算的优势：**

1. 防止错误：避免除零、数组越界等错误
2. 优化gas：避免不必要的计算
3. 逻辑清晰：先检查简单条件


# 8. 类型转换

## 8.1 隐式转换

**隐式转换是编译器自动进行的转换，只在安全的情况下发生（小类型到大类型）：**
```sol
contract ImplicitConversion {
    function implicitConvert() public pure returns (uint256, uint256) {
        uint8 small = 100;
        uint256 big = small;  // 自动转换，安全
        uint16 medium = 1000;
        uint256 big2 = medium;  // 自动转换，安全
        
        return (big, big2);
    }
}
```
**隐式转换规则：**

* 小整数类型可以隐式转换为大整数类型
* 无符号整数不能隐式转换为有符号整数
* 有符号整数不能隐式转换为无符号整数

## 8.2 显式转换

显式转换需要手动指定，用于大类型到小类型的转换：
```sol
contract ExplicitConversion {
    function explicitConvert() public pure returns (uint8) {
        uint256 big = 300;
        uint8 small = uint8(big);  // 需要显式转换
        // 警告：300转为uint8会溢出！
        // 结果：44（300 % 256 = 44）
        return small;
    }
}
// 危险示例：
contract DangerousConversion {
    function dangerousConvert() public pure returns (uint8, uint8) {
        uint256 value1 = 255;
        uint256 value2 = 256;
        
        return (
            uint8(value1),  // 255（正常）
            uint8(value2)   // 0（溢出！）
        );
    }
}
```

## 8.3 安全的类型转换

在进行显式转换时，应该先检查范围：

```sol
contract SafeConversion {
    // 安全转换函数
    function safeConvertToUint8(uint256 value) public pure returns (uint8) {
        require(value <= type(uint8).max, "Value too large for uint8");
        return uint8(value);
    }
    function safeConvertToUint16(uint256 value) public pure returns (uint16) {
        require(value <= type(uint16).max, "Value too large for uint16");
        return uint16(value);
    }
    // 使用type(T).max和type(T).min
    function getTypeInfo() public pure returns (uint8, uint8, int8, int8) {
        return (
            type(uint8).max,   // 255
            type(uint8).min,   // 0
            type(int8).max,    // 127
            type(int8).min     // -128
        );
    }
}
// type(T).max和type(T).min：
contract TypeInfo {
    function showTypeInfo() public pure returns (
        uint8, uint8,
        uint16, uint16,
        uint256, uint256,
        int8, int8,
        int256, int256
    ) {
        return (
            type(uint8).min,    // 0
            type(uint8).max,    // 255
            type(uint16).min,   // 0
            type(uint16).max,   // 65535
            type(uint256).min,  // 0
            type(uint256).max,  // 2^256-1
            type(int8).min,     // -128
            type(int8).max,     // 127
            type(int256).min,   // -2^255
            type(int256).max    // 2^255-1
        );
    }
}
```

## 8.4 地址类型转换
```sol
contract AddressTypeConversion {
    // address转address payable
    function toPayable(address addr) public pure returns (address payable) {
        return payable(addr);
    }
    // uint160转address
    function uintToAddress(uint160 num) public pure returns (address) {
        return address(num);
    }
    // address转uint160
    function addressToUint(address addr) public pure returns (uint160) {
        return uint160(addr);
    }
    // 完整示例
    function conversionExample() public view returns (address, uint160, address payable) {
        address addr = msg.sender;
        uint160 num = uint160(addr);
        address payable pAddr = payable(addr);
        
        return (addr, num, pAddr);
    }
}
```
**为什么是uint160？**

因为地址是20字节 = 160位，所以只能和uint160互相转换。

# 9. 实践练习

**练习1：投票合约**

创建一个简单的投票合约，使用枚举定义投票选项。

**任务要求：**

1. 使用enum定义投票选项：Yes, No, Abstain
2. 使用mapping记录每个地址的投票
3. 使用uint统计每个选项的票数
4. 实现投票和查询功能

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    enum Vote { Yes, No, Abstain }
    
    mapping(address => Vote) public votes;
    mapping(address => bool) public hasVoted;
    uint public yesCount;
    uint public noCount;
    uint public abstainCount;
    
    event Voted(address indexed voter, Vote vote);
    
    function vote(Vote _vote) public {
        require(!hasVoted[msg.sender], "Already voted");
        
        votes[msg.sender] = _vote;
        hasVoted[msg.sender] = true;
        
        if (_vote == Vote.Yes) {
            yesCount++;
        } else if (_vote == Vote.No) {
            noCount++;
        } else {
            abstainCount++;
        }
        
        emit Voted(msg.sender, _vote);
    }
    
    function getResults() public view returns (uint, uint, uint) {
        return (yesCount, noCount, abstainCount);
    }
    
    function getMyVote() public view returns (Vote) {
        require(hasVoted[msg.sender], "You haven't voted");
        return votes[msg.sender];
    }
    
    function getTotalVotes() public view returns (uint) {
        return yesCount + noCount + abstainCount;
    }
}
```

**练习2：类型转换练习**

编写函数实现以下功能：

任务1：安全的uint256转uint8
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TypeConversionPractice {
    // 任务1：安全转换
    function safeConvertToUint8(uint256 value) public pure returns (uint8) {
        require(value <= type(uint8).max, "Value too large for uint8");
        return uint8(value);
    }
    
    // 任务2：字符串比较
    function compareStrings(string memory a, string memory b) 
        public pure returns (bool) 
    {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
    
    // 任务3：零地址检查
    function isZeroAddress(address addr) public pure returns (bool) {
        return addr == address(0);
    }
    
    // 额外测试函数
    function testConversion() public pure returns (uint8, uint8) {
        return (
            safeConvertToUint8(255),  // 成功
            safeConvertToUint8(100)   // 成功
            // safeConvertToUint8(256) // 会revert
        );
    }
    
    function testStringComparison() public pure returns (bool, bool) {
        return (
            compareStrings("Hello", "Hello"),  // true
            compareStrings("Hello", "World")   // false
        );
    }
    
    function testZeroAddress() public pure returns (bool, bool) {
        return (
            isZeroAddress(address(0)),                              // true
            isZeroAddress(0x0000000000000000000000000000000000001234)  // false
        );
    }
}
```

## 练习3：综合练习 - 简单代币合约

创建一个简单的代币合约，综合运用所学的数据类型。

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleToken {
    // 状态变量
    string public name = "My Token";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    address public owner;
    
    mapping(address => uint256) public balanceOf;
    
    // 事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // 构造函数
    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }
    
    // 转账函数
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "Cannot transfer to zero address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    // 查询余额
    function getBalance(address _owner) public view returns (uint256) {
        return balanceOf[_owner];
    }
    
    // 铸造代币（仅owner）
    function mint(address _to, uint256 _amount) public {
        require(msg.sender == owner, "Only owner can mint");
        require(_to != address(0), "Cannot mint to zero address");
        
        totalSupply += _amount;
        balanceOf[_to] += _amount;
        
        emit Transfer(address(0), _to, _amount);
    }
}
```

# 10. 常见问题解答

**Q1：为什么字符串不能直接比较？**

答：在Solidity中，字符串是引用类型，直接比较会比较引用（内存地址），而不是内容。正确的做法是比较它们的哈希值：
```sol
keccak256(bytes(str1)) == keccak256(bytes(str2))
```
**Q2：uint和uint256有什么区别？**

答：没有区别。uint是uint256的别名，它们完全等价。同样，int是int256的别名。

**Q3：什么时候使用address，什么时候使用address payable？**
答：

* 使用address：只需要存储地址或查询余额
* 使用address payable：需要向该地址转账ETH

可以使用payable(addr)将address转换为address payable。

**Q4：为什么除法10/3结果是3而不是3.333？**

答：Solidity没有浮点数类型，所有除法都是整数除法，只保留整数部分。如果需要精度，可以先乘以精度倍数再除：
```sol
uint result = (10 * 1000) / 3;  // 3333
// 在前端显示时除以1000，得到3.333
```

**Q5：unchecked什么时候使用？**

答：只在以下情况使用unchecked：

1. 确定不会溢出的循环计数器
2. 已经通过其他方式检查过不会溢出的计算
3. 性能关键且安全性已验证的代码

不正确使用unchecked可能导致严重的安全漏洞！

**Q6：bytes和string有什么区别？**

1. bytes：原始字节数据，可以访问单个字节
2. string：UTF-8编码的文本，不能访问单个字节

如果需要操作单个字节，使用bytes。如果存储文本，使用string。

**Q7：枚举可以转换为整数吗？**

可以。枚举本质上是uint8，可以显式转换：
```sol
enum Status { Pending, Approved }
Status s = Status.Approved;
uint num = uint(s);  // 1
```

# 11. 知识点总结

**数据类型分类**

**值类型：**
1. bool：布尔类型（true/false）
2. int/uint：整数类型（有符号/无符号）
3. address：地址类型（普通/可支付）
4. bytes1-bytes32：固定字节数组
5. enum：枚举类型

**引用类型：**

1. array：数组
2. string：字符串
3. struct：结构体
4. mapping：映射
5. bytes：动态字节数组

**关键特性**

1. uint256最常用：EVM原生类型，最高效
2. Solidity 0.8+自动检查溢出：提高安全性
3. address是区块链特有类型：用于存储以太坊地址
4. 字符串比较需要用哈希：不能直接比较
5. 枚举提高可读性：类型安全且节省gas
6. 无浮点数：除法只保留整数部分

**安全实践**
* 类型转换前检查范围
* 使用type(T).max和type(T).min
* 注意整数除法特性
* 谨慎使用unchecked
* 使用msg.sender而不是tx.origin
* 零地址检查

**类型选择建议**

整数类型：
1. 默认使用uint256
2. 需要负数时使用int256
3. 只在变量打包时考虑小类型

地址类型：
1. 普通地址用address
2. 需要接收ETH用address payable

文本类型：
1. 短标识符用bytes32
2. 用户输入文本用string

状态管理：
1. 有限状态集合用enum

# 12. 学习检查清单
完成本课后，你应该能够：

数据类型理解：

 区分值类型和引用类型
 理解uint256为什么最常用
 掌握地址类型的特性
 理解枚举的优势
布尔和整数：

 会使用布尔运算符
 会使用整数运算符
 理解整数溢出保护
 知道何时使用unchecked
字符串和字节：

 会比较字符串
 会拼接字符串（0.8.12+）
 理解bytes和string的区别
 会使用bytes32存储哈希
枚举和转换：

 会定义和使用枚举
 会进行安全的类型转换
 会使用type(T).max/min
 理解地址类型转换

实践能力：
    能编写投票合约
    能实现类型转换函数
    能综合运用各种类型

# 13. 下一步学习
完成本课后，建议：

反复练习示例代码
完成所有练习题
尝试修改和扩展示例合约
准备学习第2.2课：引用类型详解
下节课预告：

数组的详细用法
映射的特性和限制
结构体的定义和使用
存储位置的深入理解




