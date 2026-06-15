// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18 <0.9.0;

contract Callee {
    uint256 public data;
    

    event DataStored(address indexed sender, uint256 data);

    function storeData(uint256 _data) public {
        data = _data;

        emit DataStored(msg.sender, _data);
    }
}
