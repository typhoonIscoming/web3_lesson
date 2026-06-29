# 4. try-catch异常捕获

## 4.1 try-catch基础
try-catch是Solidity中用于捕获外部合约调用异常的机制。它让我们能够优雅地处理外部调用可能出现的各种错误情况。

基本语法：

```sol
try externalContract.someFunction() returns (returnType returnValue) {
    // 成功时执行的代码
} catch Error(string memory reason) {
    // 捕获require/revert的字符串错误
} catch Panic(uint errorCode) {
    // 捕获assert失败和内部错误
} catch (bytes memory lowLevelData) {
    // 捕获其他所有错误（包括自定义错误）
}
```
重要限制：

* 只能捕获外部调用：try-catch只能用于外部合约调用，不能用于当前合约的内部函数
* 必须是外部调用：被调用的函数必须标记为external或public
* 不能捕获内部错误：当前合约内部的错误会直接传播，不会被catch捕获

## 4.2 基础示例
以下是一个完整的try-catch使用示例：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 外部合约：可能失败的计算器
contract Calculator {
    error DivisionByZero();
    
    function divide(uint256 a, uint256 b) external pure returns (uint256) {
        if (b == 0) revert DivisionByZero();
        return a / b;
    }
    
    function riskyOperation(uint256 value) external pure returns (uint256) {
        require(value < 100, "Value too high");
        return value * 2;
    }
}

