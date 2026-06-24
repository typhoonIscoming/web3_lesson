## 6.3 多重继承中的override

当多个父合约有同名函数时，必须明确指定重写哪些。

```sol
contract A {
    function foo() public virtual returns (string memory) {
        return "A";
    }
}
contract B {
    function foo() public virtual returns (string memory) {
        return "B";
    }
}

contract C is A, B {
    // 必须明确指定：override(A, B)
    function foo() public override(A, B) returns (string memory) {
        return "C";
    }
    
    // 错误：不明确
    // function foo() public override returns (string memory) {
    //     return "C";
    // }
}
```
**语法规则：**
```sol
// 单继承：简单override
function foo() public override returns (string memory) { }

// 多重继承：明确指定
function foo() public override(Parent1, Parent2) returns (string memory) { }

// 如果继续被继承，还要加virtual
function foo() public virtual override(Parent1, Parent2) returns (string memory) { }
```

## 6.4 使用super在重写中调用父函数
```sol
contract Logger {
    event Log(string message);
    
    function log(string memory message) public virtual {
        emit Log(message);
    }
}

contract TimestampLogger is Logger {
    function log(string memory message) public override {
        // 先调用父合约的log
        super.log(message);
        
        // 再添加时间戳日志
        emit Log(
            string.concat(
                "Timestamp: ",
                uint2str(block.timestamp)
            )
        );
    }
    
    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
```

# 7. 抽象合约
## 7.1 什么是抽象合约
抽象合约（Abstract Contract）是包含至少一个未实现函数的合约。
```sol
abstract contract 合约名 {
    // 至少一个未实现的函数
}
// 基本示例

abstract contract Animal {
    // 抽象函数：只有声明，没有实现
    function makeSound() public virtual returns (string memory);
    
    // 普通函数：可以有实现
    function sleep() public pure returns (string memory) {
        return "Zzz...";
    }
    
    // 可以有状态变量
    uint256 public age;
}

// 实现抽象合约
contract Dog is Animal {
    // 必须实现makeSound
    function makeSound() public pure override returns (string memory) {
        return "Woof!";
    }
}

contract Cat is Animal {
    function makeSound() public pure override returns (string memory) {
        return "Meow!";
    }
}
```
**抽象合约的特点：**

* 不能直接部署：必须被继承
* 可以有实现：部分函数可以有实现
* 可以有状态变量：可以定义状态变量
* 可以有构造函数：可以有构造函数
* 强制实现：子合约必须实现所有抽象函数

## 7.2 抽象合约的使用场景
**场景1：定义基础框架**
```sol
abstract contract BaseToken {
    string public name;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    
    constructor(string memory _name, uint256 _supply) {
        name = _name;
        totalSupply = _supply;
    }
    
    // 抽象函数：每个代币的转账逻辑可能不同
    function transfer(address to, uint256 amount) 
        public virtual returns (bool);
    
    // 普通函数：查询余额逻辑相同
    function getBalance(address account) public view returns (uint256) {
        return balanceOf[account];
    }
}

// 标准代币：简单转账
contract StandardToken is BaseToken {
    constructor(string memory _name, uint256 _supply) 
        BaseToken(_name, _supply) 
    { }
    
    function transfer(address to, uint256 amount) 
        public override returns (bool) 
    {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

// 带手续费代币：转账扣手续费
contract FeeToken is BaseToken {
    uint256 public constant FEE = 100;  // 1%
    
    constructor(string memory _name, uint256 _supply) 
        BaseToken(_name, _supply) 
    { }
    
    function transfer(address to, uint256 amount) 
        public override returns (bool) 
    {
        uint256 fee = amount * FEE / 10000;
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount - fee;
        balanceOf[address(this)] += fee;
        return true;
    }
}
```
**场景2：强制实现特定功能**
```sol
abstract contract Mintable {
    // 强制子合约实现mint功能
    function mint(address to, uint256 amount) public virtual;
}

abstract contract Burnable {
    // 强制子合约实现burn功能
    function burn(uint256 amount) public virtual;
}

contract FullToken is Mintable, Burnable {
    mapping(address => uint256) public balanceOf;
    
    // 必须实现mint
    function mint(address to, uint256 amount) public override {
        balanceOf[to] += amount;
    }
    
    // 必须实现burn
    function burn(uint256 amount) public override {
        balanceOf[msg.sender] -= amount;
    }
}
```
## 7.3 抽象合约 vs 普通合约
|特性|普通合约|抽象合约|
|:--:|:--:|:--:|
|关键字|contract|abstract contract|
|可部署|是|否|
|未实现函数|不允许|允许|
|状态变量|允许|允许|
|构造函数|允许|允许|
|使用场景|完整实现|定义规范|

