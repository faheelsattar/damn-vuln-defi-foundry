// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IUniswapV3Pool} from "./interfaces.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {OracleLibrary} from "./library/OracleLibrary.sol";

/**
 * @title PuppetV3Pool
 * @notice A simple lending pool using Uniswap v3 as TWAP oracle.
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract PuppetV3Pool {
    using SafeERC20 for IERC20;

    uint256 public constant DEPOSIT_FACTOR = 3;
    uint32 public constant TWAP_PERIOD = 10 minutes;

    IERC20 public immutable weth;
    IERC20 public immutable token;
    IUniswapV3Pool public immutable uniswapV3Pool;

    mapping(address => uint256) public deposits;

    event Borrowed(address indexed borrower, uint256 depositAmount, uint256 borrowAmount);

    constructor(address _weth, address _token, address _uniswapV3Pool) {
        weth = IERC20(_weth);
        token = IERC20(_token);
        uniswapV3Pool = IUniswapV3Pool(_uniswapV3Pool);
    }

    /**
     * @notice Allows borrowing `borrowAmount` of tokens by first depositing three times their value in WETH.
     *         Sender must have approved enough WETH in advance.
     *         Calculations assume that WETH and the borrowed token have the same number of decimals.
     * @param borrowAmount amount of tokens the user intends to borrow
     */
    function borrow(uint256 borrowAmount) external {
        // Calculate how much WETH the user must deposit
        uint256 depositOfWETHRequired = calculateDepositOfWETHRequired(borrowAmount);

        // Pull the WETH
        weth.transferFrom(msg.sender, address(this), depositOfWETHRequired);

        // internal accounting
        deposits[msg.sender] += depositOfWETHRequired;

        token.safeTransfer(msg.sender, borrowAmount);

        emit Borrowed(msg.sender, depositOfWETHRequired, borrowAmount);
    }

    function calculateDepositOfWETHRequired(uint256 amount) public view returns (uint256) {
        uint256 quote = _getOracleQuote(_toUint128(amount));

        return quote * DEPOSIT_FACTOR;
    }

    function _getOracleQuote(uint128 amount) private view returns (uint256) {
        (int24 arithmeticMeanTick) = OracleLibrary.consult(address(uniswapV3Pool), TWAP_PERIOD);
        return OracleLibrary.getQuoteAtTick(
            arithmeticMeanTick,
            amount, // baseAmount
            address(token), // baseToken
            address(weth) // quoteToken
        );
    }

    function _toUint128(uint256 amount) private pure returns (uint128 n) {
        require(amount == (n = uint128(amount)));
    }
}
