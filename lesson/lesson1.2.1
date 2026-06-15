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



























