# 6. 事件的实际应用场景
现在让我们看看事件在实际项目中的具体应用。这些场景覆盖了大多数DApp开发中会遇到的情况。

## 6.1 代币转账追踪
这是最经典的应用场景。ERC20代币合约通过Transfer事件记录所有转账操作，使得钱包和区块链浏览器能够追踪代币流动。

**ERC20标准的Transfer事件：**
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ERC20Token {
    string public name = "My Token";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    // Transfer事件：记录所有代币转移
    event Transfer(
        address indexed from,      // 发送方（铸造时为address(0)）
        address indexed to,        // 接收方（销毁时为address(0)）
        uint256 value              // 转账金额
    );
    
    // Approval事件：记录授权操作
    event Approval(
        address indexed owner,     // 代币所有者
        address indexed spender,   // 被授权者
        uint256 value              // 授权金额
    );
    
    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply * 10**decimals;
        balanceOf[msg.sender] = totalSupply;
        
        // 铸造时触发Transfer事件，from为address(0)
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    // 转账函数
    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        // 触发Transfer事件
        emit Transfer(msg.sender, to, amount);
        
        return true;
    }
    
    // 授权函数
    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Invalid spender");
        
        allowance[msg.sender][spender] = amount;
        
        // 触发Approval事件
        emit Approval(msg.sender, spender, amount);
        
        return true;
    }
    
    // 授权转账函数
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(from != address(0), "Invalid sender");
        require(to != address(0), "Invalid recipient");
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        
        // 触发Transfer事件
        emit Transfer(from, to, amount);
        
        return true;
    }
    
    // 铸造函数（仅为演示）
    function mint(address to, uint256 amount) public {
        require(to != address(0), "Invalid recipient");
        
        totalSupply += amount;
        balanceOf[to] += amount;
        
        // 铸造时from为address(0)
        emit Transfer(address(0), to, amount);
    }
    
    // 销毁函数
    function burn(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        
        // 销毁时to为address(0)
        emit Transfer(msg.sender, address(0), amount);
    }
}
```
Transfer事件的设计精妙之处：

1. from和to都是indexed：

* 可以高效查询某地址发送的所有转账
* 可以高效查询某地址接收的所有转账
* 支持多维度查询

2. 使用address(0)表示特殊操作：

* from为address(0)表示铸造（凭空创建代币）
* to为address(0)表示销毁（代币消失）
* 保持接口的一致性

3. value不indexed：

* 转账金额很少用于查询
* 节省一个indexed位置给更重要的参数

**前端应用示例：钱包余额追踪：**
```js
// 钱包应用监听用户的代币变化
class TokenWallet {
    constructor(provider, tokenAddress, tokenABI, userAddress) {
        this.contract = new ethers.Contract(tokenAddress, tokenABI, provider);
        this.userAddress = userAddress;
        this.balance = ethers.BigNumber.from(0);
    }
    
    async start() {
        // 获取初始余额
        await this.updateBalance();
        
        // 监听接收转账
        this.contract.on(
            this.contract.filters.Transfer(null, this.userAddress),
            async (from, to, value, event) => {
                console.log(`💰 收到 ${ethers.utils.formatEther(value)} MTK`);
                console.log(`   来自: ${from}`);
                console.log(`   交易: ${event.transactionHash}`);
                
                await this.updateBalance();
                this.notifyUser(`收到 ${ethers.utils.formatEther(value)} MTK`);
            }
        );
        
        // 监听发送转账
        this.contract.on(
            this.contract.filters.Transfer(this.userAddress, null),
            async (from, to, value, event) => {
                console.log(`💸 发送 ${ethers.utils.formatEther(value)} MTK`);
                console.log(`   到: ${to}`);
                console.log(`   交易: ${event.transactionHash}`);
                
                await this.updateBalance();
                this.notifyUser(`发送 ${ethers.utils.formatEther(value)} MTK`);
            }
        );
        
        console.log(`钱包已启动，监听地址: ${this.userAddress}`);
    }
    
    async updateBalance() {
        const balance = await this.contract.balanceOf(this.userAddress);
        this.balance = balance;
        console.log(`当前余额: ${ethers.utils.formatEther(balance)} MTK`);
        
        // 更新UI
        // document.getElementById('balance').innerText = ethers.utils.formatEther(balance);
    }
    
    async getTransactionHistory(fromBlock = 0) {
        // 获取所有与用户相关的转账
        const sentFilter = this.contract.filters.Transfer(this.userAddress, null);
        const receivedFilter = this.contract.filters.Transfer(null, this.userAddress);
        
        const [sentEvents, receivedEvents] = await Promise.all([
            this.contract.queryFilter(sentFilter, fromBlock, 'latest'),
            this.contract.queryFilter(receivedFilter, fromBlock, 'latest')
        ]);
        
        // 合并并排序
        const allEvents = [...sentEvents, ...receivedEvents]
            .sort((a, b) => {
                if (a.blockNumber !== b.blockNumber) {
                    return a.blockNumber - b.blockNumber;
                }
                return a.logIndex - b.logIndex;
            });
        
        // 格式化交易历史
        return allEvents.map(event => ({
            type: event.args.from.toLowerCase() === this.userAddress.toLowerCase() 
                ? 'sent' : 'received',
            from: event.args.from,
            to: event.args.to,
            value: ethers.utils.formatEther(event.args.value),
            blockNumber: event.blockNumber,
            transactionHash: event.transactionHash,
            timestamp: null  // 需要额外查询区块时间戳
        }));
    }
    
