# 4. 自定义Modifier
## 4.1 什么是Modifier
Modifier（修饰符）是函数执行前的检查点，用于权限控制、状态检查和参数验证。

**基本语法：**
```sol
modifier 修饰符名称(参数) {
    require(条件, "错误信息");
    _;  // 下划线表示函数体的位置
}
```
**下划线（_）的作用：**

下划线是占位符，表示被修饰函数的函数体将在这个位置执行。
```sol
contract ModifierBasics {
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    // 定义modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;  // 函数体会插入到这里
    }
    // 使用modifier
    function restrictedFunction() public onlyOwner {
        // 只有owner可以执行
    }
}
```
## 4.2 Modifier执行流程
```sol
// 执行顺序
调用函数
    ↓
执行modifier检查
    ↓
条件满足？
    ├─ 是 → 执行函数体（_的位置）
    └─ 否 → 回退交易
// 实际执行等价：
// 使用modifier的函数
function setValue(uint256 _value) public onlyOwner {
    value = _value;
}

// 等价于
function setValue(uint256 _value) public {
    require(msg.sender == owner, "Not the owner");  // modifier的内容
    value = _value;  // 原函数体
}
```
## 4.3 常用Modifier模式
**模式1：权限控制**
```sol
contract AccessControl {
    address public owner;
    mapping(address => bool) public admins;
    constructor() {
        owner = msg.sender;
    }
    // 只有owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    // 只有admin
    modifier onlyAdmin() {
        require(admins[msg.sender], "Not an admin");
        _;
    }
    // owner或admin
    modifier onlyAuthorized() {
        require(
            msg.sender == owner || admins[msg.sender],
            "Not authorized"
        );
        _;
    }
    function addAdmin(address admin) public onlyOwner {
        admins[admin] = true;
    }
    
    function removeAdmin(address admin) public onlyOwner {
        admins[admin] = false;
    }
    
    function adminFunction() public onlyAdmin {
        // 只有admin可以调用
    }
}
```
**模式2：状态检查**
```sol
contract StateCheck {
    bool public paused = false;
    bool public initialized = false;
    // 未暂停检查
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    // 已暂停检查
    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }
    // 初始化检查
    modifier whenInitialized() {
        require(initialized, "Not initialized");
        _;
    }
    function normalOperation() public whenNotPaused whenInitialized {
        // 正常操作
    }
    function emergencyStop() public whenNotPaused {
        paused = true;
    }
    function resume() public whenPaused {
        paused = false;
    }
}
```
**模式3：参数验证**
```sol
contract ParameterValidation {
    // 地址验证
    modifier validAddress(address _addr) {
        require(_addr != address(0), "Invalid address");
        _;
    }
    // 金额验证
    modifier minValue(uint256 _minValue) {
        require(msg.value >= _minValue, "Insufficient value");
        _;
    }
    // 范围验证
    modifier inRange(uint256 _value, uint256 _min, uint256 _max) {
        require(_value >= _min && _value <= _max, "Out of range");
        _;
    }
    function transfer(address to, uint256 amount) 
        public 
        validAddress(to) 
    {
        // 转账逻辑
    }
    function deposit() public payable minValue(0.1 ether) {
        // 至少0.1 ETH
    }
    function setValue(uint256 value) public inRange(value, 1, 100) {
        // value必须在1-100之间
    }
}
```
**模式4：时间锁**
```sol
contract TimeLock {
    uint256 public lockTime;
    
    modifier afterTime(uint256 _time) {
        require(block.timestamp >= _time, "Too early");
        _;
    }
    
    modifier beforeTime(uint256 _time) {
        require(block.timestamp < _time, "Too late");
        _;
    }
    constructor() {
        lockTime = block.timestamp + 1 days;
    }
    function executeAfterLock() public afterTime(lockTime) {
        // 锁定期后才能执行
    }
    
    function executeBeforeLock() public beforeTime(lockTime) {
        // 锁定期前才能执行
    }
}
```
## 模式5：重入保护
```sol
contract ReentrancyGuard {
    bool private locked = false;
    
    modifier noReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }
    
    function withdraw(uint256 amount) public noReentrant {
        // 防止重入攻击
        // 提取资金逻辑
    }
}
```
## 4.4 组合多个Modifier
**一个函数可以使用多个modifier。**
```sol
contract MultipleModifiers {
    address public owner;
    bool public paused = false;
    uint256 public value;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }
    
    modifier validValue(uint256 _value) {
        require(_value > 0, "Invalid value");
        _;
    }
    
    // 组合三个modifier
    function criticalFunction(uint256 _value)
        public
        onlyOwner
        whenNotPaused
        validValue(_value)
    {
        value = _value;
    }
}
```
**执行顺序：**
```sol
调用 criticalFunction(100)
    ↓
1. 检查 onlyOwner
    ↓
2. 检查 whenNotPaused
    ↓
3. 检查 validValue(100)
    ↓
4. 都通过，执行函数体
    ↓
完成
```
**任何一个检查失败，交易立即回退。**

