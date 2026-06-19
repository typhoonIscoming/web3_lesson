# 7. 多维数组

# 7.1 二维数组声明
```sol
contract MultiDimensionalArrays {
    // 动态二维数组
    uint[][] public matrix;
    // 定长二维数组
    uint[3][4] public fixedMatrix;  // 4行，每行3个元素
    // 混合数组
    uint[][5] public mixedArray;  // 5个动态数组
    uint[3][] public mixedArray2;  // 动态数量的定长数组
}
```
**重要：数组声明的顺序**

在Solidity中，多维数组的声明顺序与其他语言相反：
```sol
contract ArrayOrderConfusion {
    // uint[3][4] 表示什么？
    uint[3][4] public arr;
    // 正确理解：
    // 这是4个长度为3的数组
    // 不是3行4列的矩阵！
    
    function demonstrateOrder() public {
        // arr[0] 是一个长度为3的数组
        // arr[1] 是一个长度为3的数组
        // arr[2] 是一个长度为3的数组
        // arr[3] 是一个长度为3的数组
        // 总共4个数组，每个数组有3个元素
    }
}
```
**记忆技巧：从右向左读**
```sol
uint[3][4]
     ↑  ↑
     |  |
     |  └─ 4个
     └──── 长度为3的数组
```

## 7.2 二维数组操作
```sol
contract TwoDimensionalArray {
    uint[][] public matrix;
    
    // 添加一行
    function addRow(uint[] memory row) public {
        matrix.push(row);
    }
    
    // 初始化矩阵
    function initializeMatrix() public {
        delete matrix;  // 清空
        
        // 添加3行
        uint[] memory row1 = new uint[](3);
        row1[0] = 1; row1[1] = 2; row1[2] = 3;
        matrix.push(row1);
        
        uint[] memory row2 = new uint[](3);
        row2[0] = 4; row2[1] = 5; row2[2] = 6;
        matrix.push(row2);
        
        uint[] memory row3 = new uint[](3);
        row3[0] = 7; row3[1] = 8; row3[2] = 9;
        matrix.push(row3);
        
        // 结果：
        // [1, 2, 3]
        // [4, 5, 6]
        // [7, 8, 9]
    }
    
    // 访问元素
    function getElement(uint row, uint col) public view returns (uint) {
        require(row < matrix.length, "Row out of bounds");
        require(col < matrix[row].length, "Column out of bounds");
        return matrix[row][col];
    }
    
    // 修改元素
    function setElement(uint row, uint col, uint value) public {
        require(row < matrix.length, "Row out of bounds");
        require(col < matrix[row].length, "Column out of bounds");
        matrix[row][col] = value;
    }
    
    // 获取矩阵维度
    function getDimensions() public view returns (uint rows, uint cols) {
        rows = matrix.length;
        if(rows > 0) {
            cols = matrix[0].length;
        } else {
            cols = 0;
        }
    }
}
```

# 7.3 二维数组遍历
```sol
contract MatrixOperations {
    uint[][] public matrix;
    
    constructor() {
        // 初始化3x3矩阵
        for(uint i = 0; i < 3; i++) {
            uint[] memory row = new uint[](3);
            for(uint j = 0; j < 3; j++) {
                row[j] = i * 3 + j + 1;
            }
            matrix.push(row);
        }
    }
    
    // 计算矩阵所有元素之和
    function sumMatrix() public view returns (uint) {
        uint total = 0;
        uint rows = matrix.length;
        
        for(uint i = 0; i < rows; i++) {
            uint cols = matrix[i].length;
            for(uint j = 0; j < cols; j++) {
                total += matrix[i][j];
            }
        }
        return total;
    }
    
    // 查找元素位置
    function findElement(uint value) public view returns (bool, uint, uint) {
        for(uint i = 0; i < matrix.length; i++) {
            for(uint j = 0; j < matrix[i].length; j++) {
                if(matrix[i][j] == value) {
                    return (true, i, j);  // 找到，返回行列
                }
            }
        }
        return (false, 0, 0);  // 未找到
    }
    
    // 获取指定行
    function getRow(uint row) public view returns (uint[] memory) {
        require(row < matrix.length, "Row out of bounds");
        return matrix[row];
    }
}
```

