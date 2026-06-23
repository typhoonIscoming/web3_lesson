
# 4. 枚举类型

## 4.1 枚举基础
枚举（enum）是用户定义的类型，用于表示一组有限的选项或状态。

**定义语法：**
```sol
contract EnumBasics {
    // 定义订单状态枚举
    enum OrderStatus {
        Pending,      // 0
        Paid,         // 1
        Shipped,      // 2
        Delivered,    // 3
        Cancelled     // 4
    }
    
    // 声明枚举变量
    OrderStatus public status;  // 默认值：Pending (0)
    
    // 设置枚举值
    function createOrder() public {
        status = OrderStatus.Pending;
    }
    
    function payOrder() public {
        require(status == OrderStatus.Pending, "Not pending");
        status = OrderStatus.Paid;
    }
    
    function shipOrder() public {
        require(status == OrderStatus.Paid, "Not paid");
        status = OrderStatus.Shipped;
    }
    
    // 检查枚举值
    function isPaid() public view returns (bool) {
        return status == OrderStatus.Paid;
    }
}
```
## 4.2 枚举的优势
**优势1：代码可读性**
```sol
// 不使用枚举（难理解）
uint public status = 2;

if (status == 2) {
    // 2代表什么？需要查文档
}

// 使用枚举（一目了然）
OrderStatus public status = OrderStatus.Shipped;

if (status == OrderStatus.Shipped) {
    // 清晰明了，状态是"已发货"
}
```
**优势2：类型安全**
```sol
contract TypeSafety {
    enum Status { Pending, Active, Completed }
    Status public status;
    
    function setStatus() public {
        status = Status.Active;      // 正确
        // status = Status.Invalid;  // 编译错误（不存在的值）
        // status = 10;              // 编译错误（类型不匹配）
    }
}
```
**优势3：节省Gas**
```sol
contract GasSaving {
    // 使用string：昂贵
    string public statusStr = "Active";  // 存储字符串消耗大量gas
    
    enum Status { Pending, Active, Completed }
    // 使用enum：便宜
    Status public statusEnum = Status.Active;  // 只存储uint8，非常便宜
}
```
## 4.3 枚举操作
**类型转换：**
```sol
contract EnumConversion {
    enum Status { Pending, Active, Completed }
    
    function conversions() public pure returns (uint, Status) {
        Status status = Status.Active;
        
        // 枚举 → 整数
        uint statusValue = uint(status);  // 1
        
        // 整数 → 枚举
        Status newStatus = Status(2);  // Completed
        
        return (statusValue, newStatus);
    }
    
    // 安全转换（检查范围）
    function safeConvert(uint value) public pure returns (Status) {
        require(value <= uint(type(Status).max), "Invalid status value");
        return Status(value);
    }
}
```
**获取枚举范围：**
```sol
contract EnumRange {
    enum Status { Pending, Active, Completed }
    
    function getRange() public pure returns (Status, Status) {
        Status minValue = type(Status).min;  // Pending (0)
        Status maxValue = type(Status).max;  // Completed (2)
        return (minValue, maxValue);
    }
}
```
**在映射中使用：**
```sol
contract EnumInMapping {
    enum Role { None, User, Admin, Owner }
    
    // 地址到角色的映射
    mapping(address => Role) public userRoles;
    
    // 角色统计
    mapping(Role => uint) public roleCount;
    
    function assignRole(address user, Role role) public {
        userRoles[user] = role;
        roleCount[role]++;
    }
    
    function hasRole(address user, Role role) public view returns (bool) {
        return userRoles[user] == role;
    }
}
```
## 4.4 状态机模式
状态机是枚举最经典的应用场景。

