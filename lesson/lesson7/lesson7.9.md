# 6. 实际应用场景

## 6.1 代币合约
代币合约是最常见的智能合约类型,需要严格的错误处理来保障资金安全。

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenContract {
    // 自定义错误
    error InsufficientBalance(address account, uint256 available, uint256 required);
    error InsufficientAllowance(address owner, address spender, uint256 available, uint256 required);
    error InvalidRecipient(address recipient);
    error InvalidAmount(uint256 amount);
    
    string public name = "MyToken";
    string public symbol = "MTK";
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
    }
    
    /**
     * @notice 转账代币
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        // 输入验证
        if (to == address(0)) revert InvalidRecipient(to);
        if (amount == 0) revert InvalidAmount(amount);
        
        // 状态检查
        if (balanceOf[msg.sender] < amount) {
            revert InsufficientBalance(msg.sender, balanceOf[msg.sender], amount);
        }
        
        // 执行转账
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    /**
     * @notice 授权第三方使用代币
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        if (spender == address(0)) revert InvalidRecipient(spender);
        
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    /**
     * @notice 从授权额度中转账
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        // 输入验证
        if (to == address(0)) revert InvalidRecipient(to);
        if (amount == 0) revert InvalidAmount(amount);
        
        // 余额检查
        if (balanceOf[from] < amount) {
            revert InsufficientBalance(from, balanceOf[from], amount);
        }
        
        // 授权检查
        if (allowance[from][msg.sender] < amount) {
            revert InsufficientAllowance(
                from,
                msg.sender,
                allowance[from][msg.sender],
                amount
            );
        }
        
        // 执行转账
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
}
```

## 6.2 拍卖合约
拍卖合约需要处理复杂的业务逻辑和时间限制,错误处理至关重要。

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AuctionContract {
    // 自定义错误
    error BidTooLow(uint256 currentBid, uint256 newBid);
    error AuctionEnded();
    error AuctionNotEnded();
    error NotHighestBidder();
    error WithdrawalFailed();
    error AlreadyWithdrawn();
    
    address public owner;
    uint256 public auctionEnd;
    uint256 public highestBid;
    address public highestBidder;
    
    mapping(address => uint256) public pendingReturns;
    mapping(address => bool) public hasWithdrawn;
    
    event NewBid(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);
    event Withdrawal(address indexed bidder, uint256 amount);
    
    constructor(uint256 _duration) {
        owner = msg.sender;
        auctionEnd = block.timestamp + _duration;
    }
    
    /**
     * @notice 出价函数
     */
    function bid() public payable {
        // 检查拍卖是否还在进行
        if (block.timestamp >= auctionEnd) {
            revert AuctionEnded();
        }
        
        // 检查出价是否高于当前最高价
        if (msg.value <= highestBid) {
            revert BidTooLow(highestBid, msg.value);
        }
        
        // 使用assert检查时间不变量
        assert(auctionEnd > block.timestamp);
        
        // 如果有之前的最高出价者,记录待退款
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }
        
        // 更新最高出价
        highestBidder = msg.sender;
        highestBid = msg.value;
        
        emit NewBid(msg.sender, msg.value);
    }
    
    /**
     * @notice 提取未中标的出价
     */
    function withdraw() public returns (bool) {
        // 检查是否有待退款
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "没有待退款");
        
        // 检查是否已经提取过
        if (hasWithdrawn[msg.sender]) {
            revert AlreadyWithdrawn();
        }
        
        // 先更新状态,防止重入攻击
        pendingReturns[msg.sender] = 0;
        hasWithdrawn[msg.sender] = true;
        
        // 使用try-catch处理转账
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            // 如果转账失败,恢复状态
            pendingReturns[msg.sender] = amount;
            hasWithdrawn[msg.sender] = false;
            revert WithdrawalFailed();
        }
        
        emit Withdrawal(msg.sender, amount);
        return true;
    }
    
    /**
     * @notice 结束拍卖（仅所有者）
     */
    function endAuction() public {
        require(msg.sender == owner, "只有所有者可以结束拍卖");
        
        if (block.timestamp < auctionEnd) {
            revert AuctionNotEnded();
        }
        
        emit AuctionEnded(highestBidder, highestBid);
        
        // 转账给所有者
        (bool success, ) = owner.call{value: highestBid}("");
        require(success, "转账失败");
    }
}
```
## 6.3 多签钱包
多签钱包需要处理多个签名者的协调和外部调用的异常。
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MultiSigWallet {
    // 自定义错误
    error NotOwner();
    error TxNotExists(uint256 txId);
    error TxAlreadyExecuted(uint256 txId);
    error TxAlreadyConfirmed(uint256 txId);
    error TxNotConfirmed(uint256 txId);
    error CannotExecute(uint256 txId);
    error ExecutionFailed(uint256 txId);
    
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required;
    
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
    }
    
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    
    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId);
    event Confirm(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);
    event ExecutionFailure(uint256 indexed txId, string reason);
    
    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }
    
    modifier txExists(uint256 _txId) {
        if (_txId >= transactions.length) revert TxNotExists(_txId);
        _;
    }
    
    modifier notExecuted(uint256 _txId) {
        if (transactions[_txId].executed) revert TxAlreadyExecuted(_txId);
        _;
    }
    
    modifier notConfirmed(uint256 _txId) {
        if (confirmations[_txId][msg.sender]) revert TxAlreadyConfirmed(_txId);
        _;
    }
    
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "所有者不能为空");
        require(
            _required > 0 && _required <= _owners.length,
            "无效的所需确认数"
        );
        
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "无效的所有者地址");
            require(!isOwner[owner], "所有者重复");
            
            isOwner[owner] = true;
            owners.push(owner);
        }
        
        required = _required;
    }
    
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @notice 提交交易
     */
    function submit(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner returns (uint256) {
        uint256 txId = transactions.length;
        
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            confirmations: 0
        }));
        
        emit Submit(txId);
        return txId;
    }
    
    /**
     * @notice 确认交易
     */
    function confirm(uint256 _txId)
        public
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
        notConfirmed(_txId)
    {
        confirmations[_txId][msg.sender] = true;
        transactions[_txId].confirmations += 1;
        
        emit Confirm(msg.sender, _txId);
    }
    
    /**
     * @notice 执行交易（使用try-catch处理外部调用）
     */
    function execute(uint256 _txId)
        public
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        
        // 检查确认数是否足够
        if (transaction.confirmations < required) {
            revert CannotExecute(_txId);
        }
        
        transaction.executed = true;
        
        // 使用try-catch处理外部调用
        (bool success, bytes memory returnData) = transaction.to.call{
            value: transaction.value
        }(transaction.data);
        
        if (success) {
            emit Execute(_txId);
        } else {
            // 执行失败,恢复状态
            transaction.executed = false;
            
            // 提取失败原因
            string memory reason;
            if (returnData.length > 0) {
                assembly {
                    reason := mload(add(returnData, 0x20))
                }
            } else {
                reason = "Unknown error";
            }
            
            emit ExecutionFailure(_txId, reason);
            revert ExecutionFailed(_txId);
        }
    }
    
    /**
     * @notice 撤销确认
     */
    function revoke(uint256 _txId)
        public
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        if (!confirmations[_txId][msg.sender]) {
            revert TxNotConfirmed(_txId);
        }
        
        confirmations[_txId][msg.sender] = false;
        transactions[_txId].confirmations -= 1;
        
        emit Revoke(msg.sender, _txId);
    }
}
```

