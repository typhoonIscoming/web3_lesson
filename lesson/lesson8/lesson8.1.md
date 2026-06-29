## 第8.1课：合约间调用
学习目标：掌握Solidity中合约间调用的各种方式、理解接口调用和底层调用的区别、学会安全地进行外部调用、能够在实际项目中正确应用合约间调用技术

# 1. 合约间调用基础概念

## 1.1 为什么需要合约间调用

在实际的区块链开发中，很少有孤立存在的合约。更常见的情况是，多个合约之间需要相互协作、调用，共同完成复杂的业务逻辑。

合约间调用的必要性：

1. 模块化设计：

* 将复杂系统拆分为多个专门的合约
* 每个合约负责特定功能
* 提高代码可维护性和可重用性

2. 功能复用：

* 使用标准接口（如ERC20、ERC721）实现互操作性
* 避免重复实现相同功能
* 利用经过审计的成熟合约

3. 业务复杂性：

* DeFi协议需要调用多个外部合约
* 借贷协议需要价格预言机、代币合约、流动性池
* 复杂的业务逻辑需要多个合约协作

4. 升级和维护：

* 通过代理模式实现合约升级
* 分离数据和逻辑，便于维护
* 支持渐进式功能迭代

**实际应用场景：**
```sol
// 场景1：DeFi借贷协议
contract LendingProtocol {
    IERC20 public token;           // 调用代币合约
    IPriceOracle public oracle;    // 调用价格预言机
    ILiquidityPool public pool;    // 调用流动性池
    
    function borrow(uint256 amount) public {
        // 1. 从价格预言机获取价格
        uint256 price = oracle.getPrice(address(token));
        
        // 2. 从代币合约转移资金
        token.transferFrom(msg.sender, address(this), amount);
        
        // 3. 与流动性池交互
        pool.deposit(amount);
    }
}
```
## 1.2 合约间调用的方式

Solidity提供了多种合约间调用的方式，每种方式都有其特点和适用场景：

1. 接口调用（Interface）：

* 最安全、最规范的方式
* 编译时类型检查
* 代码可读性好
* 适合调用已知接口的合约

2. 底层调用方法：

* call：最通用的调用方式，可以发送以太币
* delegatecall：在调用者上下文中执行，用于代理模式
* staticcall：只读调用，不能修改状态

3. 合约创建：

* new关键字：传统创建方式
* create2：可预先计算地址的创建方式

## 1.3 调用上下文的重要性
理解调用上下文是掌握合约间调用的关键。不同的调用方式会在不同的上下文中执行，这直接影响：

* 状态变量的修改位置
* msg.sender的值
* 合约余额的归属
* Gas消耗


# 2. 接口调用（Interface）

接口调用是合约间交互最安全、最规范的方式。它提供了类型安全、代码可读性好、Gas效率高等优势。

## 2.1 什么是接口
在Solidity中，接口（Interface）是一种定义合约必须实现的函数签名的方式。接口本身不包含任何实现代码，只声明函数的名称、参数和返回值。

**接口的三个重要特征：**

1. 定义函数签名：接口规定了合约应该提供哪些功能，就像一份合同
2. 不包含实现：接口只告诉你"有什么"，不告诉你"怎么做"
3. 只声明函数：接口不包含状态变量，保持极简，专注于函数定义

**接口与合约的区别：**
```sol
// 接口：只有函数签名，没有实现
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// 合约：有完整的实现
contract ERC20Token is IERC20 {
    mapping(address => uint256) public balanceOf;
    
    // 必须实现接口中声明的所有函数
    function transfer(address to, uint256 amount) external returns (bool) {
        // 具体实现...
        return true;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        // 具体实现...
        return balanceOf[account];
    }
}
```
## 2.2 接口定义语法
基本语法：
```sol
interface InterfaceName {
    function functionName(param1, param2) external returns (returnType);
    // 更多函数声明...
}
```
重要规则：

