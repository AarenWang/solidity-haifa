
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
```solidity
   abi.encodeWithSignature(string memory signature, ...) returns (bytes memory):
   abi.encodeWithSignature("函数签名", 逗号分隔的具体参数)
```

比如调用函数```function foo(string memory _message, uint _x)的```encodeWithSignature调用参数为

```solidity
abi.encodeWithSignature("foo(string,uint256)", "call foo", 123)
```

参数"foo(string,uint256)"为函数签名，"call foo"为被调用函数第一个参数message，123为被调用函数第二个参数x


更多abi.encode函数参考 [abi-encoding-and-decoding-functions](https://docs.soliditylang.org/en/v0.8.17/units-and-global-variables.html?highlight=abi.encodeWithSignature#abi-encoding-and-decoding-functions)

[Address Call函数例子](contracts/basic-learning/contract-call/call.sol)



#### Delegatecall
与```call``` 类似 ```delegatecall``` 也是Address类型的的低层次函数
当用户发起智能合约调用，从合约A调用合约B时
- 合约A用call()来调用合约B，则合约B的msg.sender为合约A地址，msg.data是合约A发送给合约B的data
- 合约A用delegatecall()来调用合约B，则合约B的msg.sender是用户地址，msg.data是用户设置的data


示例
```solidity
// 被调用的合约C
contract C {
    uint256 public num;
    address public sender;

    function setNum(uint256 _num) public payable {
        num = _num;
        sender = msg.sender;
    }

    function getNum() public view returns(uint256) {
        return num;
    }
}
```


```solidity 
contract B {
    
    uint256 public num;
    address public sender;

    // 通过call来调用C的setNum()函数，将改变合约C里的状态变量
    function callSetNum(address _addr, uint _num) external payable{
        num = _num;
        sender = msg.sender;
        // 通过call来调用
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("setNum(uint256)", _num)
        );
       
    }

    // 通过delegatecall来调用C的setNum()函数，将改变合约C里的状态变量
    function delegatecallSetNum(address _addr, uint _num) external payable{
        num = _num;
        sender = msg.sender;
        // delegatecall setNum()
        (bool success, bytes memory data) = _addr.delegatecall(
            abi.encodeWithSignature("setNum(uint256)", _num)
        );

    }
}
```

什么场景下使用delegatecall调用
**可更新的代理合约场景**  
代理合约作为整个智能合约的门面(facade)，代理合约owner可以设置目标合约的地址，owner更新合约逻辑重新部署之后，更新目标合约地址
外部合约同步与代理(Proxy)合约交互，交互地址和接口保持不变，代理合约调用(delegatecall)新的合约，实现智能合约更新升级


**如何安全使用delegatecall**
//TODO


 ### 参数校验 require 和 assert
Solidity提供了两个用于校验函数```require```和```assert```，两个函数都是不满足校验条件，则抛出异常或错误，但有很大区别
assert函数创建类为```Panic(unit256)```的error type，assert必须使用在内部错误和检查不变性(check invariants)

require函数用于入参校验和校验外部合约调用的返回值，如果校验不满足条件，则抛出```Error(String)```
除了require函数抛出Error,还有以下场景抛出```Error(String)```：
1. 调用```require(x)```,当条件x位false时
2. 使用```revert()```或```revert("description")```
3. 调用外部合约，对应的代码不存在(包括合约不存在，调用方法不存在)
4. 通过公开的合约函数接收Ether，但是函数没有用**payable**修饰(包括构造函数和falllback函数)
5. 通过公开的getter合约函数接收Ether

下面的例子用require校验输入，用assert进行内部错误检查
```solidity
// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.5.0 <0.9.0;
contract Sharer {

    function sendHalf(address payable addr) public payable returns (uint balance) { 
        require(msg.value % 2 == 0, "Even value required."); 
        uint balanceBeforeTransfer = address(this).balance; 
        addr.transfer(msg.value / 2); 
        // Since transfer throws an exception on failure and 
        // cannot call back here, there should be no way for us to 
        // still have half of the money. 
        assert(address(this).balance == balanceBeforeTransfer - msg.value / 2); 
        return address(this).balance;
    }
}
```
如果函数执行过程发送Panic或Error,则EVM会回滚执行过程修改的状态，回滚到合约方法执行前的状态

 ### 流程回滚 revert函数
 可用使用revert语句或revert函数触发流程回滚。
 revert语句接收个性化错误```revert CustomError(arg1,arg2)```

 同时solidity也保留了兼容的revert函数
 ```
  revert(); 或 revert("description");
 ```

错误信息会传递给调用者，调用者可以捕获错误信息,```revert()```返回的错误信息为空，而```revert("description")```则返回```Error(string)```错误。
使用个性化错误类型比使用revert("description")消耗更少的gas，只有4个字节

revert使用例子
```solidity
contract RevertTest{
    address private owner;
    uint private _num;

    constructor(){
        owner = msg.sender;
    }

    function setNum(uint num) public {
        if(msg.sender != owner){
            revert CallByOtherError(msg.sender);
        }
        _num = num;
    }

    error CallByOtherError(address call);
}
```

 ### 使用try catch 捕获异常流程 