## 6.4 DeFi借贷协议
DeFi协议需要处理复杂的金融逻辑和多个外部合约调用。
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IPriceOracle {
    function getPrice(address token) external view returns (uint256);
}

contract LendingProtocol {
    // 自定义错误
    error InsufficientCollateral(uint256 provided, uint256 required);
    error LoanNotFound(uint256 loanId);
    error Unauthorized();
    error TokenTransferFailed();
    error PriceOracleFailed();
    error CollateralRatioTooLow();
    
    struct Loan {
        address borrower;
        address collateralToken;
        address borrowToken;
        uint256 collateralAmount;
        uint256 borrowAmount;
        bool active;
    }
    
    mapping(uint256 => Loan) public loans;
    uint256 public loanCount;
    
    IPriceOracle public priceOracle;
    uint256 public constant COLLATERAL_RATIO = 150; // 150%
    
    event LoanCreated(uint256 indexed loanId, address indexed borrower);
    event LoanRepaid(uint256 indexed loanId);
    event CollateralLiquidated(uint256 indexed loanId);
    
    constructor(address _priceOracle) {
        priceOracle = IPriceOracle(_priceOracle);
    }
    
    /**
     * @notice 创建贷款
     */
    function createLoan(
        address collateralToken,
        address borrowToken,
        uint256 collateralAmount,
        uint256 borrowAmount
    ) public returns (uint256) {
        // 获取价格（使用try-catch处理预言机调用）
        uint256 collateralPrice;
        uint256 borrowPrice;
        
        try priceOracle.getPrice(collateralToken) returns (uint256 price) {
            collateralPrice = price;
        } catch {
            revert PriceOracleFailed();
        }
        
        try priceOracle.getPrice(borrowToken) returns (uint256 price) {
            borrowPrice = price;
        } catch {
            revert PriceOracleFailed();
        }
        
        // 计算抵押价值
        uint256 collateralValue = collateralAmount * collateralPrice;
        uint256 borrowValue = borrowAmount * borrowPrice;
        uint256 requiredCollateral = (borrowValue * COLLATERAL_RATIO) / 100;
        
        // 检查抵押率
        if (collateralValue < requiredCollateral) {
            revert InsufficientCollateral(collateralValue, requiredCollateral);
        }
        
        // 转移抵押物（使用try-catch）
        try IERC20(collateralToken).transferFrom(
            msg.sender,
            address(this),
            collateralAmount
        ) returns (bool success) {
            if (!success) revert TokenTransferFailed();
        } catch {
            revert TokenTransferFailed();
        }
        
        // 创建贷款
        uint256 loanId = loanCount++;
        loans[loanId] = Loan({
            borrower: msg.sender,
            collateralToken: collateralToken,
            borrowToken: borrowToken,
            collateralAmount: collateralAmount,
            borrowAmount: borrowAmount,
            active: true
        });
        
        // 发放借款
        try IERC20(borrowToken).transfer(msg.sender, borrowAmount) returns (bool success) {
            if (!success) {
                // 如果借款发放失败,退还抵押物
                IERC20(collateralToken).transfer(msg.sender, collateralAmount);
                revert TokenTransferFailed();
            }
        } catch {
            // 如果借款发放失败,退还抵押物
            IERC20(collateralToken).transfer(msg.sender, collateralAmount);
            revert TokenTransferFailed();
        }
        
        emit LoanCreated(loanId, msg.sender);
        return loanId;
    }
    
    /**
     * @notice 偿还贷款
     */
    function repayLoan(uint256 loanId) public {
        Loan storage loan = loans[loanId];
        
        // 检查贷款是否存在且活跃
        if (!loan.active) revert LoanNotFound(loanId);
        if (loan.borrower != msg.sender) revert Unauthorized();
        
        // 收回借款
        try IERC20(loan.borrowToken).transferFrom(
            msg.sender,
            address(this),
            loan.borrowAmount
        ) returns (bool success) {
            if (!success) revert TokenTransferFailed();
        } catch {
            revert TokenTransferFailed();
        }
        
        // 返还抵押物
        try IERC20(loan.collateralToken).transfer(
            loan.borrower,
            loan.collateralAmount
        ) returns (bool success) {
            if (!success) {
                // 如果返还失败,退回借款
                IERC20(loan.borrowToken).transfer(msg.sender, loan.borrowAmount);
                revert TokenTransferFailed();
            }
        } catch {
            // 如果返还失败,退回借款
            IERC20(loan.borrowToken).transfer(msg.sender, loan.borrowAmount);
            revert TokenTransferFailed();
        }
        
        loan.active = false;
        emit LoanRepaid(loanId);
    }
}
```

# 7. 常见错误与注意事项

在使用错误处理机制时,开发者经常会遇到一些陷阱。了解这些常见错误可以帮助你避免类似问题。

## 7.1 忘记检查条件
这是最常见也是最危险的错误之一。
```sol
contract ForgottenCheck {
    mapping(address => uint256) public balances;
    
    // ❌ 危险：没有检查余额就执行转账
    function badTransfer(address to, uint256 amount) public {
        // 直接执行转移,没有检查余额
        balances[msg.sender] -= amount;  // 可能导致整数下溢
        balances[to] += amount;
    }
    
    // ✅ 正确：先检查余额
    function goodTransfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "余额不足");
        require(to != address(0), "无效地址");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
