This Readme explains the structure and process of passing the pool test cases from the original Uniswap Protocol to a compatible and more readable cairo structure.

To test the swap() functionality, Uniswap does the following:
It creates an array of Pools
It creates an array of Swaps configurations
It does every swap with every pool, resulting in around 240 tests.

To verify the resulting values, Uniswap has a snapshot file with an element for each of these 240 test, an object with many expected values before and after each swap: pool price before, pool price after, tokens transferred, etc.

To use these values, we have made a python script ´parse_to_cairo_struct.py´ that parses the original snapshot of a pool and converts the syntax to a cairo object. This way, we can use the same testing technique.

After this, there is a process of manually reordering the outputted expected cases so that they pair with the swap cases of each pool case.
