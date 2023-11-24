import sys
import math


def calculate_difference(a, b):
    dif = a - b
    dif_x96 = dif / (2**96)
    dif_x96 = dif_x96**2
    print('abs dif', dif_x96)
    print('percentage dif', dif_x96 /  max(a, b))

    sqrt_price_a = a / (2**96)
    sqrt_price_b = b / (2**96)
    price_a = float(sqrt_price_a ** 2)
    price_b = float(sqrt_price_b ** 2)

    absolute_difference = abs(price_a - price_b)
    percentage_difference = '{:.50f}'.format((absolute_difference / max(price_a, price_b)) * 100)

    # Print the results
    formatted_diff = '{:.50f}'.format(abs(a - b) / 2**96)
    print('// pool_price_after from Uniswap:', b)
    print('// Difference: ( sqrt_X96:', abs(a - b),')', '( decimals:', formatted_diff,')')
    print("Percentage Difference:", percentage_difference, "%")

if __name__ == "__main__":
    # Check if two command-line arguments are provided
    if len(sys.argv) != 3:
        print("Usage: python difference.py <value_a> <value_b>")
        sys.exit(1)

    # Get values from command-line arguments
    a = int(sys.argv[1])
    b = int(sys.argv[2])

    # Calculate and display the difference
    calculate_difference(a, b)