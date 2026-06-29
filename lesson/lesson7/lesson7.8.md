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






















































































