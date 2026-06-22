
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































