# 5. 错误处理
## 5.1 require - 输入验证
require是最常用的错误处理机制，用于验证外部输入和前置条件。

语法：
```sol
require(条件, "错误消息");
```
**条件为false时：**

* 交易立即回滚
* 显示错误消息
* 返还剩余Gas
* 所有状态改变撤销

```sol
contract RequireExample {
    mapping(address => uint) public balances;
    
    function transfer(address to, uint amount) public {
        // 检查1：地址有效性
        require(to != address(0), "Cannot transfer to zero address");
        
        // 检查2：金额有效性
        require(amount > 0, "Amount must be positive");
        
        // 检查3：余额充足
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // 所有检查通过，执行转账
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
// 典型使用场景：
contract RequireUseCases {
    address public owner;
    bool public paused;
    
    constructor() {
        owner = msg.sender;
    }
    
    // 场景1：权限检查
    function ownerOnly() public view {
        require(msg.sender == owner, "Not the owner");
        // 操作...
    }
    
    // 场景2：状态检查
    function whenNotPaused() public view {
        require(!paused, "Contract is paused");
        // 操作...
    }
    
    // 场景3：参数验证
    function setAge(uint age) public pure {
        require(age > 0 && age < 150, "Invalid age");
        // 设置年龄...
    }
    
    // 场景4：余额检查
    function withdraw(uint amount) public view {
        require(address(this).balance >= amount, "Insufficient contract balance");
        // 提款...
    }
    
    // 场景5：时间条件
    function afterDeadline(uint deadline) public view {
        require(block.timestamp >= deadline, "Too early");
        // 操作...
    }
}
```

## 5.2 assert - 内部检查
assert用于检查不应该失败的条件，主要用于检测代码bug和不变量。
```sol
assert(条件);
```
**条件为false时：**

* 交易回滚
* 表示代码有bug
* 返还剩余Gas（Solidity 0.8.0+）
* 不支持错误消息
```sol
contract AssertExample {
    mapping(address => uint) public balances;
    uint public totalSupply;
    
    function transfer(address to, uint amount) public {
        // require：验证外部输入
        require(to != address(0), "Invalid address");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // 记录转账前，两个账户的余额总和
        uint balanceSumBefore = balances[msg.sender] + balances[to];
        
        // 执行转账
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        // assert：检查不变量
        // 逻辑上：转账后，两个账户的余额总和必须与转账前完全一致
        assert(balances[msg.sender] + balances[to] == balanceSumBefore);
        // 如果这个检查失败，说明余额计算逻辑出现了极其严重的 Bug（如溢出或赋值错误）
    }
    
    function mint(address to, uint amount) public {
        require(to != address(0), "Invalid address");
        
        uint supplyBefore = totalSupply;
        
        balances[to] += amount;
        totalSupply += amount;
        
        // 检查不变量：新的总供应 = 旧的 + 增发的
        assert(totalSupply == supplyBefore + amount);
    }
}
```
**require vs assert对比：**
|特性|require|assert|
|:--:|:--:|:--:|
|用途|外部验证|内部检查|
|失败原因|用户错误/外部条件|代码bug|
|错误消息|支持|不支持|
|Gas返还|是|是（0.8.0+）|
|使用频率|非常高（90%）|很低（10%）|

**使用原则：**

* require：验证用户输入、检查外部条件
* assert：检查代码逻辑、验证不变量

大多数情况下使用require，只在需要检查不变量时使用assert。

## 5.3 revert - 灵活的错误处理
revert提供了更灵活的错误处理方式。
```sol
contract RevertExample {
    mapping(address => uint) public balances;
    function complexCheck(address to, uint amount) public {
        // 方式1：带字符串消息
        if (to == address(0)) {
            revert("Invalid address");
        }
        if (amount == 0) {
            revert("Amount cannot be zero");
        }
        
        if (balances[msg.sender] < amount) {
            revert("Insufficient balance");
        }
        
        // 执行转账
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
```
**自定义错误（Solidity 0.8.4+）：**
```sol
contract CustomErrors {
    // 定义自定义错误
    error InsufficientBalance(uint requested, uint available);
    error InvalidAddress(address addr);
    error AmountTooLow(uint amount, uint minimum);
    error Unauthorized(address caller);
    
    mapping(address => uint) public balances;
    address public owner;
    uint public constant MIN_AMOUNT = 100;
    
    constructor() {
        owner = msg.sender;
    }
    
    function transfer(address to, uint amount) public {
        // 使用自定义错误
        if (to == address(0)) {
            revert InvalidAddress(to);
        }
        
        if (amount < MIN_AMOUNT) {
            revert AmountTooLow(amount, MIN_AMOUNT);
        }
        
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance({
                requested: amount,
                available: balances[msg.sender]
            });
        }
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    
    function adminFunction() public {
        if (msg.sender != owner) {
            revert Unauthorized(msg.sender);
        }
        // 管理员操作
    }
}
```
**自定义错误的优势：**
|特性|字符串错误|自定义错误|
|:--:|:--:|:--:|
|Gas成本|高|低（节省约50%）|
|可带参数|否|是|
|类型安全|否|是|
|易于解析|难|易|
|前端集成|复杂|简单|

