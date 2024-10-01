// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity =0.7.6;
pragma abicoder v2;

import "../src/SimpleSwap.sol";
import "v3-periphery/interfaces/ISwapRouter.sol";
import "forge-std/Test.sol";

contract SimpleSwapTest is Test {
    function setUp() public {
        ISwapRouter swapRouter = ISwapRouter(0x1);
        SimpleSwap simpleSwap = new SimpleSwap(swapRouter);
    }

    function testOk() public {}
}
