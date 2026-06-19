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










































