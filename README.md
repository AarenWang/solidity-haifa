
# Solidity学习笔记和源码

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
```
 interface MyConstractInteface{

    //接口合约里抽象方法定义
    ......
    function count() external view returns (uint);
    
 }
```

通过接口合约调用实际合约
```
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



# Hardhat Useing 
```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```
