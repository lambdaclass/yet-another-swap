This Readme explains the structure and process of passing the pool test cases from the original Uniswap Protocol to a compatible and more readable cairo structure.

To test the swap() functionality, Uniswap does the following:
    It creates an array of Pools
    It creates an array of Swaps configurations
    It does every swap with every pool, resulting in around 240 tests.

To verify the resulting values, Uniswap has a snapshot file with an element for each of these 240 test, an obje