## 7.4 三维及更高维数组
```sol
contract HighDimensionalArrays {
    // 三维数组
    uint[][][] public cube;
    
    // 添加一个2D平面
    function addPlane(uint[][] memory plane) public {
        cube.push(plane);
    }
    
    // 访问三维元素
    function getElement3D(uint x, uint y, uint z) public view returns (uint) {
        require(x < cube.length, "X out of bounds");
        require(y < cube[x].length, "Y out of bounds");
        require(z < cube[x][y].length, "Z out of bounds");
        return cube[x][y][z];
    }
    
    // 警告：高维数组非常复杂，通常应避免使用
    // 考虑使用mapping代替
}
```
**高维数组的问题：**
1. Gas消耗极高：每增加一维，Gas成本指数增长
2. 代码复杂：难以理解和维护
3. 遍历困难：多层嵌套循环容易出错
4. 替代方案：使用mapping组合或结构体
```sol
contract BetterAlternative {
    // 使用mapping替代三维数组
    mapping(uint => mapping(uint => mapping(uint => uint))) public betterCube;
    
    function setValue(uint x, uint y, uint z, uint value) public {
        betterCube[x][y][z] = value;
    }
    
    function getValue(uint x, uint y, uint z) public view returns (uint) {
        return betterCube[x][y][z];
    }
    
    // 优势：
    // - Gas消耗更低
    // - 代码更清晰
    // - 不需要初始化
    // - 支持稀疏数据
}
```
# 8. Gas优化技巧

## 8.1 优化技巧1：缓存数组长度

** 问题：每次读取array.length都会访问storage，消耗200 gas。**
```sol
contract LengthCaching {
    uint[] public data;
    // 未优化：每次循环读取length
    function sumUnoptimized() public view returns (uint) {
        uint total = 0;
        for(uint i = 0; i < data.length; i++) {  // 每次读取200 gas
            total += data[i];
        }
        return total;
    }
    // 100个元素约消耗：25,000 gas
    
    // 优化：缓存length
    function sumOptimized() public view returns (uint) {
        uint total = 0;
        uint len = data.length;  // 只读取一次
        for(uint i = 0; i < len; i++) {
            total += data[i];
        }
        return total;
    }
    // 100个元素约消耗：23,000 gas
    // 节省：2,000 gas (8%)
}
```
**节省计算：**

* 数组长度：n
* 未优化：n × 200 gas（读取length）
* 优化后：1 × 200 gas
* 节省：(n - 1) × 200 gas

## 8.2 优化技巧2：限制数组最大长度
```sol
contract ArraySizeLimit {
    uint[] public data;
    uint public constant MAX_ARRAY_SIZE = 100;
    
    // 限制数组大小
    function safePush(uint value) public {
        require(data.length < MAX_ARRAY_SIZE, "Array is full");
        data.push(value);
    }
    
    // 批量添加也要检查
    function safePushMultiple(uint[] memory values) public {
        require(
            data.length + values.length <= MAX_ARRAY_SIZE, 
            "Would exceed max size"
        );
        
        for(uint i = 0; i < values.length; i++) {
            data.push(values[i]);
        }
    }
}
```
**为什么限制大小？**

1. 防止Gas耗尽：确保遍历操作可以完成
2. 可预测成本：用户知道最大Gas消耗
3. 避免DoS攻击：防止恶意用户填满数组
4. 合约可用性：确保合约长期可用

**推荐的最大长度：**
|操作复杂度|推荐最大长度|
|:--:|:--:|
|简单读取|≤ 1,000|
|简单计算|≤ 500|
|复杂计算|≤ 100|
|安全保守|≤ 100|

## 8.3 优化技巧3：分批处理
```sol
contract BatchProcessing {
    uint[] public data;
    // 分批求和
    function sumRange(uint start, uint end) public view returns (uint) {
        require(start < end, "Invalid range");
        require(end <= data.length, "End out of bounds");
        
        uint total = 0;
        for(uint i = start; i < end; i++) {
            total += data[i];
        }
        return total;
    }
    // 分批删除
    function deleteRange(uint start, uint count) public {
        require(start + count <= data.length, "Range out of bounds");
        
        for(uint i = 0; i < count; i++) {
            // 删除start位置count次
            // 每次删除后，start位置的元素都会变化
            removeOrdered(start);
        }
    }
    function removeOrdered(uint index) private {
        require(index < data.length, "Index out of bounds");
        for(uint i = index; i < data.length - 1; i++) {
            data[i] = data[i + 1];
        }
        data.pop();
    }
}
// 假设有1000个元素的数组
// 不要一次处理全部
// sumRange(0, 1000);  // 可能gas耗尽

// 分批处理
sumRange(0, 100);    // 处理前100个
sumRange(100, 200);  // 处理接下来100个
sumRange(200, 300);  // 继续...
// 可以分多次交易完成
```
## 8.4 优化技巧4：使用calldata

