// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract ParamCheck {
    constructor() {
        
    }
    /**
     *  call to ParamCheck.paramCheck1 errored: Error: VM Exception while processing transaction: reverted with reason string 'age must great or equal 18'
    */
    function paramCheck1(string calldata name,uint  age) public pure returns(bool){
        require(age >= 18,"age must great or equal 18");
        return true;
    } 

    /**
    *  call to ParamCheck.paramCheck2 errored: Error: VM Exception while processing transaction: reverted with panic code 0x1 (Assertion error)
    */
    function paramCheck2(string calldata name,uint  age) public pure returns(bool){
        assert(age >= 18);
        return true;
    } 
}

