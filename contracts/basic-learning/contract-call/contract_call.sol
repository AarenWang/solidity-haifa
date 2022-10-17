// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/**
 * 被调用的合约
 */
contract Callee {
    uint256 private _x = 0; // 状态变量_x

    uint private _value =  0;

    // 收到eth的事件，记录amount和gas
    event EtherReceive(uint amount, uint gas);
    
    // 返回合约ETH余额
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }

    // 可以调整状态变量_x的函数
    function setX(uint x) external payable returns(uint) {
        _x = x;
        return _x;
        
    }

     // 可以调整状态变量_x的函数，并且可以往合约转ETH (payable)
    function setXandSendEther(uint x) external payable returns(uint,uint) {
        _x = x;
        _value = msg.value;
       
         // 如果转入ETH，则释放Log事件
        //if(msg.value > 0){
            emit EtherReceive(_value, gasleft());
        //}

        return (x,_value);
    }

    // 读取_x
    function getX() external view returns(uint x){
        x = _x;
    }
}

/**
 * 调用者合约
 */
contract Caller {

     constructor() payable {
        
    }

    function setX(Callee _callee, uint _x) public {
        uint x = _callee.setX(_x);
    }

    /**
    *  只设置X
    */
    function setXFromAddress(address _addr, uint _x) public {
        Callee callee = Callee(_addr);
        callee.setX(_x);
    }

    /**
     * 设置x并发送Ether
     */
    function setXandSendEther(Callee _callee, uint _x) public payable {
        (uint x, uint value) = _callee.setXandSendEther{value: msg.value}(_x);
    }
}
