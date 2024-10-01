// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.21;
pragma abicoder v2;

import "../src/SimpleSwap.sol";
import "v3-periphery/interfaces/ISwapRouter.sol";
import "../src/test/IWETH9.sol";
import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleSwapTest is Test {
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    uint8 public constant DAI_DECIMALS = 18;
    address public constant SwapRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    SimpleSwap simpleSwap;
    IWETH9 WETH;
    IERC20 DAI;

    function setUp() public {
        simpleSwap = new SimpleSwap(ISwapRouter(SwapRouterAddress));
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
}
