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

# 第三部分：气体优化六大最佳实践

**3.1 外部参数用Calldata**

核心原则：引用类型的外部函数参数，优先使用calldata。

适用类型：
1. string calldata
2. bytes calldata
3. uint[] calldata
4. 任何储备类型
5. 任何结构体类型
```sol
// 实战实例
contract CalldataOptimization {
    // ✅ 推荐：只读操作用calldata
    function validateData(
        bytes calldata data
    ) external pure returns (bool) {
        return data.length > 0 && data[0] == 0x01;
    }
    
    // ✅ 推荐：批量查询用calldata
    function batchQuery(
        address[] calldata users
    ) external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](users.length);
        for (uint i = 0; i < users.length; i++) {
            balances[i] = address(users[i]).balance;
        }
        return balances;
    }
    
    // ❌ 不推荐：除非确实需要修改
    function processData(
        bytes memory data  // 只有需要修改时才用memory
    ) external pure returns (bytes memory) {
        data[0] = 0xFF;  // 修改操作
        return data;
    }
}
```
# 3.2 存储器存储变量

**核心原则：内部访问存储数据，先读取到局部数据。**

**识别模式：**
```sol
// 识别：同一个storage变量被多次访问
function needsCaching() external view {
    if (owner == msg.sender) {          // 访问1
        require(balances[owner] > 0);   // 访问2
        return balances[owner] * 2;     // 访问3
    }
}
// ✅ 优化：缓存到局部变量
function cached() external view {
    address _owner = owner;             // 一次SLOAD
    if (_owner == msg.sender) {
        uint256 balance = balances[_owner];  // 一次SLOAD
        require(balance > 0);
        return balance * 2;
    }
}
```
**高级示例：绘制地图**
```sol
contract NestedMapping {
    mapping(address => mapping(uint256 => uint256)) public data;
    
    // ❌ 未优化：反复访问嵌套映射
    function unoptimized(address user, uint256 id) external view returns (uint256) {
        if (data[user][id] > 100) {           // SLOAD 1
            return data[user][id] * 2;        // SLOAD 2
        } else {
            return data[user][id] + 10;       // SLOAD 3
        }
    }
    
    // ✅ 优化：缓存映射值
    function optimized(address user, uint256 id) external view returns (uint256) {
        uint256 value = data[user][id];       // SLOAD 1（仅一次）
        if (value > 100) {
            return value * 2;
        } else {
            return value + 10;
        }
        // 节省：2次SLOAD ≈ 4,200 gas
    }
}
```
## 3.3 批量操作

核心原则：避免在循环中间隙写入存储。

**反模式识别：**
```sol
// ❌ 反模式：循环中的storage写入
for (uint i = 0; i < n; i++) {
    storageArray.push(value);     // 每次都是昂贵的SSTORE
    storageMapping[i] = value;    // 每次都是昂贵的SSTORE
    storageCounter++;              // 每次都是昂贵的SSTORE
}
// 优化：策略
contract BatchOptimization {
    uint256[] public results;
    uint256 public counter;
    
    // ✅ 策略1：累积后批量写入
    function batchAppend(
        uint256[] calldata newItems
    ) external {
        uint256 len = newItems.length;
        
        // 先计算，不写入
        uint256[] memory temp = new uint256[](len);
        for (uint i = 0; i < len; i++) {
            temp[i] = newItems[i] * 2;
        }
        
        // 最后批量写入
        for (uint i = 0; i < len; i++) {
            results.push(temp[i]);
        }
    }
    
    // ✅ 策略2：单次更新计数器
    function processItems(
        uint256[] calldata items
    ) external {
        uint256 count = 0;  // 本地计数
        
        for (uint i = 0; i < items.length; i++) {
            if (items[i] > 100) {
                count++;  // 只更新本地变量
            }
        }
        counter += count;  // 最后一次性更新storage
    }
}
```

## 3.4 变量资源

**核心原则：** 将多个小变量备份到同一个存储槽。

存储槽机制：

