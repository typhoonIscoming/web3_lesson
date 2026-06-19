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
## 2.3 定长数组的限制
```sol
contract FixedArrayLimitations {
    uint[5] public numbers = [1, 2, 3, 4, 5];
    function attemptPush() public {
        // 编译错误：定长数组不支持push
        // numbers.push(6);  // Error!
    }
    function attemptPop() public {
        // 编译错误：定长数组不支持pop
        // numbers.pop();  // Error!
    }
    // 可以使用delete设置为默认值
    function resetElement(uint index) public {
        delete numbers[index];  // 将numbers[index]设为0
    }
}
```
## 2.4 定长数组的使用场景

**适合使用定长数组的场景：**
```sol
// 1. 固定数量的配置参数：
contract WeeklySchedule {
    // 一周7天的工作时间（小时）
    uint8[7] public workingHours = [8, 8, 8, 8, 8, 0, 0];
}
// 2. 预定义的选项集合：
contract VotingSystem {
    // 固定的4个选项
    string[4] public options = ["Option A", "Option B", "Option C", "Option D"];
}
// 3. 固定大小的数据记录：
contract GameBoard {
    // 3x3的井字棋棋盘
    uint8[9] public board;  // 0=空, 1=X, 2=O
}
```
# 3. 动态数组

## 3.1 动态数组的声明和初始化
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract DynamicArrayExample {
    // 声明动态数组（空数组）
    uint[] public numbers;
    
    // 声明并初始化
    address[] public users = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    ];
    // 其他类型的动态数组
    string[] public names;
    bool[] public flags;
    bytes[] public dataList;
    constructor() {
        // 在构造函数中添加初始元素
        numbers.push(1);
        numbers.push(2);
        numbers.push(3);
    }
}
```
## 3.2 动态数组的基本操作
```sol
// 添加元素（push）：
contract DynamicArrayPush {
    uint[] public numbers;
    // 添加单个元素
    function addNumber(uint value) public {
        numbers.push(value);
    }
    // 批量添加元素
    function addMultiple(uint[] memory values) public {
        for(uint i = 0; i < values.length; i++) {
            numbers.push(values[i]);
        }
    }
    // push的返回值（Solidity 0.6.0+）
    function pushAndGetLength(uint value) public returns (uint) {
        numbers.push(value);
        return numbers.length;
    }
}
// 删除最后元素（pop）：
contract DynamicArrayPop {
    uint[] public numbers = [1, 2, 3, 4, 5];
    // 删除最后一个元素
    function removeLastElement() public {
        require(numbers.length > 0, "Array is empty");
        numbers.pop();
    }
    // 删除多个元素
    function removeMultiple(uint count) public {
        require(count <= numbers.length, "Not enough elements");
        for(uint i = 0; i < count; i++) {
            numbers.pop();
        }
    }
    // 获取并删除最后元素
    function popAndReturn() public returns (uint) {
        require(numbers.length > 0, "Array is empty");
        uint lastValue = numbers[numbers.length - 1];
        numbers.pop();
        return lastValue;
    }
}
// 获取长度（length）：
contract ArrayLength {
    uint[] public data;
    function getLength() public view returns (uint) {
        return data.length;
    }
    function isEmpty() public view returns (bool) {
        return data.length == 0;
    }
    function addAndCheckLength(uint value) public returns (uint) {
        data.push(value);
        return data.length;  // 返回添加后的长度
    }
}
```
## 3.3 Storage数组 vs Memory数组
```sol
// Storage数组（状态变量）：
contract StorageArray {
    uint[] public storageArray;  // 存储在区块链上
    function addToStorage(uint value) public {
        storageArray.push(value);  // 修改永久保存
    }
    function getStorage() public view returns (uint[] memory) {
        return storageArray;  // 返回storage数组的副本
    }
}
// Memory数组（临时变量）：
contract MemoryArray {
    // 在memory中创建数组
    function createMemoryArray() public pure returns (uint[] memory) {
        // 必须指定长度
        uint[] memory arr = new uint[](5);
        
        // 可以赋值
        arr[0] = 1;
        arr[1] = 2;
        arr[2] = 3;
        arr[3] = 4;
        arr[4] = 5;
        
        return arr;
    }
    // Memory数组的限制
    function memoryArrayLimitations() public pure {
        uint[] memory arr = new uint[](5);
        // 不能push（编译错误）
        // arr.push(6);  // Error!
        
        // 不能pop（编译错误）
        // arr.pop();  // Error!
        
        // 不能改变长度
        // arr.length = 10;  // Error!
    }
}
```
**Storage vs Memory对比：**
|特性|Storage数组|Memory数组|
|:--:|:--:|:--:|
|存储位置|区块链上（永久）|内存中（临时）|
|创建方式|状态变量声明|new uint[](n)|
|长度|可变（动态数组）|固定（创建时确定）|
|push/pop|支持|不支持|
|Gas成本|高（写入区块链）|低（仅计算）|
|生命周期|永久|函数执行期间|

# 4. 数组基本操作

## 4.1 访问数组元素
```sol
contract ArrayAccess {
    uint[] public numbers = [10, 20, 30, 40, 50];
    // 通过索引访问
    function getElement(uint index) public view returns (uint) {
        require(index < numbers.length, "Index out of bounds");
        return numbers[index];
    }
    // 获取第一个元素
    function getFirst() public view returns (uint) {
        require(numbers.length > 0, "Array is empty");
        return numbers[0];
    }
    // 获取最后一个元素
    function getLast() public view returns (uint) {
        require(numbers.length > 0, "Array is empty");
        return numbers[numbers.length - 1];
    }
    // 安全访问（返回bool表示是否成功）
    function tryGetElement(uint index) public view returns (bool, uint) {
        if (index >= numbers.length) {
            return (false, 0);
        }
        return (true, numbers[index]);
    }
}
```
## 4.2 修改数组元素
```sol
contract ArrayModification {
    uint[] public numbers = [1, 2, 3, 4, 5];
    // 修改指定位置的元素
    function updateElement(uint index, uint value) public {
        require(index < numbers.length, "Index out of bounds");
        numbers[index] = value;
    }
    // 递增元素值
    function incrementElement(uint index) public {
        require(index < numbers.length, "Index out of bounds");
        numbers[index] += 1;
    }
    // 批量修改
    function updateMultiple(uint[] memory indices, uint[] memory values) public {
        require(indices.length == values.length, "Length mismatch");
        
        for(uint i = 0; i < indices.length; i++) {
            require(indices[i] < numbers.length, "Index out of bounds");
            numbers[indices[i]] = values[i];
        }
    }
    // 重置所有元素为0
    function resetAll() public {
        delete numbers;  // 清空数组，length变为0
    }
}
```
## 4.3 获取整个数组
```sol
contract GetWholeArray {
    uint[] public numbers;
    constructor() {
        numbers.push(1);
        numbers.push(2);
        numbers.push(3);
    }
    // 返回整个数组
    function getAllNumbers() public view returns (uint[] memory) {
        return numbers;
    }
    // 返回数组副本并进行处理
    function getDoubledArray() public view returns (uint[] memory) {
        uint[] memory result = new uint[](numbers.length);
        for(uint i = 0; i < numbers.length; i++) {
            result[i] = numbers[i] * 2;
        }
        return result;
    }
}
```
## 4.4 delete操作的陷阱
```sol
contract DeleteTrap {
    uint[] public numbers = [1, 2, 3, 4, 5];
    // delete单个元素
    function deleteElement(uint index) public {
        require(index < numbers.length, "Index out of bounds");
        delete numbers[index];
        // 结果：numbers[index] = 0
        // 重要：length不变！
    }
    // 演示delete的问题
    function demonstrateDeleteProblem() public {
        // 初始：[1, 2, 3, 4, 5], length = 5
        delete numbers[2];
        // 结果：[1, 2, 0, 4, 5], length = 5
        // 注意：3变成了0，但数组长度仍然是5
        // 留下了一个"空洞"
    }
    // delete整个数组
    function deleteArray() public {
        delete numbers;
        // 结果：[], length = 0
        // 清空整个数组
    }
    // 检查空洞
    function hasZeros() public view returns (bool) {
        for(uint i = 0; i < numbers.length; i++) {
            if(numbers[i] == 0) {
                return true;  // 发现空洞
            }
        }
        return false;
    }
}
```
**delete操作总结：**
|操作|效果|length变化|注意事项|
|:--:|:--:|:--:|:--:|
|delete arr[i]|元素重置为0|不变|留下空洞|
|delete arr|清空数组|变为0|完全清空|
|arr.pop()|删除最后元素|减1|真正删除|

# 5. 删除数组元素

## 5.1 删除方法对比

在Solidity中，真正删除数组中间的元素需要特殊处理。有两种主要方法：

1. 方法1：保持顺序（移动元素）

优点：保持元素的原有顺序 缺点：Gas消耗高（需要移动多个元素）

2. 方法2：快速删除（不保序）

优点：Gas消耗低（只需两步操作） 缺点：不保持元素顺序

## 5.2 方法1：保持顺序删除
```sol
contract OrderedRemoval {
    uint[] public numbers;
    constructor() {
        numbers = [1, 2, 3, 4, 5];
    }
    // 删除指定索引的元素，保持顺序
    function removeOrdered(uint index) public {
        require(index < numbers.length, "Index out of bounds");
        
        // 将后面的元素向前移动
        for(uint i = index; i < numbers.length - 1; i++) {
            numbers[i] = numbers[i + 1];
        }
        // 删除最后一个元素
        numbers.pop();
    }
    // 示例演示
    function demonstrateOrderedRemoval() public {
        // 初始：[1, 2, 3, 4, 5]
        removeOrdered(1);  // 删除索引1的元素（值为2）
        // 结果：[1, 3, 4, 5]
        // 顺序保持：3、4、5向前移动
    }
}
// 执行过程详解
初始数组：[1, 2, 3, 4, 5]
删除索引1（值为2）：