状态转换图：
```sol
[Fundraising] ─────┐
     │             │
     │ 达到目标     │ 超时未达标
     ↓             ↓
[Successful]    [Failed]
```
**完整实现：**
```sol
contract Crowdfunding {
    enum State { Fundraising, Successful, Failed }
    
    State public currentState = State.Fundraising;
    address public creator;
    uint public goal;
    uint public deadline;
    uint public totalFunded;
    mapping(address => uint) public contributions;
    
    event StateChanged(State newState);
    event Contribution(address indexed contributor, uint amount);
    
    modifier inState(State expectedState) {
        require(
            currentState == expectedState,
            "Invalid state for this operation"
        );
        _;
    }
    
    constructor(uint _goal, uint durationDays) {
        creator = msg.sender;
        goal = _goal;
        deadline = block.timestamp + (durationDays * 1 days);
    }
    
    // 贡献资金（仅在募资中）
    function contribute() 
        public 
        payable 
        inState(State.Fundraising) 
    {
        require(block.timestamp <= deadline, "Fundraising ended");
        require(msg.value > 0, "Must contribute");
        
        contributions[msg.sender] += msg.value;
        totalFunded += msg.value;
        
        emit Contribution(msg.sender, msg.value);
        
        // 自动检查是否达到目标
        if (totalFunded >= goal) {
            currentState = State.Successful;
            emit StateChanged(State.Successful);
        }
    }
    
    // 检查并更新状态
    function checkGoalReached() public inState(State.Fundraising) {
        require(block.timestamp > deadline, "Deadline not passed");
        
        if (totalFunded >= goal) {
            currentState = State.Successful;
        } else {
            currentState = State.Failed;
        }
        
        emit StateChanged(currentState);
    }
    
    // 创建者提取资金（仅成功时）
    function withdrawFunds() public inState(State.Successful) {
        require(msg.sender == creator, "Only creator can withdraw");
        
        uint amount = address(this).balance;
        (bool sent, ) = creator.call{value: amount}("");
        require(sent, "Transfer failed");
    }
    
    // 退款（仅失败时）
    function refund() public inState(State.Failed) {
        uint amount = contributions[msg.sender];
        require(amount > 0, "No contribution to refund");
        
        contributions[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Refund failed");
    }
}
```
**状态机优势：**

* 状态转换逻辑清晰：明确哪些操作在哪些状态下可执行
* 防止无效操作：错误状态下的操作会被拒绝
* 代码易于维护：添加新状态和转换很容易
* 减少if-else嵌套：用状态替代复杂的条件判断
* 增强安全性：状态检查保证逻辑正确


# 5. constant和immutable

## 5.1 为什么需要常量
**问题场景：**
```sol
contract NoConstant {
    uint public maxSupply = 1000000;  // 存储在storage
    
    function checkLimit(uint amount) public view returns (bool) {
        return amount <= maxSupply;  // 每次读取storage，消耗2100 gas
    }
}
```
每次访问storage都要消耗gas，但maxSupply永远不变，为什么不优化？

解决方案：使用constant或immutable

定义：

constant必须在声明时赋值，值在编译时确定，运行时不能改变。

```sol
// 语法
类型 public constant 变量名 = 值;
```
**示例**
```sol
contract ConstantExample {
    // 常量定义
    uint public constant MAX_SUPPLY = 1000000;
    uint public constant MIN_AMOUNT = 100;
    address public constant ZERO_ADDRESS = address(0);
    string public constant NAME = "My Token";
    
    // 计算型常量
    uint public constant DECIMALS = 18;
    uint public constant MAX_SUPPLY_WITH_DECIMALS = MAX_SUPPLY * 10**DECIMALS;
    
    // 使用常量
    function checkAmount(uint amount) public pure returns (bool) {
        return amount >= MIN_AMOUNT && amount <= MAX_SUPPLY;
        // 直接使用常量值，无需读取storage，gas = 0
    }
}
```
**constant的特点：**

1.  编译时确定：值必须是常量表达式
2. 内联替换：编译器将常量直接替换到代码中
3. 不占storage：不消耗storage槽位
4. 访问cost = 0：相当于直接使用数字
5. 不可修改：运行时绝对不能改变

**可以和不可以：**
```sol
contract ConstantRules {
    // 可以：字面值
    uint public constant NUMBER = 100;
    
    // 可以：计算表达式
    uint public constant RESULT = 50 * 2;
    
    // 可以：使用其他常量
    uint public constant BASE = 10;
    uint public constant DERIVED = BASE * 10;
    
    // 不可以：运行时值
    // uint public constant TIME = block.timestamp;  // 编译错误
    // uint public constant SENDER = uint160(msg.sender);  // 编译错误
    
    // 不可以：在构造函数中赋值
    // uint public constant VALUE;
    // constructor() {
    //     VALUE = 100;  // 编译错误
    // }
}
```

## 5.3 immutable - 部署时常量
**定义：**