    notifyUser(message) {
        // 在实际应用中，这里可以发送推送通知
        console.log(`📱 通知: ${message}`);
    }
}

// 使用示例
const provider = new ethers.providers.JsonRpcProvider('http://localhost:8545');
const tokenAddress = '0x...';
const tokenABI = [...];
const userAddress = '0xYourAddress';

const wallet = new TokenWallet(provider, tokenAddress, tokenABI, userAddress);
wallet.start();

// 获取交易历史
const history = await wallet.getTransactionHistory();
console.log('交易历史:', history);
```

## 6.2 NFT市场交易
NFT（非同质化代币）市场使用事件来追踪NFT的铸造、转移、挂单、成交等所有操作。

NFT市场合约示例：

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract NFTMarketplace {
    // NFT转移事件（ERC721标准）
    event Transfer(
        address indexed from,      // 发送方
        address indexed to,        // 接收方
        uint256 indexed tokenId    // NFT ID
    );
    
    // NFT授权事件
    event Approval(
        address indexed owner,     // NFT所有者
        address indexed approved,  // 被授权地址
        uint256 indexed tokenId    // NFT ID
    );
    
    // NFT挂单事件
    event NFTListed(
        uint256 indexed tokenId,      // NFT ID
        address indexed seller,       // 卖家地址
        uint256 price,                // 挂单价格
        uint256 timestamp             // 挂单时间
    );
    
    // NFT成交事件
    event NFTSold(
        uint256 indexed tokenId,      // NFT ID
        address indexed seller,       // 卖家地址
        address indexed buyer,        // 买家地址
        uint256 price,                // 成交价格
        uint256 fee,                  // 平台手续费
        uint256 timestamp             // 成交时间
    );
    
    // NFT取消挂单事件
    event NFTDelisted(
        uint256 indexed tokenId,      // NFT ID
        address indexed seller,       // 卖家地址
        uint256 timestamp             // 取消时间
    );
    
    // 价格更新事件
    event PriceUpdated(
        uint256 indexed tokenId,      // NFT ID
        address indexed seller,       // 卖家地址
        uint256 oldPrice,             // 旧价格
        uint256 newPrice,             // 新价格
        uint256 timestamp             // 更新时间
    );
    
    // 数据结构
    struct Listing {
        address seller;
        uint256 price;
        bool active;
    }
    
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => Listing) public listings;
    
    uint256 public feeRate = 25;  // 2.5%手续费
    
    // 铸造NFT
    function mint(address to, uint256 tokenId) public {
        require(ownerOf[tokenId] == address(0), "Token already minted");
        
        ownerOf[tokenId] = to;
        
        // 触发Transfer事件（from为address(0)表示铸造）
        emit Transfer(address(0), to, tokenId);
    }
    
    // 挂单出售NFT
    function listNFT(uint256 tokenId, uint256 price) public {
        require(ownerOf[tokenId] == msg.sender, "Not token owner");
        require(price > 0, "Price must be greater than zero");
        require(!listings[tokenId].active, "Already listed");
        
        listings[tokenId] = Listing({
            seller: msg.sender,
            price: price,
            active: true
        });
        
        // 触发挂单事件
        emit NFTListed(tokenId, msg.sender, price, block.timestamp);
    }
    
    // 购买NFT
    function buyNFT(uint256 tokenId) public payable {
        Listing memory listing = listings[tokenId];
        
        require(listing.active, "NFT not listed");
        require(msg.value == listing.price, "Incorrect payment amount");
        require(ownerOf[tokenId] == listing.seller, "Seller no longer owns token");
        
        address seller = listing.seller;
        uint256 price = listing.price;
        
        // 计算手续费
        uint256 fee = (price * feeRate) / 1000;
        uint256 sellerAmount = price - fee;
        
        // 转移NFT所有权
        ownerOf[tokenId] = msg.sender;
        
        // 删除挂单
        delete listings[tokenId];
        
        // 转账给卖家
        payable(seller).transfer(sellerAmount);
        
        // 触发Transfer事件
        emit Transfer(seller, msg.sender, tokenId);
        
        // 触发成交事件
        emit NFTSold(tokenId, seller, msg.sender, price, fee, block.timestamp);
    }
    
    // 取消挂单
    function delistNFT(uint256 tokenId) public {
        require(listings[tokenId].seller == msg.sender, "Not the seller");
        require(listings[tokenId].active, "Not listed");
        
        delete listings[tokenId];
        
        // 触发取消挂单事件
        emit NFTDelisted(tokenId, msg.sender, block.timestamp);
    }
    
    // 更新价格
    function updatePrice(uint256 tokenId, uint256 newPrice) public {
        require(listings[tokenId].seller == msg.sender, "Not the seller");
        require(listings[tokenId].active, "Not listed");
        require(newPrice > 0, "Price must be greater than zero");
        
        uint256 oldPrice = listings[tokenId].price;
        listings[tokenId].price = newPrice;
        
        // 触发价格更新事件
        emit PriceUpdated(tokenId, msg.sender, oldPrice, newPrice, block.timestamp);
    }
}
```
**前端应用示例：NFT市场界面：**
```sol
class NFTMarketplaceUI {
    constructor(provider, contractAddress, contractABI) {
        this.contract = new ethers.Contract(contractAddress, contractABI, provider);
    }
    
    // 监听所有市场活动
    monitorMarketplace() {
        // 监听新挂单
        this.contract.on("NFTListed", (tokenId, seller, price, timestamp, event) => {
            console.log(`🏷️  NFT #${tokenId} 已挂单`);
            console.log(`   卖家: ${seller}`);
            console.log(`   价格: ${ethers.utils.formatEther(price)} ETH`);
            
            // 更新UI：在市场页面显示新挂单
            this.addListingToUI(tokenId, seller, price);
        });
        
        // 监听成交
        this.contract.on("NFTSold", (tokenId, seller, buyer, price, fee, timestamp, event) => {
            console.log(`✅ NFT #${tokenId} 已售出`);
            console.log(`   卖家: ${seller}`);
            console.log(`   买家: ${buyer}`);
            console.log(`   成交价: ${ethers.utils.formatEther(price)} ETH`);
            console.log(`   手续费: ${ethers.utils.formatEther(fee)} ETH`);
            
            // 更新UI：从市场页面移除，在交易历史中添加
            this.removeListingFromUI(tokenId);
            this.addSaleToHistory(tokenId, seller, buyer, price);
            
            // 如果是当前用户卖出或买入，显示通知
            if (seller === this.userAddress) {
                this.showNotification(`你的NFT #${tokenId} 已售出`);
            } else if (buyer === this.userAddress) {
                this.showNotification(`你购买了NFT #${tokenId}`);
            }
        });
        
        // 监听取消挂单
        this.contract.on("NFTDelisted", (tokenId, seller, timestamp, event) => {
            console.log(`❌ NFT #${tokenId} 已取消挂单`);
            
            // 更新UI：从市场页面移除
            this.removeListingFromUI(tokenId);
        });
        
        // 监听价格更新
        this.contract.on("PriceUpdated", (tokenId, seller, oldPrice, newPrice, timestamp, event) => {
            console.log(`💰 NFT #${tokenId} 价格已更新`);
            console.log(`   从: ${ethers.utils.formatEther(oldPrice)} ETH`);
            console.log(`   到: ${ethers.utils.formatEther(newPrice)} ETH`);
            
            // 更新UI：更新价格显示
            this.updatePriceInUI(tokenId, newPrice);
        });
    }
    
    // 获取NFT的完整历史
    async getNFTHistory(tokenId) {
        // 查询Transfer事件
        const transferFilter = this.contract.filters.Transfer(null, null, tokenId);
        const transfers = await this.contract.queryFilter(transferFilter, 0, 'latest');
        
        // 查询挂单事件
        const listFilter = this.contract.filters.NFTListed(tokenId, null);
        const listings = await this.contract.queryFilter(listFilter, 0, 'latest');
        
        // 查询成交事件
        const saleFilter = this.contract.filters.NFTSold(tokenId, null, null);
        const sales = await this.contract.queryFilter(saleFilter, 0, 'latest');
        
        // 合并所有事件并按时间排序
        const allEvents = [
            ...transfers.map(e => ({ type: 'transfer', ...e })),
            ...listings.map(e => ({ type: 'listed', ...e })),
            ...sales.map(e => ({ type: 'sold', ...e }))
        ].sort((a, b) => a.blockNumber - b.blockNumber);
        
        return allEvents;
    }
    
    // 获取用户的NFT活动
    async getUserActivity(userAddress) {
        // 用户买入的NFT
        const buyFilter = this.contract.filters.NFTSold(null, null, userAddress);
        const purchases = await this.contract.queryFilter(buyFilter, 0, 'latest');
        
        // 用户卖出的NFT
        const sellFilter = this.contract.filters.NFTSold(null, userAddress, null);
        const sales = await this.contract.queryFilter(sellFilter, 0, 'latest');
        
        // 用户的挂单
        const listFilter = this.contract.filters.NFTListed(null, userAddress);
        const listings = await this.contract.queryFilter(listFilter, 0, 'latest');
        
        return {
            purchases: purchases.length,
            sales: sales.length,
            activeListings: listings.length,
            history: { purchases, sales, listings }
        };
    }
    
    // UI更新方法（示例）
    addListingToUI(tokenId, seller, price) {
        // 实际应用中更新DOM
        console.log(`UI: 添加挂单 #${tokenId}`);
    }
    
    removeListingFromUI(tokenId) {
        console.log(`UI: 移除挂单 #${tokenId}`);
    }
    
    addSaleToHistory(tokenId, seller, buyer, price) {
        console.log(`UI: 添加成交记录 #${tokenId}`);
    }
    
    updatePriceInUI(tokenId, newPrice) {
        console.log(`UI: 更新价格 #${tokenId}`);
    }
    
    showNotification(message) {
        console.log(`📱 通知: ${message}`);
    }
}

