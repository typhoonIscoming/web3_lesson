// SPDX-License-Identifier: GPL-3.0
// solidity 文件第一行必须声明文件协议
// 第二行定义使用solidity的版本：大于等于0.8.2，小于0.9.0
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
 // contract 定义一个合约，合约名字就是Strorage
contract Storage {
    // 无符号的整数类型
    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}