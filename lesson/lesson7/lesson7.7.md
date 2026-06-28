# 3. 自定义错误(0.8.4+)

## 3.1 自定义错误的定义
自定义错误是Solidity 0.8.4版本引入的重要特性，它允许开发者创建结构化的、可重用的错误类型。

基本语法：

```sol
// 定义自定义错误
error ErrorName(type1 param1, type2 param2, ...);

// 使用自定义错误
revert ErrorName(value1, value2, ...);
```

简单示例：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CustomErrorBasics {
    // 定义不带参数的错误
    error Unauthorized();
    
    // 定义带参数的错误
    error InsufficientBalance(uint256 available, uint256 required);
    
    // 定义带多个参数的错误
    error InvalidTransfer(address from, address to, uint256 amount, string reason);
    
    mapping(address => uint256) public balances;
    address public owner;
    
    constructor() {
        owner = msg.sender;
        balances[msg.sender] = 1000;
    }
    
    function transfer(address to, uint256 amount) public {
        // 使用不带参数的错误
        if (msg.sender != owner && amount > 100) {
            revert Unauthorized();
        }
        
        // 使用带参数的错误
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(balances[msg.sender], amount);
        }
        
        // 使用带多个参数的错误
        if (to == address(0)) {
            revert InvalidTransfer(msg.sender, to, amount, "接收地址不能为零地址");
        }
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
```
## 3.2 自定义错误的优势

1. Gas优化：

自定义错误比字符串错误消耗更少的Gas，这在高频交易场景下能带来显著的成本节省。
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract GasOptimization {
    uint256 public balance = 100;
    
    // 自定义错误
    error InsufficientBalance(uint256 available, uint256 required);
    
    // 使用字符串错误（Gas消耗较高）
    function withdrawString(uint256 amount) public {
        require(balance >= amount, "Insufficient balance: available balance is less than required");
        balance -= amount;
    }
    
    // 使用自定义错误（Gas消耗较低）
    function withdrawCustomError(uint256 amount) public {
        if (balance < amount) {
            revert InsufficientBalance(balance, amount);
        }
        balance -= amount;
    }
}
```
Gas消耗对比（典型场景）：

* 字符串错误：约24,000-28,000 gas（取决于字符串长度）
* 自定义错误：约21,000-23,000 gas
* 节省：约10-20%的Gas

2. 可重用性：

自定义错误可以在合约中定义一次，然后在多个函数中重复使用，减少代码重复。
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ErrorReusability {
    // 在合约顶部定义所有错误
    error InsufficientBalance(uint256 available, uint256 required);
    error Unauthorized(address caller);
    error InvalidAmount(uint256 amount);
    error InvalidRecipient(address recipient);
    
    mapping(address => uint256) public balances;
    address public owner;
    
    constructor() {
        owner = msg.sender;
        balances[msg.sender] = 1000;
    }
    
    // 在多个函数中重用相同的错误
    function transfer(address to, uint256 amount) public {
        if (to == address(0)) {
            revert InvalidRecipient(to);  // 重用InvalidRecipient
        }
        if (amount == 0) {
            revert InvalidAmount(amount);  // 重用InvalidAmount
        }
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(balances[msg.sender], amount);  // 重用InsufficientBalance
        }
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    
    function withdraw(uint256 amount) public {
        if (amount == 0) {
            revert InvalidAmount(amount);  // 重用InvalidAmount
        }
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(balances[msg.sender], amount);  // 重用InsufficientBalance
        }
        
        balances[msg.sender] -= amount;
    }
    
    function mint(address to, uint256 amount) public {
        if (msg.sender != owner) {
            revert Unauthorized(msg.sender);  // 重用Unauthorized
        }
        if (to == address(0)) {
            revert InvalidRecipient(to);  // 重用InvalidRecipient
        }
        
        balances[to] += amount;
    }
}
```
3. 可识别性：

自定义错误提供结构化的错误信息，外部合约和前端应用可以根据错误类型进行不同的处理。
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 代币合约
contract Token {
    error InsufficientBalance(uint256 available, uint256 required);
    error InsufficientAllowance(uint256 available, uint256 required);
    error InvalidRecipient(address recipient);
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    function transfer(address to, uint256 amount) public returns (bool) {
        if (to == address(0)) revert InvalidRecipient(to);
        if (balanceOf[msg.sender] < amount) {
            revert InsufficientBalance(balanceOf[msg.sender], amount);
        }
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        if (to == address(0)) revert InvalidRecipient(to);
        if (balanceOf[from] < amount) {
            revert InsufficientBalance(balanceOf[from], amount);
        }
        if (allowance[from][msg.sender] < amount) {
            revert InsufficientAllowance(allowance[from][msg.sender], amount);
        }
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        return true;
    }
}

// 调用者合约可以根据错误类型进行处理
contract TokenCaller {
    Token public token;
    
    event TransferFailed(string reason);
    
    constructor(address _token) {
        token = Token(_token);
    }
    
    function safeTransfer(address to, uint256 amount) public {
        try token.transfer(to, amount) returns (bool success) {
            if (success) {
                // 转账成功
            }
        } catch Error(string memory reason) {
            // 捕获字符串错误
            emit TransferFailed(reason);
        } catch (bytes memory lowLevelData) {
            // 捕获自定义错误（可以解码错误类型和参数）
            // 前端可以根据错误签名判断是哪种错误
            emit TransferFailed("Custom error occurred");
        }
    }
}
```
## 3.3 自定义错误的最佳实践

