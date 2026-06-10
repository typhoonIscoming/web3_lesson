// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

contract FavoriteNumber{
    /**
        实现的功能：
        将名字和他喜欢的数字一一对应起来
    */
    mapping (string => uint256) private nameToFavoriteNumber;

    // 定义public，让这个方法可以在外部调用
    // 这里定义memory是因为string是一个动态大小的类型，所以使用memory指定这个参数在函数执行过程中放在内存里面
    // uint256是一个简单的值类型，大小是固定的
    function createOrUpdateNumber(string memory name, uint256 number) public {
        nameToFavoriteNumber[name] = number;
    }
    // 加上view这个关键字，表示这个函数只是读取数据，不会做任何修改
    // 如果是pure，那么这个函数既不能修改也不能读取，但是这个函数读取了mapping的数据结构
    function getNumber(string memory name) public view returns (uint256) {
        return nameToFavoriteNumber[name];
    }
}
