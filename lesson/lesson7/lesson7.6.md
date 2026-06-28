## 第7.2课：错误处理和自定义错误
学习目标：掌握Solidity中的三种错误处理机制、理解自定义错误的优势、学会使用try-catch捕获异常、能够在实际项目中正确应用错误处理最佳实践

# 1. 错误处理基础概念

## 1.1 为什么需要错误处理
在智能合约开发中，错误处理不仅仅是让程序正常运行的技术手段，更是保障合约安全、优化Gas消耗、提升用户体验的关键环节。

错误处理的重要性：

1. 保障合约安全：

* 防止非法输入破坏合约状态
* 防止整数溢出、下溢等运算错误
* 防止未经授权的操作
* 确保资金安全

2. 优化Gas消耗：

* 尽早检测错误可以避免不必要的计算
* 自定义错误比字符串错误更节省Gas
* 合理的错误处理可以减少失败交易的成本

3. 提升用户体验：

* 清晰的错误消息帮助用户理解失败原因
* 避免用户因为不明确的错误而困惑
* 便于前端应用提供友好的错误提示

4. 便于调试和维护：

* 明确的错误信息加速问题定位
* 结构化的错误类型便于分类处理
* 降低开发和维护成本

## 1.2 错误处理的基本原理

交易回滚机制：

当智能合约执行过程中遇到错误时，会触发交易回滚（Transaction Revert）。回滚意味着：

* 所有状态变更都会被撤销
* 合约状态恢复到交易执行前
* 已消耗的Gas不会退还（取决于错误类型）
* 可以返回错误信息给调用者
```sol
contract RevertExample {
    uint256 public balance = 100;
    
    function withdraw(uint256 amount) public {
        // 如果余额不足，这里会触发回滚
        require(balance >= amount, "余额不足");
        
        // 如果上面的require失败，下面的代码不会执行
        balance -= amount;
        // 状态不会被修改
    }
}
```
错误传播：

在Solidity中，错误会沿着调用链向上传播：

* 如果函数A调用函数B，函数B发生错误，错误会传播到函数A
* 除非使用try-catch捕获，否则错误会一直传播到外部调用者
* 整个交易会失败并回滚
```sol
contract ErrorPropagation {
    function functionA() public {
        functionB();  // 如果functionB失败，functionA也会失败
    }
    
    function functionB() public pure {
        require(false, "这个错误会传播到functionA");
    }
}
```
## 1.3 Solidity中的错误处理方式
Solidity提供了三种基本的错误处理机制：

1. require：用于验证条件，适合输入检查和状态验证
2. assert：用于检查不变量，适合内部一致性验证
3. revert：用于自定义错误处理，最灵活

此外，Solidity还支持：

* 自定义错误（0.8.4+）：结构化的错误类型
* try-catch：捕获外部调用的异常

# 2. require/assert/revert详解

## 2.1 require - 输入验证和条件检查

基本语法：
```sol
require(condition, "错误消息");
// 或者
require(condition);
```
核心特点：

