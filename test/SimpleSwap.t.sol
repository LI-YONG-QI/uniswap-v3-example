// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity =0.7.6;
pragma abicoder v2;

import {SimpleSwap} from "../src/SimpleSwap.sol";
import {IWETH9} from "../src/test/IWETH9.sol";
import {LiquidityExamples, ILiquidityExamples} from "../src/LiquidityExamples.sol";

import "v3-periphery/interfaces/INonfungiblePositionManager.sol";
import "v3-periphery/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleSwapTest is Test {
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant SwapRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant NonfungiblePositionManagerAddress = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    bytes32 public constant INCREASE_LIQUIDITY_EVENT = keccak256("IncreaseLiquidity(uint256,uint128,uint256,uint256)");

    uint8 public constant DAI_DECIMALS = 18;

    SimpleSwap simpleSwap;
    LiquidityExamples liquidityManagement;

    IWETH9 WETH;
    IERC20 DAI;

    function _getLogs(bytes32 events) internal returns (Vm.Log memory) {
        Vm.Log[] memory entries = vm.getRecordedLogs();

        for (uint256 i = 0; i < entries.length; i++) {
            bytes32 sig = entries[i].topics[0];
            if (sig == events) {
                return entries[i];
            }
        }

        revert("Event not found");
    }

    function setUp() public {
        simpleSwap = new SimpleSwap(ISwapRouter(SwapRouterAddress));
        liquidityManagement = new LiquidityExamples(INonfungiblePositionManager(NonfungiblePositionManagerAddress));

        WETH = IWETH9(WETH_ADDRESS);
        DAI = IERC20(DAI_ADDRESS);

        WETH.deposit{value: 10 ether}();
    }

    function testSwapInputSingle() public {
        WETH.approve(address(simpleSwap), 1 ether);
        uint256 amountIn = 0.1 ether;

        simpleSwap.swapWETHForDAI(amountIn);

        uint256 balance = DAI.balanceOf(address(this));
        assertGt(balance, 0);
    }

    function testSwapOutputSingle() public {
        WETH.approve(address(simpleSwap), 1 ether);
        uint256 amountOut = 200 ether;
        uint256 amountInMaximum = 1 ether; // 1 WETH = 2600 DAI

        simpleSwap.swapExactOutputSingle(amountOut, amountInMaximum);

        uint256 balance = DAI.balanceOf(address(this));
        assertGt(balance, 0);
    }

    function testAddLiquidity() public {
        // Add liquidity USDC and DAI

        // Arrange
        uint256 beforeAmount = 10 ether;
        deal(DAI_ADDRESS, address(liquidityManagement), 10 ether);
        deal(USDC_ADDRESS, address(liquidityManagement), 10 ether);

        vm.recordLogs();

        // Act
        liquidityManagement.mintNewPosition(1 ether, 1 ether);

        Vm.Log memory log = _getLogs(INCREASE_LIQUIDITY_EVENT);
        (uint128 liquidity,,) = abi.decode(log.data, (uint128, uint256, uint256));

        uint256 tokenId = uint256(log.topics[1]);
        ILiquidityExamples.Deposit memory deposit = liquidityManagement.getPosition(tokenId);

        // Assert
        // Deposits
        assertEq(uint256(deposit.liquidity), uint256(liquidity));
        assertEq(deposit.owner, address(liquidityManagement));
        assertEq(deposit.token0, DAI_ADDRESS);
        assertEq(deposit.token1, USDC_ADDRESS);

        // NFT
        address owner = INonfungiblePositionManager(NonfungiblePositionManagerAddress).ownerOf(tokenId);
        uint256 balance =
            INonfungiblePositionManager(NonfungiblePositionManagerAddress).balanceOf(address(liquidityManagement));
        assertEq(owner, address(liquidityManagement));
        assertEq(balance, 1);

        // Token
        uint256 afterAmount = DAI.balanceOf(address(liquidityManagement));
        assertLe(afterAmount, beforeAmount);
    }

    function testIncreaseLiquidity() public {
        // Arrange
        deal(DAI_ADDRESS, address(liquidityManagement), 10 ether);
        deal(USDC_ADDRESS, address(liquidityManagement), 10 ether);

        vm.recordLogs();
        liquidityManagement.mintNewPosition(1 ether, 1 ether);
        Vm.Log memory log = _getLogs(INCREASE_LIQUIDITY_EVENT);
        uint256 tokenId = uint256(log.topics[1]);
        (uint128 beforeLiquidity,,) = abi.decode(log.data, (uint128, uint256, uint256));

        // Act
        liquidityManagement.increaseLiquidity(tokenId, 1 ether, 1 ether);

        // Assert
        ILiquidityExamples.Deposit memory deposit = liquidityManagement.getPosition(tokenId);
        assertLt(beforeLiquidity, uint256(deposit.liquidity));
    }
}