- 每个槽位为32字节（256位）
- 相邻的小变量会自动备用
- 一次SLOAD/SSTORE操作整个槽
```sol
// 优化对比：
// ❌ 未优化：每个变量占一个slot
contract Unoptimized {
    uint8 a;      // Slot 0 (浪费31字节)
    uint256 b;    // Slot 1
    uint8 c;      // Slot 2 (浪费31字节)
    uint256 d;    // Slot 3
    
    // 读取a和c需要2次SLOAD
    function getValues() external view returns (uint8, uint8) {
        return (a, c);  // 2次SLOAD ≈ 4,200 gas
    }
}

// ✅ 优化：打包到同一个slot
contract Optimized {
    uint8 a;      // Slot 0 (前8位)
    uint8 c;      // Slot 0 (后8位) ✅ 与a共享slot
    uint256 b;    // Slot 1
    uint256 d;    // Slot 2
    
    // 读取a和c只需1次SLOAD
    function getValues() external view returns (uint8, uint8) {
        return (a, c);  // 1次SLOAD ≈ 2,100 gas
    }
    // 节省：50%
}

// 配额规则：
contract PackingRules {
    // ✅ 好的打包：同一个slot
    uint128 var1;  // Slot 0: 前128位
    uint128 var2;  // Slot 0: 后128位
    
    // ✅ 好的打包：三个变量一个slot
    uint64 var3;   // Slot 1: 0-63位
    uint64 var4;   // Slot 1: 64-127位
    uint128 var5;  // Slot 1: 128-255位
    
    // ❌ 坏的打包：被uint256打断
    uint128 var6;  // Slot 2: 前128位
    uint256 var7;  // Slot 3: 完整256位 (打断了打包)
    uint128 var8;  // Slot 4: 新的slot
}
// 实战示例：用户信息结构
// ❌ 未优化：占用5个slot
struct UserUnoptimized {
    address wallet;      // Slot 0 (20字节，浪费12字节)
    uint256 balance;     // Slot 1 (32字节)
    uint8 level;         // Slot 2 (1字节，浪费31字节)
    bool active;         // Slot 3 (1字节，浪费31字节)
    uint256 timestamp;   // Slot 4 (32字节)
}

// ✅ 优化：只占用3个slot
struct UserOptimized {
    address wallet;      // Slot 0: 0-159位 (20字节)
    uint8 level;         // Slot 0: 160-167位 (1字节)
    bool active;         // Slot 0: 168位 (1字节)
    // Slot 0还剩余88位可用
    uint256 balance;     // Slot 1 (32字节)
    uint256 timestamp;   // Slot 2 (32字节)
}
// 节省：2个slot的读写成本 ≈ 40% Gas优化
```
## 3.5 使用常量和不可变

**核心原则：不变的价值不宜存储在存储中。**

**常见量类型对比：**
| 类型	| 设定时间	| 仓储位置	| 天然气成本 |
| :--: | :--: | :--: | :--: |
| constant	| 编译时	| 代码中（内联）	| 0 |
| immutable	| 部署时（构造函数） | 代码中 | 约200种气体 |
| storage | 运行时 | 贮存 | 约2100个气体 |
```sol
contract ConstantOptimization {
    // ❌ 浪费：不变的值存在storage
    uint256 public maxSupply = 1000000;  // 每次读取：2,100 gas
    address public admin = 0x123...;      // 每次读取：2,100 gas
    
    // ✅ 优化：使用constant
    uint256 public constant MAX_SUPPLY = 1000000;  // 读取：0 gas (内联)
    
    // ✅ 优化：使用immutable（部署时确定）
    address public immutable ADMIN;  // 读取：~200 gas
    
    constructor(address _admin) {
        ADMIN = _admin;  // 只能在构造函数中设置
    }
    
    function checkLimit(uint256 amount) external view returns (bool) {
        // 使用constant：直接替换为1000000，无SLOAD
        return amount <= MAX_SUPPLY;
    }
}
// 使用场景：
contract TokenContract {
    // Constant：编译时已知的常量
    string public constant NAME = "MyToken";
    string public constant SYMBOL = "MTK";
    uint8 public constant DECIMALS = 18;
    uint256 public constant MAX_SUPPLY = 1000000 * 10**18;
    
    // Immutable：部署时确定的值
    address public immutable FACTORY;
    address public immutable ROUTER;
    uint256 public immutable DEPLOYED_AT;
    // immutable变量特性
    // 一次性初始化：只能在构造函数中赋值，之后不可修改
    // 部署时确定值：可以使用构造函数参数或部署时的上下文信息（如block.number）
    // 存储优化：值直接编码到合约字节码中，减少存储操作
    // gas高效：读取成本远低于普通状态变量
    
    constructor(address factory, address router) {
        FACTORY = factory;
        ROUTER = router;
        DEPLOYED_AT = block.timestamp;
        // 节省开支：
        // 一路持续节省：~2,100 汽油
        // 附带不变的节省：~1,900 汽油
        // 在高频调用的函数中，节省效果显着
    }
    
    // Storage：运行时可变的值
    uint256 public totalSupply;
    mapping(address => uint256) public balances;
}
```

