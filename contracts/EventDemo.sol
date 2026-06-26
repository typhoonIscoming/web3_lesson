// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EventDemo {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event DataUpdate(address indexed user, uint256 indexed id, string data, uint256 timestamp);
    
    mapping(address => uint256) public balances;
    
    constructor() {
        balances[msg.sender] = 1000;
    }
    
    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
    }
    
    function updateData(uint256 id, string memory data) public {
        emit DataUpdate(msg.sender, id, data, block.timestamp);
    }
}