1. 函数必须标记为external：接口中的函数不能是public、internal或private
2. 没有函数体：接口中的函数只有签名，没有实现代码
3. 可以继承：接口可以继承其他接口
4. 不能有状态变量：接口中不能声明状态变量
5. 不能有构造函数：接口不能有构造函数

完整示例：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// ERC20代币接口定义
interface IERC20 {
    // 转账函数：从调用者地址向指定地址转账
    function transfer(address to, uint256 amount) external returns (bool);
    
    // 授权转账函数：从指定地址向另一个地址转账（需要授权）
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    
    // 查询余额函数：查询指定地址的代币余额
    function balanceOf(address account) external view returns (uint256);
    
    // 授权函数：授权指定地址使用调用者的代币
    function approve(address spender, uint256 amount) external returns (bool);
    
    // 查询授权额度：查询owner授权给spender的额度
    function allowance(address owner, address spender) 
        external 
        view 
        returns (uint256);
    
    // 查询总供应量
    function totalSupply() external view returns (uint256);
}
```
在上面的接口定义中：

* 所有函数都标记为external，这是接口的要求
* view函数（如balanceOf）仍然需要external关键字
* 函数只有签名，没有实现代码
* 返回值类型明确声明，便于调用者处理

## 2.3 接口使用示例
定义了接口后，我们可以在其他合约中使用它来调用外部合约。

基础使用示例：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 定义ERC20接口
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// 代币交换合约：使用接口调用外部代币合约
contract TokenSwap {
    // 声明两个代币接口变量
    IERC20 public tokenA;
    IERC20 public tokenB;
    
    // 定义交换事件，记录每次交换的详细信息
    event Swap(
        address indexed user,
        uint256 amountA,
        uint256 amountB
    );
    
    // 构造函数：初始化两个代币合约地址
    constructor(address _tokenA, address _tokenB) {
        // 将地址转换为接口类型，这样就可以调用接口中定义的方法
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }
    
    /**
     * @notice 执行代币交换
     * @param amountA 要交换的tokenA数量
     * @dev 使用接口调用确保类型安全
     */
    function swap(uint256 amountA) external {
        // 步骤1：从用户账户转移tokenA到本合约
        // transferFrom需要用户先调用approve授权本合约使用其代币
        // 如果转账失败，require会回滚整个交易
        require(
            tokenA.transferFrom(msg.sender, address(this), amountA),
            "TokenA transfer failed"
        );
        
        // 步骤2：计算可交换的tokenB数量（简化示例，1:1兑换）
        uint256 amountB = amountA;
        
        // 步骤3：从本合约向用户转移tokenB
        // 如果转账失败，require会回滚整个交易
        require(
            tokenB.transfer(msg.sender, amountB),
            "TokenB transfer failed"
        );
        
        // 步骤4：触发事件，记录交换信息
        emit Swap(msg.sender, amountA, amountB);
    }
    
    /**
     * @notice 查询合约持有的代币余额
     * @return balanceA 合约持有的tokenA数量
     * @return balanceB 合约持有的tokenB数量
     */
    function getBalances() external view returns (uint256 balanceA, uint256 balanceB) {
        // 使用接口的view函数查询余额，不消耗Gas
        balanceA = tokenA.balanceOf(address(this));
        balanceB = tokenB.balanceOf(address(this));
    }
}
```
在上面的代码中：

* TokenSwap合约通过接口调用外部代币合约
* 使用IERC20(_tokenA)将地址转换为接口类型
* 调用transferFrom和transfer时，编译器会检查参数类型
* 如果传入错误的参数类型，编译时就会报错

## 2.4 接口调用的优势
使用接口调用有四个明显的优势：

1. 类型安全（Type Safety）：

编译时检查可以减少很多错误。如果你调用的函数不存在，或者参数类型不对，编译器会直接报错，而不是等到运行时才发现问题。
```sol
contract TypeSafetyExample {
    IERC20 public token;
    
    function transferTokens(address to, uint256 amount) public {
        // 正确：编译器会检查参数类型
        token.transfer(to, amount);
        
        // 编译错误：参数类型不匹配
        // token.transfer(to, "100");  // 字符串不能传给uint256参数
        
        // 编译错误：函数不存在
        // token.nonExistentFunction();  // 接口中没有这个函数
    }
}
```
2. 代码可读性好（Readability）：