## 3.6 避免外部调用

**核心原则：外部调用比内部调用昂贵，能用内部函数就不用外部函数。**

**调用成本对比：**
|调用类型|天然气基础成本|额外成本|
|:--:|:--:|:--:|
|内部的|约20种气体|无|
|外部的|约700气体|参数复制到calldata|
|外部（契约间）|约2600个气体|冷访问额外成本|
```sol
// 优化示例
contract CallOptimization {
    // ❌ 外部函数：昂贵
    function calculateExternal(uint256 a, uint256 b) external pure returns (uint256) {
        return a * b + 100;
    }
    
    // ✅ 内部函数：便宜
    function calculateInternal(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b + 100;
    }
    
    // ❌ 低效：在合约内部调用外部函数
    function processUnoptimized(uint256 x) external view returns (uint256) {
        // this.calculateExternal() 是外部调用！
        return this.calculateExternal(x, 2);  // ~700 gas
    }
    
    // ✅ 高效：调用内部函数
    function processOptimized(uint256 x) external pure returns (uint256) {
        return calculateInternal(x, 2);  // ~20 gas
    }
    // 节省：~680 gas (97%)
}
// 重构模式：
contract RefactoringPattern {
    uint256 public value;
    
    // 设计模式：提供internal版本用于内部调用
    function _setValue(uint256 newValue) internal {
        require(newValue > 0, "Invalid value");
        value = newValue;
    }
    
    // External版本供外部调用
    function setValue(uint256 newValue) external {
        _setValue(newValue);
    }
    
    // 其他函数可以高效调用internal版本
    function doubleValue() external {
        _setValue(value * 2);  // 内部调用，便宜
    }
    
    function resetValue() external {
        _setValue(1);  // 内部调用，便宜
    }
}
```

# 第四部分：综合优化实战

**4.1 复杂案例：代币里程碑**

