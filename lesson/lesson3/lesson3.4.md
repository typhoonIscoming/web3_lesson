# 5. Struct结构体

# 5.1 什么是Struct
Struct（结构体）是一种自定义的复合数据类型，允许将多个相关的变量组织在一起。

作用：

* 组织相关数据
* 提高代码可读性
* 创建复杂的数据模型
* 实现面向对象的数据封装

## 5.2 Struct定义
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StructBasics {
    // 定义用户结构体
    struct User {
        string name;
        uint256 age;
        address wallet;
        bool isActive;
    }
    
    // 定义书籍结构体
    struct Book {
        string title;
        string author;
        uint256 price;
        bool available;
    }
    
    // 定义提案结构体
    struct Proposal {
        string description;
        uint256 voteCount;
        uint256 deadline;
        bool executed;
    }
}
```
## 5.3 Struct定义位置
```sol
// 位置1：合约内部
contract MyContract {
    struct User {
        string name;
        uint256 age;
    }
    
    User public admin;
}
// 位置2：合约外部（全局），全局定义，多个合约可以使用
struct User {
    string name;
    uint256 age;
}

contract ContractA {
    User public userA;
}

contract ContractB {
    User public userB;
}

// 位置3：库文件中
library Types {
    struct User {
        string name;
        uint256 age;
        address wallet;
    }
}

