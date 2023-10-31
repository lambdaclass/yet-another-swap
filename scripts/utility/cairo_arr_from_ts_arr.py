# Assuming you have parsed the TypeScript file and extracted the array of structures
typescript_data = [...]

# Define the Python struct class
class SwapInCairo:
    def __init__(self, zero_for_one, exact_out, amount_specified, has_sqrt_price_limit, sqrt_price_limit_u256):
        self.zero_for_one = zero_for_one
        self.exact_out = exact_out
        self.amount_specified = amount_specified
        self.has_sqrt_price_limit = has_sqrt_price_limit
        self.sqrt_price_limit_u256 = sqrt_price_limit_u256


# Initialize an empty array for the structs
struct_array = []


# Iterate and transform the TypeScript data into Python structs
for ts_structure in typescript_data:
    zero_for_one = ts_structure['zero_for_one']
    exact_out = ts_structure['exact_out']
    amount_specified = ts_structure['amount_specified']
    has_sqrt_price_limit = ts_structure['has_sqrt_price_limit']
    sqrt_price_limit_u256 = ts_structure['sqrt_price_limit_u256']

    python_struct = SwapInCairo(zero_for_one, exact_out, amount_specified, has_sqrt_price_limit, sqrt_price_limit_u256)
    struct_array.append(python_struct)


# Generate code to create an array of structs in Python
code_in_cairo = f"struct_array = [{', '.join([f'MyStruct({s.zero_for_one}, {s.exact_out}, {s.amount_specified}, {s.has_sqrt_price_limit}, {s.sqrt_price_limit_u256})' for s in struct_array])}]"
print(python_code)