让我们看一个综合应用所有优化技巧的实战案例：
```sol
// 未优化版本
contract TokenUnoptimized {
    mapping(address => uint256) public balances;
    address public owner;
    uint256 public totalSupply;
    uint256 public feeRate = 100;  // 1%
    
    function transfer(
        address to,
        uint256 amount,
        bytes memory data  // ❌ 应该用calldata
    ) external {
        // ❌ 多次读取storage
        require(balances[msg.sender] >= amount);
        require(to != address(0));
        require(msg.sender == owner || amount >= 100);  // ❌ 重复读取owner
        
        // ❌ 计算手续费时重复读取
        uint256 fee = amount * feeRate / 10000;  // ❌ 读取feeRate
        
        // ❌ 多次写入storage
        balances[msg.sender] -= amount;
        balances[to] += amount - fee;
        balances[owner] += fee;  // ❌ 再次读取owner
        
        totalSupply = totalSupply;  // ❌ 无意义的storage写入
    }
    
    // Gas消耗：~80,000
}
// 完全优化版本：
contract TokenOptimized {
    mapping(address => uint256) public balances;
    address public immutable OWNER;  // ✅ 使用immutable
    uint256 public totalSupply;
    uint256 public constant FEE_RATE = 100;  // ✅ 使用constant
    
    constructor() {
        OWNER = msg.sender;
    }
    
    function transfer(
        address to,
        uint256 amount,
        bytes calldata data  // ✅ 使用calldata
    ) external {
        // ✅ 缓存storage变量
        uint256 senderBalance = balances[msg.sender];
        
        // ✅ 验证逻辑
        require(senderBalance >= amount, "Insufficient balance");
        require(to != address(0), "Invalid recipient");
        require(msg.sender == OWNER || amount >= 100, "Amount too small");
        
        // ✅ 使用constant，无storage读取
        uint256 fee = amount * FEE_RATE / 10000;
        uint256 amountAfterFee = amount - fee;
        
        // ✅ 使用内部函数批量更新
        _updateBalances(msg.sender, to, amount, amountAfterFee, fee);
    }
    
    // ✅ 内部函数：避免外部调用开销
    function _updateBalances(
        address from,
        address to,
        uint256 amount,
        uint256 amountAfterFee,
        uint256 fee
    ) internal {
        balances[from] -= amount;
        balances[to] += amountAfterFee;
        balances[OWNER] += fee;
    }
    
    // Gas消耗：~45,000
    // 节省：43.75%
}
```
## 4.2 优化效果对比表
|优化项|优化前|优化后|节省开支|
|:--:|:--:|:--:|:--:|
|参数类型|bytes memory|bytes calldata|约3000个气体|
|业主读取|2次SLOAD|	不可变访问|	约4000个气体|
|费率读取|1次SLOAD|	持续访问|约2100个气体|
|余额读取|重复SLOAD| 存储一次 |约2100个气体|
|无意义写入|总供应写入|删除|约20,000个气体|
|函数调用|-|使用内部|约4000个气体|
|总共|约80,000个气体|约45,000个气体|约35,000个气体（43.75%）|

## 第五部分：常见问题与陷阱

**5.1 过度优化的陷阱**
```sol
// 问题：牺牲代码的可执行性追求最优化。
// ❌ 过度优化：难以理解
function processData(uint[] calldata d) external {
    uint l=d.length;uint s;uint t=myValue;
    for(uint i;i<l;){s+=d[i]*t;unchecked{++i;}}
    result=s;
}

// ✅ 平衡优化：保持可读性
function processData(uint256[] calldata data) external {
    uint256 length = data.length;
    uint256 sum = 0;
    uint256 multiplier = myValue;  // 缓存storage
    
    for (uint256 i = 0; i < length; i++) {
        sum += data[i] * multiplier;
    }
    
    result = sum;
}
```

## 5.2 错误的服务器场景
```sol
// 问题：只读取一次的变量反而增加了成本。
// ❌ 无意义的缓存
function singleUse() external view returns (uint256) {
    uint256 _value = myValue;  // 额外的本地变量赋值
    return _value + 1;         // 只用一次
    // 不如直接：return myValue + 1;
}

// ✅ 有意义的缓存
function multipleUse() external view returns (uint256) {
    uint256 _value = myValue;  // 缓存
    if (_value > 100) {        // 使用1
        return _value * 2;     // 使用2
    }
    return _value + 10;        // 使用3
    // 三次使用，缓存有价值
}
```
## 5.3 Calldata 的局限性

历史说明：在 Solidity 0.6.9 之前的版本中，calldata不能在内部函数中使用。但从 0.6.9 开始（包括 0.8.x），这个限制已经被移除。

旧版本的限制（0.6.9之前）：