contract MyContract {
    Types.User public admin;
}
```
**推荐做法：**

* 简单项目：合约内部定义
* 复杂项目：库文件或接口中定义
* 多合约共享：全局定义或库文件

## 5.4 创建Struct实例

有三种方式创建struct实例：
```sol
// 方式1：逐个赋值
contract CreateStruct1 {
    struct User {
        string name;
        uint256 age;
        address wallet;
        bool isActive;
    }
    
    User public admin;
    
    function createUser1() public {
        admin.name = "Alice";
        admin.age = 25;
        admin.wallet = msg.sender;
        admin.isActive = true;
    }
}
```
特点：

* 灵活，可以只设置部分字段
* 代码较长
* 适合部分更新

## 方式2：构造器语法
```sol
contract CreateStruct2 {
    struct User {
        string name;
        uint256 age;
        address wallet;
        bool isActive;
    }
    
    User public admin;
    
    function createUser2() public {
        admin = User("Bob", 30, msg.sender, true);
    }
}
```
特点：

* 简洁
* 必须按照定义顺序传参
* 容易出错（顺序错误）

## 方式3：键值对（推荐）
```sol
contract CreateStruct3 {
    struct User {
        string name;
        uint256 age;
        address wallet;
        bool isActive;
    }
    
    User public admin;
    
    function createUser3() public {
        admin = User({
            name: "Charlie",
            age: 35,
            wallet: msg.sender,
            isActive: true
        });
    }
}
```
特点：

* 最清晰
* 不需要记住字段顺序
* 可读性最好
* 推荐使用

# 5.5 Struct的存储位置
```sol
// Storage中的Struct
contract StorageStruct {
    struct User {
        string name;
        uint256 age;
    }
    // 状态变量
    User public admin;
    // 数组
    User[] public users;
    
    // Mapping值
    mapping(address => User) public userMap;
    
    function updateAdmin() public {
        // Storage引用
        User storage user = admin;
        user.name = "New Admin";  // 直接修改storage
    }
}
// Memory中的Struct
contract MemoryStruct {
    struct User {
        string name;
        uint256 age;
    }
    
    User[] public users;
    
    function createMemoryUser() public pure returns (User memory) {
        // 在memory中创建
        User memory user = User({
            name: "Temp User",
            age: 20
        });
        
        return user;
    }
    
    function processUser() public view {
        // 从storage复制到memory
        User memory user = users[0];
        user.age = 30;  // 修改memory副本，不影响storage
    }
}
// Calldata中的Struct
contract CalldataStruct {
    struct User {
        string name;
        uint256 age;
    }
    
    // 外部函数参数用calldata（只读）
    function processUser(User calldata user) external pure returns (string memory) {
        // user.age = 30;  // 编译错误：calldata是只读的
        return user.name;
    }
}
```
**存储位置对比：**
|位置|可修改|Gas成本|使用场景|
|:--:|:--:|:--:|:--:|
|Storage|是|高|永久保存|
|Memory|是|中|临时处理|
|Calldata|否|低|外部参数|


## 5.6 访问和修改Struct
```sol
contract StructOperations {
    struct User {
        string name;
        uint256 age;
        address wallet;
        bool isActive;
    }
    
    User[] public users;
    
    // 添加用户
    function addUser(string calldata name, uint256 age) public {
        users.push(User({
            name: name,
            age: age,
            wallet: msg.sender,
            isActive: true
        }));
    }
    
    // 访问字段
    function getUserAge(uint256 index) public view returns (uint256) {
        require(index < users.length, "Index out of bounds");
        return users[index].age;
    }
    
    // 修改字段
    function updateUserAge(uint256 index, uint256 newAge) public {
        require(index < users.length, "Index out of bounds");
        users[index].age = newAge;
    }
    
    // Storage引用修改
    function deactivateUser(uint256 index) public {
        require(index < users.length, "Index out of bounds");
        
        User storage user = users[index];
        user.isActive = false;
    }
    
    // 整体替换
    function replaceUser(uint256 index, User memory newUser) public {
        require(index < users.length, "Index out of bounds");
        users[index] = newUser;
    }
    
    // 获取完整用户信息
    function getUser(uint256 index) public view returns (User memory) {
        require(index < users.length, "Index out of bounds");
        return users[index];
    }
}
```

# 6. Mapping与Struct组合

## 6.1 为什么组合使用

Mapping的优势：

1. O(1)快速查找
2. 按键索引

Struct的优势：

1. 组织复杂数据
2. 提高可读性

组合优势：

1. 快速查找复杂数据结构
2. 代码更清晰
3. 功能更强大

这是Solidity开发中最常用的模式！

## 6.2 基本组合模式
```sol
contract MappingStructBasic {
    // 定义用户信息结构体
    struct UserInfo {
        string name;
        uint256 balance;
        uint256 registeredAt;
        bool exists;  // 重要：标记用户是否真实存在
    }
    
    // Mapping存储用户信息
    mapping(address => UserInfo) public users;
    
    // 注册用户
    function register(string calldata name) public {
        require(!users[msg.sender].exists, "Already registered");
        
        users[msg.sender] = UserInfo({
            name: name,
            balance: 0,
            registeredAt: block.timestamp,
            exists: true
        });
    }
    
    // 查询用户信息
    function getUserInfo(address user) public view returns (UserInfo memory) {
        require(users[user].exists, "User not found");
        return users[user];
    }
    
    // 检查用户是否存在
    function isRegistered(address user) public view returns (bool) {
        return users[user].exists;
    }
    
    // 存款
    function deposit() public payable {
        require(users[msg.sender].exists, "Not registered");
        users[msg.sender].balance += msg.value;
    }
}
```

## 6.3 exists字段的重要性
**问题场景**
```sol
mapping(address => uint256) public balances;

// 查询某个地址
balances[0x123...]  // 返回: 0

// 问题：这个0代表什么？
// 1. 用户余额确实是0？
// 2. 用户从未注册？
// 无法区分！

// 解决方案：添加exists字段
struct UserInfo {
    uint256 balance;
    bool exists;  // 明确标记是否存在
}

mapping(address => UserInfo) public users;

