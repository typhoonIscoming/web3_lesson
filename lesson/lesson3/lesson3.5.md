# 第3.3课：函数与修饰符

## 1. 函数基本结构

## 1.1 完整的函数定义
函数是智能合约的核心组成部分，用于实现合约的各种功能。一个完整的函数包含多个组成部分。
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FunctionExample {
    uint256 public value;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    // 完整的函数定义
    function setValue(uint256 _value)
        public              // 可见性修饰符
        onlyOwner           // 自定义修饰符
        returns (bool)      // 返回类型
    {
        value = _value;
        return true;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}
```
## 1.2 函数的组成部分
必需部分：

* function关键字：声明这是一个函数
* 函数名：标识函数的名称
* 可见性修饰符：定义谁可以调用（public/external/internal/private）

可选部分：

* 参数列表：函数的输入参数（可以为空）
* 状态修饰符：定义函数是否修改状态（view/pure/payable）
* 自定义修饰符：权限控制和前置检查
* 返回值：函数的输出（可以没有返回值）

## 1.3 基本函数示例
```sol
contract BasicFunctions {
    uint256 public counter;
    
    // 最简单的函数（无参数，无返回值）
    function increment() public {
        counter++;
    }
    
    // 带参数的函数
    function setCounter(uint256 _value) public {
        counter = _value;
    }
    
    // 带返回值的函数
    function getCounter() public view returns (uint256) {
        return counter;
    }
    
    // 带参数和返回值的函数
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }
    
    // 多个返回值
    function getValues() public view returns (uint256, uint256) {
        return (counter, counter * 2);
    }
    
    // 命名返回值
    function calculate(uint256 a, uint256 b) 
        public pure 
        returns (uint256 sum, uint256 product) 
    {
        sum = a + b;
        product = a * b;
        // 命名返回值可以不写return
    }
}
```
## 1.4 参数和返回值
```sol
contract ParameterPassing {
    // 值类型参数（传递副本）
    function updateValue(uint256 _value) public pure returns (uint256) {
        _value = _value + 1;  // 修改的是副本
        return _value;
    }
    // 引用类型参数（需要指定存储位置）
    function processArray(uint256[] memory arr) public pure returns (uint256) {
        return arr.length;
    }
    // calldata参数（只读，更省gas）
    function processArrayCalldata(uint256[] calldata arr) 
        external pure returns (uint256) 
    {
        return arr.length;
    }
}
// 返回值
contract ReturnValues {
    // 单个返回值
    function getSingle() public pure returns (uint256) {
        return 42;
    }
    // 多个返回值
    function getMultiple() public pure returns (uint256, bool, string memory) {
        return (42, true, "Hello");
    }
    // 命名返回值
    function getNamedReturns() 
        public pure 
        returns (uint256 number, bool flag, string memory message) 
    {
        number = 42;
        flag = true;
        message = "Hello";
        // 不需要显式return
    }
    // 调用带返回值的函数
    function callFunction() public pure {
        // 接收所有返回值
        (uint256 num, bool f, string memory msg) = getMultiple();
        
        // 只接收部分返回值
        (uint256 n, , ) = getMultiple();
        
        // 忽略返回值
        getMultiple();
    }
}
```
# 2. 可见性修饰符
## 2.1 可见性修饰符概览
Solidity提供了四种可见性修饰符，用于控制函数的访问权限。
|修饰符|外部调用|内部调用|继承合约调用|Gas成本|
|:--:|:--:|:--:|:--:|:--:|
|public|可以|可以|可以|中等|
|external|可以|不可以|可以|较低|
|internal|不可以|可以|可以|-|
|private|不可以|可以|不可以|-|
记忆口诀：

* public 最开放，任何人都可以调用
* external 外部强，只能从外部调用
* internal 内部用，本合约和子合约
* private 最保守，只能本合约调用

## 2.2 Public - 公开函数
public是最常用的可见性修饰符，任何人都可以调用。
```sol
contract PublicExample {
    uint256 public value;  // public状态变量自动生成getter函数
    
    // public函数可以被任何人调用
    function publicFunction() public pure returns (string memory) {
        return "This is public";
    }
    
    // 内部调用示例
    function internalCall() public pure returns (string memory) {
        return publicFunction();  // 可以内部调用
    }
}
// 外部调用示例
contract Caller {
    PublicExample public example;
    
    constructor(address _addr) {
        example = PublicExample(_addr);
    }
    
    function callPublic() public view returns (string memory) {
        return example.publicFunction();  // 外部调用public函数
    }
}
```
**public的特点：**

1. 外部可调用：任何账户或合约都可以调用
2. 内部可调用：合约内部可以直接调用
3. 继承可调用：子合约可以调用和重写
4. 自动生成getter：public状态变量自动创建getter函数

**使用场景：**

* 对外提供的接口函数
* 用户需要调用的功能
* 需要被继承和重写的函数
* 最常用的可见性修饰符

## 2.3 External - 外部函数
external函数只能从外部调用，在某些情况下比public更省gas。
```sol
contract ExternalExample {
    // external函数只能从外部调用
    function externalFunction() external pure returns (string memory) {
        return "This is external";
    }
    // 错误：不能在内部直接调用external函数
    // function internalCall() public view returns (string memory) {
    //     return externalFunction();  // 编译错误！
    // }
    // 正确：使用this调用（但这实际上是外部调用，消耗更多gas）
    function callExternal() public view returns (string memory) {
        return this.externalFunction();  // 可以，但不推荐
    }
    // external函数处理大数组更省gas
    function processLargeArray(uint256[] calldata data) 
        external pure returns (uint256) 
    {
        uint256 sum = 0;
        for(uint256 i = 0; i < data.length; i++) {
            sum += data[i];
        }
        return sum;
    }
}
```
**external的优势：**

1. Gas优化：可以直接从calldata读取参数，不需要复制到memory
2. 适合大数组：处理大数组或字符串时更高效
3. 明确语义：清楚表明这是一个外部接口

**public vs external Gas对比：**
```sol
contract GasComparison {
    // public函数：参数会从calldata复制到memory
    function publicProcess(uint256[] memory data) 
        public pure returns (uint256) 
    {
        return data.length;
    }
    // Gas: ~3,000（100个元素）
    
    // external函数：直接从calldata读取
    function externalProcess(uint256[] calldata data) 
        external pure returns (uint256) 
    {
        return data.length;
    }
    // Gas: ~1,000（100个元素）
    // 节省: ~66%
}
```
**何时使用external：**

1. 只给外部调用的函数
2. 参数包含大数组或长字符串
3. 追求gas优化
4. 接口定义

## 2.4 Internal - 内部函数
internal函数只能在合约内部和继承合约中调用。
```sol
contract InternalExample {
    uint256 private value;
    // internal函数：内部辅助函数
    function _setValue(uint256 _value) internal {
        require(_value > 0, "Value must be positive");
        value = _value;
    }
    // public函数调用internal函数
    function setValue(uint256 _value) public {
        _setValue(_value);  // 内部调用
    }
    // internal辅助函数
    function _calculateFee(uint256 amount) internal pure returns (uint256) {
        return amount * 3 / 100;  // 3% fee
    }
    function processWithFee(uint256 amount) public pure returns (uint256) {
        uint256 fee = _calculateFee(amount);
        return amount - fee;
    }
}
// 继承合约可以调用internal函数
contract InheritedContract is InternalExample {
    function useInternal(uint256 _value) public {
        _setValue(_value);  // 子合约可以调用父合约的internal函数
    }
}
```
**internal的特点：**

1. 内部可调用：本合约可以调用
2. 继承可调用：子合约可以调用和重写
3. 外部不可调用：外部账户和合约不能调用

使用场景：

* 内部辅助函数
* 可复用的逻辑
* 给子合约继承使用的函数
* 实现细节封装

命名规范：

通常internal函数以下划线开头，如_setValue、_calculateFee，这是一种常见的命名约定。

## 2.5 Private - 私有函数

private是最严格的可见性，只能在当前合约内部调用。
```sol
contract PrivateExample {
    uint256 private secretValue;
    // private函数：只能本合约调用
    function _updateSecret(uint256 _value) private {
        secretValue = _value;
    }
    // public函数调用private函数
    function setSecret(uint256 _value) public {
        _updateSecret(_value);
    }
    // private计算函数
    function _complexCalculation(uint256 a, uint256 b) 
        private pure returns (uint256) 
    {
        return (a * b) + (a ** 2) - (b ** 2);
    }
    function calculate(uint256 a, uint256 b) public pure returns (uint256) {
        return _complexCalculation(a, b);
    }
}

