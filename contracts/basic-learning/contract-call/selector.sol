// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract SelectorTest {
    // 当参数to为 0x05Aa229Aec102f78CE0E852A812a388F076Aa555 
    // data为0x6a62784200000000000000000000000005aa229aec102f78ce0e852a812a388f076aa555
    // 第一部分为前四个字节0x6a627842，是mint函数的选择器
    // 剩下为32字节的address 00000000000000000000000005aa229aec102f78ce0e852a812a388f076aa555
    // 地址长度为20字节，左边12字节用0补全
    event Log(address to,bytes data);


    constructor() {
        
    }

   
    function mint(address to)  external {
        emit Log(to,msg.data);
    }

    // mint函数选择器为0x6a627842
    function mintSelector() public pure returns(bytes4 mSelector){
        return bytes4(keccak256("mint(address)"));
    }
}