// 现在可以明确区分
function checkUser(address user) public view returns (string memory) {
    if(!users[user].exists) {
        return "User not registered";
    } else if(users[user].balance == 0) {
        return "User registered, balance is 0";
    } else {
        return "User registered with balance";
    }
}
```
**exists字段的作用：**

1. 区分默认值和设置值：明确用户是否真实存在
2. 逻辑清晰：避免误判
3. 安全性：防止对不存在用户的操作
4. 最佳实践：几乎所有项目都使用这个模式

## 6.4 完整组合模式
**结合Mapping、Struct和Array，实现功能完整的数据管理。**
```sol
contract CompletePattern {
    // 用户信息结构体
    struct UserInfo {
        string name;
        string email;
        uint256 balance;
        uint256 registeredAt;
        bool exists;
    }
    
    // 主数据存储
    mapping(address => UserInfo) public users;
    
    // 地址列表（用于遍历）
    address[] public userAddresses;
    
    // 用户计数器
    uint256 public userCount;
    
    // 最大用户限制
    uint256 public constant MAX_USERS = 1000;
    
    // 事件
    event UserRegistered(address indexed user, string name);
    event UserUpdated(address indexed user, string name);
    event Deposit(address indexed user, uint256 amount);
    
    // 注册用户
    function register(string memory name, string memory email) public {
        require(!users[msg.sender].exists, "Already registered");
        require(userCount < MAX_USERS, "Max users reached");
        require(bytes(name).length > 0, "Name required");
        
        users[msg.sender] = UserInfo({
            name: name,
            email: email,
            balance: 0,
            registeredAt: block.timestamp,
            exists: true
        });
        
        userAddresses.push(msg.sender);
        userCount++;
        
        emit UserRegistered(msg.sender, name);
    }
    
    // 更新个人资料
    function updateProfile(string memory name, string memory email) public {
        require(users[msg.sender].exists, "Not registered");
        
        users[msg.sender].name = name;
        users[msg.sender].email = email;
        
        emit UserUpdated(msg.sender, name);
    }
    
    // 存款
    function deposit() public payable {
        require(users[msg.sender].exists, "Not registered");
        require(msg.value > 0, "Must send ETH");
        
        users[msg.sender].balance += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }
    
    // 查询用户信息
    function getUserInfo(address user) public view returns (UserInfo memory) {
        require(users[user].exists, "User not found");
        return users[user];
    }
    
    // 检查用户是否注册
    function isRegistered(address user) public view returns (bool) {
        return users[user].exists;
    }
    
    // 获取所有用户地址
    function getAllUsers() public view returns (address[] memory) {
        return userAddresses;
    }
    
    // 分批查询用户
    function getUsersByRange(
        uint256 start,
        uint256 end
    ) public view returns (address[] memory) {
        require(start < end, "Invalid range");
        require(end <= userAddresses.length, "End out of bounds");
        
        uint256 length = end - start;
        address[] memory result = new address[](length);
        
        for(uint256 i = 0; i < length; i++) {
            result[i] = userAddresses[start + i];
        }
        
        return result;
    }
    
    // 批量查询用户信息
    function getUserInfoBatch(
        address[] memory addresses
    ) public view returns (UserInfo[] memory) {
        UserInfo[] memory result = new UserInfo[](addresses.length);
        
        for(uint256 i = 0; i < addresses.length; i++) {
            result[i] = users[addresses[i]];
        }
        
        return result;
    }
}
```
## 6.5 Struct中包含Mapping

Struct中可以包含mapping，但有严格限制。
```sol
contract StructWithMapping {
    // 提案结构体
    struct Proposal {
        string description;
        uint256 voteCount;
        uint256 deadline;
        bool executed;
        mapping(address => bool) voters;  // struct内的mapping
    }
    
    // 存储提案
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    
    // 创建提案
    function createProposal(
        string memory description,
        uint256 duration
    ) public returns (uint256) {
        uint256 proposalId = proposalCount++;
        
        Proposal storage p = proposals[proposalId];
        p.description = description;
        p.voteCount = 0;
        p.deadline = block.timestamp + duration;
        p.executed = false;
        
        return proposalId;
    }
    
    // 投票
    function vote(uint256 proposalId) public {
        Proposal storage p = proposals[proposalId];
        
        require(block.timestamp < p.deadline, "Voting ended");
        require(!p.voters[msg.sender], "Already voted");
        
        p.voters[msg.sender] = true;
        p.voteCount++;
    }
    
    // 检查是否已投票
    function hasVoted(
        uint256 proposalId,
        address voter
    ) public view returns (bool) {
        return proposals[proposalId].voters[voter];
    }
}
```
**包含mapping的struct的限制：**
1. 只能在storage中：不能在memory或calldata
2. 不能作为参数：不能传递给函数
3. 不能作为返回值：不能返回
4. 不能在数组中：不能创建包含mapping的struct数组
```sol
contract MappingStructLimitations {
    struct ProposalWithMapping {
        string description;
        mapping(address => bool) voters;
    }
    
    // 正确：storage中使用
    mapping(uint256 => ProposalWithMapping) public proposals;
    
    // 错误：不能作为参数
    // function process(ProposalWithMapping memory p) public {
    //     // 编译错误！
    // }
    
    // 错误：不能作为返回值
    // function getProposal(uint256 id) 
    //     public view returns (ProposalWithMapping memory) {
    //     // 编译错误！
    // }
    
    // 错误：不能在数组中
    // ProposalWithMapping[] public proposalArray;  // 编译错误！
}
```

# 7. 常见设计模式

## 7.1 模式1：用户管理系统
```sol
contract UserManagement {
    struct User {
        string name;
        uint256 balance;
        bool exists;
    }
    
    mapping(address => User) public users;
    address[] public userList;
    
    function register(string memory name) public {
        require(!users[msg.sender].exists, "Already registered");
        
        users[msg.sender] = User(name, 0, true);
        userList.push(msg.sender);
    }
}
// 使用场景：任何需要管理用户的应用
```
## 7.2 模式2：ID自增系统
```sol
contract IDSystem {
    struct Item {
        string name;
        address owner;
        uint256 createdAt;
    }
    
    mapping(uint256 => Item) public items;
    uint256 public itemCount;
    
    function createItem(string memory name) public returns (uint256) {
        uint256 itemId = itemCount++;
        
        items[itemId] = Item({
            name: name,
            owner: msg.sender,
            createdAt: block.timestamp
        });
        
        return itemId;
    }
}
// 使用场景：NFT、订单系统、票务系统
```
## 7.3 模式3：双向映射
```sol
contract BidirectionalMapping {
    mapping(address => uint256) public addressToId;
    mapping(uint256 => address) public idToAddress;
    uint256 public nextId;
    
    function register() public returns (uint256) {
        require(addressToId[msg.sender] == 0, "Already registered");
        
        uint256 id = ++nextId;
        addressToId[msg.sender] = id;
        idToAddress[id] = msg.sender;
        
        return id;
    }
    
    function getUserByAddress(address user) public view returns (uint256) {
        return addressToId[user];
    }
    
    function getAddressById(uint256 id) public view returns (address) {
        return idToAddress[id];
    }
}
// 使用场景：需要双向查询的系统
```
## 7.4 模式4：一对多关系
```sol
contract OneToMany {
    // 用户 → 关注列表
    mapping(address => address[]) public following;
    
    // 用户 → 粉丝列表
    mapping(address => address[]) public followers;
    
    // 快速检查是否关注
    mapping(address => mapping(address => bool)) public isFollowing;
    
    function follow(address user) public {
        require(!isFollowing[msg.sender][user], "Already following");
        require(msg.sender != user, "Cannot follow yourself");
        
        following[msg.sender].push(user);
        followers[user].push(msg.sender);
        isFollowing[msg.sender][user] = true;
    }
    
    function getFollowing(address user) public view returns (address[] memory) {
        return following[user];
    }
    
    function getFollowers(address user) public view returns (address[] memory) {
        return followers[user];
    }
}
// 使用场景：社交网络、关注系统
```
## 7.5 模式5：计数器模式
```sol
contract CounterPattern {
    struct TokenInfo {
        string name;
        uint256 supply;
    }
    
    mapping(address => uint256) public balances;
    mapping(uint256 => TokenInfo) public tokens;
    
    uint256 public totalSupply;
    uint256 public tokenCount;
    
    function mint(address to, uint256 amount) public {
        balances[to] += amount;
        totalSupply += amount;  // 保持总量一致
    }
    
    function createToken(string memory name, uint256 supply) public {
        tokens[tokenCount++] = TokenInfo(name, supply);
    }
}
// 使用场景：代币系统、供应量管理
```

# 8. 实战练习

练习1：完整用户管理系统
需求：

创建一个完整的用户管理系统，实现以下功能：

1. 用户注册（包含name、email）
2. 更新个人资料
3. 存款功能（payable）
4. 查询用户信息
5. 获取所有用户列表
6. 分批查询用户
7. 限制最多1000个用户
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserManagementSystem {
    struct User {
        string name;
        string email;
        uint256 balance;
        uint256 registeredAt;
        bool exists;
    }
    
    mapping(address => User) public users;
    address[] public userAddresses;
    uint256 public userCount;
    uint256 public constant MAX_USERS = 1000;
    
    event UserRegistered(address indexed user, string name);
    event UserUpdated(address indexed user);
    event Deposit(address indexed user, uint256 amount);
    
    function register(string memory name, string memory email) public {
        require(!users[msg.sender].exists, "Already registered");
        require(userCount < MAX_USERS, "Max users reached");
        require(bytes(name).length > 0, "Name required");
        require(bytes(email).length > 0, "Email required");
        
        users[msg.sender] = User({
            name: name,
            email: email,
            balance: 0,
            registeredAt: block.timestamp,
            exists: true
        });
        
        userAddresses.push(msg.sender);
        userCount++;
        
        emit UserRegistered(msg.sender, name);
    }
    
    function updateProfile(string memory name, string memory email) public {
        require(users[msg.sender].exists, "Not registered");
        
        users[msg.sender].name = name;
        users[msg.sender].email = email;
        
        emit UserUpdated(msg.sender);
    }
    
    function deposit() public payable {
        require(users[msg.sender].exists, "Not registered");
        require(msg.value > 0, "Must send ETH");
        
        users[msg.sender].balance += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }
    
    function getUserInfo(address user) public view returns (User memory) {
        require(users[user].exists, "User not found");
        return users[user];
    }
    
    function getAllUsers() public view returns (address[] memory) {
        return userAddresses;
    }
    
    function getUsersByRange(
        uint256 start,
        uint256 end
    ) public view returns (address[] memory) {
        require(start < end, "Invalid range");
        require(end <= userAddresses.length, "End out of bounds");
        
        uint256 length = end - start;
        address[] memory result = new address[](length);
        
        for(uint256 i = 0; i < length; i++) {
            result[i] = userAddresses[start + i];
        }
        
        return result;
    }
    
    function isRegistered(address user) public view returns (bool) {
        return users[user].exists;
    }
}
```
##练习2：投票系统
需求：