immutable可以在构造函数中赋值，一旦部署后就不能改变。
```sol
类型 public immutable 变量名;

contract ImmutableExample {
    // immutable变量
    address public immutable OWNER;
    address public immutable FACTORY;
    uint public immutable DEPLOYED_AT;
    uint public immutable INITIAL_SUPPLY;
    
    // 在构造函数中赋值
    constructor(address factory, uint supply) {
        OWNER = msg.sender;
        FACTORY = factory;
        DEPLOYED_AT = block.timestamp;
        INITIAL_SUPPLY = supply;
    }
    
    // 使用immutable
    function checkOwner() public view returns (bool) {
        return msg.sender == OWNER;
        // 访问immutable比storage便宜，约200 gas
    }
}
```
**immutable的特点：**

1. 部署时确定：在构造函数中赋值
2. 运行时不可变：部署后不能修改
3. 不占storage：存储在合约代码中
4. 访问便宜：约200 gas（比storage的2100便宜）
5. 可用运行时值：可以使用msg.sender、block.timestamp等

## 5.4 三种变量类型对比
|特性|storage变量|constant|immutable|
|:--:|:--:|:--:|:--:|
|赋值时机|任何时候|编译时|构造函数|
|可修改性|可修改|不可修改|不可修改|
|存储位置|Storage|代码（内联）|代码|
|访问成本|~2100 gas|0 gas|~200 gas|
|可用运行时值|是|否|是|
|典型用途|动态数据|固定常量|部署时确定的值|

**使用场景对比：**
```sol
contract ComparisonExample {
    // Storage：运行时可变
    uint public totalSupply;  // 可以mint和burn
    mapping(address => uint) public balances;  // 会频繁变化
    address public owner;  // 可以转移所有权
    
    // Constant：编译时确定，永不改变
    uint public constant MAX_SUPPLY = 1000000;
    uint public constant DECIMALS = 18;
    string public constant NAME = "My Token";
    
    // Immutable：部署时确定，之后不变
    address public immutable CREATOR;
    address public immutable FACTORY;
    uint public immutable CREATED_AT;
    
    constructor(address factory) {
        CREATOR = msg.sender;
        FACTORY = factory;
        CREATED_AT = block.timestamp;
        owner = msg.sender;
    }
}
```

## 5.5 Gas优化效果
```sol
contract GasOptimization {
    // 未优化：storage
    uint public feeRate = 300;  // 每次访问：~2100 gas
    
    function calculateFee1(uint amount) public view returns (uint) {
        return amount * feeRate / 10000;
    }
    // Gas: ~2500
    
    // 优化：constant
    uint public constant FEE_RATE = 300;  // 访问：0 gas
    
    function calculateFee2(uint amount) public pure returns (uint) {
        return amount * FEE_RATE / 10000;
    }
    // Gas: ~400
    // 节省：~84%
}
```
**实际项目中的应用：**
```sol
contract TokenWithOptimization {
    // Constant：永远不变的值
    string public constant NAME = "My Token";
    string public constant SYMBOL = "MTK";
    uint8 public constant DECIMALS = 18;
    uint public constant MAX_SUPPLY = 1000000 * 10**DECIMALS;
    uint public constant TRANSFER_FEE = 100;  // 1%
    
    // Immutable：部署时确定
    address public immutable OWNER;
    address public immutable FACTORY;
    uint public immutable DEPLOYMENT_TIME;
    
    // Storage：会变化的值
    uint public totalSupply;
    mapping(address => uint) public balances;
    bool public paused;
    
    constructor(address factory) {
        OWNER = msg.sender;
        FACTORY = factory;
        DEPLOYMENT_TIME = block.timestamp;
    }
    
    function transfer(address to, uint amount) public returns (bool) {
        // 使用constant：0 gas
        uint fee = amount * TRANSFER_FEE / 10000;
        
        // 检查immutable：~200 gas
        require(msg.sender != OWNER || !paused, "Transfers paused");
        
        // 操作storage：正常gas
        balances[msg.sender] -= amount;
        balances[to] += amount - fee;
        
        return true;
    }
}
```
**命名规范：**
```sol
// 常量通常用大写 + 下划线
uint public constant MAX_SUPPLY = 1000000;
uint public constant MIN_AMOUNT = 100;
address public constant ZERO_ADDRESS = address(0);

// immutable也可以用大写
address public immutable OWNER;
uint public immutable CREATED_AT;
```

