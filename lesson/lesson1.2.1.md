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


