创建一个提案投票系统：

1. 定义Proposal结构体（包含voters的mapping）
2. 支持创建提案
3. 支持投票（每人只能投一次）
4. 查询提案信息
5. 获取获胜提案

```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    struct Proposal {
        string description;
        uint256 voteCount;
        uint256 deadline;
        bool executed;
        mapping(address => bool) voters;
    }
    
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    
    event ProposalCreated(uint256 indexed proposalId, string description);
    event Voted(uint256 indexed proposalId, address indexed voter);
    
    function createProposal(
        string memory description,
        uint256 duration
    ) public returns (uint256) {
        require(bytes(description).length > 0, "Description required");
        require(duration > 0, "Duration must be positive");
        
        uint256 proposalId = proposalCount++;
        
        Proposal storage p = proposals[proposalId];
        p.description = description;
        p.voteCount = 0;
        p.deadline = block.timestamp + duration;
        p.executed = false;
        
        emit ProposalCreated(proposalId, description);
        
        return proposalId;
    }
    
    function vote(uint256 proposalId) public {
        require(proposalId < proposalCount, "Proposal does not exist");
        
        Proposal storage p = proposals[proposalId];
        
        require(block.timestamp < p.deadline, "Voting has ended");
        require(!p.voters[msg.sender], "Already voted");
        
        p.voters[msg.sender] = true;
        p.voteCount++;
        
        emit Voted(proposalId, msg.sender);
    }
    
    function hasVoted(
        uint256 proposalId,
        address voter
    ) public view returns (bool) {
        require(proposalId < proposalCount, "Proposal does not exist");
        return proposals[proposalId].voters[voter];
    }
    
    function getProposalInfo(uint256 proposalId) public view returns (
        string memory description,
        uint256 voteCount,
        uint256 deadline,
        bool executed
    ) {
        require(proposalId < proposalCount, "Proposal does not exist");
        
        Proposal storage p = proposals[proposalId];
        return (p.description, p.voteCount, p.deadline, p.executed);
    }
    
    function getWinningProposal() public view returns (uint256 winningProposalId) {
        uint256 maxVotes = 0;
        
        for(uint256 i = 0; i < proposalCount; i++) {
            if(proposals[i].voteCount > maxVotes) {
                maxVotes = proposals[i].voteCount;
                winningProposalId = i;
            }
        }
        
        return winningProposalId;
    }
}
```