```sol
// ❌ 在0.6.9之前会编译错误
function processData(uint[] calldata data) external {
    _processInternal(data);  // 错误：不能传递calldata给internal
}

function _processInternal(uint[] calldata data) internal {
    // internal函数不能使用calldata（旧版本）
}
```
**现代版本的解决方案（0.6.9+，包括0.8.x）：**
```sol
// ✅ 解决方案1：internal函数直接使用calldata（推荐，0.6.9+）
function processData(uint[] calldata data) external {
    _processInternal(data);  // 可以直接传递calldata
}

function _processInternal(uint[] calldata data) internal {
    // 从0.6.9开始，internal函数可以使用calldata
    // 优势：避免复制到memory，节省gas
}

// ✅ 解决方案2：转换为memory（如果需要修改数据）
function processData(uint[] calldata data) external {
    uint[] memory dataCopy = data;  // 复制到memory以便修改
    _processInternal(dataCopy);
}

function _processInternal(uint[] memory data) internal {
    data[0] = 100;  // 可以修改memory中的数据
}
```
**何时使用哪种方案：**

- 使用calldata（方案1）：数据修改，减少修改，节省gas
- 使用内存（方案2）：需要修改数据内容时使用

# 第六部分：练习与思考

## 6.1 实战练习：优化合约

题目：优化以下合约，目标节省至少 20% 的 Gas。
```sol
contract PracticeContract {
    uint256[] public numbers;
    address public admin;
    uint256 public multiplier = 2;
    
    function batchProcess(
        uint256[] memory inputs
    ) external {
        require(msg.sender == admin);
        
        for (uint i = 0; i < inputs.length; i++) {
            uint256 result = inputs[i] * multiplier;
            numbers.push(result);
        }
    }
    
    function getSum() external view returns (uint256) {
        require(msg.sender == admin);
        
        uint256 sum = 0;
        for (uint i = 0; i < numbers.length; i++) {
            sum += numbers[i];
        }
        return sum;
    }
}
// 优化如下
contract PracticeContractOptimized {
    uint256[] public numbers;
    address public immutable ADMIN;  // ✅ 改为immutable
    uint256 public constant MULTIPLIER = 2;  // ✅ 改为constant
    
    constructor() {
        ADMIN = msg.sender;
    }
    
    function batchProcess(
        uint256[] calldata inputs  // ✅ 改为calldata
    ) external {
        require(msg.sender == ADMIN, "Not admin");
        
        uint256 length = inputs.length;  // ✅ 缓存length
        
        for (uint i = 0; i < length; i++) {
            uint256 result = inputs[i] * MULTIPLIER;  // ✅ 使用constant
            numbers.push(result);
        }
    }
    
    function getSum() external view returns (uint256) {
        require(msg.sender == ADMIN, "Not admin");
        
        uint256 sum = 0;
        uint256 length = numbers.length;  // ✅ 缓存length
        
        for (uint i = 0; i < length; i++) {
            sum += numbers[i];
        }
        return sum;
    }
}

// 优化效果：
// - calldata替代memory：~3,000 gas
// - admin改为immutable：~2,000 gas/次
// - multiplier改为constant：~2,100 gas/次
// - 缓存length（两个函数）：~4,000 gas
// 总节省：约25-30%
```


# 7.2 Gas优化检查清单
在部署合约前，检查以下优化点：

- [ ] 参数优化

&emsp;&emsp;- [ ] 外部函数的引用类型参数使用calldata
&ensp;&ensp;- [ ] 缩进一个汉字宽度。

- [ ] 仅在需要修改时使用内存
    - [ ] 存储优化

- [ ] 服务器在循环中使用的存储变量
    - [ ] 存储器被多次读取的存储变量
    - [ ] 避免在循环中写入存储
    - [ ] 变量优化

- [ ] 小变量备份正确到同一个槽
    - [ ] 不变的值使用常数
    - [ ] 配置时确定的值使用immutable
- [ ] 函数优化

    - [ ] 内部调用使用internal或external
    - [ ] 提取公共逻辑到内部函数
- [ ] 循环优化

    - [ ] 备份长度
    - [ ] 避免循环中的重复计算
    - [ ] 考虑批量操作
- [ ] 其他优化

    - [ ] 删除不需要的存储写入
    - [ ] 使用事件及存储历史记录
    - [ ] 考虑使用攻击










