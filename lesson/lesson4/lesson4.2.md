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















