1. 用于条件验证：检查输入参数、合约状态等
2. 交易可恢复：失败时状态回滚
3. Gas部分返还：未使用的Gas会退还给调用者
4. 可以带错误消息：便于调试和用户理解

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract RequireExample {
    mapping(address => uint256) public balances;
    address public owner;
    
    constructor() {
        owner = msg.sender;
        balances[msg.sender] = 1000;
    }
    
    // 场景1：输入参数验证
    function transfer(address to, uint256 amount) public {
        require(to != address(0), "接收地址不能为零地址");
        require(amount > 0, "转账金额必须大于0");
        require(balances[msg.sender] >= amount, "余额不足");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    
    // 场景2：权限检查
    function mint(address to, uint256 amount) public {
        require(msg.sender == owner, "只有所有者可以铸造");
        require(to != address(0), "接收地址不能为零地址");
        
        balances[to] += amount;
    }
    
    // 场景3：状态检查
    bool public paused = false;
    
    function withdraw(uint256 amount) public {
        require(!paused, "合约已暂停");
        require(balances[msg.sender] >= amount, "余额不足");
        
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
    
    // 场景4：时间检查
    uint256 public lockTime;
    
    function setLockTime(uint256 duration) public {
        require(msg.sender == owner, "只有所有者可以设置");
        lockTime = block.timestamp + duration;
    }
    
    function unlock() public {
        require(block.timestamp >= lockTime, "尚未到解锁时间");
        // 解锁操作...
    }
}
```
使用场景：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract RequireExample {
    mapping(address => uint256) public balances;
    address public owner;
    
    constructor() {
        owner = msg.sender;
        balances[msg.sender] = 1000;
    }
    
    // 场景1：输入参数验证
    function transfer(address to, uint256 amount) public {
        require(to != address(0), "接收地址不能为零地址");
        require(amount > 0, "转账金额必须大于0");
        require(balances[msg.sender] >= amount, "余额不足");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    
    // 场景2：权限检查
    function mint(address to, uint256 amount) public {
        require(msg.sender == owner, "只有所有者可以铸造");
        require(to != address(0), "接收地址不能为零地址");
        
        balances[to] += amount;
    }
    
    // 场景3：状态检查
    bool public paused = false;
    
    function withdraw(uint256 amount) public {
        require(!paused, "合约已暂停");
        require(balances[msg.sender] >= amount, "余额不足");
        
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
    
    // 场景4：时间检查
    uint256 public lockTime;
    
    function setLockTime(uint256 duration) public {
        require(msg.sender == owner, "只有所有者可以设置");
        lockTime = block.timestamp + duration;
    }
    
    function unlock() public {
        require(block.timestamp >= lockTime, "尚未到解锁时间");
        // 解锁操作...
    }
}
```
在上面的代码中：

* transfer函数使用require验证输入参数的有效性
* mint函数使用require检查调用者权限
* withdraw函数使用require检查合约状态
* unlock函数使用require检查时间条件

require的工作原理：
```sol
contract RequireInternals {
    uint256 public value = 100;
    
    function testRequire(uint256 newValue) public {
        // require内部实际上是这样工作的：
        // if (!condition) {
        //     revert("错误消息");
        // }
        
        require(newValue <= 200, "值不能超过200");
        
        value = newValue;
    }
}
```
当require条件为false时：

1. 交易立即停止执行
2. 所有状态变更回滚
3. 返回错误消息
4. 未使用的Gas退还给调用者

## 2.2 assert - 不变量检查
基本语法：
```sol
assert(condition);
```
核心特点：

1. 用于不变量检查：验证理论上永远为真的条件
2. 交易不可恢复：失败表示严重bug
3. 消耗全部Gas：所有Gas都会被消耗，不会退还
4. 没有错误消息：assert不支持错误消息

使用场景：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AssertExample {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    
    constructor() {
        totalSupply = 1000;
        balanceOf[msg.sender] = 1000;
    }
    
    // 场景1：检查数学运算的正确性
    function transfer(address to, uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "余额不足");
        
        uint256 senderBalanceBefore = balanceOf[msg.sender];
        uint256 recipientBalanceBefore = balanceOf[to];
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        // 检查不变量：总和应该保持不变
        assert(
            balanceOf[msg.sender] + balanceOf[to] ==
            senderBalanceBefore + recipientBalanceBefore
        );
    }
    
    // 场景2：检查状态一致性
    function mint(address to, uint256 amount) public {
        uint256 oldTotalSupply = totalSupply;
        uint256 oldBalance = balanceOf[to];
        
        totalSupply += amount;
        balanceOf[to] += amount;
        
        // 检查不变量：总供应量变化应该等于余额变化
        assert(totalSupply - oldTotalSupply == balanceOf[to] - oldBalance);
    }
    
    // 场景3：检查合约状态的内部一致性
    function burn(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "余额不足");
        
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        
        // 检查不变量：总供应量不应该小于所有余额之和
        // 注意：这只是示例，实际中很难遍历所有地址
        assert(totalSupply >= balanceOf[msg.sender]);
    }
}
```
assert vs require的区别：
```sol
contract AssertVsRequire {
    uint256 public balance = 100;
    
    // 使用require：条件可能为假（用户错误）
    function withdrawWithRequire(uint256 amount) public {
        require(balance >= amount, "余额不足");  // 用户可能输入错误金额
        balance -= amount;
    }
    
    // 使用assert：条件永远应该为真（程序错误）
    function withdrawWithAssert(uint256 amount) public {
        require(balance >= amount, "余额不足");
        
        uint256 oldBalance = balance;
        balance -= amount;
        
        // 这个条件理论上永远为真，如果为假说明代码有bug
        assert(balance == oldBalance - amount);
    }
}
```
何时使用assert：

1. 检查溢出/下溢（Solidity 0.8.0之前）：
```sol
contract OverflowCheck {
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);  // 检查是否溢出
        return c;
    }
}
```

2. 检查状态一致性：

```sol
contract StateConsistency {
    uint256 public total;
    uint256 public partA;
    uint256 public partB;
    
    function update(uint256 _partA, uint256 _partB) public {
        partA = _partA;
        partB = _partB;
        total = partA + partB;
        
        // 检查不变量
        assert(total == partA + partB);
    }
}
```
3. 检查合约内部逻辑：
```sol
contract InternalLogic {
    enum State { Created, Active, Completed }
    State public state;
    
    function complete() public {
        require(state == State.Active, "只能完成活跃状态的任务");
        state = State.Completed;
        
        // 检查状态转换是否正确
        assert(state == State.Completed);
    }
}
```

## 2.3 revert - 自定义错误处理
基本语法：
```sol
revert("错误消息");
// 或者使用自定义错误
revert CustomError(param1, param2);
```
核心特点：

1. 灵活的错误处理：可以在任何位置使用
2. 支持自定义错误：可以传递结构化的错误信息
3. 交易可恢复：与require类似，会退还未使用的Gas
4. 更适合复杂逻辑：在if-else中使用更自然

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract RevertExample {
    mapping(address => uint256) public balances;
    mapping(address => bool) public blacklist;
    
    // 定义自定义错误
    error InsufficientBalance(uint256 available, uint256 required);
    error Blacklisted(address account);
    error InvalidAmount(uint256 amount);
    
    constructor() {
        balances[msg.sender] = 1000;
    }
    
    // 场景1：复杂条件判断
    function transfer(address to, uint256 amount) public {
        // 使用revert处理复杂条件
        if (to == address(0)) {
            revert("接收地址不能为零地址");
        }
        
        if (blacklist[msg.sender]) {
            revert Blacklisted(msg.sender);
        }
        
        if (blacklist[to]) {
            revert Blacklisted(to);
        }
        
        if (amount == 0) {
            revert InvalidAmount(amount);
        }
        
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(balances[msg.sender], amount);
        }
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    
    // 场景2：多路径错误处理
    function withdraw(uint256 amount, bool emergency) public {
        if (emergency) {
            // 紧急提现，不检查余额
            if (msg.sender != owner) {
                revert("只有所有者可以紧急提现");
            }
            // 紧急提现逻辑...
        } else {
            // 正常提现，检查余额
            if (balances[msg.sender] < amount) {
                revert InsufficientBalance(balances[msg.sender], amount);
            }
            balances[msg.sender] -= amount;
            // 提现逻辑...
        }
    }
    
    address public owner;
    
    // 场景3：提前退出函数
    function complexOperation(uint256 value) public {
        // 提前检查，如果不满足条件直接返回
        if (value > 1000) {
            revert("值过大");
        }
        
        // 执行复杂操作...
        for (uint256 i = 0; i < value; i++) {
            // 某些操作...
            
            if (/* 某个条件 */ false) {
                revert("操作过程中发生错误");
            }
        }
    }
}
```
**revert vs require的选择：**
```sol
contract RevertVsRequire {
    mapping(address => uint256) public balances;
    
    // 使用require：简单的条件检查
    function transferRequire(address to, uint256 amount) public {
        require(to != address(0), "无效接收地址");
        require(balances[msg.sender] >= amount, "余额不足");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    
    // 使用revert：复杂的条件判断
    function transferRevert(address to, uint256 amount) public {
        if (to == address(0)) {
            revert("无效接收地址");
        }
        
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(balances[msg.sender], amount);
        }
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    
    error InsufficientBalance(uint256 available, uint256 required);
}
```
## 2.4 三种机制的对比
|特性|require|assert|revert|
|:--:|:--:|:--:|:--:|
|用途|输入验证、条件检查|不变量检查、内部一致性|自定义错误处理|
|Gas返还|✅ 是|❌ 否（消耗全部）|✅ 是|
|错误消息|✅ 支持字符串|❌ 不支持|✅ 支持字符串和自定义错误|
|使用场景|函数入口验证|内部逻辑检查|复杂条件判断|
|失败影响|交易回滚|交易回滚|交易回滚|
|典型用例|余额检查、权限验证|数学运算验证|多路径错误处理|