当你看到IERC20类型的变量，立刻就知道这是一个符合ERC20标准的代币合约，它支持哪些操作一目了然。

```sol
contract ReadabilityExample {
    // 看到IERC20类型，就知道这个变量代表一个ERC20代币
    IERC20 public token;
    
    // 看到IPriceOracle类型，就知道这个变量代表一个价格预言机
    IPriceOracle public oracle;
    
    // 代码意图非常清晰，不需要查看具体实现就知道能做什么
    function getTokenPrice() public view returns (uint256) {
        return oracle.getPrice(address(token));
    }
}

interface IPriceOracle {
    function getPrice(address token) external view returns (uint256);
}
```
3. Gas效率高（Gas Efficiency）：

接口调用生成的字节码体积小，执行效率高。相比直接使用低级call调用，接口调用的Gas消耗更少。

```sol
contract GasEfficiencyComparison {
    IERC20 public token;
    address public tokenAddress;
    
    // 使用接口调用：Gas消耗较低
    function transferWithInterface(address to, uint256 amount) public {
        token.transfer(to, amount);
    }
    
    // 使用call调用：Gas消耗较高
    function transferWithCall(address to, uint256 amount) public {
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(success, "Transfer failed");
    }
}
```
4. 易于测试（Testability）：

在单元测试中，我们可以使用mock合约来模拟接口，而不需要部署真实的合约，这大大简化了测试流程。

```sol
// 测试用的Mock代币合约
contract MockERC20 is IERC20 {
    mapping(address => uint256) public balanceOf;
    
    // 实现接口中的所有函数，但逻辑可以简化
    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return balanceOf[account];
    }
    
    // 其他接口函数的简化实现...
}

// 在测试中使用Mock合约
contract TokenSwapTest {
    function testSwap() public {
        // 部署Mock合约而不是真实合约
        MockERC20 mockTokenA = new MockERC20();
        MockERC20 mockTokenB = new MockERC20();
        
        // 使用Mock合约测试TokenSwap
        TokenSwap swap = new TokenSwap(
            address(mockTokenA),
            address(mockTokenB)
        );
        
        // 执行测试...
    }
}
```
## 2.5 接口继承
接口可以继承其他接口，这样可以组合多个接口的功能。

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 基础代币接口
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// 扩展接口：增加了授权功能
interface IERC20Extended is IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// 使用扩展接口
contract AdvancedTokenSwap {
    // 使用扩展接口，可以调用更多方法
    IERC20Extended public token;
    
    function swapWithApproval(
        address to,
        uint256 amount
    ) external {
        // 可以使用扩展接口中的方法
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "TransferFrom failed"
        );
        require(
            token.transfer(to, amount),
            "Transfer failed"
        );
    }
}
```
## 2.6 接口调用的完整示例
以下是一个完整的代币交换合约示例，展示了接口调用的实际应用：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 定义ERC20接口
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

// 简单的ERC20代币实现（用于演示）
contract SimpleToken is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _initialSupply * 10**decimals;
        _balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(_allowances[from][msg.sender] >= amount, "Insufficient allowance");
        require(_balances[from] >= amount, "Insufficient balance");
        
        _allowances[from][msg.sender] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}

// 代币交换合约（使用接口调用）
contract TokenSwap {
    // 声明两个代币接口变量
    IERC20 public tokenA;
    IERC20 public tokenB;
    
    // 交换事件：记录每次交换的详细信息
    event Swap(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    
    // 构造函数：初始化代币合约地址
    constructor(address _tokenA, address _tokenB) {
        // 将地址转换为接口类型
        // 这样编译器会检查这些地址对应的合约是否实现了接口中的函数
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }
    
    /**
     * @notice 执行代币交换
     * @param amountA 要交换的tokenA数量
     * @dev 用户需要先调用tokenA的approve函数授权本合约使用其代币
     */
    function swap(uint256 amountA) external {
        // 步骤1：检查合约是否有足够的tokenB用于交换
        // 使用接口的view函数查询余额，不消耗Gas
        uint256 contractBalanceB = tokenB.balanceOf(address(this));
        require(contractBalanceB >= amountA, "Insufficient tokenB in contract");
        
        // 步骤2：从用户账户转移tokenA到本合约
        // transferFrom需要用户先调用tokenA.approve授权本合约
        // 如果转账失败，require会回滚整个交易
        require(
            tokenA.transferFrom(msg.sender, address(this), amountA),
            "TokenA transfer failed"
        );
        
        // 步骤3：从本合约向用户转移tokenB
        // 简化示例：1:1兑换比例
        uint256 amountB = amountA;
        require(
            tokenB.transfer(msg.sender, amountB),
            "TokenB transfer failed"
        );
        
        // 步骤4：触发事件，记录交换信息
        // 前端应用可以监听这个事件来更新UI
        emit Swap(msg.sender, address(tokenA), address(tokenB), amountA, amountB);
    }
    
    /**
     * @notice 查询合约持有的代币余额
     * @return balanceA 合约持有的tokenA数量
     * @return balanceB 合约持有的tokenB数量
     */
    function getContractBalances() 
        external 
        view 
        returns (uint256 balanceA, uint256 balanceB) 
    {
        // 使用接口的view函数查询余额
        // view函数不修改状态，外部调用不消耗Gas
        balanceA = tokenA.balanceOf(address(this));
        balanceB = tokenB.balanceOf(address(this));
    }
    
    /**
     * @notice 查询用户持有的代币余额
     * @param user 要查询的用户地址
     * @return balanceA 用户的tokenA余额
     * @return balanceB 用户的tokenB余额
     */
    function getUserBalances(address user) 
        external 
        view 
        returns (uint256 balanceA, uint256 balanceB) 
    {
        balanceA = tokenA.balanceOf(user);
        balanceB = tokenB.balanceOf(user);
    }
}
```
使用流程：

