// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// 创建一个合约部署到虚拟环境以太坊上
// 
contract TipJar {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == owner, "you are not owner");
        _; // 下划线代表是别的方法的逻辑
    }

    function tip() public payable {
        // 转账金额必须大于0
        require(msg.value > 0, "Tip amount must be greater than 0");
    }
    // 提现
    function withDraw() public onlyOwner {
        // 这里的withDraw是一个public方法，意味着任何人都可以调用这个方法
        // 所以这里加一个限制条件
        // 这里也可以使用装饰器来完成这个操作, 定义一个装饰器onlyOwner，再将onlyOwner装饰器
        // 放在定义的方法后面，就可以执行拦截操作
        // require(msg.sender == owner, "you are not owner");
        // 1、查询余额（solidity中有内置方法）
        // 2、将余额提现到owner中
       uint256 contractBalance = address(this).balance;
       // 这里可以加入一些限制,只有余额大于0才可以执行转账
       // solidity从0.7.0开始支持unicode，第二个参数就可以传任意类型的utf-8字符
       require(contractBalance > 0, unicode"这里没有可提现的余额");
       payable(owner).transfer(contractBalance);
    }
    // 获取余额
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

