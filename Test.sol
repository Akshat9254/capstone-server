// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
    uint public data; 

    function getData() external view returns(uint) { 
        return data;
    }

    function setData(uint _data) external {
        data = _data;
    }
}