## 练习3：NFT市场
挑战任务：

创建一个简单的NFT市场合约：

1. 定义NFT结构体（id、owner、price、forSale）
2. 铸造NFT功能
3. 上架/下架功能
4. 购买功能
5. 查询所有在售NFT

提示：

* 使用ID自增模式
* 使用mapping存储NFT
* 使用array追踪在售列表


# 9. 常见问题解答

Q1：为什么mapping不能遍历？

答：Mapping的底层实现决定了它不能遍历。

技术原因：

1. 不存储键列表：Mapping只存储值，不存储键
2. 哈希存储：通过哈希函数计算存储位置
3. 无限键空间：理论上所有可能的键都"存在"
4. Gas成本：如果要遍历，成本无法预估

解决方案：使用Mapping+Array组合模式


Q2：如何实现可遍历的mapping？

答：使用Mapping+Array组合模式。
```sol
mapping(address => uint256) public data;  // 存储数据
address[] public keys;                    // 存储键列表
mapping(address => bool) public exists;   // 快速检查

function add(address key, uint256 value) public {
    if(!exists[key]) {
        keys.push(key);
        exists[key] = true;
    }
    data[key] = value;
}

function iterate() public view returns (uint256[] memory) {
    uint256[] memory values = new uint256[](keys.length);
    for(uint256 i = 0; i < keys.length; i++) {
        values[i] = data[keys[i]];
    }
    return values;
}
```