**对于外部函数的数组参数，使用calldata替代memory：**
```sol
contract CalldataOptimization {
    uint[] public stored;
    // 未优化：使用memory
    function processMemory(uint[] memory arr) public {
        for(uint i = 0; i < arr.length; i++) {
            stored.push(arr[i]);
        }
    }
    // Gas: 约 150,000（100个元素）
    
    // 优化：使用calldata
    function processCalldata(uint[] calldata arr) external {
        for(uint i = 0; i < arr.length; i++) {
            stored.push(arr[i]);
        }
    }
    // Gas: 约 120,000（100个元素）
    // 节省：30,000 gas (20%)
}
```
**calldata vs memory：**

|特性|memory|calldata|
|:--:|:--:|:--:|
|存储位置|内存（临时）|调用数据区|
|可修改性|可修改|只读|
|Gas成本|需要复制数据|无需复制|
|使用场景|内部函数、需要修改|外部函数、只读|
|函数类型|public/external|仅external|

## 8.5 优化技巧5：避免循环中的storage写入

**重要说明：这个优化技巧有严格的适用场景。对于更新数组中的部分元素，直接在循环中写storage通常已经是最优解。只有在特定场景下，memory优化才有效。**

**场景1：批量更新数组元素（部分更新 - 不适用优化）**
```sol
contract BatchUpdateOptimization {
    uint[] public scores;
    
    // 初始化函数：创建测试数据（用于演示）
    function initialize() external {
        // 创建10个初始分数：0, 10, 20, 30, 40, 50, 60, 70, 80, 90
        for(uint i = 0; i < 10; i++) {
            scores.push(i * 10);
        }
    }
    
    // 方式1：循环中直接写storage（推荐）
    function updateScoresBad(uint[] calldata indices, uint[] calldata newScores) external {
        require(indices.length == newScores.length, "Arrays length mismatch");
        require(scores.length > 0, "Scores array is empty");
        
        for(uint i = 0; i < indices.length; i++) {
            require(indices[i] < scores.length, "Index out of bounds");
            scores[indices[i]] = newScores[i];  // 每次循环都写storage
        }
    }
    // Gas: 约 42,024（更新3个元素，10个元素的数组）
    // 优势：只写入需要更新的元素，不读取其他元素
    
    // 方式2：先在memory中处理，最后一次性写入（不推荐）
    function updateScoresGood(uint[] calldata indices, uint[] calldata newScores) external {
        require(indices.length == newScores.length, "Arrays length mismatch");
        require(scores.length > 0, "Scores array is empty");
        
        uint len = indices.length;
        
        // 检查所有索引是否有效
        for(uint i = 0; i < len; i++) {
            require(indices[i] < scores.length, "Index out of bounds");
        }
        
        // 将storage数组复制到memory（读取所有元素，很贵！）
        uint[] memory tempScores = new uint[](scores.length);
        for(uint i = 0; i < scores.length; i++) {
            tempScores[i] = scores[i];  // 读取所有元素到memory
        }
        
        // 在memory中更新（不写storage）
        for(uint i = 0; i < len; i++) {
            tempScores[indices[i]] = newScores[i];
        }
        
        // 一次性写回storage（写入整个数组，很贵！）
        scores = tempScores;
    }
    // Gas: 约 54,482（更新3个元素，10个元素的数组）
    // 更差：多了 12,458 gas (29.6%)，不推荐！
}
```
**测试结果分析（更新3个元素，数组长度为10）：**
|方式|Gas消耗|相对updateScoresBad|说明|
|:--:|:--:|:--:|:--:|
|updateScoresBad|42,024|基准|直接写storage，只更新需要的元素|
|updateScoresGood|54,482|+29.6%|更差！多了12,458 gas|

**为什么"优化"版本更差？**

1. **读取整个数组到memory：**
    + 需要读取所有10个元素（包括不需要更新的7个）
    + Storage读取成本：约2,100 gas/次
    + 10次读取 = 约21,000 gas