// 使用示例
const provider = new ethers.providers.WebSocketProvider('ws://localhost:8546');
const contractAddress = '0x...';
const contractABI = [...];

const marketplaceUI = new NFTMarketplaceUI(provider, contractAddress, contractABI);
marketplaceUI.monitorMarketplace();

// 查询特定NFT的历史
const nftHistory = await marketplaceUI.getNFTHistory(123);
console.log('NFT #123 的历史:', nftHistory);

// 查询用户活动
const userActivity = await marketplaceUI.getUserActivity('0xUserAddress...');
console.log('用户活动:', userActivity);
```
## 6.3 投票和治理系统
去中心化自治组织（DAO）使用事件来追踪提案、投票和执行过程，确保治理过程的透明性。

投票系统合约：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DAOGovernance {
    // 投票开始事件
    event ProposalCreated(
        uint256 indexed proposalId,    // 提案ID
        address indexed proposer,      // 提案者
        string description,            // 提案描述
        uint256 startTime,             // 开始时间
        uint256 endTime               // 结束时间
    );
    
    // 投票事件
    event Voted(
        uint256 indexed proposalId,    // 提案ID
        address indexed voter,         // 投票者
        bool indexed support,          // 是否支持（true=赞成，false=反对）
        uint256 votes,                 // 投票权重
        string reason                  // 投票理由（可选）
    );
    
    // 提案执行事件
    event ProposalExecuted(
        uint256 indexed proposalId,    // 提案ID
        bool indexed passed,           // 是否通过
        uint256 forVotes,              // 赞成票数
        uint256 againstVotes,          // 反对票数
        uint256 executionTime          // 执行时间
    );
    
    // 提案取消事件
    event ProposalCanceled(
        uint256 indexed proposalId,    // 提案ID
        address indexed canceler,      // 取消者
        string reason                  // 取消原因
    );
    
    // 投票权重变更事件
    event VotingPowerChanged(
        address indexed voter,         // 投票者
        uint256 oldPower,              // 旧权重
        uint256 newPower,              // 新权重
        uint256 timestamp              // 变更时间
    );
    
    struct Proposal {
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted;
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public votingPower;
    uint256 public proposalCount;
    
    uint256 public constant VOTING_PERIOD = 3 days;
    uint256 public constant QUORUM = 100;  // 最低投票数要求
    
    // 创建提案
    function createProposal(string memory description) public returns (uint256) {
        require(votingPower[msg.sender] > 0, "No voting power");
        
        uint256 proposalId = proposalCount++;
        Proposal storage proposal = proposals[proposalId];
        
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + VOTING_PERIOD;
        
        // 触发提案创建事件
        emit ProposalCreated(
            proposalId,
            msg.sender,
            description,
            proposal.startTime,
            proposal.endTime
        );
        
        return proposalId;
    }
    
    // 投票
    function vote(uint256 proposalId, bool support, string memory reason) public {
        Proposal storage proposal = proposals[proposalId];
        
        require(block.timestamp >= proposal.startTime, "Voting not started");
        require(block.timestamp <= proposal.endTime, "Voting ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(votingPower[msg.sender] > 0, "No voting power");
        
        uint256 votes = votingPower[msg.sender];
        proposal.hasVoted[msg.sender] = true;
        
        if (support) {
            proposal.forVotes += votes;
        } else {
            proposal.againstVotes += votes;
        }
        
        // 触发投票事件
        emit Voted(proposalId, msg.sender, support, votes, reason);
    }
    
    // 执行提案
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        
        require(block.timestamp > proposal.endTime, "Voting not ended");
        require(!proposal.executed, "Already executed");
        require(proposal.forVotes + proposal.againstVotes >= QUORUM, "Quorum not reached");
        
        proposal.executed = true;
        proposal.passed = proposal.forVotes > proposal.againstVotes;
        
        // 触发提案执行事件
        emit ProposalExecuted(
            proposalId,
            proposal.passed,
            proposal.forVotes,
            proposal.againstVotes,
            block.timestamp
        );
        
        // 如果提案通过，执行相应的操作
        if (proposal.passed) {
            // 执行提案内容...
        }
    }
    
    // 取消提案
    function cancelProposal(uint256 proposalId, string memory reason) public {
        Proposal storage proposal = proposals[proposalId];
        
        require(msg.sender == proposal.proposer, "Not proposer");
        require(!proposal.executed, "Already executed");
        require(block.timestamp <= proposal.endTime, "Voting ended");
        
        proposal.executed = true;
        proposal.passed = false;
        
        // 触发提案取消事件
        emit ProposalCanceled(proposalId, msg.sender, reason);
    }
    
    // 更新投票权重（仅为演示）
    function updateVotingPower(address voter, uint256 newPower) public {
        uint256 oldPower = votingPower[voter];
        votingPower[voter] = newPower;
        
        // 触发投票权重变更事件
        emit VotingPowerChanged(voter, oldPower, newPower, block.timestamp);
    }
}
```
前端应用示例：DAO治理界面：
```js
class DAOGovernanceUI {
    constructor(provider, contractAddress, contractABI) {
        this.contract = new ethers.Contract(contractAddress, contractABI, provider);
    }
    
    // 监听治理活动
    monitorGovernance() {
        // 监听新提案
        this.contract.on("ProposalCreated", (proposalId, proposer, description, startTime, endTime, event) => {
            console.log(`📝 新提案创建 #${proposalId}`);
            console.log(`   提案者: ${proposer}`);
            console.log(`   描述: ${description}`);
            console.log(`   投票期: ${new Date(startTime * 1000)} - ${new Date(endTime * 1000)}`);
            
            // 更新UI：添加新提案到列表
            this.addProposalToUI(proposalId, {
                proposer,
                description,
                startTime,
                endTime
            });
            
            // 发送通知
            this.showNotification(`新提案: ${description}`);
        });
        
        // 监听投票
        this.contract.on("Voted", (proposalId, voter, support, votes, reason, event) => {
            console.log(`🗳️  新投票 - 提案 #${proposalId}`);
            console.log(`   投票者: ${voter}`);
            console.log(`   立场: ${support ? '赞成' : '反对'}`);
            console.log(`   票数: ${votes.toString()}`);
            if (reason) {
                console.log(`   理由: ${reason}`);
            }
            
            // 更新UI：更新提案的投票统计
            this.updateVoteCount(proposalId, support, votes);
            
            // 如果是当前用户投票，显示确认
            if (voter === this.userAddress) {
                this.showNotification('你的投票已记录');
            }
        });
        
        // 监听提案执行
        this.contract.on("ProposalExecuted", (proposalId, passed, forVotes, againstVotes, executionTime, event) => {
            console.log(`✅ 提案 #${proposalId} 已执行`);
            console.log(`   结果: ${passed ? '通过' : '未通过'}`);
            console.log(`   赞成票: ${forVotes.toString()}`);
            console.log(`   反对票: ${againstVotes.toString()}`);
            
            // 更新UI：标记提案为已执行
            this.markProposalExecuted(proposalId, passed, forVotes, againstVotes);
            
            // 发送通知
            this.showNotification(
                `提案 #${proposalId} ${passed ? '通过' : '未通过'}`
            );
        });
        
        // 监听提案取消
        this.contract.on("ProposalCanceled", (proposalId, canceler, reason, event) => {
            console.log(`❌ 提案 #${proposalId} 已取消`);
            console.log(`   取消者: ${canceler}`);
            console.log(`   原因: ${reason}`);
            
            // 更新UI：标记提案为已取消
            this.markProposalCanceled(proposalId, reason);
        });
    }
    
    // 获取提案的完整投票历史
    async getProposalVotes(proposalId) {
        const filter = this.contract.filters.Voted(proposalId, null, null);
        const votes = await this.contract.queryFilter(filter, 0, 'latest');
        
        return votes.map(event => ({
            voter: event.args.voter,
            support: event.args.support,
            votes: event.args.votes.toString(),
            reason: event.args.reason,
            blockNumber: event.blockNumber,
            transactionHash: event.transactionHash
        }));
    }
    
    // 获取用户的投票历史
    async getUserVotingHistory(userAddress) {
        const filter = this.contract.filters.Voted(null, userAddress, null);
        const votes = await this.contract.queryFilter(filter, 0, 'latest');
        
        return votes.map(event => ({
            proposalId: event.args.proposalId.toString(),
            support: event.args.support,
            votes: event.args.votes.toString(),
            reason: event.args.reason,
            blockNumber: event.blockNumber
        }));
    }
    
    // 获取所有活跃提案
    async getActiveProposals() {
        const filter = this.contract.filters.ProposalCreated();
        const proposals = await this.contract.queryFilter(filter, 0, 'latest');
        
        const currentTime = Math.floor(Date.now() / 1000);
        
        return proposals
            .filter(event => {
                const endTime = event.args.endTime.toNumber();
                return endTime > currentTime;  // 投票期未结束
            })
            .map(event => ({
                proposalId: event.args.proposalId.toString(),
                proposer: event.args.proposer,
                description: event.args.description,
                startTime: event.args.startTime.toNumber(),
                endTime: event.args.endTime.toNumber(),
                blockNumber: event.blockNumber
            }));
    }
    
    // 分析治理参与度
    async analyzeGovernanceParticipation() {
        // 获取所有提案
        const proposalFilter = this.contract.filters.ProposalCreated();
        const proposals = await this.contract.queryFilter(proposalFilter, 0, 'latest');
        
        // 获取所有投票
        const voteFilter = this.contract.filters.Voted();
        const votes = await this.contract.queryFilter(voteFilter, 0, 'latest');
        
        // 统计
        const totalProposals = proposals.length;
        const totalVotes = votes.length;
        const uniqueVoters = new Set(votes.map(v => v.args.voter)).size;
        const avgVotesPerProposal = totalProposals > 0 ? totalVotes / totalProposals : 0;
        
        // 统计每个提案的投票数
        const votesPerProposal = {};
        votes.forEach(vote => {
            const id = vote.args.proposalId.toString();
            votesPerProposal[id] = (votesPerProposal[id] || 0) + 1;
        });
        
        return {
            totalProposals,
            totalVotes,
            uniqueVoters,
            avgVotesPerProposal: avgVotesPerProposal.toFixed(2),
            mostActiveProposal: Object.entries(votesPerProposal)
                .sort((a, b) => b[1] - a[1])[0]
        };
    }
    
    // UI更新方法
    addProposalToUI(proposalId, data) {
        console.log(`UI: 添加提案 #${proposalId}`);
    }
    
    updateVoteCount(proposalId, support, votes) {
        console.log(`UI: 更新提案 #${proposalId} 投票数`);
    }
    
    markProposalExecuted(proposalId, passed, forVotes, againstVotes) {
        console.log(`UI: 标记提案 #${proposalId} 为已执行`);
    }
    
    markProposalCanceled(proposalId, reason) {
        console.log(`UI: 标记提案 #${proposalId} 为已取消`);
    }
    
    showNotification(message) {
        console.log(`📱 通知: ${message}`);
    }
}

