import sys
from decimal import Decimal, getcontext

def parse_price(formatted_price):
    getcontext().prec = 50
    price = Decimal(formatted_price)
    original_price = (price.sqrt()) * (2 ** 96)
    return str(original_price)

def main():
    if len(sys.argv) != 2:
        print("Usage: python script.py <formatted_price>")
        sys.exit(1)
    formatted_price = sys.argv[1]
    result = parse_price(formatted_price)
    print(f"RESULT: {result}")

if __name__ == "__main__":
    main()