**Gas成本对比：**
```sol
contract GasComparison {
    // 字符串错误：~24,000 gas
    function stringError() public pure {
        require(false, "This is an error message");
    }
    
    error CustomError();
    
    // 自定义错误：~12,000 gas
    function customError() public pure {
        revert CustomError();
    }
    // 节省：约50%
}
```
## 5.4 错误处理对比
|特性|require|assert|revert|
|:--:|:--:|:--:|:--:|
|用途|输入验证|内部检查|灵活控制|
|条件判断|需要|需要|不需要|
|错误消息|支持|不支持|支持|
|自定义错误|支持|不支持|支持|
|Gas返还|是|是|是|
|使用频率|很高|低|中等|

**选择指南：**
```sol
需要错误处理？
    ↓
简单条件判断？
    ├─ 是 → require
    └─ 否 → 复杂逻辑？
            ├─ 是 → revert
            └─ 否 → 检查不变量？
                    └─ 是 → assert
```

# 6. 状态机模式
## 6.1 什么是状态机
状态机（State Machine）是一种管理复杂状态转换的设计模式。

概念：

* 合约在任何时刻都处于某个特定状态
* 只能从当前状态转换到特定的下一个状态
* 某些操作只能在特定状态下执行

## 6.2 状态机实现
```sol
contract StateMachine {
    // 定义状态
    enum State {
        Preparing,   // 准备中
        Active,      // 进行中
        Checking,    // 检查中
        Success,     // 成功
        Failed,      // 失败
        Cancelled    // 已取消
    }
    
    State public currentState;
    
    // 状态检查modifier
    modifier inState(State expected) {
        require(currentState == expected, "Invalid state for this operation");
        _;
    }
    
    constructor() {
        currentState = State.Preparing;
    }
    
    // 只能在Preparing状态执行
    function start() public inState(State.Preparing) {
        currentState = State.Active;
    }
    
    // 只能在Active状态执行
    function contribute() public payable inState(State.Active) {
        // 贡献资金
    }
    
    // 只能在Active状态执行
    function check() public inState(State.Active) {
        currentState = State.Checking;
    }
    
    // 状态转换
    function finalize() public inState(State.Checking) {
        if (address(this).balance >= 100 ether) {
            currentState = State.Success;
        } else {
            currentState = State.Failed;
        }
    }
    
    // 紧急取消
    function cancel() public {
        require(
            currentState == State.Preparing || currentState == State.Active,
            "Cannot cancel at this stage"
        );
        currentState = State.Cancelled;
    }
}
```
**状态转换图：**
```sol
[Preparing]
    │
    │ start()
    ↓
[Active] ────────┐
    │            │
    │ check()    │ contribute()
    ↓            │
[Checking] ──────┘
    │
    │ finalize()
    ├──────────┬──────────┐
    ↓          ↓          ↓
[Success] [Failed] [Cancelled]
```