步骤1：i=1, numbers[1] = numbers[2]  → [1, 3, 3, 4, 5]
步骤2：i=2, numbers[2] = numbers[3]  → [1, 3, 4, 4, 5]
步骤3：i=3, numbers[3] = numbers[4]  → [1, 3, 4, 5, 5]
步骤4：pop()                         → [1, 3, 4, 5]

最终结果：[1, 3, 4, 5]
```
**Gas分析：**
假设删除索引为index，数组长度为n：

* 需要移动的元素数量：n - index - 1
* 每次赋值约消耗：5,000 gas（storage写入）
* 总Gas消耗：约5,000 × (n - index - 1) + 5,000（pop）

## 5.3 方法2：快速删除（不保序）
```sol
contract UnorderedRemoval {
    uint[] public numbers;
    constructor() {
        numbers = [1, 2, 3, 4, 5];
    }
    // 快速删除，不保持顺序
    function removeUnordered(uint index) public {
        require(index < numbers.length, "Index out of bounds");
        
        // 用最后一个元素替换要删除的元素
        numbers[index] = numbers[numbers.length - 1];
        
        // 删除最后一个元素
        numbers.pop();
    }
    // 示例演示
    function demonstrateUnorderedRemoval() public {
        // 初始：[1, 2, 3, 4, 5]
        removeUnordered(1);  // 删除索引1的元素（值为2）
        // 结果：[1, 5, 3, 4]
        // 最后的5移到了索引1的位置
    }
}
// 执行过程详解：
初始数组：[1, 2, 3, 4, 5]
删除索引1（值为2）：

