# TokenSweeper
Swap multiple tokens for ETH on Uniswap in one transaction.

Interfaces, Libraries, and Utils sourced from Uniswap and OpenZeppelin.

To use this tool, you must approve the contract as a spender for all tokens you wish to swap. Supply an array containing the contract addresses of the tokens you wish to swap to the function 'swapTokensForEth', along with the maximum slippage you will accept which will be passed in directly as an integer(max slippage equalling 1 means 1%). Any transfer fees associated specifically with the individual tokens being swapped should be included in the max slippage parameter. Keep in mind this tool will swap your entire balance of these tokens.