1. 使用PascalCase命名：

自定义错误应该使用PascalCase（大驼峰）命名法，每个单词首字母大写。

```sol
// ✅ 好的命名
error InsufficientBalance(uint256 available, uint256 required);
error Unauthorized(address caller);
error InvalidRecipient(address recipient);
error TransferPaused();
error ExceedsMaxSupply(uint256 current, uint256 max);

// ❌ 不好的命名
error insufficientBalance(uint256 available, uint256 required);  // 应该用PascalCase
error IB(uint256 a, uint256 r);  // 太简短，不清晰
error Error1(uint256 x);  // 没有意义的命名
```
2. 添加相关上下文参数：

为错误添加必要的参数，便于调试和用户理解。

```sol
contract ContextfulErrors {
    // ✅ 好的错误定义：包含充足的上下文信息
    error InsufficientBalance(
        address account,
        uint256 available,
        uint256 required
    );
    
    error TransferLimitExceeded(
        address from,
        address to,
        uint256 amount,
        uint256 dailyLimit,
        uint256 usedToday
    );
    
    error TokenLocked(
        address token,
        uint256 lockedUntil,
        uint256 currentTime
    );
    
    // ❌ 不好的错误定义：缺少上下文
    error Failed();  // 太笼统
    error Error(uint256 code);  // 使用错误代码不如直接定义明确的错误
    
    mapping(address => uint256) public balances;
    mapping(address => uint256) public dailyUsed;
    uint256 public constant DAILY_LIMIT = 1000;
    
    function transfer(address to, uint256 amount) public {
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(msg.sender, balances[msg.sender], amount);
        }
        
        if (dailyUsed[msg.sender] + amount > DAILY_LIMIT) {
            revert TransferLimitExceeded(
                msg.sender,
                to,
                amount,
                DAILY_LIMIT,
                dailyUsed[msg.sender]
            );
        }
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        dailyUsed[msg.sender] += amount;
    }
}
```
3. 组织错误层次结构：