## 6.3 众筹合约示例
```sol
contract Crowdfunding {
    enum State { Fundraising, Success, Failed, PaidOut }
    
    State public currentState = State.Fundraising;
    
    address public creator;
    uint public goal;
    uint public deadline;
    uint public totalFunded;
    
    mapping(address => uint) public contributions;
    
    constructor(uint _goal, uint _duration) {
        creator = msg.sender;
        goal = _goal;
        deadline = block.timestamp + _duration;
    }
    
    modifier inState(State expected) {
        require(currentState == expected, "Invalid state");
        _;
    }
    
    // 贡献资金（只在Fundraising状态）
    function contribute() 
        public payable inState(State.Fundraising) 
    {
        require(block.timestamp < deadline, "Campaign ended");
        require(msg.value > 0, "Must send ETH");
        
        contributions[msg.sender] += msg.value;
        totalFunded += msg.value;
    }
    
    // 检查目标（deadline后调用）
    function checkGoalReached() public inState(State.Fundraising) {
        require(block.timestamp >= deadline, "Campaign not ended yet");
        
        if (totalFunded >= goal) {
            currentState = State.Success;
        } else {
            currentState = State.Failed;
        }
    }
    
    // 创建者提取资金（成功后）
    function payout() public inState(State.Success) {
        require(msg.sender == creator, "Only creator can payout");
        
        currentState = State.PaidOut;
        payable(creator).transfer(address(this).balance);
    }
    
    // 退款（失败后）
    function refund() public inState(State.Failed) {
        uint amount = contributions[msg.sender];
        require(amount > 0, "No contribution to refund");
        
        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
```
**状态机的优势：**
1. 状态转换清晰：明确哪些操作在哪些状态下可以执行
2. 减少if-else嵌套：用状态替代复杂的条件判断
3. 易于维护：添加新状态和转换很容易
4. 防止无效操作：在错误状态下的操作会被拒绝
5. 代码可读性高：状态名称清楚表达合约状态

# 7. 最佳实践
## 7.1 错误处理最佳实践

**原则1：尽早检查，尽早失败**
```sol
contract EarlyCheck {
    mapping(address => uint) public balances;
    // 好的做法：所有检查放在开头
    function goodExample(address to, uint amount) public {
        // 所有验证在前面
        require(to != address(0), "Invalid address");
        require(amount > 0, "Invalid amount");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // 执行业务逻辑
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    
    // 不好的做法：检查和业务逻辑混在一起
    function badExample(address to, uint amount) public {
        balances[msg.sender] -= amount;  // 还没检查就修改状态
        require(to != address(0), "Invalid address");  // 检查太晚
        balances[to] += amount;
    }
}
```
**原则2：清晰的错误消息**
```sol
contract ClearErrorMessages {
    // 不好：模糊的错误消息
    function badError(uint x) public pure {
        require(x > 0, "Error");  // 什么错误？
        require(x < 100, "Bad");  // 为什么bad？
    }
    
    // 好：清晰的错误消息
    function goodError(uint x) public pure {
        require(x > 0, "Value must be positive");
        require(x < 100, "Value exceeds maximum limit of 100");
    }
}
```
**原则3：检查顺序优化**
便宜的检查放前面，可以节省Gas。
```sol
contract CheckOrder {
    mapping(address => uint) public balances;
    mapping(address => bool) public whitelist;
    // 优化：便宜的检查在前
    function optimizedOrder(address to, uint amount) public view {
        require(amount > 0, "Invalid amount");              // 最便宜
        require(to != address(0), "Invalid address");       // 便宜
        require(balances[msg.sender] >= amount, "Low balance");  // 中等
        require(whitelist[to], "Not whitelisted");          // 稍贵
        // 如果前面的检查失败，后面的检查就不需要执行了
    }
}
```
**原则4：使用自定义错误**
```sol
contract CustomErrorPractice {
    error InsufficientBalance(uint requested, uint available);
    error InvalidRecipient(address recipient);
    error AmountBelowMinimum(uint amount, uint minimum);
    
    mapping(address => uint) public balances;
    uint public constant MIN_AMOUNT = 100;
    
    function transfer(address to, uint amount) public {
        if (to == address(0)) {
            revert InvalidRecipient(to);
        }
        
        if (amount < MIN_AMOUNT) {
            revert AmountBelowMinimum(amount, MIN_AMOUNT);
        }
        
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance({
                requested: amount,
                available: balances[msg.sender]
            });
        }
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
```
**原则5：不要忽略返回值**
```sol
contract CheckReturnValues {
    // 危险：忽略返回值
    function dangerousCall(address token, address to, uint amount) public {
        // 如果transfer失败，这里不会知道
        // token.transfer(to, amount);  // 危险！
    }
    // 安全：检查返回值
    function safeCall(address token, address to, uint amount) public {
        (bool success, ) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(success, "Transfer failed");
    }
}
```
**原则6：合理使用modifier**
```sol
contract ModifierForChecks {
    address public owner;
    bool public paused;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }
    // 使用modifier简化代码
    function adminFunction() public onlyOwner whenNotPaused {
        // 不需要在函数内重复写require
        // 代码更清晰
    }
}
```