# 8. 接口
接口（Interface）是纯粹的接口定义，只声明函数签名，不包含任何实现。
```sol
interface 接口名 {
    // 只有函数声明
}
```
**基本示例：**
```sol
interface ICounter {
    // 所有函数必须是external
    function getCount() external view returns (uint256);
    function increment() external;
    function decrement() external;
    
    // 可以定义事件
    event CountChanged(uint256 newCount);
}

// 实现接口
contract Counter is ICounter {
    uint256 private count;
    
    event CountChanged(uint256 newCount);
    
    function getCount() external view override returns (uint256) {
        return count;
    }
    
    function increment() external override {
        count++;
        emit CountChanged(count);
    }
    
    function decrement() external override {
        count--;
        emit CountChanged(count);
    }
}
```
## 8.2 接口的特点和限制
接口的特点：

* 使用interface关键字
* 不能有实现：所有函数都是声明
* 不能有状态变量：不能定义storage变量
* 不能有构造函数
* 所有函数必须external
* 可以继承其他接口
* 可以定义事件

**接口vs合约对比：**
|特性|合约|抽象合约|接口|
|:--:|:--:|:--:|:--:|
|关键字|contract|abstract contract|interface|
|函数实现|必须全部实现|可以部分实现|不能有实现|
|函数可见性|任意|任意|必须external|
|状态变量|允许|允许|不允许|
|构造函数|允许|允许|不允许|
|可部署|是|否|否|

## 8.3 ERC20接口标准
**ERC20是最经典的接口定义示例。**
```sol
interface IERC20 {
    // 查询函数
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) 
        external view returns (uint256);
    
    // 操作函数
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    
    // 事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
```

## 实现ERC20接口：
```sol
contract MyToken is IERC20 {
    string public name = "My Token";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    constructor(uint256 initialSupply) {
        _totalSupply = initialSupply;
        _balances[msg.sender] = initialSupply;
    }
    
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) 
        external view override returns (uint256) 
    {
        return _allowances[owner][spender];
    }
    
    function transfer(address to, uint256 amount) 
        external override returns (bool) 
    {
        require(to != address(0), "Invalid address");
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) 
        external override returns (bool) 
    {
        require(spender != address(0), "Invalid spender");
        
        _allowances[msg.sender][spender] = amount;
        
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        require(from != address(0), "From zero");
        require(to != address(0), "To zero");
        require(_balances[from] >= amount, "Insufficient balance");
        require(_allowances[from][msg.sender] >= amount, "Insufficient allowance");
        
        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
}
```

## 8.4 接口用于合约交互

接口最重要的应用是合约间交互。

**场景：合约A调用合约B**
```sol
// 定义接口
interface IToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// 使用接口与其他合约交互
contract Exchanger {
    function swapTokens(address tokenAddress, address recipient, uint256 amount) 
        public 
    {
        // 通过接口与代币合约交互
        IToken token = IToken(tokenAddress);
        
        // 检查余额
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Insufficient balance");
        
        // 执行转账
        bool success = token.transfer(recipient, amount);
        require(success, "Transfer failed");
    }
}
```
**接口的优势：**

* 解耦：不需要知道合约的完整代码
* 标准化：统一的接口规范
* 互操作性：不同合约可以互相调用
* 节省gas：不需要导入完整合约代码

# 9. 实战练习
**练习1：实现完整的权限管理系统**
需求：

创建一个模块化的权限管理系统：

* Ownable合约：单一所有者管理
* Pausable合约：暂停功能
* MyContract：组合两个功能
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable {
    bool public paused;
    
    event Paused(address account);
    event Unpaused(address account);
    
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }
    
    function _pause() internal whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }
    
    function _unpause() internal whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }
}