// 调用者合约：使用try-catch处理异常
contract CalculatorCaller {
    Calculator public calculator;
    
    event OperationSuccess(uint256 result);
    event OperationFailed(string reason);
    event UnknownError();
    
    constructor(address _calculator) {
        calculator = Calculator(_calculator);
    }
    
    // 基础try-catch示例
    function safeDivide(uint256 a, uint256 b) public returns (uint256) {
        try calculator.divide(a, b) returns (uint256 result) {
            // 成功时执行
            emit OperationSuccess(result);
            return result;
        } catch Error(string memory reason) {
            // 捕获字符串错误
            emit OperationFailed(reason);
            return 0;
        } catch (bytes memory lowLevelData) {
            // 捕获自定义错误和其他错误
            emit UnknownError();
            return 0;
        }
    }
    
    // 处理require错误
    function safeRiskyOperation(uint256 value) public returns (uint256) {
        try calculator.riskyOperation(value) returns (uint256 result) {
            emit OperationSuccess(result);
            return result;
        } catch Error(string memory reason) {
            // 捕获"Value too high"错误
            emit OperationFailed(reason);
            return 0;
        } catch {
            // 简化的catch，捕获所有其他错误
            emit UnknownError();
            return 0;
        }
    }
}
```

## 4.3 catch子句类型
Solidity提供了三种类型的catch子句：

1. catch Error(string memory reason)：

捕获使用require或revert抛出的字符串错误。

```sol
contract StringErrorCatch {
    interface IExternal {
        function doSomething() external;
    }
    
    IExternal public externalContract;
    
    event ErrorCaught(string reason);
    
    function callExternal() public {
        try externalContract.doSomething() {
            // 成功
        } catch Error(string memory reason) {
            // 捕获字符串错误
            // 例如：require(false, "这是错误消息")
            emit ErrorCaught(reason);
        }
    }
}
```

2. catch Panic(uint errorCode)：
捕获Panic错误，这些错误通常由assert失败或运行时错误（如除以零、数组越界等）引起。
```sol
contract PanicCatch {
    interface IExternal {
        function riskyCalculation(uint256 a, uint256 b) external returns (uint256);
    }
    
    IExternal public externalContract;
    
    event PanicCaught(uint256 errorCode);
    
    function callExternal(uint256 a, uint256 b) public {
        try externalContract.riskyCalculation(a, b) returns (uint256 result) {
            // 成功
        } catch Panic(uint errorCode) {
            // 捕获Panic错误
            // errorCode可能的值：
            // 0x01: assert失败
            // 0x11: 算术运算溢出/下溢
            // 0x12: 除以零或模零
            // 0x21: 枚举转换错误
            // 0x22: 访问存储字节数组错误
            // 0x31: 对空数组调用.pop()
            // 0x32: 数组越界
            // 0x41: 分配过多内存
            // 0x51: 调用零值internal function
            emit PanicCaught(errorCode);
        }
    }
}
```
3. catch (bytes memory lowLevelData)：

捕获所有其他类型的错误，包括自定义错误、没有错误消息的revert等。

```sol
contract LowLevelCatch {
    interface IExternal {
        function doSomething() external;
    }
    
    IExternal public externalContract;
    
    event LowLevelErrorCaught(bytes data);
    
    function callExternal() public {
        try externalContract.doSomething() {
            // 成功
        } catch (bytes memory lowLevelData) {
            // 捕获所有其他错误
            // 包括自定义错误
            // 可以解析lowLevelData获取错误详情
            emit LowLevelErrorCaught(lowLevelData);
        }
    }
}
```

## 4.4 完整的try-catch示例
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 外部ERC20代币合约接口
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// 模拟的代币合约
contract MockToken {
    mapping(address => uint256) public balanceOf;
    bool public paused = false;
    
    error TransferPaused();
    error InsufficientBalance(uint256 available, uint256 required);
    
    constructor() {
        balanceOf[msg.sender] = 1000;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        if (paused) revert TransferPaused();
        
        if (balanceOf[msg.sender] < amount) {
            revert InsufficientBalance(balanceOf[msg.sender], amount);
        }
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
    
    function pause() external {
        paused = true;
    }
    
    function riskyCalculation(uint256 a, uint256 b) external pure returns (uint256) {
        return a / b;  // 如果b=0，会触发Panic
    }
}

// 代币处理合约
contract TokenHandler {
    IERC20 public token;
    
    event TransferSuccess(address indexed to, uint256 amount);
    event TransferFailedString(address indexed to, uint256 amount, string reason);
    event TransferFailedPanic(address indexed to, uint256 amount, uint256 errorCode);
    event TransferFailedCustom(address indexed to, uint256 amount, bytes data);
    
    constructor(address _token) {
        token = IERC20(_token);
    }
    
    /**
     * @notice 安全转账：捕获所有类型的错误
     */
    function safeTransfer(address to, uint256 amount) public {
        try token.transfer(to, amount) returns (bool success) {
            if (success) {
                emit TransferSuccess(to, amount);
            } else {
                emit TransferFailedString(to, amount, "Transfer returned false");
            }
        } catch Error(string memory reason) {
            // 捕获字符串错误（require/revert with string）
            emit TransferFailedString(to, amount, reason);
        } catch Panic(uint errorCode) {
            // 捕获Panic错误（assert/运行时错误）
            emit TransferFailedPanic(to, amount, errorCode);
        } catch (bytes memory lowLevelData) {
            // 捕获自定义错误和其他错误
            emit TransferFailedCustom(to, amount, lowLevelData);
        }
    }
    
    /**
     * @notice 批量安全转账：单个失败不影响其他
     */
    function batchSafeTransfer(
        address[] memory recipients,
        uint256[] memory amounts
    ) public {
        require(recipients.length == amounts.length, "Array length mismatch");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            try token.transfer(recipients[i], amounts[i]) returns (bool success) {
                if (success) {
                    emit TransferSuccess(recipients[i], amounts[i]);
                }
            } catch Error(string memory reason) {
                emit TransferFailedString(recipients[i], amounts[i], reason);
                // 继续处理下一个，不中断整个批次
            } catch Panic(uint errorCode) {
                emit TransferFailedPanic(recipients[i], amounts[i], errorCode);
                // 继续处理下一个
            } catch (bytes memory lowLevelData) {
                emit TransferFailedCustom(recipients[i], amounts[i], lowLevelData);
                // 继续处理下一个
            }
        }
    }
    
    /**
     * @notice 条件转账：先检查余额再转账
     */
    function transferIfSufficient(address to, uint256 amount) public returns (bool) {
        // 先检查余额
        try token.balanceOf(address(this)) returns (uint256 balance) {
            if (balance < amount) {
                emit TransferFailedString(to, amount, "Insufficient contract balance");
                return false;
            }
            
            // 余额充足，尝试转账
            try token.transfer(to, amount) returns (bool success) {
                if (success) {
                    emit TransferSuccess(to, amount);
                    return true;
                } else {
                    emit TransferFailedString(to, amount, "Transfer returned false");
                    return false;
                }
            } catch Error(string memory reason) {
                emit TransferFailedString(to, amount, reason);
                return false;
            } catch {
                emit TransferFailedCustom(to, amount, "");
                return false;
            }
        } catch {
            emit TransferFailedString(to, amount, "Balance check failed");
            return false;
        }
    }
}
```

## 4.5 try-catch的使用场景

**场景1：ERC20代币转账**