## 7.2 循环使用最佳实践
**实践1：优先考虑mapping**
```sol
contract PreferMapping {
    // 不好：使用数组需要循环
    address[] public users;
    
    function findUser(address user) public view returns (bool) {
        for (uint i = 0; i < users.length; i++) {
            if (users[i] == user) {
                return true;
            }
        }
        return false;
    }
    // Gas: O(n)，随数组增长
    // 好：使用mapping，O(1)查询
    mapping(address => bool) public isUser;
    
    function checkUser(address user) public view returns (bool) {
        return isUser[user];
    }
    // Gas: O(1)，恒定成本
}
```
**实践2：必须循环时严格限制**
```sol
contract LimitLoops {
    uint[] public data;
    uint public constant MAX_ARRAY_SIZE = 100;
    function safePush(uint value) public {
        require(data.length < MAX_ARRAY_SIZE, "Array is full");
        data.push(value);
    }
    
    function safeProcess() public view returns (uint) {
        uint total = 0;
        uint len = data.length;  // 缓存length
        
        for (uint i = 0; i < len; i++) {
            total += data[i];
        }
        return total;
    }
}
```
**实践3：避免嵌套循环**
```sol
contract AvoidNesting {
    // 不好：嵌套循环
    function badPattern(uint[][] memory matrix) 
        public pure returns (uint) 
    {
        uint total = 0;
        for (uint i = 0; i < matrix.length; i++) {
            for (uint j = 0; j < matrix[i].length; j++) {
                total += matrix[i][j];  // O(n²)
            }
        }
        return total;
    }
    
    // 好：使用mapping或其他数据结构避免嵌套
    mapping(bytes32 => uint) public values;
    
    function goodPattern(uint x, uint y) public view returns (uint) {
        bytes32 key = keccak256(abi.encode(x, y));
        return values[key];  // O(1)
    }
}
```
**实践4：分批处理**
```sol
contract BatchProcessing {
    uint[] public data;
    uint public constant BATCH_SIZE = 50;
    
    function processBatch(uint startIndex) public {
        uint endIndex = startIndex + BATCH_SIZE;
        if (endIndex > data.length) {
            endIndex = data.length;
        }
        
        for (uint i = startIndex; i < endIndex; i++) {
            data[i] = data[i] * 2;
        }
    }
    function getTotalBatches() public view returns (uint) {
        return (data.length + BATCH_SIZE - 1) / BATCH_SIZE;
    }
}
```

## 7.3 安全编程原则
**Checks-Effects-Interactions模式**