contract MyContract is Ownable, Pausable {
    uint256 public value;
    
    function setValue(uint256 _value) public onlyOwner whenNotPaused {
        value = _value;
    }
    
    function pause() public onlyOwner {
        _pause();
    }
    
    function unpause() public onlyOwner {
        _unpause();
    }
}
```
**练习2：实现动物抽象合约**
需求：

* 创建Animal抽象合约，定义makeSound抽象函数
* 创建Dog和Cat子合约实现makeSound
* 添加共同的eat函数

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract Animal {
    string public species;
    
    constructor(string memory _species) {
        species = _species;
    }
    
    // 抽象函数：子合约必须实现
    function makeSound() public virtual returns (string memory);
    
    // 普通函数：所有动物共用
    function eat() public pure returns (string memory) {
        return "Eating...";
    }
    
    function sleep() public pure returns (string memory) {
        return "Sleeping...";
    }
}

contract Dog is Animal {
    constructor() Animal("Dog") { }
    
    function makeSound() public pure override returns (string memory) {
        return "Woof! Woof!";
    }
}

contract Cat is Animal {
    constructor() Animal("Cat") { }
    
    function makeSound() public pure override returns (string memory) {
        return "Meow! Meow!";
    }
}
```
**练习3：使用OpenZeppelin创建代币**
需求：

使用OpenZeppelin库创建一个完整的代币合约：

* 继承ERC20
* 继承Ownable
* 添加mint功能

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("My Token", "MTK") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }
    
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
```

# 10. 常见问题解答

## Q1：什么时候使用单继承，什么时候使用多重继承？

答：根据功能模块数量选择。

**单继承：**

* 简单的扩展
* 线性关系
* 一个基础合约

**多重继承：**

* 组合多个功能模块
* 需要多个基础功能
* 模块化设计


## Q2：private和internal在继承中有什么区别？

答：子合约的访问权限不同。

* private：子合约不能访问
* internal：子合约可以访问

推荐：如果希望子合约访问，使用internal。

## Q3：super在多重继承中指向哪个合约？
答：指向继承链中的下一个合约，不是直接父合约。

按照C3线性化算法确定的顺序调用。

## Q4：什么时候用抽象合约，什么时候用接口？
答：根据需求选择。

**抽象合约：**

* 需要部分实现
* 有状态变量
* 有构造函数
* 定义基础框架

**接口：**

* 纯接口定义
* 标准规范（ERC20、ERC721）
* 合约间交互
* 不需要实现

## Q5：必须重写父合约的所有virtual函数吗？
答：不是必须的。

* virtual只是表示"可以"重写
* 子合约可以选择重写或不重写
* 只有abstract函数必须实现

## Q6：多重继承时如何避免冲突？
答：遵循几个原则。

* 明确指定override：override(A, B)
* 调用super链：让所有父合约都执行
* 合理设计继承顺序：最通用的在最右边
* 避免菱形继承：尽量简化继承关系

## Q7：继承会增加Gas成本吗？
答：部署时会增加，执行时不会。

部署成本：

* 继承的代码会包含在子合约中
* 字节码更大，部署成本更高

执行成本：

* 执行时与普通函数相同
* 没有额外开销
* 可能因为代码复用反而更优化


# 11. 知识点总结

**继承基础**

单继承
```sol
contract Child is Parent { }
```
多重继承：
```sol
contract Child is Parent1, Parent2 { }
```
**访问权限：**

* public：子合约可访问
* internal：子合约可访问
* private：子合约不可访问


## super关键字
作用：

* 调用父合约函数
* 按继承链顺序调用
* 不是指向直接父合约

使用场景：

* 扩展父合约功能
* 调用链
* 多重继承中的函数调用

## 构造函数继承
执行顺序：

* 父合约优先
* 从左到右
* 最后是子合约

**参数传递：**
```sol
// 方式1：固定值
contract Child is Parent(100) { }

// 方式2：动态值（推荐）
contract Child is Parent {
    constructor(uint v) Parent(v) { }
}
```

## 函数重写
关键字：

* virtual：可以被重写
* override：重写父合约函数

规则：

* 签名必须相同
* 多重继承需明确指定：override(A, B)
* 可见性可以更开放

## 抽象合约
特点：

* abstract关键字
* 可以有未实现函数
* 不能部署
* 可以有状态变量

使用场景：

* 定义基础框架
* 部分实现
* 强制子合约实现特定功能

## 接口
特点：

* interface关键字
* 所有函数external
* 不能有实现
* 不能有状态变量

使用场景：

* 标准规范（ERC20、ERC721）
* 合约间交互
* 纯接口定义