// 继承合约不能调用private函数
contract InheritedPrivate is PrivateExample {
    function tryCallPrivate() public {
        // _updateSecret(100);  // 编译错误！无法调用父合约的private函数
    }
}
```
**重要警告：private不等于隐私**
```sol
contract PrivacyWarning {
    uint256 private secretNumber = 12345;
    // 即使是private，数据仍然在区块链上公开！
    // 任何人都可以通过读取storage来查看
}
```
**如何读取private变量（使用Web3.js）：**
```sol
// 任何人都可以读取storage
const value = await web3.eth.getStorageAt(contractAddress, 0);
console.log(value);  // 可以看到"private"的secretNumber
```
**private的特点：**

1. 只能本合约调用：子合约也不能调用
2. 最严格的访问控制
3. 不代表数据隐私：区块链上所有数据都是公开的

使用场景：

* 纯内部逻辑
* 不希望子合约访问的函数
* 实现细节的封装

## 2.6 可见性选择指南
**决策流程：**
```sol
外部用户需要调用这个函数吗？
├─ 是 → 参数包含大数组或长字符串吗？
│       ├─ 是 → external（省gas）
│       └─ 否 → public
└─ 否 → 子合约需要访问吗？
        ├─ 是 → internal
        └─ 否 → private
```
**选择建议：**
```sol
contract VisibilityChoice {
    // 对外接口：用户需要调用 → public或external
    function deposit() public payable {
        // 对外服务
    }
    // 大参数：用external省gas
    function processBatch(uint256[] calldata items) external {
        // 处理大数组
    }
    // 内部辅助：给本合约和子合约用 → internal
    function _validate(address user) internal view returns (bool) {
        // 内部验证逻辑
    }
    // 私有逻辑：只给本合约用 → private
    function _calculateSecret(uint256 seed) private pure returns (uint256) {
        // 私有计算
    }
}
```
**最佳实践：**

1. 默认使用最严格的可见性：从private开始，需要时再放宽
2. 对外接口明确：public或external清楚表明意图
3. 大数组用external：显著节省gas
4. 内部函数用下划线：_functionName作为命名约定

# 3. 状态修饰符
## 3.1 状态修饰符概览

状态修饰符定义了函数与区块链状态的交互方式。
|修饰符|读取状态|修改状态|接收ETH|Gas消耗（外部调用）|
|:--:|:--:|:--:|:--:|:--:|
|默认|可以|可以|不可以|正常消耗|
|view|可以|不可以|不可以|0（不改变状态）|
|pure|不可以|不可以|不可以|0（不改变状态）|
|payable|可以|可以|可以|正常消耗|

**选择建议：**

* 需要修改状态？→ 默认或payable
* 只读取状态？→ view
* 不读不写？→ pure
* 需要接收ETH？→ payable

重要提示：能用pure就pure，能用view就view！

## 3.2 View - 只读函数
view函数承诺不修改状态，只读取数据。
```sol
contract ViewExample {
    uint256 public counter = 0;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    // view函数：读取状态变量
    function getCounter() public view returns (uint256) {
        return counter;  // 可以读取状态
    }
    // view函数：可以读取多个状态变量
    function getInfo() public view returns (uint256, address) {
        return (counter, owner);
    }
    // view函数：可以读取全局变量
    function getBlockInfo() public view returns (uint256, address) {
        return (block.timestamp, msg.sender);
    }
    // view函数：可以进行计算
    function calculateDouble() public view returns (uint256) {
        return counter * 2;  // 读取并计算
    }
    // view函数：可以调用其他view函数
    function complexView() public view returns (uint256) {
        uint256 c = getCounter();
        return c * 2;
    }
}
```
**view函数可以做什么：**

1. 读取状态变量
2. 读取全局变量（msg、block、tx等）
3. 调用其他view或pure函数
4. 进行计算和逻辑判断

**view函数不能做什么：**
```sol
contract ViewRestrictions {
    uint256 public value;
    function badView1() public view {
        // value = 100;  // 错误：不能修改状态变量
    }
    function badView2() public view {
        // selfdestruct(payable(msg.sender));  // 错误：不能销毁合约
    }
    function badView3() public view {
        // emit SomeEvent();  // 错误：不能触发事件
    }
}
```
**Gas消耗：**
```sol
contract ViewGas {
    uint256 public value = 100;
    // 外部直接调用view函数：不消耗gas
    function getValue() public view returns (uint256) {
        return value;
    }
    // 但在交易中调用view函数：消耗gas
    function modifyAndView() public returns (uint256) {
        value = 200;  // 修改状态，消耗gas
        return getValue();  // 内部调用view，也消耗gas
    }
}
```
**重要提示：**

* 外部直接调用view函数（只读查询）：不消耗gas
* 在交易中调用view函数：消耗gas
* view承诺不修改状态，但编译器会检查

## 3.3 Pure - 纯函数
pure函数既不读取也不修改状态，只使用参数和局部变量
```sol
contract PureExample {
    // pure函数：只使用参数
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }
    
    // pure函数：数学计算
    function calculate(uint256 x) public pure returns (uint256) {
        uint256 result = x * x + 2 * x + 1;
        return result;
    }
    
    // pure函数：字符串处理
    function concatenate(string memory a, string memory b) 
        public pure returns (string memory) 
    {
        return string(abi.encodePacked(a, b));
    }
    // pure函数：可以调用其他pure函数
    function complexPure(uint256 a, uint256 b) 
        public pure returns (uint256) 
    {
        uint256 sum = add(a, b);
        return sum * 2;
    }
    // pure函数：数组处理
    function arraySum(uint256[] memory arr) 
        public pure returns (uint256) 
    {
        uint256 sum = 0;
        for(uint256 i = 0; i < arr.length; i++) {
            sum += arr[i];
        }
        return sum;
    }
}
```
**pure函数可以做什么：**

1. 使用函数参数
2. 使用局部变量
3. 调用其他pure函数
4. 进行纯计算

**pure函数不能做什么：**
```sol
contract PureRestrictions {
    uint256 public value = 100;
    function badPure1() public pure returns (uint256) {
        // return value;  // 错误：不能读取状态变量
    }
    function badPure2() public pure returns (uint256) {
        // return block.timestamp;  // 错误：不能读取全局变量
    }
    function badPure3() public pure returns (address) {
        // return msg.sender;  // 错误：不能读取msg
    }
    function badPure4() public pure returns (uint256) {
        // return address(this).balance;  // 错误：不能读取余额
    }
}
```
**pure函数的类比：**
pure函数就像数学函数：
```sol
f(x) = x + 1
```
* 输入确定，输出确定
* 没有副作用
* 不依赖外部状态
**使用场景**
```sol
contract PureUseCases {
    // 工具函数
    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a < b ? a : b;
    }
    
    function max(uint256 a, uint256 b) public pure returns (uint256) {
        return a > b ? a : b;
    }
    
    // 验证函数
    function isValidAddress(address addr) public pure returns (bool) {
        return addr != address(0);
    }
    
    // 计算函数
    function calculateFee(uint256 amount, uint256 feePercent) 
        public pure returns (uint256) 
    {
        return amount * feePercent / 100;
    }
}
```
## 3.4 Payable - 可支付函数
**payable函数可以接收ETH。**
```sol
contract PayableExample {
    uint256 public totalReceived;
    mapping(address => uint256) public balances;
    
    // payable函数：可以接收ETH
    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        totalReceived += msg.value;
    }
    
    // payable函数：带参数
    function depositWithMessage(string memory message) public payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        // 可以使用message参数
    }
    
    // 查询合约余额
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    // 提取ETH
    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
    
    // 接收ETH的特殊函数
    receive() external payable {
        // 直接转账ETH到合约时调用
        balances[msg.sender] += msg.value;
    }
    
    fallback() external payable {
        // 调用不存在的函数时调用
        balances[msg.sender] += msg.value;
    }
}
```
**没有payable会发生什么：**
```sol
contract NoPayable {
    // 没有payable修饰符
    function normalFunction() public {
        // 如果调用时发送ETH，交易会失败并回退
    }
    
    // 错误：尝试访问msg.value但没有payable
    function badFunction() public {
        // uint256 amount = msg.value;  // 编译错误！
    }
}
```
**msg.value的使用**
```sol
contract MsgValueExample {
    event Received(address sender, uint256 amount);
    function checkValue() public payable {
        if(msg.value > 1 ether) {
            emit Received(msg.sender, msg.value);
        } else {
            revert("Must send at least 1 ETH");
        }
    }
    function getExactAmount() public payable {
        require(msg.value == 0.5 ether, "Must send exactly 0.5 ETH");
        // 处理逻辑
    }
}
```




















