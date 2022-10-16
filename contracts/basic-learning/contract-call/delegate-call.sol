// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// 被调用的合约C
contract C {
    uint256 public cNum;
    address public sender;

    function setNum(uint256 _num) public payable {
        cNum = _num;
        sender = msg.sender;
    }

    function getNum() public view returns(uint256) {
        return cNum;
    }
}

contract B {
    uint public num;
    address public sender;

    // 通过call来调用C的setNum()函数，将改变合约C里的状态变量
    function callSetNum(address _addr, uint _num) external payable{
        // 通过call来调用
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("setNum(uint256)", _num)
        );
    }


    // 通过delegatecall来调用C的setNum()函数，将改变合约C里的状态变量
    function delegatecallSetNum(address _addr, uint _num) external payable{
        // delegatecall setNum()
        (bool success, bytes memory data) = _addr.delegatecall(
            abi.encodeWithSignature("setNum(uint256)", _num)
        );
    }
}