2. **创建memory数组：**
    + 分配内存需要gas开销
    + 数组越大，开销越大

3. 写入整个数组到storage：
    + 需要写入所有10个元素（包括未修改的7个）
    + Storage写入成本：约20,000 gas/次
    + 10次写入 = 约200,000 gas

4. 直接写storage的优势：
    + 只写入需要更新的3个元素
    + 不读取其他元素
    + 总成本：3次写入 ≈ 60,000 gas（加上其他开销）


**结论：**

对于更新数组中的部分元素，直接在循环中写storage已经是最优解。只有在以下情况下，memory优化才可能有效：

    1. 需要更新大部分或全部元素（>80%）
    2. 数组很小（小于5个元素）
    3. 需要复杂的计算，在memory中计算后再写回

**最佳实践：对于部分更新，直接写storage；对于全量替换，考虑使用memory优化。**

**场景2：全量替换数组（适用优化）**

当需要更新数组中的大部分或全部元素时，memory优化可能有效：

```sol
contract FullArrayUpdate {
    uint[] public data;
    
    // 未优化：循环中逐个更新
    function updateAllBad(uint[] calldata newData) external {
        require(newData.length == data.length, "Length mismatch");
        
        for(uint i = 0; i < data.length; i++) {
            data[i] = newData[i];  // 每次循环都写storage
        }
    }
    // Gas: 取决于数组长度
    // 问题：每个元素都要写storage
    
    // 优化：一次性替换整个数组
    function updateAllGood(uint[] calldata newData) external {
        require(newData.length == data.length, "Length mismatch");
        
        // 复制到memory
        uint[] memory temp = new uint[](newData.length);
        for(uint i = 0; i < newData.length; i++) {
            temp[i] = newData[i];
        }
        
        // 一次性替换
        data = temp;
    }
    // Gas: 可能更优（取决于数组大小和编译器优化）
    // 注意：需要实际测试验证
}
```

**场景3：需要复杂计算的批量更新（适用优化）**

当更新需要复杂计算时，在memory中计算后再写入可能更优：

```sol
contract ComplexCalculation {
    uint[] public results;
    uint public multiplier;
    
    // 未优化：循环中读取storage、计算、写storage
    function processBad(uint[] calldata inputs) external {
        for(uint i = 0; i < inputs.length; i++) {
            // 每次循环都要读取multiplier（storage读取）
            results.push(inputs[i] * multiplier);  // 读storage + 计算 + 写storage
        }
    }
    // 优化：缓存storage变量，在memory中计算
    function processGood(uint[] calldata inputs) external {
        uint mult = multiplier;  // 只读取一次storage
        uint len = inputs.length;
        uint[] memory temp = new uint[](len);
        
        // 在memory中计算
        for(uint i = 0; i < len; i++) {
            temp[i] = inputs[i] * mult;  // 只读memory，不读storage
        }
        
        // 批量写入
        for(uint i = 0; i < len; i++) {
            results.push(temp[i]);
        }
    }
    // 优势：减少了storage读取次数
}
```
**优化原理和适用场景：**

1. **Storage写入成本高：**

    + 每次storage写入需要约20,000 gas
    + 在循环中写入会累积大量gas消耗

2. **Memory操作成本低：**
    + Memory读写只需约3-10 gas**
    + 在memory中完成计算后再写入storage更高效

3. **优化有效的场景：**
    + ✅ 全量替换数组：需要更新所有或大部分元素
    + ✅ 复杂计算：需要读取多个storage变量进行计算
    + ✅ 缓存storage变量：减少重复读取storage
    + ✅ 小数组（<5个元素）：复制成本低

4. **优化无效的场景：**
    + ❌ 部分更新：只更新少量元素（如3/10），memory优化反而更差
    + ❌ 向数组追加元素：push操作已优化，无需此技巧
    + ❌ 大数组部分更新：复制整个数组的成本 > 直接更新的成本

**关键原则：**
    1. 部分更新：直接在循环中写storage
    2. 全量替换：考虑使用memory优化
    3. 复杂计算：缓存storage变量，在memory中计算
    4. 实际测试：优化效果因场景而异，需要实际测试验证

总结：这个优化技巧不是万能的，需要根据具体场景判断。对于部分更新，直接写storage通常已经是最优解。

