
# Solidity学习笔记和源码
[TOC]

### 发送ETH原生代币
Solidity通过以下三种方式发送Ether到其它合约
- transfer()函数，消耗2300 gas，碰到错误会throw error
- send 消耗2300 gas，返回布尔值
- call 返回bool
call()保证可重入性(re-entrancy guard)，推荐使用call方法

合约至少要实现以下两个方法其中一个，才能接受Ether
- receive() external payable
- fallback() external payable  
receive()方法在msg.data为空时调用，否则调用fallback()方法

接收Ether合约 [ReceiveEther.sol](contracts/basic-learning/transfer/ReceiveEther.sol)
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract ReceiveEther {
    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

}

```


发送Ether合约 [SendEther.sol](contracts/basic-learning/transfer/SendEther.sol)
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract SendEther {

    //构造函数加payable，方便创建合约时转入一笔ETH 
    constructor() payable{
        
    } 
     // amount单位是wei
     function sendViaTransfer(address payable _to, uint amount) public payable {
        // transfer()函数已经不在推荐用来发送Ether
        //_to.transfer(msg.value);
        _to.transfer(amount);
    }

    function sendViaSend(address payable _to) public payable {
        // 通过send()函数发送ether，返回布尔值表示成功或失败 
        // 该函数不再推荐用来发送Ether
        bool sent = _to.send(msg.value);
        require(sent, "Failed to send Ether");
    }

    function sendViaCall(address payable _to) public payable {
        // 通过返回布尔值表示是否发送成功
        // 当前推荐使用call()函数来发送Ether
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}
```


### 接口合约
和Java等面向对象编程语言一样，Solidity提供抽象合约和接口合约能力，我们先谈谈接口合约
安装Solidity要求接口合约必须
- 函数只定义接口，不能有任何实现
- 可以从其它合约继承
- 所有函数定义必须使用**external**修饰
- 不能定义合约构造方法
- 不能定义状态变量

使用接口合约场景
- 调用他人合约，没有合约源码，只知道合约接口
- 调用的合约文件庞大，不想引入，只想通过接口调用
- 开发合约项目，将接口和实现分离，接口文件之定义接口合约

接口合约使用**interface**关键字定义
```solidity
 interface MyConstractInteface{

    //接口合约里抽象方法定义
    ......
    function count() external view returns (uint);
    
 }
```

通过接口合约调用实际合约
```solidity
  //实际实现合约的地址
  address public realyAddress;
  
  //
  MyConstractInteface(address).inc(); //通过接口合约名称直接调用实现合约
```

一个最简单的计数器合约例子  [interface.sol](contracts/basic-learning/interface.sol)

```solidity
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

```

### 合约调用 Call与Delegatecall
以太坊为代表的区块链dAPP生态繁荣，离不改智能合约的可组合性，可组合性能力来自最基础的合约调用能力
Solidity提供两种合约调用方式
- 方式一 已经合约的ABI，通过合约名称和方法调用
- 通过低层次call函数调用

我们先学习通过合约名称加合约方法名来调用合约

被调用合约 [Call.sol](contracts/basic-learning/contract-call/contract_call.sol)
```solidity
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
```

调用者合约 [Call.sol](contracts/basic-learning/contract-call/contract_call.sol)
```solidity
/**
 * 调用者合约
 */
contract Caller {

    constructor() payable{

    };

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

```


#### Call
**call** 是address类型的低级成员函数，它用来与其他合约交互。它的返回值为```(bool, data)```，分别对应call是否成功以及目标函数的返回值。
- ```call```是solidity官方推荐的通过触发```fallback```或```receive```函数发送ETH的方法。
- 不推荐用```call```来调用另一个合约，call是一个非常低层方法，容易出错。推荐的方法仍是声明合约变量后调用函数
- 当我们不知道对方合约的源代码或ABI，就没法生成合约接口；这时，我们仍可以通过call构造合约调用

call调用格式
```solidity
 address.call{value:msg.value}(encode_data)
 //value为发送的Ether，encode_data是经过编码的十六进制数据
```

abi.encodeWithSignature参数格式如下
```abi.encodeWithSignature(string memory signature, ...) returns (bytes memory):```

比如调用函数```function foo(string memory _message, uint _x)的```encodeWithSignature调用参数为

```solidity
abi.encodeWithSignature("foo(string,uint256)", "call foo", 123)
```

参数"foo(string,uint256)"为函数签名，"call foo"为被调用函数第一个参数message，123为被调用函数第二个参数x


更多abi.encode函数参考 [abi-encoding-and-decoding-functions](https://docs.soliditylang.org/en/v0.8.17/units-and-global-variables.html?highlight=abi.encodeWithSignature#abi-encoding-and-decoding-functions)

[Address Call函数例子](contracts/basic-learning/contract-call/call.sol)



#### Delegatecall