这是智能合约开发中最重要的安全模式。
```sol
contract CEIPattern {
    mapping(address => uint) public balances;
    
    // 正确：遵循CEI模式
    function withdraw(uint amount) public {
        // 1. Checks - 检查
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // 2. Effects - 更新状态
        balances[msg.sender] -= amount;
        
        // 3. Interactions - 外部调用
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    // 错误：先外部调用，后更新状态（重入攻击风险）
    function dangerousWithdraw(uint amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // 危险：先外部调用
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        // 后更新状态（可能被重入攻击）
        balances[msg.sender] -= amount;
    }
}
```
**为什么CEI模式重要？**
重入攻击示例：
```sol
// 受害合约（有漏洞）
contract Vulnerable {
    mapping(address => uint) public balances;
    
    function withdraw() public {
        uint amount = balances[msg.sender];
        
        // 危险：先转账
        msg.sender.call{value: amount}("");
        
        // 后更新余额
        balances[msg.sender] = 0;
    }
}

// 攻击合约
contract Attacker {
    Vulnerable public victim;
    
    fallback() external payable {
        // 在收到钱后，再次调用withdraw
        // 因为余额还没更新，可以重复提取
        if (address(victim).balance > 0) {
            victim.withdraw();  // 重入攻击！
        }
    }
}
```
**正确做法：**
```sol
contract SafeContract {
    mapping(address => uint) public balances;
    
    function withdraw() public {
        uint amount = balances[msg.sender];
        require(amount > 0, "No balance");
        
        // 先更新状态
        balances[msg.sender] = 0;
        
        // 再转账
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

# 8. 实战练习

## 练习1：投票系统
需求：

创建一个完整的投票系统：

* 支持创建多个提案
* 每个提案有截止时间
* 只有owner可以创建提案
* 每个地址只能投一次票
* 可以查询投票结果
* 可以获取获胜提案
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    struct Proposal {
        string description;
        uint voteCount;
        uint deadline;
        bool exists;
    }
    
    address public owner;
    uint public proposalCount;
    
    mapping(uint => Proposal) public proposals;
    mapping(uint => mapping(address => bool)) public hasVoted;
    
    event ProposalCreated(uint indexed proposalId, string description, uint deadline);
    event Voted(uint indexed proposalId, address indexed voter);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }
    
    function createProposal(string memory description, uint durationDays) 
        public onlyOwner 
    {
        require(bytes(description).length > 0, "Empty description");
        require(durationDays >= 1 && durationDays <= 30, "Invalid duration");
        
        uint proposalId = proposalCount++;
        uint deadline = block.timestamp + (durationDays * 1 days);
        
        proposals[proposalId] = Proposal({
            description: description,
            voteCount: 0,
            deadline: deadline,
            exists: true
        });
        
        emit ProposalCreated(proposalId, description, deadline);
    }
    
    function vote(uint proposalId) public {
        require(proposals[proposalId].exists, "Proposal does not exist");
        require(block.timestamp <= proposals[proposalId].deadline, "Voting ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        
        hasVoted[proposalId][msg.sender] = true;
        proposals[proposalId].voteCount++;
        
        emit Voted(proposalId, msg.sender);
    }
    
    function getWinner() public view returns (uint winningProposalId) {
        uint maxVotes = 0;
        
        for (uint i = 0; i < proposalCount; i++) {
            if (proposals[i].voteCount > maxVotes) {
                maxVotes = proposals[i].voteCount;
                winningProposalId = i;
            }
        }
        
        return winningProposalId;
    }
    
    function getProposalInfo(uint proposalId) 
        public view 
        returns (
            string memory description,
            uint voteCount,
            uint deadline,
            bool hasEnded
        ) 
    {
        require(proposals[proposalId].exists, "Proposal does not exist");
        
        Proposal memory p = proposals[proposalId];
        return (
            p.description,
            p.voteCount,
            p.deadline,
            block.timestamp > p.deadline
        );
    }
}
```

## 练习2：安全批量转账
需求：

实现一个安全的批量转账功能：