## 8.6 Gas优化效果对比
```sol
contract OptimizationComparison {
    uint[] public data;
    // 初始化测试数据
    function initialize(uint count) public {
        delete data;
        for(uint i = 0; i < count; i++) {
            data.push(i);
        }
    }
    // 级别1：完全未优化
    function level1_NoOptimization() public view returns (uint) {
        uint total = 0;
        for(uint i = 0; i < data.length; i++) {  // 每次读length
            total += data[i];
        }
        return total;
    }
    // 100个元素：约25,000 gas
    // 级别2：缓存length
    function level2_CacheLength() public view returns (uint) {
        uint total = 0;
        uint len = data.length;  // 缓存
        for(uint i = 0; i < len; i++) {
            total += data[i];
        }
        return total;
    }
    // 100个元素：约23,000 gas（节省8%）
    
    // 级别3：缓存length + unchecked
    function level3_CacheAndUnchecked() public view returns (uint) {
        uint total = 0;
        uint len = data.length;
        for(uint i = 0; i < len; ) {
            total += data[i];
            unchecked { i++; }
        }
        return total;
    }
    // 100个元素：约21,000 gas（节省16%）
}
```
**优化效果总结：**
|优化级别|Gas消耗|节省比例|
|:--:|:--:|:--:|
|未优化|25,000|-|
|缓存length|23,000|8%|
|+unchecked|21,000|16%|

# 9. 数组vs映射

## 9.1 何时使用数组

**数组的优势：**

1. 可以遍历所有元素
2. 保持元素顺序
3. 可以获取所有数据
4. 支持索引访问

**适合使用数组的场景：**
```sol
contract ArrayUseCases {
    // 场景1：需要遍历的小集合
    address[] public members;  // 会员列表（<100人）
    
    // 场景2：需要保持顺序
    uint[] public priceHistory;  // 价格历史记录
    
    // 场景3：需要返回所有数据
    string[] public announcements;  // 公告列表
    
    // 场景4：固定大小的集合
    uint[7] public weeklyData;  // 一周的数据
}
```
## 9.2 何时使用映射

**映射的优势：**
1. 恒定时间（O(1)）查找
2. 不受数量限制
3. Gas消耗稳定
4. 适合大数据集

**适合使用映射的场景：**
```sol
contract MappingUseCases {
    // 场景1：大量数据的查找
    mapping(address => uint) public balances;  // 用户余额
    
    // 场景2：不需要遍历
    mapping(bytes32 => bool) public usedNonces;  // 已使用的nonce
    
    // 场景3：数据量不确定
    mapping(address => bool) public isWhitelisted;  // 白名单
    
    // 场景4：只需键值查询
    mapping(uint => address) public tokenOwners;  // NFT所有者
}
```
## 9.3 数组与映射的对比
|特性|数组|映射|
|:--:|:--:|:--:|
|遍历|可以|不可以|
|顺序|保持|无序|
|查找速度|O(n)|O(1)|
|获取所有数据|可以|不可以|
|大小限制|有（gas限制）	|无|
|Gas成本（查找）|随大小增加|恒定|
|Gas成本（遍历）|线性增长|不支持|
|默认值|无|有|
|删除元素|复杂|简单|

## 9.4 组合使用：最佳实践

**最强大的模式是数组+映射组合：**
```sol
contract ArrayPlusMappingPattern {
    // 组合模式：数组+映射
    address[] public userList;  // 可遍历
    mapping(address => bool) public isUser;  // 快速查找
    mapping(address => uint) public userIndex;  // 快速定位
    
    uint public constant MAX_USERS = 1000;
    
    // 添加用户
    function addUser(address user) public {
        require(!isUser[user], "User already exists");
        require(userList.length < MAX_USERS, "User list is full");
        
        userList.push(user);
        isUser[user] = true;
        userIndex[user] = userList.length - 1;
    }
    
    // 快速检查（O(1)）
    function checkUser(address user) public view returns (bool) {
        return isUser[user];
    }
    
    // 遍历所有用户
    function getAllUsers() public view returns (address[] memory) {
        return userList;
    }
    
    // 删除用户（快速）
    function removeUser(address user) public {
        require(isUser[user], "User does not exist");
        
        uint index = userIndex[user];
        uint lastIndex = userList.length - 1;
        
        // 如果不是最后一个，用最后一个替换
        if(index != lastIndex) {
            address lastUser = userList[lastIndex];
            userList[index] = lastUser;
            userIndex[lastUser] = index;
        }
        
        userList.pop();
        delete isUser[user];
        delete userIndex[user];
    }
    
    // 获取用户数量
    function getUserCount() public view returns (uint) {
        return userList.length;
    }
}
```