处理代币转账可能出现的各种异常情况。
```sol
contract TokenTransferHandler {
    IERC20 public token;
    
    event TransferAttempted(address to, uint256 amount, bool success);
    
    function safeTransferToken(address to, uint256 amount) public {
        try token.transfer(to, amount) returns (bool success) {
            emit TransferAttempted(to, amount, success);
        } catch {
            // 转账失败，记录但不revert
            emit TransferAttempted(to, amount, false);
        }
    }
}
```

**场景2：多合约交互**

在复杂的DeFi协议中，需要调用多个外部合约。
```sol
contract DeFiProtocol {
    interface ILendingPool {
        function deposit(address asset, uint256 amount) external;
    }
    
    interface ISwapRouter {
        function swap(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256);
    }
    
    ILendingPool public lendingPool;
    ISwapRouter public swapRouter;
    
    event StepFailed(string step, string reason);
    
    function complexOperation(
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) public {
        // 步骤1：交换代币
        try swapRouter.swap(tokenIn, tokenOut, amount) returns (uint256 amountOut) {
            // 步骤2：存入借贷池
            try lendingPool.deposit(tokenOut, amountOut) {
                // 全部成功
            } catch Error(string memory reason) {
                emit StepFailed("deposit", reason);
                // 回滚或执行补救措施
            }
        } catch Error(string memory reason) {
            emit StepFailed("swap", reason);
            // 处理交换失败
        }
    }
}
```
**场景3：合约升级和迁移**

在合约升级过程中安全地调用新旧合约。

```sol
contract ContractMigration {
    address public oldContract;
    address public newContract;
    
    interface IOldContract {
        function getData(uint256 id) external view returns (bytes memory);
    }
    
    interface INewContract {
        function setData(uint256 id, bytes memory data) external;
    }
    
    event MigrationSuccess(uint256 id);
    event MigrationFailed(uint256 id, string reason);
    
    function migrateData(uint256[] memory ids) public {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            
            // 从旧合约读取数据
            try IOldContract(oldContract).getData(id) returns (bytes memory data) {
                // 写入新合约
                try INewContract(newContract).setData(id, data) {
                    emit MigrationSuccess(id);
                } catch Error(string memory reason) {
                    emit MigrationFailed(id, reason);
                }
            } catch Error(string memory reason) {
                emit MigrationFailed(id, reason);
            }
        }
    }
}
```

## 4.6 try-catch注意事项

1. 避免嵌套过深

过深的嵌套会让代码难以理解和维护。

```sol
// ❌ 不好：嵌套过深
function badNestedTryCatch() public {
    try external1.call1() {
        try external2.call2() {
            try external3.call3() {
                // 太多层级
            } catch {
                // ...
            }
        } catch {
            // ...
        }
    } catch {
        // ...
    }
}

// ✅ 好：将逻辑拆分到不同函数
function goodSeparatedCalls() public {
    if (!tryCall1()) return;
    if (!tryCall2()) return;
    tryCall3();
}

function tryCall1() private returns (bool) {
    try external1.call1() {
        return true;
    } catch {
        return false;
    }
}
```

2. 注意Gas消耗

catch块中的代码也会消耗Gas，需要保持简单。

```sol
contract GasAwareTryCatch {
    // ❌ 不好：catch块中有复杂逻辑
    function badCatch() public {
        try externalCall() {
            // ...
        } catch {
            // 复杂的循环和计算
            for (uint256 i = 0; i < 1000; i++) {
                // 大量Gas消耗
            }
        }
    }
    
    // ✅ 好：catch块保持简单
    function goodCatch() public {
        try externalCall() {
            // ...
        } catch {
            // 只记录错误或设置标志
            emit ErrorOccurred();
        }
    }
    
    event ErrorOccurred();
    function externalCall() public {}
}
```

3. 处理返回值

正确处理try块中的返回值。

```sol
contract ReturnValueHandling {
    interface IExternal {
        function getValue() external returns (uint256);
    }
    
    IExternal public externalContract;
    
    // ✅ 正确处理返回值
    function handleReturnValue() public returns (uint256) {
        try externalContract.getValue() returns (uint256 value) {
            // 使用返回值
            return value * 2;
        } catch {
            // 返回默认值
            return 0;
        }
    }
}
```

# 5. 错误处理最佳实践
良好的错误处理不仅能让合约更安全,还能提升用户体验和降低Gas成本。以下是10个关键的最佳实践。