1. 部署代币合约：
```sol
SimpleToken tokenA = new SimpleToken("TokenA", "TKA", 1000000);
SimpleToken tokenB = new SimpleToken("TokenB", "TKB", 1000000);
```
2. 部署交换合约：
```sol
TokenSwap swap = new TokenSwap(address(tokenA), address(tokenB));
```
3. 准备交换池：
```sol
// 向交换合约转入tokenB作为交换池
tokenB.transfer(address(swap), 100000);
```
4. 用户授权：
```sol
// 用户授权交换合约使用其tokenA
tokenA.approve(address(swap), 1000);
```
5. 执行交换：
```sol
// 用户执行交换
swap.swap(1000);
```

# 3. 底层调用方法
除了接口调用，Solidity还提供了三种底层调用方法：call、delegatecall和staticcall。这三个方法功能强大但也更危险，需要谨慎使用。

## 3.1 call方法
call是最通用的底层调用方法，它可以调用任意合约的任意函数，甚至可以发送以太币。

call方法的特点：

* 可以发送以太币：这是call相比其他方法的独特优势
* 在被调用合约的上下文中执行：被调用的合约会使用它自己的storage、自己的余额
* 最通用的调用方式：当你不确定用哪种方法时，call通常是安全的选择

基本语法：
```sol
(bool success, bytes memory data) = address.call{value: amount}(
    abi.encodeWithSignature("functionName(type1,type2)", arg1, arg2)
);
```
参数说明：

* address：要调用的合约地址
* {value: amount}：可选，要发送的以太币数量（wei）
* abi.encodeWithSignature(...)：编码函数调用数据
* 返回值：success表示调用是否成功，data是返回的数据

完整示例：

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 被调用的目标合约
contract TargetContract {
    uint256 public value;
    address public sender;
    
    // 接收以太币的函数
    function setValue(uint256 _value) external payable {
        value = _value;
        sender = msg.sender;
    }
    
    // 普通函数
    function getValue() external view returns (uint256) {
        return value;
    }
}