**组合模式的优势：**

1. O(1)查找：通过mapping快速检查存在性
2. 可遍历：通过数组遍历所有元素
3. 快速删除：通过userIndex快速定位并删除
4. 数据一致性：三个数据结构保持同步


# 10. 实践练习

1. **练习1：安全数组管理合约**

任务要求：

创建一个完整的数组管理合约，实现以下功能：

1. 限制最大长度为100
2. 实现安全的添加功能（safePush）
3. 实现两种删除方法（保序和快速）
4. 实现分批求和功能（sumRange）
5. 实现查找功能（返回元素索引）
6. 实现获取所有元素功能

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SafeArrayManager {
    uint[] public data;
    uint public constant MAX_SIZE = 100;
    
    event ElementAdded(uint value, uint index);
    event ElementRemoved(uint index, uint value);
    
    // 1. 安全添加
    function safePush(uint value) public {
        require(data.length < MAX_SIZE, "Array is full");
        data.push(value);
        emit ElementAdded(value, data.length - 1);
    }
    
    // 2. 保序删除
    function removeOrdered(uint index) public {
        require(index < data.length, "Index out of bounds");
        
        uint removedValue = data[index];
        
        for(uint i = index; i < data.length - 1; i++) {
            data[i] = data[i + 1];
        }
        data.pop();
        
        emit ElementRemoved(index, removedValue);
    }
    
    // 3. 快速删除
    function removeUnordered(uint index) public {
        require(index < data.length, "Index out of bounds");
        
        uint removedValue = data[index];
        
        data[index] = data[data.length - 1];
        data.pop();
        
        emit ElementRemoved(index, removedValue);
    }
    
    // 4. 分批求和
    function sumRange(uint start, uint end) public view returns (uint) {
        require(start < end, "Invalid range");
        require(end <= data.length, "End out of bounds");
        
        uint total = 0;
        for(uint i = start; i < end; i++) {
            total += data[i];
        }
        return total;
    }
    
    // 5. 查找元素
    function findElement(uint value) public view returns (bool found, uint index) {
        uint len = data.length;
        for(uint i = 0; i < len; i++) {
            if(data[i] == value) {
                return (true, i);
            }
        }
        return (false, 0);
    }
    
    // 6. 获取所有元素
    function getAll() public view returns (uint[] memory) {
        return data;
    }
    
    // 辅助功能
    function getLength() public view returns (uint) {
        return data.length;
    }
    
    function isEmpty() public view returns (bool) {
        return data.length == 0;
    }
    
    function isFull() public view returns (bool) {
        return data.length >= MAX_SIZE;
    }
}
```

**练习2：Gas优化挑战**

任务：优化以下函数，至少节省15% Gas。

原始代码（未优化）：
```sol
contract UnoptimizedCode {
    uint[] public data;
    
    function process(uint[] memory values) public {
        for(uint i = 0; i < values.length; i++) {
            if(values[i] > 10) {
                data.push(values[i]);
            }
        }
    }
}
// 优化提示：

// 使用calldata替代memory
// 缓存数组长度
// 考虑减少storage写入

// 优化
contract OptimizedCode {
    uint[] public data;

    function process(uint[] calldata values) external {
        uint len = values.length;
        
        // 使用临时 memory 数组收集符合条件的值
        uint[] memory temp = new uint[](len);
        uint count = 0;
        
        // 一次遍历完成收集
        for(uint i = 0; i < len; i++) {
            if(values[i] > 10) {
                temp[count] = values[i];
                count++;
            }
        }
        
        // 批量 push（连续操作更省 gas）
        for(uint i = 0; i < count; i++) {
            data.push(temp[i]);
        }
    }
}

