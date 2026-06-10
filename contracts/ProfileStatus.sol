// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ProfileStatus{
    // 在favoriteNumber中，mapping是将名字作为一个查询的key
    // 如果名字重名了，那么mapping就造成冲突了
    // 这里解决这个问题就是使用地址来解决
    // 定义一个结构体
    struct Status{
        string name; // 
        string message;
    }
    // 创建一个mapping将地址和结构体关联起来
    mapping(address => Status) private userStatus;

    function createOrUpdate(string memory _name, string memory _message) public {
        // 这里调用的时候不知道地址是什么？
        // 这里通过内置方法获取
        // 在合约调用这个方法的时候，会传入地址from、to等
        userStatus[msg.sender].name = _name;
        userStatus[msg.sender].message = _message;
    }
    function getStatus() public view returns (string memory, string memory) {
        return (userStatus[msg.sender].name, userStatus[msg.sender].message);
    }
}
