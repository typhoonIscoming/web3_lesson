# 第二部分：Gas优化实战案例

***2.1 优化前的低效代码***

让我们分析一个典型的低效合约：
```js
contract UnoptimizedContract {
    uint256[] public array;
    
    // ❌ 问题1：使用memory而不是calldata
    function processArray(
        uint[] memory data  // 不必要的内存复制！
    ) external {
        // ❌ 问题2：循环中直接写storage
        for (uint i = 0; i < data.length; i++) {
            array.push(data[i]);  // 每次push都是昂贵的storage操作
        }
    }
    
    // ❌ 问题3：每次循环都读取storage的length
    function getLength() external view returns (uint256) {
        uint256 sum = 0;
        for (uint i = 0; i < array.length; i++) {  // 反复SLOAD
            sum += array[i];
        }
        return sum;
    }
}
```
**燃气消耗分析（假设10个元素）：**

| 操作 | 次数 | 单次成本 | 总成本 |
| :--: | :--: | :--: | :--: |
| 内存复制| 1次 | 约3000个气体 | 3,000 气体 |
| SLOAD（数组.长度） | 10次 | 2,100 气体 | 21,000 气体 |
| SSTORE (push操作) | 10次 | 约20,000个气体 | 20万气体 |
| 总共 | - | - | 约224,000个气体 |

**2.2 优化后的高效代码**

现在让我们应用优化技巧：

```sol
contract OptimizedContract {
    uint256[] public array;
    
    // ✅ 优化1：使用calldata替代memory
    function processArray(
        uint[] calldata data  // 避免内存复制，节省~3,000 gas
    ) external {
        uint256 len = data.length;  // ✅ 优化2：缓存length
        
        // ✅ 优化3：预先计算，减少storage操作
        for (uint i = 0; i < len; i++) {
            array.push(data[i]);
        }
    }
    
    // ✅ 优化4：缓存storage变量
    function getLength() external view returns (uint256) {
        uint256 sum = 0;
        uint256 len = array.length;  // 只读取一次storage
        
        for (uint i = 0; i < len; i++) {
            sum += array[i];
        }
        return sum;
    }
}
```
**优化后Gas消耗分析（10个要素）：**

|操作|次数|单次成本|总成本|
|:--:|:--:|:--:|:--:|
|~~内存复制~~|0次|零气体|0 气体 ✅|
|加载（数组.长度）|1次|2,100 气体|2,100 天然气 ✅|
|SSTORE (推送操作)|10次|约20,000个气体|20万气体|
|总共|-|-|约202,100个气体|

节省成本：

- 绝对值：224,000 - 202,100 = 21,900 气体
- 比例：21,900 / 224,000 = 9.8%

## 2.3 优化技巧深度解析

### 技巧1：Calldata vs Memory

**原理说明：**

当您使用memory参数时，EVM 会进行以下操作：

1. 从交易输入（calldata区域）读取数据
2. 复制到内存（内存区域）
3. 函数访问内存区域的数据

**当你使用calldata参数时：**

1. 直接从交易输入读取数据
2. 消耗复制，节省燃气

**对比示例：**
```sol
// Memory方式：需要复制
function processMemory(
    uint256[] memory data  // 数据流：calldata → memory → 使用
) external pure returns (uint256) {
    // 成本：复制成本 + 访问成本
    return data.length;
}

// Calldata方式：直接读取
function processCalldata(
    uint256[] calldata data  // 数据流：calldata → 直接使用
) external pure returns (uint256) {
    // 成本：仅访问成本
    return data.length;
}
```
**什么时候必须用内存？**
```sol
function needsMemory(
    string memory text
) external pure returns (string memory) {
    // 必须用memory的情况：需要修改参数
    bytes memory b = bytes(text);
    b[0] = 'X';  // 修改操作
    return string(b);
}
```
## 技巧2：服务器存储变量

**原理说明：**

存储读取（SLOAD）是昂贵的操作：

- 冷读取（第一次）：~2,100gas
- 热读取（相同交易内再次读取）：~100gas

即使是热读取，在循环中累积起来也很可观。
```sol
// ❌ 未优化：每次循环读取storage
function badPattern() external view {
    for (uint i = 0; i < array.length; i++) {  // 每次读取array.length
        // 10次循环 = 10次SLOAD ≈ 1,000 gas
        // 处理逻辑...
    }
}

// ✅ 优化：缓存到局部变量
function goodPattern() external view {
    uint256 len = array.length;  // 只读取一次：~100 gas
    for (uint i = 0; i < len; i++) {  // 使用局部变量
        // 10次循环 = 0次额外SLOAD
        // 处理逻辑...
    }
    // 节省：~900 gas
}
```
**复杂示例：多个存储变量**
```sol
contract ComplexContract {
    address public owner;
    uint256 public feeRate;
    uint256 public minAmount;
    
    // ❌ 未优化
    function processUnoptimized(uint256 amount) external view returns (uint256) {
        require(msg.sender == owner);      // SLOAD 1
        require(amount >= minAmount);      // SLOAD 2
        uint256 fee = amount * feeRate / 10000;  // SLOAD 3
        
        if (msg.sender == owner) {         // SLOAD 4（重复）
            return amount;
        }
        return amount - fee;
        // 总计：4次SLOAD ≈ 8,400 gas
    }
    
    // ✅ 优化
    function processOptimized(uint256 amount) external view returns (uint256) {
        address _owner = owner;            // SLOAD 1
        uint256 _minAmount = minAmount;    // SLOAD 2
        uint256 _feeRate = feeRate;        // SLOAD 3
        
        require(msg.sender == _owner);
        require(amount >= _minAmount);
        uint256 fee = amount * _feeRate / 10000;
        
        if (msg.sender == _owner) {        // 使用缓存，无SLOAD
            return amount;
        }
        return amount - fee;
        // 总计：3次SLOAD ≈ 6,300 gas
        // 节省：~2,100 gas (25%)
    }
}
```
**技巧3：大规模操作优化**
```sol
// ❌ 低效：循环中逐个写入storage
function inefficientBatch(
    uint256[] calldata values
) external {
    for (uint i = 0; i < values.length; i++) {
        array.push(values[i]);  // 每次push都要：
        // 1. 读取array.length (SLOAD)
        // 2. 写入新元素 (SSTORE)
        // 3. 更新length (SSTORE)
    }
    // 100个元素 ≈ 2,000,000 gas
}
// 优化方案1：使用内存作为中间层
// ✅ 优化方案：计算与存储分离
// 注意：如果只是简单的线性 push，多出的内存循环会增加 Gas。
// 该方案适用于循环中包含复杂计算（如多重乘除、条件分支）的场景。
function efficientBatch(
    uint256[] calldata values
) external {
    uint256 len = values.length;
    uint256[] memory processed = new uint256[](len);
    
    // 1. 先在 memory 中进行复杂计算（Gas 成本极低）
    for (uint i = 0; i < len; i++) {
        // 假设这里有复杂的业务逻辑处理
        processed[i] = values[i] * 2; 
    }
    
    // 2. 将最终计算结果批量写入 storage
    // 这样计算逻辑就不会与昂贵的 storage 操作交织在一起
    for (uint i = 0; i < len; i++) {
        array.push(processed[i]);
    }
}
// 优化方案2：完全替换（最优化）
// ✅最优：如果要完全替换数组
// 在 Solidity 0.8.x 中，直接赋值会自动处理底层循环并进行优化
function replaceArray(
    uint256[] calldata newValues
) external {
    // 这种直接赋值的方式比手动循环 push 更简洁，编译器也会进行优化
    array = newValues; 
}
```


























