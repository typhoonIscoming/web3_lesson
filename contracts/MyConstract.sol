// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Strings.sol";

contract MyContract{
    using Strings for uint256;

    uint256 public myNumber = 123456;

    function getNumberAsString() public view returns (string memory) {
        return myNumber.toString();
    }

    // 将地址转换成16进制字符串
    function addressToString(address addr) public pure returns (string memory) {
        return uint256(uint160(addr)).toHexString(20);
    }
}
