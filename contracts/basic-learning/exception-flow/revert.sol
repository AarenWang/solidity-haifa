// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

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