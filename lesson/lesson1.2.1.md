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
























