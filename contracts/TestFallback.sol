// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SpecialPayable {
    event Received(address sender, uint256 amount);
    event Fallback(address sender, uint256 amount, bytes data);
    
    // receive：接收纯ETH转账（无data）
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    // fallback：调用不存在的函数或带data的转账
    fallback() external payable {
        emit Fallback(msg.sender, msg.value, msg.data);
    }
}