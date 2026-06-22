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
```sol
contract TernaryOperator {
    // 使用if-else
    function maxWithIf(uint a, uint b) 
        public pure returns (uint) 
    {
        if (a > b) {
            return a;
        } else {
            return b;
        }
    }
    
    // 使用三元运算符（推荐）
    function maxWithTernary(uint a, uint b) 
        public pure returns (uint) 
    {
        return a > b ? a : b;
    }
    
    // 更多示例
    function getStatus(bool isActive) 
        public pure returns (string memory) 
    {
        return isActive ? "Active" : "Inactive";
    }
    
    // 嵌套三元运算符（不推荐，难以阅读）
    function complexTernary(uint value) 
        public pure returns (string memory) 
    {
        return value > 100 ? "High" : 
               value > 50 ? "Medium" : "Low";
        // 可读性差，建议用if-else if
    }
}
```
**使用建议：**

适合使用：

1. 简单的条件赋值
2. 返回值选择
3. 单行逻辑

不适合使用：

1. 复杂逻辑
2. 多层嵌套
3. 需要执行多条语句

# 3. 循环语句

## 3.1 for循环
for循环是最常用的循环语句，适合已知循环次数的场景。
```sol
contract ForLoop {
    // 基本for循环
    function sum(uint n) public pure returns (uint) {
        uint total = 0;
        for (uint i = 0; i <= n; i++) {
            total += i;
        }
        return total;
    }
    
    // 数组遍历
    function sumArray(uint[] memory arr) 
        public pure returns (uint) 
    {
        uint total = 0;
        for (uint i = 0; i < arr.length; i++) {
            total += arr[i];
        }
        return total;
    }
    
    // 倒序循环
    function countdown(uint n) 
        public pure returns (uint[] memory) 
    {
        uint[] memory result = new uint[](n);
        for (uint i = n; i > 0; i--) {
            result[n - i] = i;
        }
        return result;
    }
    
    // 步长为2的循环
    function sumEven(uint n) public pure returns (uint) {
        uint total = 0;
        for (uint i = 0; i <= n; i += 2) {
            total += i;
        }
        return total;
    }
}
```
## 3.2 while循环
while循环先判断条件，再执行循环体，适合循环次数不确定的场景。
```sol
contract WhileLoop {
    // 基本while循环
    function countdown(uint start) 
        public pure returns (uint) 
    {
        uint count = start;
        while (count > 0) {
            count--;
        }
        return count;
    }
    
    // 查找第一个非零值
    function findNonZero(uint[] memory arr) 
        public pure returns (uint) 
    {
        uint i = 0;
        while (i < arr.length && arr[i] == 0) {
            i++;
        }
        return i;  // 返回第一个非零值的索引
    }
    
    // 计算2的幂次
    function powerOfTwo(uint target) 
        public pure returns (uint) 
    {
        uint result = 1;
        while (result < target) {
            result *= 2;
        }
        return result;
    }
}
```
**while循环特点：**

* 先判断条件，再执行
* 最少执行0次（条件初始就为false）
* 适合条件驱动的循环

## 3.3 do-while循环
do-while循环先执行循环体，再判断条件，保证至少执行一次。
```sol
contract DoWhileLoop {
    // 基本do-while
    function doWhileDemo(uint n) 
        public pure returns (uint) 
    {
        uint i = 0;
        uint result = 0;
        do {
            result += i;
            i++;
        } while (i < n);
        return result;
    }
    
    // 至少执行一次的场景
    function validateInput(uint value) 
        public pure returns (bool) 
    {
        uint attempts = 0;
        bool valid = false;
        
        do {
            attempts++;
            valid = (value > 0);
            value = value / 10;
        } while (value > 0 && attempts < 10);
        
        return valid;
    }
}
```
**do-while特点：**

* 先执行，再判断
* 至少执行1次
* 使用较少，适合特殊场景

## 3.4 三种循环的对比
|特性|for|while|do-while|
|:--:|:--:|:--:|:--:|
|语法复杂度|复杂|简单|简单|
|循环次数|已知|未知|未知|
|最少执行|0次|0次|1次|
|适用场景|计数循环|条件循环|至少执行一次|
|使用频率|最高|中等|较低|

**选择建议：**

1. 优先选择for循环
    + 循环次数明确
    + 代码结构清晰
    + 不易出错

2. 其次考虑while
    + 条件驱动
    + 灵活性高

3. 谨慎使用do-while
    + 特殊场景（至少执行一次）
    + 使用较少

## 3.5 break和continue
**break：立即退出循环**
```sol
contract BreakStatement {
    // 查找目标值
    function findTarget(uint[] memory arr, uint target) 
        public pure returns (bool, uint) 
    {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == target) {
                return (true, i);  // 找到就退出
            }
        }
        return (false, 0);
    }
    // 查找第一个满足条件的元素
    function findFirstGreaterThan(uint[] memory arr, uint threshold) 
        public pure returns (uint) 
    {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] > threshold) {
                return i;  // 找到就退出
            }
        }
        revert("Not found");
    }
}
```
**continue：跳过本次循环，继续下一次**
```sol
contract ContinueStatement {
    // 只累加偶数
    function sumEven(uint n) 
        public pure returns (uint) 
    {
        uint total = 0;
        for (uint i = 0; i <= n; i++) {
            if (i % 2 != 0) {
                continue;  // 跳过奇数
            }
            total += i;
        }
        return total;
    }
    
    // 跳过零值
    function sumNonZero(uint[] memory arr) 
        public pure returns (uint) 
    {
        uint total = 0;
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == 0) {
                continue;  // 跳过0
            }
            total += arr[i];
        }
        return total;
    }
    // 过滤无效地址
    function countValidAddresses(address[] memory addresses) 
        public pure returns (uint) 
    {
        uint count = 0;
        for (uint i = 0; i < addresses.length; i++) {
            if (addresses[i] == address(0)) {
                continue;  // 跳过零地址
            }
            count++;
        }
        return count;
    }
}
```
**break vs continue：**
|关键字|作用|效果|使用场景|
|:--:|:--:|:--:|:--:|
|break|退出循环|终止整个循环|找到目标值|
|continue|跳过本次|继续下次循环|过滤特定值|