## 4.5 带返回值的Modifier

Modifier可以在函数执行前后进行操作。

```sol
contract ModifierWithLogic {
    uint256 public counter = 0;
    // modifier在函数前后执行
    modifier countCalls() {
        counter++;  // 函数执行前
        _;          // 执行函数体
        counter++;  // 函数执行后
    }
    function doSomething() public countCalls {
        // 每次调用，counter增加2
    }
    
    // modifier可以修改返回值（不推荐）
    modifier addOne() {
        _;
        // 注意：不能直接修改返回值
    }
}
```

# 5. 函数重载

## 5.1 什么是函数重载
函数重载（Function Overloading）允许同名函数有不同的参数。

```sol
contract FunctionOverloading {
    // 版本1：两个参数
    function transfer(address to, uint256 amount) public {
        // 简单转账
    }
    
    // 版本2：三个参数（重载）
    function transfer(
        address to,
        uint256 amount,
        string memory memo
    ) public {
        // 带备注的转账
    }
    
    // 版本3：不同类型（重载）
    function getValue() public pure returns (uint256) {
        return 42;
    }
    
    function getValue(uint256 multiplier) public pure returns (uint256) {
        return 42 * multiplier;
    }
}
```
## 5.2 重载规则
可以重载的情况：

1. 参数数量不同
2. 参数类型不同
3. 参数顺序不同

```sol
contract OverloadingRules {
    // 参数数量不同
    function process(uint256 a) public pure returns (uint256) {
        return a;
    }
    
    function process(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }
    
    // 参数类型不同
    function getValue(uint256 id) public pure returns (uint256) {
        return id;
    }
    
    function getValue(address user) public pure returns (address) {
        return user;
    }
    
    // 参数顺序不同
    function swap(uint256 a, address b) public pure {}
    function swap(address a, uint256 b) public pure {}
}
```
**不能重载的情况**
```sol
contract CannotOverload {
    // 错误：只有返回值不同不能重载
    // function test() public pure returns (uint256) {
    //     return 1;
    // }
    
    // function test() public pure returns (bool) {  // 编译错误！
    //     return true;
    // }
    
    // 错误：只有modifier不同不能重载
    // function test() public pure {}
    // function test() public view {}  // 编译错误！
}
```
## 5.3 调用重载函数
Solidity会根据参数自动匹配正确的函数。

```sol
contract CallOverloaded {
    function transfer(address to, uint256 amount) public {
        // 版本1
    }
    
    function transfer(
        address to,
        uint256 amount,
        string memory memo
    ) public {
        // 版本2
    }
    
    function testCalls() public {
        address addr = address(0x123);
        
        // 调用版本1
        transfer(addr, 100);
        
        // 调用版本2
        transfer(addr, 100, "Payment");
    }
}
```
## 5.4 重载的实际应用
```sol
contract PracticalOverloading {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferWithMemo(
        address indexed from,
        address indexed to,
        uint256 value,
        string memo
    );
    
    mapping(address => uint256) public balances;
    
    // 简单转账
    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }
    
    // 带备注的转账
    function transfer(
        address to,
        uint256 amount,
        string memory memo
    ) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit TransferWithMemo(msg.sender, to, amount, memo);
    }
    
    // 批量转账
    function transfer(address[] memory recipients, uint256[] memory amounts) public {
        require(recipients.length == amounts.length, "Length mismatch");
        
        for(uint256 i = 0; i < recipients.length; i++) {
            require(balances[msg.sender] >= amounts[i], "Insufficient balance");
            balances[msg.sender] -= amounts[i];
            balances[recipients[i]] += amounts[i];
            emit Transfer(msg.sender, recipients[i], amounts[i]);
        }
    }
}
```
# 6. 最佳实践

## 6.1 可见性选择原则
**原则1：默认使用最严格的可见性**
```sol
contract VisibilityPrinciple {
    // 从最严格开始
    function _helperFunction() private pure returns (uint256) {
        return 42;
    }
    
    // 需要子合约访问时改为internal
    function _internalHelper() internal pure returns (uint256) {
        return 42;
    }
    
    // 需要对外提供时才用public/external
    function publicInterface() public pure returns (uint256) {
        return _helperFunction();
    }
}
```
**原则2：大参数用external**
```sol
contract LargeParameters {
    // 大数组：用external + calldata
    function processBatch(uint256[] calldata items) external {
        // 处理大数组
    }
    // 小参数：用public也可以
    function processSmall(uint256 a, uint256 b) public {
        // 处理小数据
    }
}
```
## 6.2 状态修饰符原则
原则1：能用pure就pure，能用view就view
```sol
contract StatePrinciple {
    uint256 public value = 100;
    
    // 纯计算：用pure
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }
    
    // 只读取：用view
    function getValue() public view returns (uint256) {
        return value;
    }
    
    // 需要修改：不加修饰符
    function setValue(uint256 _value) public {
        value = _value;
    }
}
```
**原则2：明确标注函数是否修改状态**
```sol
contract ClearIntent {
    uint256 public counter;
    
    // 清楚表明这是查询函数
    function getCounter() public view returns (uint256) {
        return counter;
    }
    
    // 清楚表明这会修改状态
    function incrementCounter() public {
        counter++;
    }
}
```

