// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./Interfaces/IERC20.sol";
import "./Interfaces/ISwapRouter.sol";
import "./Interfaces/IWETH9.sol";
import "./Interfaces/IUniswapV3Factory.sol";
import "./Interfaces/IUniswapV3PoolState.sol";
import "./Interfaces/IUniswapV3PoolImmutables.sol";

import "./Libraries/TransferHelper.sol";

import "./Utils/Ownable.sol";

contract TokenSweeper is Ownable {
    IUniswapV3Factory Factory;
    ISwapRouter Router;
    IUniswapV3PoolState PState;
    address public immutable WETH9;
    address public router;
    address public factory;

    constructor(address _weth9, address _router, address _factory) {
        WETH9 = _weth9;
        router = _router;
        factory = _factory;
        Factory = IUniswapV3Factory(_factory);
        Router = ISwapRouter(_router);
    }
    

    event routerAddressChanged(address _router);
    event factoryAddressChanged(address _factory);

    receive() external payable {}
    
    function setRouterAddress(address _router) external onlyOwner() {
        router = _router;

        emit routerAddressChanged(_router);
    }

    function setFactoryAddress(address _factory) external onlyOwner() {
        factory = _factory;

        emit factoryAddressChanged(_factory);
    }


    //returns prices for each pair
    function currentTokenPriceInWETH9(address _token) internal view returns (uint, uint) {
        address pair = Factory.getPool(WETH9, _token, 500);
        (uint160 sqrtPricex96, , , , , , ) = IUniswapV3PoolState(pair).slot0();
        uint price0 = (sqrtPricex96 ** 2) / (2 ** 192);
        uint price1 = 1 / price0;
        return (price0, price1);
    }


    //swaps entire balance of tokens selected for wbnb
    //supply the max slippage required for your trade, take highest token transfer fee + regular slippage. ex: _maxSlippage = 5 = 5%
    function swapTokensForEth(address[] calldata _tokens, uint _maxSlippage) external {
        address[] memory path = new address[](2);
        path[1] = WETH9;
        uint counter = 0;
        uint amountOutT = 0;
        require (_maxSlippage > 0 && _maxSlippage < 100, 'slippage must be more than 0 and less than 100');

        for (uint i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            address pair = Factory.getPool(WETH9, token, 500);
            (uint price0, uint price1) = currentTokenPriceInWETH9(token);
            uint AmountIn = IERC20(token).balanceOf(_msgSender());
            uint value = (WETH9 == IUniswapV3PoolImmutables(pair).token0() ? price1 : price0) * AmountIn;
            uint amountOutMin = value * ((100 - _maxSlippage) / 100);
            
            ISwapRouter.ExactInputSingleParams memory params;
            params = ISwapRouter.ExactInputSingleParams(token, WETH9, 500, address(this), block.timestamp, AmountIn, amountOutMin, 0);

            path[0] = token;
            uint amountOut = Router.exactInputSingle(params);
            amountOutT += amountOut;
            counter++;
        }

        TransferHelper.safeTransferETH(_msgSender(), amountOutT);
    }
}