## 5.1 使用有意义的错误消息
错误消息应该清晰地说明问题所在,帮助开发者调试和用户理解。
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MeaningfulErrors {
    mapping(address => uint256) public balances;
    
    // ❌ 不好：错误消息不明确
    function badTransfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Error");  // 太笼统
        require(to != address(0), "Invalid");              // 不够具体
        require(amount > 0, "Bad amount");                 // 不专业
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    
    // ✅ 好：清晰、具体的错误消息
    function goodTransfer(address to, uint256 amount) public {
        require(
            balances[msg.sender] >= amount,
            "余额不足: 您的余额少于转账金额"
        );
        require(
            to != address(0),
            "无效接收地址: 接收地址不能为零地址"
        );
        require(
            amount > 0,
            "无效金额: 转账金额必须大于0"
        );
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    
    // ✅ 更好：使用自定义错误提供结构化信息
    error InsufficientBalance(address account, uint256 available, uint256 required);
    error InvalidRecipient(address recipient);
    error InvalidAmount(uint256 amount);
    
    function bestTransfer(address to, uint256 amount) public {
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(msg.sender, balances[msg.sender], amount);
        }
        if (to == address(0)) {
            revert InvalidRecipient(to);
        }
        if (amount == 0) {
            revert InvalidAmount(amount);
        }
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
```
## 5.2 优先使用require进行输入验证
require应该放在函数开始处,尽早检测错误,避免不必要的计算。
```sol
contract RequireFirst {
    mapping(address => uint256) public balances;
    uint256 public totalTransferred;
    
    // ❌ 不好：在执行操作后才检查
    function badWithdraw(uint256 amount) public {
        balances[msg.sender] -= amount;  // 可能导致整数下溢
        
        require(balances[msg.sender] >= 0, "余额不足");  // 检查太晚
    }
    
    // ✅ 好：在函数开始处检查所有条件
    function goodWithdraw(uint256 amount) public {
        // 1. 先检查所有输入和状态
        require(amount > 0, "金额必须大于0");
        require(balances[msg.sender] >= amount, "余额不足");
        
        // 2. 然后执行操作
        balances[msg.sender] -= amount;
        totalTransferred += amount;
        
        // 3. 最后触发事件
        emit Withdrawal(msg.sender, amount);
    }
    
    event Withdrawal(address indexed account, uint256 amount);
}
```
## 5.3 使用assert验证不变量
assert应该只用于检查理论上永远不应该失败的条件。
```sol
contract InvariantChecks {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    
    // 不变量：所有余额之和应该等于总供应量
    function transfer(address to, uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "余额不足");
        require(to != address(0), "无效接收地址");
        
        // 记录操作前的状态
        uint256 totalBefore = balanceOf[msg.sender] + balanceOf[to];
        
        // 执行转账
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        // 使用assert检查不变量
        // 转账前后的总和应该保持不变
        assert(balanceOf[msg.sender] + balanceOf[to] == totalBefore);
    }
    
    function mint(address to, uint256 amount) public {
        uint256 oldTotalSupply = totalSupply;
        uint256 oldBalance = balanceOf[to];
        
        totalSupply += amount;
        balanceOf[to] += amount;
        
        // 检查不变量：总供应量的增加应该等于余额的增加
        assert(totalSupply - oldTotalSupply == balanceOf[to] - oldBalance);
    }
}
```
## 5.4 自定义错误优于字符串错误
在Solidity 0.8.4+版本中,应该优先使用自定义错误。
```sol
contract CustomVsString {
    uint256 public balance = 1000;
    
    // 字符串错误示例
    function withdrawString(uint256 amount) public {
        require(balance >= amount, "Insufficient balance: your balance is less than the requested amount");
        // 长字符串消耗更多Gas
        balance -= amount;
    }
    
    // 自定义错误示例
    error InsufficientBalance(uint256 available, uint256 required);
    
    function withdrawCustom(uint256 amount) public {
        if (balance < amount) {
            revert InsufficientBalance(balance, amount);
        }
        // 更少的Gas消耗
        balance -= amount;
    }
}
```
Gas消耗对比（失败时）：

* 字符串错误：~24,000 gas
* 自定义错误：~21,000 gas
* 节省：~12.5%

# 5.5 合理使用try-catch
try-catch应该只用于外部调用,不要过度使用
```sol
contract TryCatchUsage {
    interface IExternal {
        function riskyOperation() external returns (bool);
    }
    
    IExternal public externalContract;
    
    // ✅ 正确：用于外部调用
    function callExternal() public {
        try externalContract.riskyOperation() returns (bool success) {
            if (success) {
                // 处理成功情况
            }
        } catch {
            // 处理失败情况
        }
    }
    
    // ❌ 错误：不能用于内部函数
    function internalFunction() internal {
        // 内部函数的错误会直接传播,无法catch
    }
    
    // ❌ 不好：不需要try-catch的情况
    function unnecessaryTryCatch(uint256 value) public {
        // 如果知道操作一定会成功,不需要try-catch
        if (value > 0) {
            // 执行操作
        }
    }
}
```
# 5.6 遵循Checks-Effects-Interactions模式

按照检查、效果、交互的顺序组织代码,这是防止重入攻击的最佳实践。

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ChecksEffectsInteractions {
    mapping(address => uint256) public balances;
    
    event Withdrawal(address indexed account, uint256 amount);
    
    // ✅ 正确：遵循CEI模式
    function withdraw(uint256 amount) public {
        // 1. Checks（检查）：验证所有条件
        require(amount > 0, "金额必须大于0");
        require(balances[msg.sender] >= amount, "余额不足");
        
        // 2. Effects（效果）：更新状态
        balances[msg.sender] -= amount;
        
        // 3. Interactions（交互）：外部调用和事件
        emit Withdrawal(msg.sender, amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "转账失败");
    }
    
    // ❌ 危险：外部调用在状态更新之前
    function badWithdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "余额不足");
        
        // 危险：先进行外部调用
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "转账失败");
        
        // 状态更新在外部调用之后（重入风险）
        balances[msg.sender] -= amount;
    }
}
```
# 5.7 提供错误恢复机制
在可能的情况下,提供错误恢复或回退方案。

```sol
contract ErrorRecovery {
    address public primaryOracle;
    address public fallbackOracle;
    
    interface IOracle {
        function getPrice() external view returns (uint256);
    }
    
    // ✅ 好：有回退方案
    function getPriceWithFallback() public view returns (uint256) {
        // 首先尝试主要预言机
        try IOracle(primaryOracle).getPrice() returns (uint256 price) {
            return price;
        } catch {
            // 如果主要预言机失败,尝试备用预言机
            try IOracle(fallbackOracle).getPrice() returns (uint256 price) {
                return price;
            } catch {
                // 都失败了,返回默认值或revert
                revert("无法获取价格");
            }
        }
    }
    
    // 批量操作中的部分失败处理
    mapping(address => uint256) public balances;
    
    event TransferSuccess(address to, uint256 amount);
    event TransferFailed(address to, uint256 amount, string reason);
    
    function batchTransfer(
        address[] memory recipients,
        uint256[] memory amounts
    ) public returns (uint256 successCount) {
        require(recipients.length == amounts.length, "数组长度不匹配");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == address(0)) {
                emit TransferFailed(recipients[i], amounts[i], "无效地址");
                continue;  // 跳过这个,继续处理其他
            }
            
            if (balances[msg.sender] < amounts[i]) {
                emit TransferFailed(recipients[i], amounts[i], "余额不足");
                continue;
            }
            
            balances[msg.sender] -= amounts[i];
            balances[recipients[i]] += amounts[i];
            emit TransferSuccess(recipients[i], amounts[i]);
            successCount++;
        }
        
        return successCount;
    }
}
```
# 5.8 避免错误消息过长
过长的错误消息会增加Gas消耗。

```sol
contract MessageLength {
    uint256 public value;
    
    // ❌ 不好：错误消息过长
    function badSet(uint256 newValue) public {
        require(
            newValue < 100,
            "The value you provided is too large. The maximum allowed value is 99. Please provide a smaller value and try again. For more information, please refer to the documentation."
        );
        value = newValue;
    }
    
    // ✅ 好：简洁但清晰的错误消息
    function goodSet(uint256 newValue) public {
        require(newValue < 100, "值必须小于100");
        value = newValue;
    }
    
    // ✅ 更好：使用自定义错误
    error ValueTooLarge(uint256 provided, uint256 maximum);
    
    function bestSet(uint256 newValue) public {
        if (newValue >= 100) {
            revert ValueTooLarge(newValue, 99);
        }
        value = newValue;
    }
}
```
# 5.9 文档化错误条件
使用NatSpec注释说明函数可能抛出的错误。

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DocumentedErrors {
    error InsufficientBalance(uint256 available, uint256 required);
    error InvalidRecipient(address recipient);
    error TransferPaused();
    
    mapping(address => uint256) public balances;
    bool public paused;
    
    /**
     * @notice 转账代币
     * @param to 接收方地址
     * @param amount 转账金额
     * @dev 抛出以下错误:
     *      - TransferPaused: 如果转账功能被暂停
     *      - InvalidRecipient: 如果接收方地址为零地址
     *      - InsufficientBalance: 如果发送方余额不足
     */
    function transfer(address to, uint256 amount) public {
        if (paused) revert TransferPaused();
        if (to == address(0)) revert InvalidRecipient(to);
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(balances[msg.sender], amount);
        }
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
```
# 5.10 测试错误处理
确保测试覆盖所有错误情况。

```sol
// 测试合约示例（使用Hardhat或Truffle）
contract ErrorHandlingTest {
    TokenWithErrors public token;
    
    function setUp() public {
        token = new TokenWithErrors();
    }
    
    // 测试正常情况
    function testTransferSuccess() public {
        token.transfer(address(0x1), 100);
        // 验证余额变化
    }
    
    // 测试错误情况
    function testTransferInsufficientBalance() public {
        // 期望revert
        try token.transfer(address(0x1), 10000) {
            revert("应该失败但成功了");
        } catch Error(string memory reason) {
            // 验证错误消息
            require(
                keccak256(bytes(reason)) == keccak256(bytes("余额不足")),
                "错误消息不正确"
            );
        }
    }
}

contract TokenWithErrors {
    mapping(address => uint256) public balances;
    
    constructor() {
        balances[msg.sender] = 1000;
    }
    
    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "余额不足");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
```
# 5.11 完整的最佳实践示例
以下是一个综合应用所有最佳实践的完整示例：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title BestPracticeToken
 * @notice 展示错误处理最佳实践的代币合约
 */
contract BestPracticeToken {
    // ============ 自定义错误 ============
    
    /// @notice 余额不足
    error InsufficientBalance(address account, uint256 available, uint256 required);
    
    /// @notice 无效的接收地址
    error InvalidRecipient(address recipient);
    
    /// @notice 无效的金额
    error InvalidAmount(uint256 amount);
    
    /// @notice 未授权的操作
    error Unauthorized(address caller);
    
    /// @notice 转账已暂停
    error TransferPaused();
    
    // ============ 状态变量 ============
    
    mapping(address => uint256) public balanceOf;
    address public owner;
    bool public paused;
    
    // ============ 事件 ============
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Pause();
    event Unpause();
    
    // ============ 修饰符 ============
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized(msg.sender);
        _;
    }
    
    modifier whenNotPaused() {
        if (paused) revert TransferPaused();
        _;
    }
    
    // ============ 构造函数 ============
    
    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = 1000000;
    }
    
    // ============ 公共函数 ============
    
    /**
     * @notice 转账代币
     * @param to 接收方地址
     * @param amount 转账金额
     * @dev 可能抛出的错误:
     *      - TransferPaused: 转账被暂停
     *      - InvalidRecipient: 接收地址无效
     *      - InvalidAmount: 金额无效
     *      - InsufficientBalance: 余额不足
     */
    function transfer(address to, uint256 amount) 
        public 
        whenNotPaused 
        returns (bool) 
    {
        // 1. Checks: 输入验证（使用require或自定义错误）
        if (to == address(0)) revert InvalidRecipient(to);
        if (amount == 0) revert InvalidAmount(amount);
        if (balanceOf[msg.sender] < amount) {
            revert InsufficientBalance(msg.sender, balanceOf[msg.sender], amount);
        }
        
        // 2. Effects: 状态更新
        uint256 senderBalanceBefore = balanceOf[msg.sender];
        uint256 recipientBalanceBefore = balanceOf[to];
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        // 使用assert检查不变量
        assert(
            balanceOf[msg.sender] + balanceOf[to] ==
            senderBalanceBefore + recipientBalanceBefore
        );
        
        // 3. Interactions: 触发事件
        emit Transfer(msg.sender, to, amount);
        
        return true;
    }
    
    /**
     * @notice 暂停转账（仅所有者）
     */
    function pause() public onlyOwner {
        paused = true;
        emit Pause();
    }
    
    /**
     * @notice 恢复转账（仅所有者）
     */
    function unpause() public onlyOwner {
        paused = false;
        emit Unpause();
    }
}
```















