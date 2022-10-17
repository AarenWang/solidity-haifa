// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;


/**
 * 计数器合约
 * 0xd9145CCE52D386f254917e481eB44e9943F39138
 */
contract Counter {
    //计数
    uint private _count;

    constructor() {
        _count = 0;
    }

    function count()  public view returns (uint){
        return _count;
    }

     function inc() public{
        _count++;
     }

     function dec() public{
        _count--;
     }
}

/**
 * 计数器接口合约，定义了合约接口
 */
interface ICounter {
    function count() external view returns (uint);
    function inc() external;
    function dec() external;
}

/**
 * 通过计数器接口合约调用真实的计数器合约
 */
contract CallInterface {
    uint public count;

    ///@param  _counter 计数器合约地址
    function examples(address _counter) external {
        ICounter(_counter).inc(); //通过接口合约名称直接调用实现合约
        count = ICounter(_counter).count();
    }
}