// 调用者合约：使用call方法
contract CallerContract {
    // 使用call调用目标合约的函数
    function callSetValue(address target, uint256 newValue) external payable {
        // 使用call调用setValue函数，并发送以太币
        // abi.encodeWithSignature编码函数签名和参数
        (bool success, bytes memory data) = target.call{value: msg.value}(
            abi.encodeWithSignature("setValue(uint256)", newValue)
        );
        
        // 必须检查返回值，call失败不会自动revert
        require(success, "Call failed");
    }
    
    // 使用call调用view函数
    function callGetValue(address target) external view returns (uint256) {
        // 调用view函数，不发送以太币
        (bool success, bytes memory returnData) = target.call(
            abi.encodeWithSignature("getValue()")
        );
        
        require(success, "Call failed");
        
        // 解码返回值
        // abi.decode用于解码ABI编码的数据
        uint256 value = abi.decode(returnData, (uint256));
        return value;
    }
    
    // 使用call发送以太币（不调用函数）
    function sendEther(address payable recipient) external payable {
        // 直接向地址发送以太币，不调用任何函数
        (bool success, ) = recipient.call{value: msg.value}("");
        require(success, "Ether transfer failed");
    }
}
```
在上面的代码中：

* callSetValue使用call调用目标合约的函数并发送以太币
* callGetValue使用call调用view函数并解码返回值
* sendEther使用call直接发送以太币

call方法的执行上下文：
```sol
contract ContextExample {
    uint256 public callerValue;
    address public callerSender;
    
    function testCall(address target) external {
        // 调用目标合约的setValue函数
        (bool success, ) = target.call(
            abi.encodeWithSignature("setValue(uint256)", 42)
        );
        require(success, "Call failed");
        
        // 注意：callerValue和callerSender不会被修改
        // 因为setValue是在target合约的上下文中执行的
        // 它修改的是target合约的storage，不是本合约的
    }
}
```

## 3.2 delegatecall方法
delegatecall是一个特殊的方法，它的关键特点是在调用者的上下文中执行。

delegatecall的核心特点：

1. 在调用者的上下文中执行：

* 被调用的函数会修改调用者合约的storage
* 被调用的函数使用的是调用者合约的余额
* 但代码逻辑来自被调用的合约

2. msg.sender保持不变：

* 在delegatecall中，msg.sender仍然是原始调用者
* 这对于权限控制非常重要

3. 不能发送以太币：

* delegatecall不支持value参数
* 不能通过delegatecall发送以太币

基本语法：
```sol
(bool success, bytes memory data) = address.delegatecall(
    abi.encodeWithSignature("functionName(type1,type2)", arg1, arg2)
);
```
完整示例：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 逻辑合约：包含业务逻辑
contract LogicContract {
    // 注意：这些变量的存储位置必须与代理合约匹配
    uint256 public value;
    address public owner;
    
    // 设置值的函数
    function setValue(uint256 _value) external {
        // 这个函数会修改调用者合约的storage
        value = _value;
        owner = msg.sender;  // msg.sender是原始调用者，不是代理合约
    }
    
    // 获取值的函数
    function getValue() external view returns (uint256) {
        return value;
    }
}

// 代理合约：存储数据，通过delegatecall调用逻辑合约
contract ProxyContract {
    // 存储布局必须与LogicContract完全一致
    address public implementation;  // 逻辑合约地址
    uint256 public value;           // 与LogicContract的value对应
    address public owner;            // 与LogicContract的owner对应
    
    event Upgraded(address indexed newImplementation);
    
    // LogicContract先部署，然后得到这个合约的地址
    // 再部署ProxyContract时，将已经部署的LogicContract合约地址传进来
    constructor(address _implementation) {
        implementation = _implementation;
        owner = msg.sender;
    }
    
    // fallback函数：将所有调用转发到逻辑合约
    // fallback函数是一个特殊的函数(兜底函数),当调用ProxyContract.setValue时，当前合约没有这个setValue的函数，就会执行这个特殊函数
    // impl是已经部署的LogicContract合约地址，就会将调用ProxyContract.setValue的函数放在msg.data中，这样通过delegatecall的方式就可以调用
    // LogicContract.setValue方法了
    fallback() external payable {
        address impl = implementation;
        require(impl != address(0), "Implementation not set");
        
        // 使用delegatecall调用逻辑合约
        // 逻辑合约的代码会在本合约的上下文中执行
        (bool success, bytes memory returnData) = impl.delegatecall(msg.data);
        
        if (!success) {
            // 如果调用失败，回滚
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        
        // 返回数据
        assembly {
            return(add(returnData, 0x20), mload(returnData))
        }
    }
    
    // 升级函数：更换逻辑合约
    function upgrade(address newImplementation) external {
        require(msg.sender == owner, "Not owner");
        implementation = newImplementation;
        emit Upgraded(newImplementation);
    }
}
```
**delegatecall的执行流程：**
```sol
用户调用 ProxyContract.setValue(100)
    ↓
ProxyContract的fallback函数被触发
    ↓
delegatecall到 LogicContract.setValue(100)
    ↓
LogicContract的代码在ProxyContract的上下文中执行
    ↓
修改的是ProxyContract的value和owner（不是LogicContract的）
    ↓
msg.sender仍然是原始用户（不是ProxyContract）
```