# 6. 综合实战案例
## 6.1 支付商店合约
综合运用msg.sender、msg.value、address payable。
```sol
contract SimpleShop {
    address public immutable OWNER;
    uint public constant ITEM_PRICE = 0.1 ether;
    
    mapping(address => uint) public purchases;
    
    event ItemPurchased(address indexed buyer, uint quantity, uint totalPaid);
    event Withdrawal(address indexed owner, uint amount);
    
    constructor() {
        OWNER = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == OWNER, "Not the owner");
        _;
    }
    
    // 购买商品
    function buyItem(uint quantity) public payable {
        require(quantity > 0, "Invalid quantity");
        
        uint totalCost = ITEM_PRICE * quantity;
        require(msg.value == totalCost, "Incorrect payment");
        
        purchases[msg.sender] += quantity;
        
        emit ItemPurchased(msg.sender, quantity, msg.value);
    }
    
    // 查询购买数量
    function getPurchases(address buyer) public view returns (uint) {
        return purchases[buyer];
    }
    
    // 提现（仅owner）
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        (bool sent, ) = OWNER.call{value: balance}("");
        require(sent, "Transfer failed");
        
        emit Withdrawal(OWNER, balance);
    }
    
    // 查询合约余额
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }
}
```
## 6.2 完整众筹合约
综合运用枚举、时间戳、msg.value等所有知识点。
```sol
contract AdvancedCrowdfunding {
    enum State { Fundraising, Successful, Failed, PaidOut }
    
    State public currentState = State.Fundraising;
    
    address public immutable CREATOR;
    uint public immutable GOAL;
    uint public immutable DEADLINE;
    uint public immutable MINIMUM_CONTRIBUTION = 0.01 ether;
    
    uint public totalFunded;
    uint public contributorCount;
    
    mapping(address => uint) public contributions;
    address[] public contributors;
    
    event StateChanged(State oldState, State newState, uint timestamp);
    event Contribution(address indexed contributor, uint amount, uint totalFunded);
    event FundsWithdrawn(address indexed creator, uint amount);
    event Refunded(address indexed contributor, uint amount);
    
    modifier inState(State expected) {
        require(currentState == expected, "Invalid state");
        _;
    }
    
    modifier onlyCreator() {
        require(msg.sender == CREATOR, "Only creator");
        _;
    }
    
    constructor(uint goalAmount, uint durationDays) {
        require(goalAmount > 0, "Goal must be positive");
        require(durationDays >= 1 && durationDays <= 90, "Duration: 1-90 days");
        
        CREATOR = msg.sender;
        GOAL = goalAmount;
        DEADLINE = block.timestamp + (durationDays * 1 days);
    }
    
    // 贡献资金
    function contribute() public payable inState(State.Fundraising) {
        require(block.timestamp <= DEADLINE, "Fundraising ended");
        require(msg.value >= MINIMUM_CONTRIBUTION, "Below minimum");
        
        // 新贡献者
        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
            contributorCount++;
        }
        
        contributions[msg.sender] += msg.value;
        totalFunded += msg.value;
        
        emit Contribution(msg.sender, msg.value, totalFunded);
        
        // 达到目标自动成功
        if (totalFunded >= GOAL) {
            State oldState = currentState;
            currentState = State.Successful;
            emit StateChanged(oldState, State.Successful, block.timestamp);
        }
    }
    
    // 检查并更新状态
    function checkGoalReached() public inState(State.Fundraising) {
        require(block.timestamp > DEADLINE, "Still active");
        
        State oldState = currentState;
        State newState;
        
        if (totalFunded >= GOAL) {
            newState = State.Successful;
        } else {
            newState = State.Failed;
        }
        
        currentState = newState;
        emit StateChanged(oldState, newState, block.timestamp);
    }
    
    // 创建者提取资金
    function withdrawFunds() public onlyCreator inState(State.Successful) {
        currentState = State.PaidOut;
        
        uint amount = address(this).balance;
        (bool sent, ) = CREATOR.call{value: amount}("");
        require(sent, "Transfer failed");
        
        emit FundsWithdrawn(CREATOR, amount);
    }
    
    // 退款
    function refund() public inState(State.Failed) {
        uint amount = contributions[msg.sender];
        require(amount > 0, "No contribution");
        
        contributions[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Refund failed");
        
        emit Refunded(msg.sender, amount);
    }
    
    // 查询函数
    function getInfo() public view returns (
        State state,
        uint goal,
        uint funded,
        uint deadline,
        uint timeRemaining,
        uint contributors
    ) {
        uint remaining = 0;
        if (block.timestamp < DEADLINE) {
            remaining = DEADLINE - block.timestamp;
        }
        
        return (
            currentState,
            GOAL,
            totalFunded,
            DEADLINE,
            remaining,
            contributorCount
        );
    }
    
    function getProgress() public view returns (uint percentage) {
        return (totalFunded * 100) / GOAL;
    }
    
    function isActive() public view returns (bool) {
        return currentState == State.Fundraising && 
               block.timestamp <= DEADLINE;
    }
}
```