## 6.3 Modifier原则
**原则1：权限控制用modifier**
```sol
contract ModifierPrinciple {
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    // 好：使用modifier
    function restrictedFunction() public onlyOwner {
        // 逻辑
    }
    
    // 不好：手动检查
    function badFunction() public {
        require(msg.sender == owner, "Not owner");  // 不推荐
        // 逻辑
    }
}
```
**原则2：modifier名称要清晰**
```sol
contract ClearModifiers {
    // 好的命名
    modifier onlyOwner() { _; }
    modifier whenNotPaused() { _; }
    modifier validAddress(address addr) { _; }
    
    // 不好的命名
    modifier check() { _; }  // 太笼统
    modifier m1() { _; }     // 无意义
}
```
**原则3：检查失败要有明确错误信息**
```sol
contract ClearErrors {
    address public owner;
    
    // 好：明确的错误信息
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    // 不好：无错误信息
    modifier badModifier() {
        require(msg.sender == owner);  // 不推荐
        _;
    }
}
```

## 6.4 安全原则
**原则1：private不等于隐私**
```sol
contract PrivacyWarning {
    // 即使是private，数据仍然公开
    uint256 private secretNumber = 12345;
    
    // 不要存储真正的隐私数据在区块链上
    // 任何人都可以读取storage
}
```
**原则2：谨慎使用external**
```sol
contract ExternalSafety {
    // external函数容易受到攻击
    // 确保有足够的验证
    function externalFunction(uint256 value) external {
        require(value > 0, "Invalid value");
        require(msg.sender != address(0), "Invalid sender");
        // 更多验证...
    }
}
```
**原则3：组合modifier要考虑顺序**
```sol
contract ModifierOrder {
    bool public paused;
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }
    
    // 先检查权限，再检查状态（更合理）
    function goodOrder() public onlyOwner whenNotPaused {
        // 逻辑
    }
}
```

## 6.5 命名规范
```sol
contract NamingConventions {
    // 内部函数：下划线开头
    function _internalHelper() internal {}
    
    // 私有函数：下划线开头
    function _privateHelper() private {}
    
    // Public/External：正常命名
    function publicFunction() public {}
    function externalFunction() external {}
    
    // Modifier：描述性命名
    modifier onlyOwner() { _; }
    modifier whenNotPaused() { _; }
    modifier validAddress(address addr) { _; }
}
```

# 7. 实战练习
练习1：三角色权限管理系统

需求：

创建一个完整的权限管理系统：

1. 定义三种角色：Owner、Admin、User
2. 实现角色分配和检查
3. 不同角色有不同权限
4. Owner可以添加Admin
5. Admin可以添加User
6. 所有人可以查询角色

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RoleManagement {
    enum Role { None, User, Admin, Owner }
    
    mapping(address => Role) public roles;
    address public owner;
    
    event RoleAssigned(address indexed user, Role role);
    event RoleRevoked(address indexed user);
    
    constructor() {
        owner = msg.sender;
        roles[msg.sender] = Role.Owner;
        emit RoleAssigned(msg.sender, Role.Owner);
    }
    
    modifier onlyOwner() {
        require(roles[msg.sender] == Role.Owner, "Only owner can call");
        _;
    }
    
    modifier onlyAdmin() {
        require(
            roles[msg.sender] == Role.Admin || roles[msg.sender] == Role.Owner,
            "Only admin or owner can call"
        );
        _;
    }
    
    modifier onlyUser() {
        require(roles[msg.sender] != Role.None, "Must have a role");
        _;
    }
    
    function addAdmin(address user) public onlyOwner {
        require(user != address(0), "Invalid address");
        require(roles[user] != Role.Owner, "Cannot change owner role");
        roles[user] = Role.Admin;
        emit RoleAssigned(user, Role.Admin);
    }
    
    function addUser(address user) public onlyAdmin {
        require(user != address(0), "Invalid address");
        require(roles[user] == Role.None, "User already has a role");
        roles[user] = Role.User;
        emit RoleAssigned(user, Role.User);
    }
    
    function revokeRole(address user) public onlyOwner {
        require(user != owner, "Cannot revoke owner role");
        delete roles[user];
        emit RoleRevoked(user);
    }
    
    function getRole(address user) public view returns (Role) {
        return roles[user];
    }
    
    function hasRole(address user, Role role) public view returns (bool) {
        return roles[user] == role;
    }
}
```

**练习2：支付合约**
需求：

创建一个完整的支付合约：

1. 支持存款（deposit）
2. 支持提款（withdraw）
3. 支持紧急停止（pause）
4. Owner可以暂停/恢复合约
5. 查询余额
6. 限制最小存款金额
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PaymentContract {
    address public owner;
    bool public paused = false;
    mapping(address => uint256) public balances;
    
    uint256 public constant MIN_DEPOSIT = 0.01 ether;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event Paused(address indexed by);
    event Unpaused(address indexed by);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }
    
    modifier minValue(uint256 minAmount) {
        require(msg.value >= minAmount, "Insufficient value");
        _;
    }
    
    function deposit() public payable whenNotPaused minValue(MIN_DEPOSIT) {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint256 amount) public whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }
    
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
    
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }
    
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }
    
    receive() external payable {
        deposit();
    }
}
```

