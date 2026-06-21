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

















