// 使用示例
const provider = new ethers.providers.WebSocketProvider('ws://localhost:8546');
const contractAddress = '0x...';
const contractABI = [...];

const governanceUI = new DAOGovernanceUI(provider, contractAddress, contractABI);
governanceUI.userAddress = '0xYourAddress';

// 开始监听
governanceUI.monitorGovernance();

// 查询提案投票
const proposalVotes = await governanceUI.getProposalVotes(1);
console.log('提案#1的投票:', proposalVotes);

// 查询用户投票历史
const userHistory = await governanceUI.getUserVotingHistory('0xUserAddress');
console.log('用户投票历史:', userHistory);

// 获取活跃提案
const activeProposals = await governanceUI.getActiveProposals();
console.log('活跃提案:', activeProposals);

// 分析参与度
const participation = await governanceUI.analyzeGovernanceParticipation();
console.log('治理参与度分析:', participation);
```
## 6.4 多签钱包
多签钱包（Multisig Wallet）使用事件来追踪交易的提交、确认和执行状态，确保多签流程的透明性和可追溯性。

多签钱包合约：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MultiSigWallet {
    // 交易提交事件
    event TransactionSubmitted(
        uint256 indexed transactionId,    // 交易ID
        address indexed submitter,        // 提交者
        address indexed to,               // 目标地址
        uint256 value,                    // 转账金额
        bytes data,                       // 调用数据
        uint256 timestamp                 // 提交时间
    );
    
    // 交易确认事件
    event TransactionConfirmed(
        uint256 indexed transactionId,    // 交易ID
        address indexed confirmer,        // 确认者
        uint256 confirmations,            // 当前确认数
        uint256 required,                 // 所需确认数
        uint256 timestamp                 // 确认时间
    );
    
    // 确认撤销事件
    event ConfirmationRevoked(
        uint256 indexed transactionId,    // 交易ID
        address indexed revoker,          // 撤销者
        uint256 confirmations,            // 当前确认数
        uint256 timestamp                 // 撤销时间
    );
    
    // 交易执行事件
    event TransactionExecuted(
        uint256 indexed transactionId,    // 交易ID
        address indexed executor,         // 执行者
        address indexed to,               // 目标地址
        uint256 value,                    // 转账金额
        bytes returnData,                 // 返回数据
        uint256 timestamp                 // 执行时间
    );
    
    // 交易失败事件
    event TransactionFailed(
        uint256 indexed transactionId,    // 交易ID
        address indexed executor,         // 执行者
        string reason,                    // 失败原因
        uint256 timestamp                 // 失败时间
    );
    
    // 所有者添加事件
    event OwnerAdded(
        address indexed owner,            // 新所有者
        address indexed addedBy,          // 添加者
        uint256 timestamp                 // 添加时间
    );
    
    // 所有者移除事件
    event OwnerRemoved(
        address indexed owner,            // 被移除的所有者
        address indexed removedBy,        // 移除者
        uint256 timestamp                 // 移除时间
    );
    
    // 所需确认数更新事件
    event RequiredConfirmationsChanged(
        uint256 oldRequired,              // 旧值
        uint256 newRequired,              // 新值
        address indexed changedBy,        // 修改者
        uint256 timestamp                 // 修改时间
    );
    
    // 存款事件
    event Deposit(
        address indexed sender,           // 存款者
        uint256 amount,                   // 存款金额
        uint256 balance,                  // 钱包余额
        uint256 timestamp                 // 存款时间
    );
    
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        mapping(address => bool) isConfirmed;
    }
    
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public requiredConfirmations;
    
    mapping(uint256 => Transaction) public transactions;
    uint256 public transactionCount;
    
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }
    
    constructor(address[] memory _owners, uint256 _requiredConfirmations) {
        require(_owners.length > 0, "Owners required");
        require(
            _requiredConfirmations > 0 && _requiredConfirmations <= _owners.length,
            "Invalid required confirmations"
        );
        
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner not unique");
            
            isOwner[owner] = true;
            owners.push(owner);
        }
        
        requiredConfirmations = _requiredConfirmations;
    }
    
    // 接收以太币
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance, block.timestamp);
    }
    
    // 提交交易
    function submitTransaction(
        address to,
        uint256 value,
        bytes memory data
    ) public onlyOwner returns (uint256) {
        uint256 transactionId = transactionCount++;
        
        Transaction storage transaction = transactions[transactionId];
        transaction.to = to;
        transaction.value = value;
        transaction.data = data;
        transaction.executed = false;
        transaction.confirmations = 0;
        
        // 触发交易提交事件
        emit TransactionSubmitted(
            transactionId,
            msg.sender,
            to,
            value,
            data,
            block.timestamp
        );
        
        return transactionId;
    }
    
    // 确认交易
    function confirmTransaction(uint256 transactionId) public onlyOwner {
        Transaction storage transaction = transactions[transactionId];
        
        require(!transaction.executed, "Transaction already executed");
        require(!transaction.isConfirmed[msg.sender], "Transaction already confirmed");
        
        transaction.isConfirmed[msg.sender] = true;
        transaction.confirmations++;
        
        // 触发确认事件
        emit TransactionConfirmed(
            transactionId,
            msg.sender,
            transaction.confirmations,
            requiredConfirmations,
            block.timestamp
        );
    }
    
    // 撤销确认
    function revokeConfirmation(uint256 transactionId) public onlyOwner {
        Transaction storage transaction = transactions[transactionId];
        
        require(!transaction.executed, "Transaction already executed");
        require(transaction.isConfirmed[msg.sender], "Transaction not confirmed");
        
        transaction.isConfirmed[msg.sender] = false;
        transaction.confirmations--;
        
        // 触发撤销确认事件
        emit ConfirmationRevoked(
            transactionId,
            msg.sender,
            transaction.confirmations,
            block.timestamp
        );
    }
    
    // 执行交易
    function executeTransaction(uint256 transactionId) public onlyOwner {
        Transaction storage transaction = transactions[transactionId];
        
        require(!transaction.executed, "Transaction already executed");
        require(
            transaction.confirmations >= requiredConfirmations,
            "Insufficient confirmations"
        );
        
        transaction.executed = true;
        
        // 执行交易
        (bool success, bytes memory returnData) = transaction.to.call{
            value: transaction.value
        }(transaction.data);
        
        if (success) {
            // 触发执行成功事件
            emit TransactionExecuted(
                transactionId,
                msg.sender,
                transaction.to,
                transaction.value,
                returnData,
                block.timestamp
            );
        } else {
            // 执行失败，恢复状态
            transaction.executed = false;
            
            // 提取失败原因
            string memory reason;
            if (returnData.length > 0) {
                assembly {
                    reason := add(returnData, 0x04)
                }
            } else {
                reason = "Transaction failed";
            }
            
            // 触发执行失败事件
            emit TransactionFailed(transactionId, msg.sender, reason, block.timestamp);
            
            revert(reason);
        }
    }
}
```
前端应用示例：多签钱包界面：
```js
class MultiSigWalletUI {
    constructor(provider, contractAddress, contractABI) {
        this.contract = new ethers.Contract(contractAddress, contractABI, provider);
    }
    
    // 监听多签钱包活动
    monitorWallet() {
        // 监听存款
        this.contract.on("Deposit", (sender, amount, balance, timestamp, event) => {
            console.log(`💰 收到存款`);
            console.log(`   来自: ${sender}`);
            console.log(`   金额: ${ethers.utils.formatEther(amount)} ETH`);
            console.log(`   钱包余额: ${ethers.utils.formatEther(balance)} ETH`);
            
            // 更新UI：显示新余额
            this.updateBalance(balance);
        });
        
        // 监听新交易提交
        this.contract.on("TransactionSubmitted", (txId, submitter, to, value, data, timestamp, event) => {
            console.log(`📤 新交易提交 #${txId}`);
            console.log(`   提交者: ${submitter}`);
            console.log(`   目标: ${to}`);
            console.log(`   金额: ${ethers.utils.formatEther(value)} ETH`);
            
            // 更新UI：添加交易到待确认列表
            this.addPendingTransaction(txId, {
                submitter,
                to,
                value,
                confirmations: 0
            });
            
            // 如果是当前用户提交，显示通知
            if (submitter === this.userAddress) {
                this.showNotification('交易已提交，等待其他签名者确认');
            } else {
                this.showNotification(`新交易 #${txId} 需要你的确认`);
            }
        });
        
        // 监听交易确认
        this.contract.on("TransactionConfirmed", (txId, confirmer, confirmations, required, timestamp, event) => {
            console.log(`✅ 交易 #${txId} 获得确认`);
            console.log(`   确认者: ${confirmer}`);
            console.log(`   进度: ${confirmations}/${required}`);
            
            // 更新UI：更新确认进度
            this.updateConfirmationProgress(txId, confirmations, required);
            
            // 如果是当前用户确认，显示通知
            if (confirmer === this.userAddress) {
                this.showNotification('你的确认已记录');
            }
            
            // 如果达到所需确认数，提醒可以执行
            if (confirmations.toString() === required.toString()) {
                this.showNotification(`交易 #${txId} 已获得足够确认，可以执行`);
            }
        });
        
        // 监听确认撤销
        this.contract.on("ConfirmationRevoked", (txId, revoker, confirmations, timestamp, event) => {
            console.log(`❌ 交易 #${txId} 确认被撤销`);
            console.log(`   撤销者: ${revoker}`);
            console.log(`   当前确认数: ${confirmations}`);
            
            // 更新UI：更新确认进度
            this.updateConfirmationProgress(txId, confirmations, this.requiredConfirmations);
        });
        
        // 监听交易执行
        this.contract.on("TransactionExecuted", (txId, executor, to, value, returnData, timestamp, event) => {
            console.log(`✅ 交易 #${txId} 已执行`);
            console.log(`   执行者: ${executor}`);
            console.log(`   目标: ${to}`);
            console.log(`   金额: ${ethers.utils.formatEther(value)} ETH`);
            
            // 更新UI：移动到已执行列表
            this.markTransactionExecuted(txId);
            
            // 显示通知
            this.showNotification(`交易 #${txId} 已成功执行`);
        });
        
        // 监听交易失败
        this.contract.on("TransactionFailed", (txId, executor, reason, timestamp, event) => {
            console.log(`❌ 交易 #${txId} 执行失败`);
            console.log(`   执行者: ${executor}`);
            console.log(`   原因: ${reason}`);
            
            // 更新UI：标记失败
            this.markTransactionFailed(txId, reason);
            
            // 显示错误通知
            this.showNotification(`交易 #${txId} 执行失败: ${reason}`, 'error');
        });
    }
    
    // 获取待确认交易列表
    async getPendingTransactions() {
        // 获取所有提交的交易
        const submitFilter = this.contract.filters.TransactionSubmitted();
        const submitted = await this.contract.queryFilter(submitFilter, 0, 'latest');
        
        // 获取已执行的交易
        const executeFilter = this.contract.filters.TransactionExecuted();
        const executed = await this.contract.queryFilter(executeFilter, 0, 'latest');
        
        const executedIds = new Set(executed.map(e => e.args.transactionId.toString()));
        
        // 过滤出未执行的交易
        const pending = submitted.filter(e => 
            !executedIds.has(e.args.transactionId.toString())
        );
        
        return pending.map(event => ({
            transactionId: event.args.transactionId.toString(),
            submitter: event.args.submitter,
            to: event.args.to,
            value: ethers.utils.formatEther(event.args.value),
            timestamp: event.args.timestamp.toNumber(),
            blockNumber: event.blockNumber
        }));
    }
    
    // 获取交易的确认状态
    async getTransactionConfirmations(transactionId) {
        const filter = this.contract.filters.TransactionConfirmed(transactionId, null);
        const confirmations = await this.contract.queryFilter(filter, 0, 'latest');
        
        return confirmations.map(event => ({
            confirmer: event.args.confirmer,
            timestamp: event.args.timestamp.toNumber(),
            blockNumber: event.blockNumber
        }));
    }
    
    // 获取用户需要确认的交易
    async getTransactionsNeedingConfirmation(userAddress) {
        const pending = await this.getPendingTransactions();
        
        const needsConfirmation = [];
        
        for (const tx of pending) {
            const confirmations = await this.getTransactionConfirmations(tx.transactionId);
            const hasConfirmed = confirmations.some(c => c.confirmer === userAddress);
            
            if (!hasConfirmed) {
                needsConfirmation.push({
                    ...tx,
                    currentConfirmations: confirmations.length
                });
            }
        }
        
        return needsConfirmation;
    }
    
    // 获取交易历史统计
    async getTransactionStats() {
        const submitFilter = this.contract.filters.TransactionSubmitted();
        const executeFilter = this.contract.filters.TransactionExecuted();
        const failFilter = this.contract.filters.TransactionFailed();
        
        const [submitted, executed, failed] = await Promise.all([
            this.contract.queryFilter(submitFilter, 0, 'latest'),
            this.contract.queryFilter(executeFilter, 0, 'latest'),
            this.contract.queryFilter(failFilter, 0, 'latest')
        ]);
        
        const totalSubmitted = submitted.length;
        const totalExecuted = executed.length;
        const totalFailed = failed.length;
        const pending = totalSubmitted - totalExecuted - totalFailed;
        
        return {
            totalSubmitted,
            totalExecuted,
            totalFailed,
            pending,
            successRate: totalSubmitted > 0 
                ? ((totalExecuted / totalSubmitted) * 100).toFixed(2) + '%'
                : '0%'
        };
    }
    
    // UI更新方法
    updateBalance(balance) {
        console.log(`UI: 更新余额 ${ethers.utils.formatEther(balance)} ETH`);
    }
    
    addPendingTransaction(txId, data) {
        console.log(`UI: 添加待确认交易 #${txId}`);
    }
    
    updateConfirmationProgress(txId, current, required) {
        console.log(`UI: 更新交易 #${txId} 确认进度 ${current}/${required}`);
    }
    
    markTransactionExecuted(txId) {
        console.log(`UI: 标记交易 #${txId} 为已执行`);
    }
    
    markTransactionFailed(txId, reason) {
        console.log(`UI: 标记交易 #${txId} 为失败 - ${reason}`);
    }
    
    showNotification(message, type = 'info') {
        const icon = type === 'error' ? '⚠️' : '📱';
        console.log(`${icon} 通知: ${message}`);
    }
}

// 使用示例
const provider = new ethers.providers.WebSocketProvider('ws://localhost:8546');
const contractAddress = '0x...';
const contractABI = [...];

const walletUI = new MultiSigWalletUI(provider, contractAddress, contractABI);
walletUI.userAddress = '0xYourAddress';
walletUI.requiredConfirmations = 2;

// 开始监听
walletUI.monitorWallet();

// 获取待确认交易
const pending = await walletUI.getPendingTransactions();
console.log('待确认交易:', pending);

// 获取需要当前用户确认的交易
const needsConfirmation = await walletUI.getTransactionsNeedingConfirmation(walletUI.userAddress);
console.log('需要你确认的交易:', needsConfirmation);

// 获取交易统计
const stats = await walletUI.getTransactionStats();
console.log('交易统计:', stats);
```
这四个应用场景展示了事件在不同类型DApp中的实际应用：

1. 代币转账追踪：最基础的应用，所有代币合约都需要
2. NFT市场交易：展示如何追踪复杂的市场活动
3. 投票和治理：展示如何实现透明的治理流程
4. 多签钱包：展示如何追踪多步骤的工作流











