# 8. 常见问题解答
Q1：public和external的区别是什么？

答：两者都可以从外部调用，但有重要区别。

主要区别：

    1. 内部调用：

        + public：可以内部调用
        + external：不能直接内部调用（需要用this.function()）

    2. Gas成本：

        + public：参数从calldata复制到memory
        + external：直接从calldata读取，更省gas

    3. 参数类型：

        + public：参数必须是memory
        + external：参数可以是calldata

何时用external：

1. 只给外部调用的函数
2. 参数包含大数组或长字符串
3. 追求gas优化

Q2：view和pure的区别是什么？
**答：两者都不修改状态，但读取权限不同。**

|特性|view|pure|
|:--:|:--:|:--:|
|读取状态变量|可以|不可以|
|读取全局变量|可以|不可以|
|修改状态|不可以|不可以|
|使用参数|可以|可以|

**使用场景：**

* view：查询状态、获取数据
* pure：纯计算、工具函数


## Q4：为什么private变量不是隐私的？
答：区块链上所有数据都是公开的。

原因：

* 所有storage数据都存储在区块链上
* 任何人都可以读取storage
* private只是访问控制，不是加密

如何保护隐私：

* 不在链上存储隐私数据
* 使用链下存储
* 使用零知识证明等加密技术


## Q5：什么时候使用modifier，什么时候直接用require？
答：根据复用性和可读性决定。

使用modifier：

1. 需要在多个函数中复用
2. 权限控制
3. 状态检查
4. 提高代码可读性

直接用require：

1. 只在一个函数中使用
2. 函数特定的验证
3. 简单检查


## Q6：receive和fallback的区别？
答：两者都可以接收ETH，但触发条件不同。

receive：

1. 接收纯ETH转账（msg.data为空）
2. 必须是external payable
3. 更节省gas

fallback：

1. 调用不存在的函数
2. 或带data的ETH转账
3. 可以不是payable

**优先级**
```sol
发送ETH → msg.data为空？
    ├─ 是 → 有receive? → 调用receive
    │              └─ 无 → 调用fallback
    └─ 否 → 调用fallback
```

## Q7：函数重载有什么限制？
答：只能通过参数区分，不能通过返回值区分。

可以重载：

1. 参数数量不同
2. 参数类型不同
3. 参数顺序不同

不能重载：

1. 只有返回值不同
2. 只有modifier不同
3. 只有可见性不同

# 9. 知识点总结
**函数基本结构**
**完整语法：**
```sol
function 函数名(参数)
    可见性修饰符
    状态修饰符
    自定义修饰符
    returns (返回类型)
{
    // 函数体
}
```

**可见性修饰符**
|修饰符|描述|使用场景|
|:--:|:--:|:--:|
|public|任何人都可以调用|对外接口|
|external|只能从外部调用，省gas|外部专用、大参数|
|internal|内部和继承合约可调用|内部逻辑、可继承|
|private|只能本合约调用|私有逻辑|

**状态修饰符**
|修饰符|读取状态|修改状态|接收ETH|
|:--:|:--:|:--:|:--:|
|view|可以|不可以|不可以|
|pure|不可以|不可以|不可以|
|payable|可以|可以|可以|


**自定义Modifier**
作用：

* 权限控制
* 状态检查
* 参数验证
* 可组合使用
```sol
modifier 名称(参数) {
    require(条件, "错误");
    _;
}
```
**函数重载**
规则：

1. 同名不同参数可以重载
2. 参数类型、数量、顺序不同即可
3. 只有返回值不同不能重载






















