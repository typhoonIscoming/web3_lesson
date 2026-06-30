# 5. 扩展功能：Mint和Burn

## 5.1 Mint - 铸造代币

Mint（铸造）功能用于增加代币供应量，创造新的代币。

函数实现：
```sol
function mint(address to, uint256 amount) public onlyOwner {
    // 1. 检查接收地址
    require(to != address(0), "Cannot mint to zero address");
    
    // 2. 增加总供应量
    totalSupply += amount;
    
    // 3. 增加接收者余额
    balanceOf[to] += amount;
    
    // 4. 触发Transfer事件（from为零地址）
    emit Transfer(address(0), to, amount);
}
```
Mint的特点：

1. 增加总供应：totalSupply += amount
2. 凭空创造：代币从零地址"铸造"出来
3. 需要权限：通常只有owner可以铸造
4. from为零地址：Transfer(address(0), to, amount)

使用场景：

**场景1：稳定币发行（USDC）**
```sol
用户存入100美元到Circle
    ↓
Circle调用mint函数
    ↓
铸造100个USDC给用户
    ↓
totalSupply增加100
```

**场景2：游戏代币奖励**
```sol
玩家完成任务
    ↓
游戏合约调用mint
    ↓
铸造奖励代币给玩家
```

**场景3：流动性挖矿**
```sol
用户质押LP代币
    ↓
挖矿合约定期mint
    ↓
铸造收益代币给用户
```

**场景4：社区激励**
```sol
用户贡献内容
    ↓
DAO投票通过奖励
    ↓
铸造代币给贡献者
```

## 5.2 Burn - 销毁代币
Burn（销毁）功能用于减少代币供应量，永久销毁代币。

函数实现：
```sol
function burn(uint256 amount) public {
    // 1. 检查余额
    require(balanceOf[msg.sender] >= amount, "Insufficient balance to burn");
    
    // 2. 减少总供应量
    totalSupply -= amount;
    
    // 3. 减少调用者余额
    balanceOf[msg.sender] -= amount;
    
    // 4. 触发Transfer事件（to为零地址）
    emit Transfer(msg.sender, address(0), amount);
}
```
Burn的特点：

1. 减少总供应：totalSupply -= amount
2. 永久消失：代币发送到零地址，无法恢复
3. 任何人可调用：通常不需要权限（销毁自己的代币）
4. to为零地址：Transfer(msg.sender, address(0), amount)

使用场景：

**场景1：稳定币赎回（USDC）**
```sol
用户赎回100美元
    ↓
调用burn销毁100个USDC
    ↓
Circle发送100美元给用户
    ↓
totalSupply减少100
```

**场景2：通缩机制**
```sol
每笔转账收取1%手续费
    ↓
手续费自动burn
    ↓
代币越来越稀缺
    ↓
理论上价值增加
```

**场景3：购买服务**
```sol
用户用代币购买NFT
    ↓
代币被burn销毁
    ↓
用户获得NFT
    ↓
代币总量减少
```

**场景4：回购销毁**
```sol
项目方回购代币
    ↓
调用burn销毁
    ↓
减少市场供应
    ↓
提升代币价值
```

## 5.3 Mint vs Burn对比

|特性|Mint（铸造）|Burn（销毁）|
|:--:|:--:|:--:|
|总供应|增加|减少|
|权限要求|需要（onlyOwner）|不需要（任何人）|
|Transfer事件|from = address(0)|to = address(0)|
|可逆性|可逆（可以burn）|不可逆（永久消失）|
|安全风险|滥发导致通胀|误操作无法恢复|
|典型用途|发行、奖励、质押收益|回购、销毁、赎回、通缩|

完整代码示例：
```sol
contract TokenWithMintBurn {
    string public name = "My Token";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    address public owner;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        totalSupply = _initialSupply * 10**decimals;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Zero address");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Zero address");
        
        allowance[msg.sender][spender] = amount;
        
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(from != address(0), "From zero");
        require(to != address(0), "To zero");
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
    
    // 铸造功能
    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        
        totalSupply += amount;
        balanceOf[to] += amount;
        
        emit Transfer(address(0), to, amount);
    }
    
    // 销毁功能
    function burn(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        
        emit Transfer(msg.sender, address(0), amount);
    }
}
```

# 6. 部署和测试

## 6.1 在Remix中部署
步骤1：创建合约文件

* 打开Remix IDE：https://remix.ethereum.org
* 在File Explorer中创建新文件：MyToken.sol
* 复制完整的合约代码到文件中[MyToken.sol 代码](./lesson5.1.md#4.1 合约结构设计)


步骤2：编译合约

1. 点击左侧的"Solidity Compiler"图标
2. 选择编译器版本：0.8.19或更高
3. 点击"Compile MyToken.sol"按钮
4. 确保没有错误，只有警告可以忽略

步骤3：准备部署参数

构造函数需要4个参数：

|参数|类型|示例值|说明|
|:--:|:--:|:--:|:--:|
|_name|string|"My Token"|代币名称（带引号）|
|_symbol|string|"MTK"|代币符号（带引号）|
|_decimals|uint8|18|小数位数（数字）|
|_initialSupply|uint256	1000|初始供应量（数字）|

注意：

* 字符串参数需要用引号："My Token"
* 数字参数不需要引号：18
* 实际总供应量 = _initialSupply × 10^18

步骤4：部署合约

1. 点击左侧的"Deploy & Run Transactions"图标

2. 环境选择：Remix VM (Shanghai)

3. 账户：使用默认的Account 0

4. 合约选择：MyToken

5. 在Deploy旁的输入框填入参数：

```sol
"My Token","MTK",18,1000
```
6. 点击"Deploy"按钮

7. 等待部署完成

步骤5：验证部署

部署成功后，在下方"Deployed Contracts"中可以看到合约实例。

点击展开合约，可以看到所有公开函数和变量：

* name: 返回"My Token"
* symbol: 返回"MTK"
* decimals: 返回18
* totalSupply: 返回1000000000000000000000（1000 × 10^18）
* owner: 返回部署者地址
* balanceOf: 输入地址查询余额















