将相关的错误组织在一起，使用命名前缀来分组。

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ErrorHierarchy {
    // 授权相关错误
    error Auth_Unauthorized(address caller);
    error Auth_InsufficientPermission(address caller, bytes32 requiredRole);
    error Auth_AccountLocked(address account, uint256 lockedUntil);
    
    // 余额相关错误
    error Balance_Insufficient(uint256 available, uint256 required);
    error Balance_ExceedsMaximum(uint256 amount, uint256 maximum);
    error Balance_Frozen(address account);
    
    // 转账相关错误
    error Transfer_InvalidRecipient(address recipient);
    error Transfer_InvalidAmount(uint256 amount);
    error Transfer_Paused();
    error Transfer_DailyLimitExceeded(uint256 amount, uint256 limit);
    
    // 时间相关错误
    error Time_TooEarly(uint256 currentTime, uint256 requiredTime);
    error Time_TooLate(uint256 currentTime, uint256 deadline);
    error Time_Expired(uint256 expiryTime);
    
    mapping(address => uint256) public balances;
    address public owner;
    bool public paused;
    
    function transfer(address to, uint256 amount) public {
        if (paused) revert Transfer_Paused();
        if (to == address(0)) revert Transfer_InvalidRecipient(to);
        if (amount == 0) revert Transfer_InvalidAmount(amount);
        if (balances[msg.sender] < amount) {
            revert Balance_Insufficient(balances[msg.sender], amount);
        }
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
```
4. 避免暴露敏感信息：

错误信息会被记录在区块链上，应避免暴露敏感数据。

```sol
contract SecureErrors {
    mapping(address => bytes32) private passwordHashes;
    mapping(address => uint256) private balances;
    
    // ❌ 危险：暴露了密码哈希
    error InvalidPassword(bytes32 providedHash, bytes32 expectedHash);
    
    // ✅ 安全：只说明密码错误，不暴露哈希值
    error InvalidPassword();
    
    // ❌ 危险：暴露了内部状态
    error InternalStateError(uint256 secretValue, address adminAddress);
    
    // ✅ 安全：只说明发生了内部错误
    error InternalStateError();
    
    function verifyPassword(bytes32 providedHash) public view returns (bool) {
        if (providedHash != passwordHashes[msg.sender]) {
            revert InvalidPassword();  // 不暴露期望的哈希值
        }
        return true;
    }
}
```
5. 文档化错误：
为错误添加NatSpec注释，说明错误的含义和触发条件。

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DocumentedErrors {
    /**
     * @notice 当账户余额不足时抛出
     * @param account 余额不足的账户地址
     * @param available 账户当前可用余额
     * @param required 操作所需的最小余额
     */
    error InsufficientBalance(
        address account,
        uint256 available,
        uint256 required
    );
    
    /**
     * @notice 当调用者没有执行操作的权限时抛出
     * @param caller 尝试执行操作的地址
     * @param requiredRole 执行操作所需的角色标识
     */
    error Unauthorized(address caller, bytes32 requiredRole);
    
    /**
     * @notice 当转账被暂停时抛出
     * @dev 可以通过unpause()函数恢复转账功能
     */
    error TransferPaused();
    
    /**
     * @notice 当操作在时间锁定期内执行时抛出
     * @param currentTime 当前区块时间戳
     * @param unlockTime 解锁时间戳
     */
    error TimeLocked(uint256 currentTime, uint256 unlockTime);
    
    mapping(address => uint256) public balances;
    
    function transfer(address to, uint256 amount) public {
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(msg.sender, balances[msg.sender], amount);
        }
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
```

## 3.4 自定义错误的完整示例
以下是一个完整的代币合约示例，展示了自定义错误的综合应用：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title TokenWithCustomErrors
 * @notice 使用自定义错误的ERC20代币合约示例
 */
contract TokenWithCustomErrors {
    // ============ 自定义错误定义 ============
    
    /// @notice 余额不足
    error InsufficientBalance(address account, uint256 available, uint256 required);
    
    /// @notice 授权额度不足
    error InsufficientAllowance(address owner, address spender, uint256 available, uint256 required);
    
    /// @notice 无效的接收地址
    error InvalidRecipient(address recipient);
    
    /// @notice 无效的金额
    error InvalidAmount(uint256 amount);
    
    /// @notice 未授权的操作
    error Unauthorized(address caller);
    
    /// @notice 转账功能已暂停
    error TransferPaused();
    
    /// @notice 超过最大供应量
    error ExceedsMaxSupply(uint256 requested, uint256 maxSupply);
    
    /// @notice 数组长度不匹配
    error ArrayLengthMismatch(uint256 length1, uint256 length2);
    
    // ============ 状态变量 ============
    
    string public name = "CustomError Token";
    string public symbol = "CET";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 1000000 * 10**18;
    
    address public owner;
    bool public paused;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    // ============ 事件 ============
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    
    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        _mint(msg.sender, _initialSupply);
    }
    
    // ============ 公共函数 ============
    
    /**
     * @notice 转账代币
     * @param to 接收地址
     * @param amount 转账金额
     */
    function transfer(address to, uint256 amount) 
        public 
        whenNotPaused 
        returns (bool) 
    {
        if (to == address(0)) revert InvalidRecipient(to);
        if (amount == 0) revert InvalidAmount(amount);
        if (balanceOf[msg.sender] < amount) {
            revert InsufficientBalance(msg.sender, balanceOf[msg.sender], amount);
        }
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    /**
     * @notice 授权第三方使用代币
     * @param spender 被授权地址
     * @param amount 授权金额
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        if (spender == address(0)) revert InvalidRecipient(spender);
        
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    /**
     * @notice 从授权额度中转账
     * @param from 发送方地址
     * @param to 接收方地址
     * @param amount 转账金额
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public whenNotPaused returns (bool) {
        if (to == address(0)) revert InvalidRecipient(to);
        if (amount == 0) revert InvalidAmount(amount);
        
        if (balanceOf[from] < amount) {
            revert InsufficientBalance(from, balanceOf[from], amount);
        }
        
        if (allowance[from][msg.sender] < amount) {
            revert InsufficientAllowance(
                from,
                msg.sender,
                allowance[from][msg.sender],
                amount
            );
        }
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
    
    /**
     * @notice 批量转账
     * @param recipients 接收地址数组
     * @param amounts 转账金额数组
     */
    function batchTransfer(
        address[] memory recipients,
        uint256[] memory amounts
    ) public whenNotPaused returns (bool) {
        if (recipients.length != amounts.length) {
            revert ArrayLengthMismatch(recipients.length, amounts.length);
        }
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        
        if (balanceOf[msg.sender] < totalAmount) {
            revert InsufficientBalance(msg.sender, balanceOf[msg.sender], totalAmount);
        }
        
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == address(0)) {
                revert InvalidRecipient(recipients[i]);
            }
            
            balanceOf[msg.sender] -= amounts[i];
            balanceOf[recipients[i]] += amounts[i];
            emit Transfer(msg.sender, recipients[i], amounts[i]);
        }
        
        return true;
    }
    
    /**
     * @notice 铸造新代币（仅所有者）
     * @param to 接收地址
     * @param amount 铸造金额
     */
    function mint(address to, uint256 amount) public onlyOwner {
        if (to == address(0)) revert InvalidRecipient(to);
        if (totalSupply + amount > MAX_SUPPLY) {
            revert ExceedsMaxSupply(totalSupply + amount, MAX_SUPPLY);
        }
        
        _mint(to, amount);
    }
    
    /**
     * @notice 销毁代币
     * @param amount 销毁金额
     */
    function burn(uint256 amount) public {
        if (balanceOf[msg.sender] < amount) {
            revert InsufficientBalance(msg.sender, balanceOf[msg.sender], amount);
        }
        
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        
        emit Transfer(msg.sender, address(0), amount);
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
    
    // ============ 内部函数 ============
    
    function _mint(address to, uint256 amount) private {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}
```





































