* 验证数组长度一致
* 限制批量大小
* 预先检查总金额
* 验证所有地址
* 保证原子性

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SafeBatchTransfer {
    mapping(address => uint) public balances;
    uint public constant MAX_BATCH_SIZE = 50;
    
    event Transfer(address indexed from, address indexed to, uint amount);
    event BatchTransfer(address indexed from, uint count, uint totalAmount);
    
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    
    function batchTransfer(
        address[] memory recipients,
        uint[] memory amounts
    ) public {
        // 1. 检查数组长度相等
        require(
            recipients.length == amounts.length, 
            "Length mismatch"
        );
        
        // 2. 限制批量大小
        require(
            recipients.length <= MAX_BATCH_SIZE, 
            "Batch too large"
        );
        
        // 3. 预先计算总金额
        uint totalAmount = 0;
        for (uint i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        
        // 4. 检查余额充足
        require(
            balances[msg.sender] >= totalAmount, 
            "Insufficient balance"
        );
        
        // 5. 验证所有地址和金额
        for (uint i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid address");
            require(amounts[i] > 0, "Invalid amount");
        }
        
        // 6. 执行转账（所有检查都通过后）
        for (uint i = 0; i < recipients.length; i++) {
            balances[msg.sender] -= amounts[i];
            balances[recipients[i]] += amounts[i];
            
            emit Transfer(msg.sender, recipients[i], amounts[i]);
        }
        
        emit BatchTransfer(msg.sender, recipients.length, totalAmount);
    }
    
    function getBalance(address user) public view returns (uint) {
        return balances[user];
    }
}
```

# 9. 常见陷阱

**陷阱1：无限循环**
```sol
contract InfiniteLoopTrap {
    // 危险：忘记更新循环变量
    function badLoop() public pure {
        uint i = 0;
        while (i < 10) {
            // 忘记 i++
            // 无限循环！永远无法完成
        }
    }
    
    // 正确：记得更新
    function goodLoop() public pure {
        uint i = 0;
        while (i < 10) {
            // 处理逻辑
            i++;  // 不要忘记
        }
    }
}
```
**陷阱2：循环中修改数组**
```sol
contract ArrayModificationTrap {
    uint[] public array;
    
    // 危险：边遍历边修改长度
    function dangerousDelete() public {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == 0) {
                // 删除元素会改变长度
                delete array[i];  // 只是设为0，不改变length
            }
        }
    }
    
    // 危险：边遍历边pop
    function veryDangerous() public {
        for (uint i = 0; i < array.length; i++) {
            array.pop();  // 改变length，可能跳过元素
        }
    }
    
    // 正确：从后向前删除
    function safeDelete() public {
        for (uint i = array.length; i > 0; i--) {
            if (array[i - 1] == 0) {
                // 从后向前删除安全
                array.pop();
            }
        }
    }
}
```
**陷阱3：整数溢出**
```sol
contract OverflowTrap {
    // Solidity 0.8.0之前：危险
    function oldVersion() public pure returns (uint8) {
        uint8 x = 255;
        // x++;  // 溢出变成0（0.8.0之前）
        return x;
    }
    
    // Solidity 0.8.0+：自动检查
    function newVersion() public pure returns (uint8) {
        uint8 x = 255;
        // x++;  // 交易回滚
        return x;
    }
    
    // 使用unchecked需谨慎
    function withUnchecked() public pure returns (uint) {
        uint x = 0;
        unchecked {
            x--;  // 不会回滚，变成最大值
        }
        return x;
    }
}
```
**陷阱4：block.timestamp操纵**
```sol
contract TimestampTrap {
    // 不好：用于关键随机性
    function badRandom() public view returns (uint) {
        // 矿工可以在一定范围内操纵timestamp
        return block.timestamp % 100;
    }
    
    // 可以：用于时间检查
    function goodTimeCheck(uint deadline) public view returns (bool) {
        return block.timestamp >= deadline;
    }
}
```

**陷阱5：深层嵌套**
```sol
contract NestingTrap {
    // 不好：深层嵌套，难以理解
    function badNesting(uint a, uint b, uint c) 
        public pure returns (string memory) 
    {
        if (a > 0) {
            if (b > 0) {
                if (c > 0) {
                    if (a > b) {
                        if (b > c) {
                            return "Complex result";
                        }
                    }
                }
            }
        }
        return "Default";
    }
    
    // 好：使用early return
    function goodPattern(uint a, uint b, uint c) 
        public pure returns (string memory) 
    {
        if (a == 0) return "a is zero";
        if (b == 0) return "b is zero";
        if (c == 0) return "c is zero";
        if (a <= b) return "a not greater than b";
        if (b <= c) return "b not greater than c";
        
        return "Complex result";
    }
}
```

# 10. Gas优化技巧

**技巧1：短路求值**
逻辑运算符支持短路求值，可以节省Gas。
```sol
contract ShortCircuit {
    mapping(address => uint) public balances;
    
    // 利用短路求值优化
    function optimizedCheck(uint amount) public view returns (bool) {
        // 便宜的检查在前，如果失败就不执行后面的
        if (amount > 0 && balances[msg.sender] >= amount) {
            return true;
        }
        return false;
    }
    
    // 顺序很重要
    function checkOrder(address user, uint amount) 
        public view returns (bool) 
    {
        // 好：便宜的检查在前
        return amount > 0 && user != address(0) && balances[user] >= amount;
        
        // 不好：昂贵的检查在前
        // return balances[user] >= amount && amount > 0 && user != address(0);
    }
}
```
**技巧2：缓存storage变量**
```sol
contract CacheStorage {
    uint[] public data;
    
    // 未优化：重复读取storage
    function unoptimized() public view returns (uint) {
        uint total = 0;
        for (uint i = 0; i < data.length; i++) {  // 每次读取length
            total += data[i];
        }
        return total;
    }
    // Gas: ~25,000（100个元素）
    
    // 优化：缓存length
    function optimized() public view returns (uint) {
        uint total = 0;
        uint len = data.length;  // 只读一次
        for (uint i = 0; i < len; i++) {
            total += data[i];
        }
        return total;
    }
    // Gas: ~23,000（100个元素）
    // 节省：~8%
}
```
**技巧3：使用unchecked（谨慎）**
```sol
contract UncheckedOptimization {
    uint[] public data;
    
    // 未优化：检查溢出
    function normalLoop() public view returns (uint) {
        uint total = 0;
        for (uint i = 0; i < data.length; i++) {
            total += data[i];
        }
        return total;
    }
    
    // 优化：确定不溢出时使用unchecked
    function optimizedLoop() public view returns (uint) {
        uint total = 0;
        uint len = data.length;
        
        for (uint i = 0; i < len; ) {
            total += data[i];
            unchecked { 
                i++;  // i不可能溢出
            }
        }
        return total;
    }
    // 进一步节省gas
}
```
**警告：只在确定不会溢出时使用unchecked！**


**技巧4：优化循环变量类型**
```sol
contract LoopVariableType {
    // 不推荐：uint8需要额外转换
    function withUint8() public pure {
        for (uint8 i = 0; i < 10; i++) {
            // uint8需要额外的类型转换操作
        }
    }
    
    // 推荐：uint256是EVM原生类型
    function withUint256() public pure {
        for (uint256 i = 0; i < 10; i++) {
            // 直接使用，无额外成本
        }
    }
}
```

**技巧5：批量操作合并**
```sol
contract BatchOperations {
    mapping(address => uint) public scores;
    
    // 不好：多次交易
    function updateOne(address user, uint score) public {
        scores[user] = score;
    }
    // 需要调用n次，n笔交易费用
    
    // 好：一次交易完成
    function updateBatch(
        address[] calldata users,
        uint[] calldata scoreList
    ) external {
        require(users.length == scoreList.length, "Length mismatch");
        require(users.length <= 50, "Batch too large");
        
        for (uint i = 0; i < users.length; i++) {
            scores[users[i]] = scoreList[i];
        }
    }
    // 只需1笔交易费用
}
```

# 11. 常见问题解答

## 为什么要避免循环？
答：循环在智能合约中有三大问题。

* Gas成本高：每次循环都消耗Gas
* 可能失败：大循环可能超过Gas限制
* 安全风险：可能被恶意利用（DoS攻击）

解决方案：

* 优先使用mapping（O(1)查询）
* 必须循环时严格限制次数
* 考虑分批处理
* 链下计算，链上存储

## require、assert、revert的区别？
答：三者用途不同。

require（最常用）：

* 验证用户输入
* 检查外部条件
* 支持错误消息

assert（很少用）：

* 检查代码逻辑
* 验证不变量
* 不支持错误消息

revert（中等使用）：

* 复杂条件判断
* 支持自定义错误
* 更灵活

## 如何防止重入攻击？
答：遵循CEI模式和使用ReentrancyGuard。

CEI模式（推荐）：
```sol
function withdraw(uint amount) public {
    // 1. Checks
    require(balances[msg.sender] >= amount);
    
    // 2. Effects（先更新状态）
    balances[msg.sender] -= amount;
    
    // 3. Interactions（后外部调用）
    payable(msg.sender).transfer(amount);
}
```
ReentrancyGuard：（重入防护）
```sol
bool private locked;

