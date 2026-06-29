# 8. Gas消耗对比分析
理解不同错误处理机制的Gas消耗,有助于做出更优的设计选择。

## 8.1 错误机制Gas对比
以下是不同错误处理方式的Gas消耗对比：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract GasComparison {
    uint256 public value = 100;
    
    // 自定义错误定义
    error ValueTooHigh(uint256 current, uint256 maximum);
    error ValueTooLow(uint256 current, uint256 minimum);
    
    // 1. require + 短字符串
    function testRequireShortString(uint256 newValue) public {
        require(newValue <= 200, "Too high");
        value = newValue;
    }
    
    // 2. require + 长字符串
    function testRequireLongString(uint256 newValue) public {
        require(
            newValue <= 200,
            "The value you provided is too high and exceeds the maximum allowed"
        );
        value = newValue;
    }
    
    // 3. require + 自定义错误
    function testRequireCustomError(uint256 newValue) public {
        if (newValue > 200) revert ValueTooHigh(newValue, 200);
        value = newValue;
    }
    
    // 4. assert
    function testAssert(uint256 newValue) public {
        value = newValue;
        assert(value <= 1000);  // 如果失败会消耗所有Gas
    }
    
    // 5. revert + 字符串
    function testRevertString(uint256 newValue) public {
        if (newValue > 200) revert("Value too high");
        value = newValue;
    }
    
    // 6. revert + 自定义错误
    function testRevertCustomError(uint256 newValue) public {
        if (newValue > 200) revert ValueTooHigh(newValue, 200);
        value = newValue;
    }
}
```
Gas消耗数据（失败时）：
|错误机制|Gas消耗|节省比例|
|:--:|:--:|:--:|
|require + 长字符串|~24,500 gas|基准|
|require + 短字符串|~23,800 gas|2.9%|
|revert + 字符串|~23,900 gas|2.4%|
|require + 自定义错误|~21,200 gas|13.5%|
|revert + 自定义错误|~21,300 gas|13.1%|
|assert（消耗全部）|全部Gas|-|

关键发现：

* 自定义错误比字符串错误节省约13-15%的Gas
* 字符串越长,Gas消耗越高
* assert失败时消耗全部Gas,应该避免用于输入验证
* require和revert配合自定义错误的Gas消耗相近

## 8.2 成功执行时的Gas对比
当条件满足,函数成功执行时的Gas消耗：
```sol
contract SuccessGasComparison {
    uint256 public value;
    
    error ValueOutOfRange(uint256 value);
    
    // require版本
    function setWithRequire(uint256 newValue) public {
        require(newValue < 100, "Value too high");
        value = newValue;
    }
    
    // 自定义错误版本
    function setWithCustomError(uint256 newValue) public {
        if (newValue >= 100) revert ValueOutOfRange(newValue);
        value = newValue;
    }
    
    // 无检查版本（不推荐）
    function setWithoutCheck(uint256 newValue) public {
        value = newValue;
    }
}
```
Gas消耗数据（成功时）：
|版本|Gas消耗|差异|
|:--:|:--:|:--:|
|无检查|~43,400 gas|基准|
|require + 字符串|~43,650 gas|+0.6%|
|自定义错误|~43,580 gas|+0.4%|

结论：

* 成功执行时,不同错误处理方式的Gas差异很小（[<]1%）
* 主要差异体现在失败时的Gas消耗
* 错误检查的额外成本是值得的（安全性换来的代价很小）

## 8.3 实际应用中的Gas优化建议

1. 使用自定义错误替代字符串
```sol
contract GasOptimizedToken {
    // ✅ 推荐：使用自定义错误
    error InsufficientBalance(uint256 available, uint256 required);
    
    mapping(address => uint256) public balanceOf;
    
    function transfer(address to, uint256 amount) public {
        if (balanceOf[msg.sender] < amount) {
            revert InsufficientBalance(balanceOf[msg.sender], amount);
        }
        // 每次失败节省约3,000 gas
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }
}
```
2. 合并相似的检查
```sol
contract CheckOptimization {
    // ❌ 不够优化：多个独立检查
    function badTransfer(address to, uint256 amount) public {
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Invalid amount");
        require(amount <= 1000, "Amount too high");
        // 每个require都有基础开销
    }
    
    // ✅ 更优：合并检查
    function goodTransfer(address to, uint256 amount) public {
        require(
            to != address(0) && amount > 0 && amount <= 1000,
            "Invalid parameters"
        );
        // 单个require,减少基础开销
    }
    
    // ✅ 最优：使用自定义错误分别处理
    error InvalidRecipient();
    error InvalidAmount();
    
    function bestTransfer(address to, uint256 amount) public {
        if (to == address(0)) revert InvalidRecipient();
        if (amount == 0 || amount > 1000) revert InvalidAmount();
        // 清晰且节省Gas
    }
}
```
3. 早期退出以节省Gas
```sol
contract EarlyExit {
    mapping(address => uint256) public balances;
    mapping(address => bool) public blacklist;
    
    // ✅ 好：先检查简单条件
    function transfer(address to, uint256 amount) public {
        // 1. 先检查最简单的条件（消耗最少Gas）
        if (to == address(0)) revert("Invalid recipient");
        if (amount == 0) revert("Invalid amount");
        
        // 2. 再检查状态读取相关的条件（消耗中等Gas）
        if (blacklist[msg.sender]) revert("Sender blacklisted");
        if (blacklist[to]) revert("Recipient blacklisted");
        
        // 3. 最后检查最复杂的条件（消耗最多Gas）
        if (balances[msg.sender] < amount) revert("Insufficient balance");
        
        // 执行转账
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
```
## 8.4 批量操作的错误处理
在批量操作中,错误处理策略会显著影响Gas消耗。
```sol
contract BatchOperations {
    mapping(address => uint256) public balances;
    
    error TransferFailed(uint256 index, address recipient);
    
    event TransferSuccess(address indexed to, uint256 amount);
    event TransferSkipped(address indexed to, uint256 amount, string reason);
    
    // 策略1：一个失败全部失败
    function batchTransferStrictMode(
        address[] memory recipients,
        uint256[] memory amounts
    ) public {
        require(recipients.length == amounts.length, "Length mismatch");
        
        // 一次性检查总金额
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        require(balances[msg.sender] >= totalAmount, "Insufficient balance");
        
        // 执行所有转账
        for (uint256 i = 0; i < recipients.length; i++) {
            balances[msg.sender] -= amounts[i];
            balances[recipients[i]] += amounts[i];
            emit TransferSuccess(recipients[i], amounts[i]);
        }
    }
    
    // 策略2：单个失败不影响其他
    function batchTransferLenientMode(
        address[] memory recipients,
        uint256[] memory amounts
    ) public returns (uint256 successCount) {
        require(recipients.length == amounts.length, "Length mismatch");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            // 检查单个转账
            if (recipients[i] == address(0)) {
                emit TransferSkipped(recipients[i], amounts[i], "Invalid recipient");
                continue;
            }
            
            if (balances[msg.sender] < amounts[i]) {
                emit TransferSkipped(recipients[i], amounts[i], "Insufficient balance");
                continue;
            }
            
            // 执行转账
            balances[msg.sender] -= amounts[i];
            balances[recipients[i]] += amounts[i];
            emit TransferSuccess(recipients[i], amounts[i]);
            successCount++;
        }
        
        return successCount;
    }
}
```
Gas分析：

* 严格模式：Gas更低（一次性检查）,但一个失败全部回滚
* 宽松模式：Gas稍高（多次检查）,但部分成功更灵活

根据业务需求选择合适的策略。

# 9. 实践练习
通过实践练习来巩固错误处理的知识。

## 9.1 练习1：基础错误处理（⭐⭐难度）
任务：创建一个简单的银行合约,实现存款、取款功能,并使用适当的错误处理。

要求：

* 使用require进行输入验证
* 使用自定义错误提供详细的错误信息
* 确保在余额不足时正确抛出异常

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleBank {
    // 自定义错误
    error InsufficientBalance(address account, uint256 available, uint256 required);
    error InvalidAmount(uint256 amount);
    error WithdrawalFailed();
    
    mapping(address => uint256) public balances;
    
    event Deposit(address indexed account, uint256 amount);
    event Withdrawal(address indexed account, uint256 amount);
    
    /**
     * @notice 存款
     */
    function deposit() public payable {
        require(msg.value > 0, "存款金额必须大于0");
        
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @notice 取款
     */
    function withdraw(uint256 amount) public {
        // 输入验证
        if (amount == 0) revert InvalidAmount(amount);
        
        // 余额检查
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(msg.sender, balances[msg.sender], amount);
        }
        
        // 更新状态
        balances[msg.sender] -= amount;
        
        // 转账
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            // 如果转账失败,恢复余额
            balances[msg.sender] += amount;
            revert WithdrawalFailed();
        }
        
        emit Withdrawal(msg.sender, amount);
    }
    
    /**
     * @notice 查询余额
     */
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
}
```

## 9.2 练习2：try-catch实践（⭐⭐⭐难度）
任务：创建一个代币交换合约,使用try-catch处理外部ERC20代币转账可能出现的异常。

要求：

* 使用try-catch捕获代币转账错误
* 区分不同类型的错误（字符串错误、Panic、自定义错误）
* 实现失败回滚机制

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract TokenSwap {
    event SwapSuccess(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event SwapFailed(address indexed user, string reason);
    event SwapFailedPanic(address indexed user, uint256 errorCode);
    event SwapFailedCustom(address indexed user, bytes errorData);
    
    /**
     * @notice 交换代币
     */
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) public returns (bool) {
        // 步骤1：从用户转入tokenIn
        try IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn) returns (bool success) {
            if (!success) {
                emit SwapFailed(msg.sender, "TransferFrom returned false");
                return false;
            }
            
            // 步骤2：向用户转出tokenOut
            try IERC20(tokenOut).transfer(msg.sender, amountOut) returns (bool success2) {
                if (!success2) {
                    // tokenOut转账失败,退还tokenIn
                    IERC20(tokenIn).transfer(msg.sender, amountIn);
                    emit SwapFailed(msg.sender, "Transfer returned false");
                    return false;
                }
                
                emit SwapSuccess(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
                return true;
                
            } catch Error(string memory reason) {
                // tokenOut转账失败,退还tokenIn
                IERC20(tokenIn).transfer(msg.sender, amountIn);
                emit SwapFailed(msg.sender, reason);
                return false;
            } catch Panic(uint errorCode) {
                // tokenOut转账Panic,退还tokenIn
                IERC20(tokenIn).transfer(msg.sender, amountIn);
                emit SwapFailedPanic(msg.sender, errorCode);
                return false;
            } catch (bytes memory errorData) {
                // tokenOut转账其他错误,退还tokenIn
                IERC20(tokenIn).transfer(msg.sender, amountIn);
                emit SwapFailedCustom(msg.sender, errorData);
                return false;
            }
            
        } catch Error(string memory reason) {
            emit SwapFailed(msg.sender, reason);
            return false;
        } catch Panic(uint errorCode) {
            emit SwapFailedPanic(msg.sender, errorCode);
            return false;
        } catch (bytes memory errorData) {
            emit SwapFailedCustom(msg.sender, errorData);
            return false;
        }
    }
}
```

## 9.3 练习3：自定义错误优化（⭐⭐⭐难度）
任务：将练习1中的字符串错误全部替换为自定义错误,比较Gas消耗差异。

要求：

* 定义完整的自定义错误类型
* 替换所有字符串错误
* 在Remix中测试并比较Gas消耗

参考答案：

见练习1的答案（已经使用自定义错误）

Gas对比测试步骤：

* 创建两个版本的合约：一个使用字符串错误,一个使用自定义错误
* 在Remix中部署两个合约
* 分别调用会失败的函数（如取款超过余额）
* 在控制台查看Gas消耗
* 记录并比较差异


## 9.4 练习4：完整的DApp错误处理（⭐⭐⭐⭐难度）
任务：设计一个众筹合约,实现完整的错误处理系统。

要求：

* 使用require进行输入验证
* 使用自定义错误提供详细信息
* 使用try-catch处理退款过程中的异常
* 遵循Checks-Effects-Interactions模式
* 处理所有可能的边界情况

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Crowdfunding {
    // ============ 自定义错误 ============
    
    error CampaignNotActive();
    error CampaignAlreadyEnded();
    error GoalNotReached(uint256 current, uint256 goal);
    error GoalAlreadyReached();
    error InvalidAmount(uint256 amount);
    error Unauthorized(address caller);
    error RefundFailed(address contributor);
    error WithdrawalFailed();
    error AlreadyRefunded(address contributor);
    
    // ============ 状态变量 ============
    
    address public owner;
    uint256 public goal;
    uint256 public deadline;
    uint256 public totalRaised;
    bool public ended;
    bool public goalReached;
    
    mapping(address => uint256) public contributions;
    mapping(address => bool) public refunded;
    
    // ============ 事件 ============
    
    event Contribution(address indexed contributor, uint256 amount);
    event GoalReached(uint256 totalAmount);
    event Withdrawal(address indexed owner, uint256 amount);
    event Refund(address indexed contributor, uint256 amount);
    event RefundFailed(address indexed contributor, uint256 amount, string reason);
    
    // ============ 修饰符 ============
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized(msg.sender);
        _;
    }
    
    modifier campaignActive() {
        if (ended) revert CampaignAlreadyEnded();
        if (block.timestamp >= deadline) revert CampaignNotActive();
        _;
    }
    
    // ============ 构造函数 ============
    
    constructor(uint256 _goal, uint256 _duration) {
        require(_goal > 0, "目标金额必须大于0");
        require(_duration > 0, "持续时间必须大于0");
        
        owner = msg.sender;
        goal = _goal;
        deadline = block.timestamp + _duration;
    }
    
    // ============ 公共函数 ============
    
    /**
     * @notice 贡献资金
     */
    function contribute() public payable campaignActive {
        // 1. Checks: 输入验证
        if (msg.value == 0) revert InvalidAmount(msg.value);
        
        // 2. Effects: 更新状态
        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;
        
        // 检查是否达到目标
        if (!goalReached && totalRaised >= goal) {
            goalReached = true;
            emit GoalReached(totalRaised);
        }
        
        // 3. Interactions: 触发事件
        emit Contribution(msg.sender, msg.value);
    }
    
    /**
     * @notice 结束众筹
     */
    function endCampaign() public {
        // 检查时间
        require(block.timestamp >= deadline, "众筹尚未结束");
        require(!ended, "众筹已经结束");
        
        ended = true;
        
        if (totalRaised >= goal) {
            goalReached = true;
        }
    }
    
    /**
     * @notice 提取资金（仅所有者，目标达成后）
     */
    function withdraw() public onlyOwner {
        // 1. Checks
        require(ended, "众筹尚未结束");
        if (!goalReached) revert GoalNotReached(totalRaised, goal);
        
        uint256 amount = address(this).balance;
        require(amount > 0, "没有可提取的资金");
        
        // 2. Effects: 清空余额（防止重入）
        // 注意：这里简化处理，实际应该更细致
        
        // 3. Interactions: 转账
        (bool success, ) = owner.call{value: amount}("");
        if (!success) revert WithdrawalFailed();
        
        emit Withdrawal(owner, amount);
    }
    
    /**
     * @notice 退款（目标未达成时）
     */
    function refund() public {
        // 1. Checks
        require(ended, "众筹尚未结束");
        if (goalReached) revert GoalAlreadyReached();
        
        uint256 amount = contributions[msg.sender];
        require(amount > 0, "没有贡献");
        
        if (refunded[msg.sender]) revert AlreadyRefunded(msg.sender);
        
        // 2. Effects: 更新状态
        contributions[msg.sender] = 0;
        refunded[msg.sender] = true;
        
        // 3. Interactions: 退款
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            // 如果退款失败，恢复状态
            contributions[msg.sender] = amount;
            refunded[msg.sender] = false;
            revert RefundFailed(msg.sender);
        }
        
        emit Refund(msg.sender, amount);
    }
    
    /**
     * @notice 批量退款（仅所有者，用于紧急情况）
     */
    function batchRefund(address[] memory contributors) public onlyOwner {
        require(ended, "众筹尚未结束");
        require(!goalReached, "目标已达成，不能退款");
        
        for (uint256 i = 0; i < contributors.length; i++) {
            address contributor = contributors[i];
            uint256 amount = contributions[contributor];
            
            if (amount == 0 || refunded[contributor]) {
                continue;  // 跳过已退款或没有贡献的地址
            }
            
            // 更新状态
            contributions[contributor] = 0;
            refunded[contributor] = true;
            
            // 尝试退款，使用try-catch处理异常
            (bool success, ) = contributor.call{value: amount}("");
            
            if (success) {
                emit Refund(contributor, amount);
            } else {
                // 退款失败，恢复状态并记录
                contributions[contributor] = amount;
                refunded[contributor] = false;
                emit RefundFailed(contributor, amount, "Transfer failed");
            }
        }
    }
    
    /**
     * @notice 查询剩余时间
     */
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }
}
```











