// 进一步优化
contract OptimizedCode {
    uint[] public data;

    function process(uint[] calldata values) external {
        uint len = values.length;
        uint currentLen = data.length;
        uint count = 0;
        
        // 第一次遍历：计算符合条件的数量
        for(uint i = 0; i < len; i++) {
            if(values[i] > 10) {
                count++;
            }
        }
        
        // 预先扩展数组（一次性写入长度）
        if(count > 0) {
            uint newLen = currentLen + count;
            assembly {
                // 直接扩展数组长度，避免多次 push
                sstore(add(data.slot, 0), newLen)
            }
            
            // 第二次遍历：直接赋值到已分配的位置
            uint index = currentLen;
            for(uint i = 0; i < len; i++) {
                if(values[i] > 10) {
                    data[index] = values[i];  // 直接赋值，比 push 省 gas
                    index++;
                }
            }
        }
    }
}
```

**练习3：实战项目 - 简单待办事项列表**

需求分析：

创建一个去中心化的待办事项管理合约：

1. 每个用户有自己的待办列表
2. 可以添加、完成、删除待办
3. 可以查看所有待办和已完成的待办
4. 限制每个用户最多100个待办事项
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    struct Todo {
        string task;
        bool completed;
        uint256 timestamp;
    }
    
    // 每个用户的待办列表
    mapping(address => Todo[]) private userTodos;
    uint public constant MAX_TODOS = 100;
    
    event TodoAdded(address indexed user, uint index, string task);
    event TodoCompleted(address indexed user, uint index);
    event TodoDeleted(address indexed user, uint index);
    
    // 添加待办
    function addTodo(string memory task) public {
        require(bytes(task).length > 0, "Task cannot be empty");
        require(bytes(task).length <= 200, "Task too long");
        require(userTodos[msg.sender].length < MAX_TODOS, "Todo list is full");
        
        userTodos[msg.sender].push(Todo({
            task: task,
            completed: false,
            timestamp: block.timestamp
        }));
        
        emit TodoAdded(msg.sender, userTodos[msg.sender].length - 1, task);
    }
    
    // 标记为完成
    function completeTodo(uint index) public {
        require(index < userTodos[msg.sender].length, "Index out of bounds");
        require(!userTodos[msg.sender][index].completed, "Already completed");
        
        userTodos[msg.sender][index].completed = true;
        emit TodoCompleted(msg.sender, index);
    }
    
    // 删除待办（快速删除，不保序）
    function deleteTodo(uint index) public {
        require(index < userTodos[msg.sender].length, "Index out of bounds");
        
        uint lastIndex = userTodos[msg.sender].length - 1;
        
        if(index != lastIndex) {
            userTodos[msg.sender][index] = userTodos[msg.sender][lastIndex];
        }
        
        userTodos[msg.sender].pop();
        emit TodoDeleted(msg.sender, index);
    }
    
    // 获取所有待办
    function getAllTodos() public view returns (Todo[] memory) {
        return userTodos[msg.sender];
    }
    
    // 获取待办数量
    function getTodoCount() public view returns (uint) {
        return userTodos[msg.sender].length;
    }
    
    // 获取未完成的待办
    function getPendingTodos() public view returns (Todo[] memory) {
        Todo[] memory allTodos = userTodos[msg.sender];
        uint pendingCount = 0;
        
        // 计算未完成数量
        for(uint i = 0; i < allTodos.length; i++) {
            if(!allTodos[i].completed) {
                pendingCount++;
            }
        }
        
        // 创建结果数组
        Todo[] memory pending = new Todo[](pendingCount);
        uint index = 0;
        
        // 填充结果
        for(uint i = 0; i < allTodos.length; i++) {
            if(!allTodos[i].completed) {
                pending[index] = allTodos[i];
                index++;
            }
        }
        
        return pending;
    }
    
    // 获取已完成的待办
    function getCompletedTodos() public view returns (Todo[] memory) {
        Todo[] memory allTodos = userTodos[msg.sender];
        uint completedCount = 0;
        
        for(uint i = 0; i < allTodos.length; i++) {
            if(allTodos[i].completed) {
                completedCount++;
            }
        }
        
        Todo[] memory completed = new Todo[](completedCount);
        uint index = 0;
        
        for(uint i = 0; i < allTodos.length; i++) {
            if(allTodos[i].completed) {
                completed[index] = allTodos[i];
                index++;
            }
        }
        
        return completed;
    }
}
```

# 11. 常见问题解答

## **Q1：为什么delete arr[i]不改变数组长度？**

答：delete操作只是将元素重置为默认值（数字类型为0），而不是真正删除。这是Solidity的设计决定，目的是：

1. 保持索引一致性：其他元素的索引不会改变
2. 避免昂贵的操作：不需要移动后续所有元素
3. 明确的语义：delete只是重置，不是删除

如果要真正删除元素，需要使用我们讲解的两种删除方法。