modifier noReentrant() {
    require(!locked, "Reentrant call");
    locked = true;
    _;
    locked = false;
}

function withdraw(uint amount) public noReentrant {
    // 函数逻辑
}
```

## 状态机模式的优势是什么？
答：状态机让复杂的状态管理变得简单。

优势：

* 状态转换清晰明确
* 减少if-else嵌套
* 防止无效操作
* 易于理解和维护
* 安全性更高

应用场景：

* 众筹合约（筹款中→成功/失败）
* 拍卖合约（进行中→结束→已支付）
* 游戏合约（准备→进行→结束）
* 订单系统（创建→支付→发货→完成）


# 12. 知识点总结

1. 条件语句
if、else、if-else、else-if、三元运算符

2. 循环语句
for、while、do-while、break/continue

3. Gas成本控制
关键原则：

* 能不循环就不循环
* 必须循环就限制次数
* 链下计算，链上存储
* 使用mapping代替数组遍历

优化技巧：

* 限制数组大小
* 缓存storage变量
* 分批处理
* 短路求值
* 使用unchecked（谨慎）

4. 错误处理
三种方式：

* require：输入验证（最常用）
* assert：内部检查（少用）
* revert：灵活控制（中等）

最佳实践：

* 尽早检查，尽早失败
* 清晰的错误消息
* 使用自定义错误节省Gas
* 检查顺序影响成本

5. 安全原则
CEI模式：

1. Checks - 检查条件
2. Effects - 更新状态
3. Interactions - 外部调用

其他原则：

* 防御性编程
* 避免重入攻击
* 状态机模式
* 原子性保证







