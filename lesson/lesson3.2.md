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






