步骤1：numbers[1] = numbers[4]  → [1, 5, 3, 4, 5]
步骤2：pop()                    → [1, 5, 3, 4]

最终结果：[1, 5, 3, 4]
```
**Gas分析：**

* 一次赋值：约5,000 gas
* 一次pop：约5,000 gas
* 总Gas消耗：约10,000 gas（常量，不随数组大小变化）

## 5.4 删除方法选择指南
```sol
contract RemovalComparison {
    uint[] public orderedArray;
    uint[] public unorderedArray;
    // 初始化两个相同的数组
    function initialize() public {
        delete orderedArray;
        delete unorderedArray;
        
        for(uint i = 1; i <= 100; i++) {
            orderedArray.push(i);
            unorderedArray.push(i);
        }
    }
    // 保序删除（Gas高）
    function testOrderedRemoval() public {
        require(orderedArray.length > 50, "Not enough elements");
        
        // 删除中间元素（索引50）
        for(uint i = 50; i < orderedArray.length - 1; i++) {
            orderedArray[i] = orderedArray[i + 1];
        }
        orderedArray.pop();
        // Gas: 约 250,000（需要移动50个元素）
    }
    
    // 快速删除（Gas低）
    function testUnorderedRemoval() public {
        require(unorderedArray.length > 50, "Not enough elements");
        
        // 删除中间元素（索引50）
        unorderedArray[50] = unorderedArray[unorderedArray.length - 1];
        unorderedArray.pop();
        // Gas: 约 10,000（固定消耗）
    }
}
```
**何时使用哪种方法：**

|使用场景|推荐方法|原因|
|:--:|:--:|:--:|
|需要保持顺序（如排行榜）|保序删除|顺序重要|
|数组很小（<20个元素）|保序删除|Gas差异小|
|数组较大且顺序不重要|快速删除|节省Gas|
|用户列表、ID列表|快速删除|顺序无关紧要|
|历史记录、时间序列|保序删除|时间顺序重要|




