**完整对比示例：**
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ErrorMechanismsComparison {
    uint256 public balance = 1000;
    uint256 public totalSupply = 1000;
    address public owner;
    
    error InsufficientBalance(uint256 available, uint256 required);
    
    constructor() {
        owner = msg.sender;
    }
    
    // require示例：输入验证
    function withdrawRequire(uint256 amount) public {
        require(amount > 0, "金额必须大于0");           // 输入验证
        require(msg.sender == owner, "只有所有者可以提现"); // 权限检查
        require(balance >= amount, "余额不足");         // 状态检查
        
        balance -= amount;
    }
    
    // assert示例：不变量检查
    function transferAssert(address to, uint256 amount) public {
        require(balance >= amount, "余额不足");
        
        uint256 oldBalance = balance;
        balance -= amount;
        
        // 检查不变量：新余额应该等于旧余额减去金额
        assert(balance == oldBalance - amount);
    }
    
    // revert示例：自定义错误
    function withdrawRevert(uint256 amount) public {
        if (amount == 0) {
            revert("金额必须大于0");
        }
        
        if (msg.sender != owner) {
            revert("只有所有者可以提现");
        }
        
        if (balance < amount) {
            revert InsufficientBalance(balance, amount);
        }
        
        balance -= amount;
    }
    
    // 组合使用示例
    function combinedExample(uint256 amount) public {
        // 1. 使用require进行输入验证
        require(amount > 0, "金额必须大于0");
        require(msg.sender == owner, "只有所有者可以操作");
        
        // 2. 使用revert处理复杂条件
        if (amount > balance / 2) {
            revert("单次提现不能超过余额的50%");
        }
        
        // 3. 执行操作
        uint256 oldBalance = balance;
        balance -= amount;
        
        // 4. 使用assert检查不变量
        assert(balance == oldBalance - amount);
        assert(balance <= totalSupply);
    }
}
```
选择建议：

1. 优先使用require：

* 用于所有需要验证的外部输入
* 用于检查合约状态是否满足执行条件
* 用于权限验证

2. 谨慎使用assert：

* 只用于检查理论上永远为真的条件
* 用于开发阶段的调试
* 用于检查合约内部逻辑的正确性

3. 灵活使用revert：

* 用于复杂的条件判断
* 用于需要传递详细错误信息的场景
* 结合自定义错误使用









