```
实际案例： 某些早期的ERC20代币合约由于没有充分检查余额,导致用户可以转账超过自己余额的代币,造成严重的安全问题。

## 7.2 使用assert而非require
在应该使用require的地方错误地使用assert。
```sol
contract WrongAssertUsage {
    mapping(address => uint256) public balances;
    
    // ❌ 错误：用assert检查用户输入
    function badWithdraw(uint256 amount) public {
        assert(balances[msg.sender] >= amount);  // 错误：消耗全部Gas
        
        balances[msg.sender] -= amount;
    }
    
    // ✅ 正确：用require检查用户输入
    function goodWithdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "余额不足");  // 正确：只消耗部分Gas
        
        balances[msg.sender] -= amount;
    }
    
    // ✅ 正确：用assert检查不变量
    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "余额不足");
        
        uint256 totalBefore = balances[msg.sender] + balances[to];
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        // 检查不变量：总和应该保持不变
        assert(balances[msg.sender] + balances[to] == totalBefore);
    }
}
```
Gas对比：

* require失败：退还未使用的Gas
* assert失败：消耗全部Gas（可能是用户余额的全部）


## 7.3 错误消息不明确
不清晰的错误消息会让调试变得困难。
```sol
contract UnclearErrors {
    mapping(address => uint256) public balances;
    uint256 public maxTransfer = 1000;
    
    // ❌ 不好：错误消息不明确
    function badTransfer(address to, uint256 amount) public {
        require(to != address(0));  // 没有消息
        require(amount > 0);  // 没有消息
        require(balances[msg.sender] >= amount, "Error");  // 太笼统
        require(amount <= maxTransfer, "Failed");  // 不够具体
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    
    // ✅ 好：清晰的错误消息
    function goodTransfer(address to, uint256 amount) public {
        require(to != address(0), "接收地址不能为零地址");
        require(amount > 0, "转账金额必须大于0");
        require(balances[msg.sender] >= amount, "余额不足");
        require(amount <= maxTransfer, "转账金额超过限制");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    
    // ✅ 更好：使用自定义错误
    error InvalidRecipient(address recipient);
    error InvalidAmount(uint256 amount);
    error InsufficientBalance(uint256 available, uint256 required);
    error ExceedsMaxTransfer(uint256 amount, uint256 maximum);
    
    function bestTransfer(address to, uint256 amount) public {
        if (to == address(0)) revert InvalidRecipient(to);
        if (amount == 0) revert InvalidAmount(amount);
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(balances[msg.sender], amount);
        }
        if (amount > maxTransfer) {
            revert ExceedsMaxTransfer(amount, maxTransfer);
        }
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
```

## 7.4 不恰当的try-catch使用
try-catch有特定的使用场景,不能滥用。
```sol
contract ImproperTryCatch {
    // ❌ 错误：try-catch不能用于当前合约的内部函数
    function badInternalCall() public {
        // try this.internalFunction() {  // 编译错误
        //     // ...
        // } catch {
        //     // ...
        // }
    }
    
    function internalFunction() internal pure returns (uint256) {
        return 42;
    }
    
    // ❌ 错误：try-catch不能用于public函数的内部调用
    function badPublicCall() public {
        // try this.publicFunction() {  // 虽然能编译,但会失败
        //     // ...
        // } catch {
        //     // ...
        // }
    }
    
    function publicFunction() public pure returns (uint256) {
        return 42;
    }
    
    // ✅ 正确：try-catch用于外部合约调用
    interface IExternal {
        function doSomething() external returns (bool);
    }
    
    IExternal public externalContract;
    
    function goodExternalCall() public {
        try externalContract.doSomething() returns (bool success) {
            // 处理成功
        } catch {
            // 处理失败
        }
    }
}
```
## 7.5 忽略函数返回值
某些函数返回bool值表示成功或失败,不检查返回值可能导致问题。
```sol
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract ReturnValueHandling {
    IERC20 public token;
    
    // ❌ 危险：忽略返回值
    function badTransfer(address to, uint256 amount) public {
        token.transfer(to, amount);  // 如果失败了呢?
        // 代码继续执行,好像转账成功了
    }
    
    // ✅ 正确：检查返回值
    function goodTransfer(address to, uint256 amount) public {
        bool success = token.transfer(to, amount);
        require(success, "代币转账失败");
    }
    
    // ✅ 更好：使用try-catch
    function bestTransfer(address to, uint256 amount) public {
        try token.transfer(to, amount) returns (bool success) {
            require(success, "代币转账返回false");
        } catch {
            revert("代币转账失败");
        }
    }
}
```
## 7.6 重入攻击漏洞
不正确的错误处理顺序可能导致重入攻击。

```sol
contract ReentrancyVulnerability {
    mapping(address => uint256) public balances;
    
    // ❌ 危险：外部调用在状态更新之前
    function vulnerableWithdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "余额不足");
        
        // 危险：先进行外部调用
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "转账失败");
        
        // 状态更新在外部调用之后（重入风险）
        balances[msg.sender] -= amount;
    }
    
    // ✅ 安全：遵循CEI模式
    function safeWithdraw(uint256 amount) public {
        // 1. Checks
        require(balances[msg.sender] >= amount, "余额不足");
        
        // 2. Effects (先更新状态)
        balances[msg.sender] -= amount;
        
        // 3. Interactions (然后进行外部调用)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "转账失败");
    }
}
```
## 7.7 Gas限制问题
过长的错误消息或复杂的catch块可能导致Gas不足。
```sol
contract GasLimitIssues {
    // ❌ 不好：错误消息过长
    function badError() public pure {
        require(
            false,
            "This is an extremely long error message that contains way too much information and will consume a lot of gas. You should avoid writing such long error messages because they increase the transaction cost significantly and provide diminishing returns in terms of usefulness."
        );
    }
    
    // ✅ 好：简洁的错误消息
    function goodError() public pure {
        require(false, "操作失败");
    }
    
    // ✅ 更好：使用自定义错误
    error OperationFailed(uint256 code);
    
    function bestError() public pure {
        revert OperationFailed(1);
    }
    
    // ❌ 不好：catch块中有复杂逻辑
    interface IExternal {
        function doSomething() external;
    }
    
    IExternal public externalContract;
    
    function badCatch() public {
        try externalContract.doSomething() {
            // ...
        } catch {
            // 复杂的循环可能超出Gas限制
            for (uint256 i = 0; i < 1000; i++) {
                // 大量计算...
            }
        }
    }
    
    // ✅ 好：catch块保持简单
    event ErrorOccurred();
    
    function goodCatch() public {
        try externalContract.doSomething() {
            // ...
        } catch {
            emit ErrorOccurred();
            // 简单的错误处理
        }
    }
}
```
## 7.8 注意事项总结
1. 始终检查输入：

* 验证所有外部输入
* 检查地址是否为零地址
* 检查数值是否在有效范围内
* 检查数组长度是否匹配

2. 选择正确的错误机制：

* require：用于输入验证和条件检查
* assert：用于不变量检查
* revert：用于复杂的错误处理
* 自定义错误：优先使用以节省Gas

3. 遵循Checks-Effects-Interactions模式：

* Checks：检查所有条件
* Effects：更新状态
* Interactions：进行外部调用

4. 使用try-catch处理外部调用：

* 只用于外部合约调用
* 不要嵌套过深
* 保持catch块简单

5. 提供清晰的错误信息：

* 使用描述性的错误消息
* 避免过长的消息
* 考虑使用自定义错误

6. 测试所有错误路径：

* 测试正常情况
* 测试所有错误情况
* 测试边界条件