# 10. 知识点总结

Mapping特性总结

核心特性：

* 键值对存储结构
* O(1)时间复杂度
* 基于哈希表实现
* 只能用于storage

五大特性：

* 所有键都"存在"（返回默认值）
* 不存储键列表
* 不能遍历
* 只能用于storage
* 不能作为参数/返回值

操作支持：

* 支持：赋值、查询、delete单个值
* 不支持：遍历、获取长度、delete整个mapping

**Struct特性总结**
定义和使用：

* 自定义复合数据类型
* 组织相关数据
* 提高代码可读性

三种创建方式：

* 逐个赋值（灵活）
* 构造器语法（简洁）
* 键值对语法（推荐）

存储位置：

* Storage：永久存储
* Memory：临时存储
* Calldata：只读参数

特殊限制：

* 包含mapping的struct只能在storage
* 不能作为参数和返回值（如果包含mapping）

组合模式总结

Mapping + Struct：

* 快速查找复杂数据
* 代码清晰
* 添加exists字段标记存在

Mapping + Array：

* 实现可遍历的mapping
* O(1)查找 + 遍历能力
* 需要维护一致性

Mapping + Struct + Array：

* 最完整的模式
* 快速查找 + 复杂数据 + 遍历
* 几乎所有项目都使用

关键设计原则：

* 使用struct组织数据
* 使用mapping快速查找
* 使用array实现遍历
* 添加exists标记
* 添加计数器