## 3.3 staticcall方法

staticcall是最安全但功能最受限的调用方法。它的核心特点是保证不修改状态。

staticcall的核心特点：

1. 保证不修改状态：

* 如果被调用的函数尝试修改状态，调用会直接失败
* 只能调用view和pure函数

2. 只读查询：

* 非常适合调用view和pure函数
* 提供额外的安全保障

3. 不能发送以太币：

* staticcall不支持value参数

**基本语法**
```sol
(bool success, bytes memory data) = address.staticcall(
    abi.encodeWithSignature("functionName()")
);
```
**完整示例：**
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 目标合约
contract TargetContract {
    uint256 public value = 100;
    
    // view函数：可以读取状态
    function getValue() external view returns (uint256) {
        return value;
    }
    
    // 修改状态的函数
    function setValue(uint256 _value) external {
        value = _value;
    }
}

// 调用者合约：使用staticcall
contract StaticcallDemo {
    // 使用staticcall调用view函数（安全）
    function safeGetValue(address target) external view returns (uint256) {
        (bool success, bytes memory returnData) = target.staticcall(
            abi.encodeWithSignature("getValue()")
        );
        
        require(success, "Staticcall failed");
        
        // 解码返回值
        uint256 value = abi.decode(returnData, (uint256));
        return value;
    }
    
    // 尝试使用staticcall调用修改状态的函数（会失败）
    function unsafeSetValue(address target, uint256 newValue) external {
        // 这个调用会失败，因为setValue会修改状态
        (bool success, ) = target.staticcall(
            abi.encodeWithSignature("setValue(uint256)", newValue)
        );
        
        // success会是false，因为staticcall不允许修改状态
        require(success, "Staticcall failed: cannot modify state");
    }
}
```
**staticcall的安全保障：**
```sol
contract SecurityExample {
    // 使用staticcall确保不会意外修改状态
    function safeQuery(address target) external view returns (uint256) {
        (bool success, bytes memory data) = target.staticcall(
            abi.encodeWithSignature("getValue()")
        );
        
        require(success, "Query failed");
        
        // 即使target合约有恶意代码，也无法修改本合约的状态
        // staticcall保证了这一点
        return abi.decode(data, (uint256));
    }
}
```
## 3.4 三种方法的对比
让我们通过一个完整的对比示例来理解三种方法的区别：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 目标合约：用于演示三种调用方法的区别
contract Target {
    uint256 public value;
    address public sender;
    
    event ValueChanged(uint256 newValue, address caller);
    
    // 修改状态的函数
    function setValue(uint256 _value) external {
        value = _value;
        sender = msg.sender;
        emit ValueChanged(_value, msg.sender);
    }
    
    // 只读函数
    function getValue() external view returns (uint256) {
        return value;
    }
}

// 调用者合约：对比三种调用方法
contract Caller {
    // 本合约的状态变量
    uint256 public value;
    address public sender;
    
    event CallResult(string method, bool success, uint256 value, address sender);
    
    /**
     * @notice 使用call方法调用
     * @dev call在目标合约的上下文中执行，修改目标合约的状态
     */
    function testCall(address target, uint256 newValue) external {
        // 记录调用前的状态
        uint256 callerValueBefore = value;
        uint256 targetValueBefore = Target(target).value();
        
        // 使用call调用目标合约的setValue函数
        (bool success, ) = target.call(
            abi.encodeWithSignature("setValue(uint256)", newValue)
        );
        require(success, "Call failed");
        
        // 检查状态变化
        uint256 callerValueAfter = value;
        uint256 targetValueAfter = Target(target).value();
        
        // 结论：call修改了目标合约的状态，没有修改调用者的状态
        emit CallResult(
            "call",
            success,
            targetValueAfter,  // 目标合约的值被修改
            Target(target).sender()  // msg.sender是调用者合约
        );
    }
    
    /**
     * @notice 使用delegatecall方法调用
     * @dev delegatecall在调用者的上下文中执行，修改调用者的状态
     */
    function testDelegatecall(address target, uint256 newValue) external {
        // 记录调用前的状态
        uint256 callerValueBefore = value;
        uint256 targetValueBefore = Target(target).value();
        
        // 使用delegatecall调用目标合约的setValue函数
        (bool success, ) = target.delegatecall(
            abi.encodeWithSignature("setValue(uint256)", newValue)
        );
        require(success, "Delegatecall failed");
        
        // 检查状态变化
        uint256 callerValueAfter = value;
        uint256 targetValueAfter = Target(target).value();
        
        // 结论：delegatecall修改了调用者的状态，没有修改目标合约的状态
        emit CallResult(
            "delegatecall",
            success,
            callerValueAfter,  // 调用者的值被修改
            sender  // msg.sender是原始调用者（不是调用者合约）
        );
    }
    
    /**
     * @notice 使用staticcall方法调用
     * @dev staticcall只能调用view/pure函数，不能修改状态
     */
    function testStaticcall(address target) external view returns (uint256) {
        // 使用staticcall调用view函数
        (bool success, bytes memory returnData) = target.staticcall(
            abi.encodeWithSignature("getValue()")
        );
        require(success, "Staticcall failed");
        
        // 解码返回值
        uint256 value = abi.decode(returnData, (uint256));
        
        // 结论：staticcall只读取数据，不修改任何状态
        return value;
    }
}
```