# 7. 常见问题解答

## Q1：为什么要区分address和address payable？
答：为了类型安全。

编译器可以检查：

* 防止向普通address转账（会失败）
* 明确哪些地址可以接收ETH
* 减少运行时错误


## Q2：transfer、send、call应该用哪个？
答：2024年推荐使用call。

```sol
(bool sent, ) = recipient.call{value: amount}("");
require(sent, "Failed");
```
理由：

* transfer和send有2300 gas限制，可能不够用
* call更灵活，可以转发所有gas
* 配合ReentrancyGuard使用很安全

避免：

send：容易忘记检查返回值

## Q3：tx.origin为什么危险？
答：容易受到钓鱼攻击。

危险场景：
```sol
用户 → 恶意合约 → 你的合约

在你的合约中：
tx.origin = 用户（通过检查！）
msg.sender = 恶意合约

如果用tx.origin检查权限，攻击者可以代表用户操作
```
安全原则：永远使用msg.sender做权限检查！

## Q4：block.timestamp可以用于随机数吗？
答：不能用于重要的随机性。

问题：

* 矿工可以操纵时间戳约15秒
* 可预测性
* 不够随机

适合用途：

* 时间锁（小时、天级别）
* 截止日期
* 时间间隔检查

真正的随机数方案：

* Chainlink VRF
* 提交-揭示方案
* 预言机

## Q5：constant和immutable的区别？

答：赋值时机不同。

constant：

* 编译时赋值
* 必须是常量表达式
* 访问cost = 0

immutable：

* 构造函数中赋值
* 可以用运行时值
* 访问cost ≈ 200 gas

选择建议：

* 纯常量用constant
* 部署时确定的值用immutable
* 运行时可变的用storage

## Q6：枚举的底层类型是什么？
答：uint8
```sol
enum Status { A, B, C }  // 实际上是uint8

Status s = Status.B;
uint value = uint(s);  // 1
```
特点：

* 从0开始编号
* 最多256个值（uint8的范围）
* 存储消耗很小

## Q7：如何选择使用枚举还是uint？
答：根据语义和安全性需求。

使用枚举：

* 有限的状态集合
* 需要类型安全
* 提高可读性
* 防止无效值

使用uint：

* 数值有意义
* 需要数学运算
* 范围不固定


# 8. 知识点总结

address类型

两种类型：

* address：基础类型，不能接收ETH
* address payable：可以接收ETH，有transfer/send方法

属性和方法：

* .balance：查询余额（wei）
* .code：获取字节码
* .codehash：代码哈希
* .transfer()：转账（payable专用）
* .send()：转账+返回值（payable专用）
* .call()：底层调用

类型转换：

* payable(addr)：转为address payable
* 自动转换：address payable → address

**转账方式**
|方法|特点|推荐度|
|:--:|:--:|:--:|
|transfer|自动回滚，2300 gas|中|
|send|需检查返回值，2300 gas|低|
|call|无限制，灵活|高|

**安全原则：遵循CEI模式！**

**全局变量**
msg对象：

* msg.sender：调用者（最常用）
* msg.value：发送的ETH（payable函数）
* msg.data：调用数据
* msg.sig：函数选择器

block对象：

* block.timestamp：时间戳（常用）
* block.number：区块号（常用）
* blockhash()：区块哈希

危险变量：

tx.origin：永远不要用于权限检查！


## 枚举类型

优势：

* 代码可读性高
* 类型安全
* 节省gas

应用：

* 状态机模式
* 有限选项集合
* 角色管理

## constant和immutable
constant：

* 编译时常量
* 访问cost = 0 gas
* 用于固定值

immutable：

* 部署时常量
* 访问cost ≈ 200 gas
* 用于部署时确定的值

优化效果：节省约84-95%的gas






