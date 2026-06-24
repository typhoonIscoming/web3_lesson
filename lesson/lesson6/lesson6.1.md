# 第6.1课：合约继承
学习目标：理解继承的作用和优势、掌握单继承和多重继承、学会使用super关键字、掌握函数重写机制、理解抽象合约和接口的使用

## 1. 为什么需要继承

## 1.1 代码复用的问题
在没有继承机制的情况下，开发者会遇到严重的代码复用问题。

问题场景：

假设你要创建三个代币合约：稳定币、治理代币、奖励代币。它们都需要：

* ERC20基本功能（transfer、approve等）
* 权限控制（只有owner可以执行某些操作）
* 暂停功能（紧急情况下暂停转账）

**没有继承的做法：**
```sol
// 稳定币合约
contract StableCoin {
    // 复制粘贴ERC20代码
    mapping(address => uint256) public balanceOf;
    function transfer(address to, uint256 amount) public { }
    
    // 复制粘贴权限控制代码
    address public owner;
    modifier onlyOwner() { }
    
    // 复制粘贴暂停功能代码
    bool public paused;
    modifier whenNotPaused() { }
    function pause() public { }
}

// 治理代币合约
contract GovernanceToken {
    // 又复制粘贴一遍所有代码...
    mapping(address => uint256) public balanceOf;
    function transfer(address to, uint256 amount) public { }
    address public owner;
    // ... 完全重复的代码
}

// 奖励代币合约
contract RewardToken {
    // 再次复制粘贴...
}
```
这种做法的问题：

1. 代码冗余：

* 三个合约有90%的代码相同
* 浪费存储空间
* 增加部署成本

2. 维护困难：

* 发现bug需要修改三个地方
* 容易遗漏
* 一致性难以保证

3. 升级麻烦：

* 添加新功能需要修改所有合约
* 无法批量更新
* 测试成本高

4. 容易出错：

* 复制粘贴可能出错
* 某个合约可能用旧版本代码
* 难以追踪哪个版本最新

**真实案例：**

某项目有20个代币合约，都是复制粘贴的代码。发现一个安全漏洞后，开发者修改了18个合约，遗漏了2个，最终导致黑客攻击，损失数百万美元。

## 1.2 继承的解决方案

继承（Inheritance）是面向对象编程的核心特性，它允许一个合约（子合约）继承另一个合约（父合约）的属性和方法。

**使用继承的做法：**
```sol
// 基础合约1：ERC20功能
contract BaseERC20 {
    mapping(address => uint256) public balanceOf;
    
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

// 基础合约2：权限控制
contract Ownable {
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}

// 基础合约3：暂停功能
contract Pausable {
    bool public paused;
    
    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }
    
    function pause() internal {
        paused = true;
    }
}

// 子合约：继承所有功能
contract StableCoin is BaseERC20, Ownable, Pausable {
    // 自动获得所有父合约的功能
    // 只需要添加特有功能
    
    function emergencyPause() public onlyOwner {
        pause();
    }
}

contract GovernanceToken is BaseERC20, Ownable, Pausable {
    // 同样继承所有功能
}

contract RewardToken is BaseERC20, Ownable, Pausable {
    // 同样继承所有功能
}
```
**继承的优势：**

1. 代码复用：

* 公共功能只写一次
* 多个子合约共享
* 减少90%以上的重复代码

2. 易于维护：

* bug修复只改一处
* 所有子合约自动受益
* 保证一致性

3. 模块化设计：

* 功能分离清晰
* 每个合约职责单一
* 易于理解和测试

4. 灵活扩展：

* 子合约可以添加新功能
* 可以重写父合约函数
* 组合不同功能模块

## 1.3 继承的实际应用场景

**场景1：代币项目**
```sol
// 基础代币 → 标准代币 → 项目代币
ERC20 → ERC20Burnable → MyToken
```
**场景2：权限管理**
```sol
// 基础权限 → 角色管理 → 具体合约
Ownable → AccessControl → ProjectContract
```
**场景3：安全功能**
```sol
// 基础合约 → 安全增强 → 最终合约
BaseContract → ReentrancyGuard + Pausable → SecureContract
```
**场景4：可升级合约**
```sol
// 存储合约 → 逻辑合约 → 代理合约
Storage → Logic → Proxy
```
---
# 2. 单继承
## 2.1 单继承基础语法
单继承是最简单的继承形式，一个子合约只继承一个父合约。
**基本语法：**
```sol
contract Parent {
    // 父合约代码
}

contract Child is Parent {
    // 子合约代码
    // 自动继承Parent的所有内容
}
```
**关键字说明：**

* is：表示继承关系
* Child：子合约（派生合约）
* Parent：父合约（基础合约）

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Parent {
    uint256 public value;
    
    function getValue() public view returns (uint256) {
        return value;
    }
    
    function setValue(uint256 _value) public {
        value = _value;
    }
}

contract Child is Parent {
    // 自动继承：
    // - value状态变量
    // - getValue()函数
    // - setValue()函数
    
    // 添加新功能
    function doubleValue() public view returns (uint256) {
        return value * 2;  // 可以直接访问父合约的value
    }
}
```
**子合约获得了什么：**
```sol
// 部署Child合约后，可以调用：
Child child = new Child();