对比表格：

|特性|call|delegatecall|staticcall|
|:--:|:--:|:--:|:--:|
|执行上下文|被调用合约|调用者合约|被调用合约|
|可发送以太币|是|否|否|
|可修改状态|是|是|否|
|msg.sender|调用者合约|原始调用者|调用者合约|
|适用场景|通用调用|代理模式|只读查询|
|安全性|中等|低（需谨慎）|高|

实际执行结果对比：

假设调用者合约调用testCall(target, 42)：
```sol
调用前：
- Caller.value = 0
- Target.value = 0

调用后（使用call）：
- Caller.value = 0（未改变）
- Target.value = 42（被修改）
- Target.sender = Caller地址
```

假设调用者合约调用testDelegatecall(target, 88)：

```sol
调用前：
- Caller.value = 0
- Target.value = 0

调用后（使用delegatecall）：
- Caller.value = 88（被修改！）
- Target.value = 0（未改变）
- Caller.sender = 原始用户地址（不是Caller地址）
```

## 3.5 选择正确的调用方法

根据不同的场景，选择合适的调用方法：

使用call的场景：

* 需要发送以太币
* 调用外部合约的普通函数
* 不确定使用哪种方法时的默认选择

使用delegatecall的场景：

* 代理模式（可升级合约）
* 库合约调用
* 需要保持msg.sender不变

使用staticcall的场景：

* 只读查询
* 调用view/pure函数
* 需要额外的安全保障