# 4. 循环的Gas成本
**循环是Solidity开发中最危险的操作之一，因为Gas成本会随循环次数线性或指数增长。**

危险示例：
```sol
contract DangerousLoop {
    uint[] public data;
    // 危险：无限制的循环
    function sumAll() public view returns (uint) {
        uint total = 0;
        for (uint i = 0; i < data.length; i++) {
            total += data[i];
        }
        return total;
        // 如果data有10,000个元素，这个函数将无法执行！
    }
}
```
**Gas消耗分析：**
|数组大小|循环次数|Gas消耗（估算）|结果|
|:--:|:--:|:--:|:--:|
|10|10|~5,000|成功|
|100|100|~50,000|成功|
|1,000|1,000|~500,000|可能失败|
|10,000|10,000|~5,000,000|必定失败|
**区块Gas限制：以太坊每个区块的Gas限制约为30,000,000，单个交易通常限制在10,000,000以内。**

## 4.2 嵌套循环的危险
嵌套循环的Gas消耗呈指数增长。
```sol
contract NestedLoopDanger {
    // 危险：O(n²)复杂度
    function multiplicationTable(uint n) 
        public pure returns (uint[][] memory) 
    {
        uint[][] memory table = new uint[][](n);
        
        for (uint i = 0; i < n; i++) {        // 外循环
            table[i] = new uint[](n);
            for (uint j = 0; j < n; j++) {    // 内循环
                table[i][j] = (i + 1) * (j + 1);
            }
        }
        
        return table;
    }
}
```
**Gas消耗对比：**
|输入大小(n)|循环总次数|Gas消耗（估算）|状态|
|:--:|:--:|:--:|:--:|
|n=10|100|~50,000|安全|
|n=50|2,500|~500,000|警告|
|n=100|10,000|~2,000,000|危险|
|n=200|40,000|~8,000,000|极危险|

三大危害：

1. Gas耗尽：交易失败，但已消耗的Gas不退还
2. 资金锁定：如果提款函数有循环，用户可能无法提款
3. DoS攻击：恶意用户可以故意让合约无法使用

## 4.3 循环安全实践
## 方案1：限制循环次数
```sol
contract SafeLoop {
    uint public constant MAX_ARRAY_SIZE = 100;
    // 限制输入大小
    function safeSum(uint[] memory data) 
        public pure returns (uint) 
    {
        require(data.length <= MAX_ARRAY_SIZE, "Array too large");
        
        uint total = 0;
        for (uint i = 0; i < data.length; i++) {
            total += data[i];
        }
        return total;
    }
}
```
## 方案2：使用mapping代替循环
```sol
contract UseMappingInstead {
    // 不好：需要循环查找
    address[] public users;
    function getUserBalance(address user) public view returns (uint) {
        // O(n) 复杂度，很慢
        for (uint i = 0; i < users.length; i++) {
            if (users[i] == user) {
                return i;
            }
        }
        return 0;
    }
    // 好：使用mapping，O(1)查询
    mapping(address => uint) public balances;
    
    function getBalance(address user) public view returns (uint) {
        return balances[user];  // 直接访问，快速
    }
}
```
## 方案3：分批处理
```sol
contract BatchProcessing {
    uint[] public data;
    uint public constant BATCH_SIZE = 50;
    
    // 分批处理大数组
    function processBatch(uint startIndex, uint batchSize) 
        public 
    {
        require(batchSize <= BATCH_SIZE, "Batch too large");
        uint endIndex = startIndex + batchSize;
        require(endIndex <= data.length, "Out of bounds");
        
        for (uint i = startIndex; i < endIndex; i++) {
            // 每次处理50个，分多次交易完成
            data[i] = data[i] * 2;
        }
    }
}
```
## 方案4：链下计算，链上存储
```sol
contract OffchainCalculation {
    mapping(address => uint) public rewards;
    
    // 前端计算好结果，合约只存储
    function setRewards(
        address[] calldata users,
        uint[] calldata amounts
    ) external {
        require(users.length == amounts.length, "Length mismatch");
        require(users.length <= 100, "Too many users");
        
        // 只是简单的赋值，不做复杂计算
        for (uint i = 0; i < users.length; i++) {
            rewards[users[i]] = amounts[i];
        }
    }
}
```

## 4.4 Gas优化效果对比
|方法|Gas消耗|适用场景|推荐度|
|:--:|:--:|:--:|:--:|
|无限制循环|极高|危险，避免|不推荐|
|限制循环次数|中等|小数据集([<]100)	|推荐|
|mapping查询|恒定(低)|单个查询|强烈推荐|
|分批处理|分散|大数据集|推荐|
|链下计算|几乎为0|复杂计算|强烈推荐|

实际案例对比：

处理1000个用户的积分：

方案A：循环遍历
```sol
function updateAll() public {
    for (uint i = 0; i < users.length; i++) {
        scores[users[i]] += 10;
    }
}
// Gas: ~2,000,000（可能失败）
```
方案B：mapping直接更新
```sol
function updateUser(address user) public {
    scores[user] += 10;
}
// Gas: ~25,000（每次）
// 用户自己调用，分散Gas成本
```