child.value();          // 继承自Parent
child.getValue();       // 继承自Parent
child.setValue(100);    // 继承自Parent
child.doubleValue();    // Child自己的函数
```
## 2.2 访问权限
子合约对父合约的访问权限取决于可见性修饰符。
|父合约可见性|子合约可访问|外部可访问|
|:--:|:--:|:--:|
|public|是|是|
|internal|是|否|
|private|否|否|
|external|是（作为外部调用）|是|

```sol
contract Parent {
    uint256 public publicVar = 1;       // 子合约可访问
    uint256 internal internalVar = 2;   // 子合约可访问
    uint256 private privateVar = 3;     // 子合约不可访问
    
    function publicFunc() public pure returns (string memory) {
        return "public";
    }
    
    function internalFunc() internal pure returns (string memory) {
        return "internal";
    }
    
    function privateFunc() private pure returns (string memory) {
        return "private";
    }
}

contract Child is Parent {
    function test() public view returns (uint256, uint256) {
        // 可以访问public和internal
        uint256 a = publicVar;
        uint256 b = internalVar;
        // uint256 c = privateVar;  // 编译错误！无法访问private
        
        publicFunc();    // 可以调用
        internalFunc();  // 可以调用
        // privateFunc();  // 编译错误！无法访问private
        
        return (a, b);
    }
}
```
**重要理解：**

* public：最开放，子合约和外部都能访问
* internal：只有子合约能访问，外部不能
* private：最严格，连子合约都不能访问

**常见错误：**
```sol
contract Parent {
    uint256 private secretValue = 100;
}

contract Child is Parent {
    function getSecret() public view returns (uint256) {
        // return secretValue;  // 编译错误！
        // private变量子合约无法访问
    }
}

// 解决方案：
// 如果希望子合约访问，应该使用internal而不是private。
contract Parent {
    uint256 internal protectedValue = 100;  // 改为internal
}

contract Child is Parent {
    function getValue() public view returns (uint256) {
        return protectedValue;  // 可以访问
    }
}
```

## 2.3 实际示例：代币合约
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 父合约：基础代币功能
contract BaseToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
    }
    
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
}

// 子合约：扩展功能
contract MyToken is BaseToken {
    uint8 public constant decimals = 18;
    address public owner;
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) BaseToken(_name, _symbol, _initialSupply) {
        owner = msg.sender;
    }
    
    // 添加mint功能
    function mint(address to, uint256 amount) public {
        require(msg.sender == owner, "Only owner");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
    
    // 添加burn功能
    function burn(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}
```
**继承关系**
```sol
BaseToken（父合约）
    ↓ 继承
MyToken（子合约）

MyToken拥有：
├─ BaseToken的功能
│  ├─ name, symbol, totalSupply, balanceOf
│  └─ transfer()
└─ MyToken自己的功能
   ├─ decimals, owner
   └─ mint(), burn()
```

# 3. 多重继承
## 3.1 多重继承基础
Solidity支持多重继承，一个合约可以同时继承多个父合约。
```sol
contract Child is Parent1, Parent2, Parent3 {
    // 同时继承多个父合约
}
```
**继承顺序：**

* 从左到右列出父合约
* 顺序很重要
* 影响super调用和函数解析

```sol
contract Parent1 {
    function foo() public virtual returns (string memory) {
        return "Parent1";
    }
}

contract Parent2 {
    function bar() public virtual returns (string memory) {
        return "Parent2";
    }
}

// 多重继承
contract Child is Parent1, Parent2 {
    // 自动获得foo()和bar()
    
    function test() public view returns (string memory, string memory) {
        return (foo(), bar());
    }
}
```
**继承关系图：**
```sol
        Child
         /\
        /  \
   Parent1  Parent2
```
## 3.2 C3线性化算法
Solidity使用C3线性化算法（C3 Linearization）确定继承顺序。

**基本规则：**

1. 从右到左：Child is A, B, C，C最优先，A最后（Solidity中继承列表写法是从基类到派生类）
2. 深度优先：子合约覆盖父合约
3. 保持单调性：不能打乱已有的继承关系
```sol
继承声明：contract C is A, B

继承顺序（解析顺序）：C → B → A

调用链：
C.foo()
  → B.foo() (B在右侧，覆盖A)
    → A.foo()
```
**复杂示例**
```sol
contract GrandParent {
    function identify() public virtual returns (string memory) {
        return "GrandParent";
    }
}
contract Parent1 is GrandParent {
    function identify() public virtual override returns (string memory) {
        return "Parent1";
    }
}

contract Parent2 is GrandParent {
    function identify() public virtual override returns (string memory) {
        return "Parent2";
    }
}

contract Child is Parent1, Parent2 {
    function identify() public override(Parent1, Parent2) returns (string memory) {
        return "Child";
    }
}
```
**分析**
```sol
继承声明：
Child is Parent1, Parent2
Parent1 is GrandParent
Parent2 is GrandParent

C3线性化结果：
Child → Parent2 → Parent1 → GrandParent

原因：
1. Child 继承 Parent1 和 Parent2。
2. 在 Solidity 的继承列表中，Parent2（右侧）比 Parent1（左侧）更具体（Derived），解析时优先于 Parent1。
3. 顺序为：先 Child，再 Parent2，再 Parent1，最后 GrandParent。
```
**继承顺序的重要性：**
```sol
继承顺序不同，结果不同：

contract A is B, C { }  // C优先于B（C在右侧，更派生）
contract A is C, B { }  // B优先于C（B在右侧，更派生）

如果B和C有同名函数，右侧的合约优先被调用
```












































