# Input of the script
# Object {
#   "amount0Before": "2000000000000000000",
#   "amount0Delta": "1000",
#   "amount1Before": "2000000000000000000",
#   "amount1Delta": "-998",
#   "executionPrice": "0.99800",
#   "feeGrowthGlobal0X128Delta": "170141183460469231731",
#   "feeGrowthGlobal1X128Delta": "0",
#   "poolPriceAfter": "1.0000",
#   "poolPriceBefore": "1.0000",
#   "tickAfter": -1,
#   "tickBefore": 0,
# }
# `;

# Output of the script
# let swap_expected_result = SwapExpectedResults {
#   amount_0_before: 2000000000000000000,
#   amount_0_delta: IntegerTrait::<i256>::new(1000, false),
#   amount_1_before: 2000000000000000000,
#   amount_1_delta: IntegerTrait::<i256>::new(998, true),
#   execution_price: 99800, // original executionPrice * 10**5
#   fee_growth_global_0_X128_delta: 170141183460469231731,
#   fee_growth_global_1_X128_delta: 0,
#   pool_price_after: 79228162514264337593543950336, //  after applying parse_price from test_to_cairo
#   pool_price_before: 79228162514264337593543950336, //  after applying parse_price from test_to_cairo
#   tick_after: IntegerTrait::<i32>::new(1, true),
#   tick_before: IntegerTrait::<i32>::new(0, false),
# }

# pass "True" to "true"
def sign_to_text(sign):
    if sign :
        return "true"
    else:
        return "false"

def format_amount_delta(amount_delta):
    # convert to integer
    amount_delta = int(amount_delta)
    # if the amount_delta is negative, then sign is true
    sign = amount_delta < 0
    # convert to positive
    amount_delta = abs(amount_delta)
    # return the formatted amount_delta and if its 0 then sign is false
    return f'IntegerTrait::<i256>::new({amount_delta}, {sign_to_text(sign)})'

def format_execution_price(execution_price):
    # remove the quotes
    execution_price = execution_price.replace('"', '')
    # remove the comma
    execution_price = execution_price.replace(',', '')
    # convert to float
    execution_price = float(execution_price)
    # multiply by 10**5
    execution_price = execution_price * 10**5
    # convert to integer
    execution_price = int(round(execution_price))
    # return the formatted execution_price
    return f'{execution_price}'

# end format is * 10**5
def format_pool_price(pool_price):
    # remove the quotes
    pool_price = pool_price.replace('"', '')
    # remove the comma
    pool_price = pool_price.replace(',', '')
    # convert to float
    pool_price = float(pool_price)
    # dislpace comma
    pool_price = pool_price * 10**5
    rounded = '%s' % float('%.5g' % pool_price)
    pool_price = float(rounded)
    ## take the square root
    #pool_price = pool_price ** (1/2)
    ## multiply by 2**96
    #pool_price = pool_price * 2**96
    # convert to integer
    pool_price = int(pool_price)
    # return the formatted pool_price
    return f'{pool_price}'

def format_tick(tick):
    # remove the quotes
    tick = tick.replace('"', '')
    # remove the comma
    tick = tick.replace(',', '')
    # convert to integer
    tick = int(tick)
    # return the formatted tick
    return f'IntegerTrait::<i32>::new({abs(tick)}, {sign_to_text(tick < 0)})'

def parse_object(object):
    # first save in a dictionary the key-value pairs
    # each key is a string and each value is a string
    # the value of a key is separated by a "," from the next key
    values = {}
    keys_in_cairo ={
        "amount0Before": "amount_0_before",
        "amount0Delta": "amount_0_delta",
        "amount1Before": "amount_1_before",
        "amount1Delta": "amount_1_delta",
        "executionPrice": "execution_price",
        "feeGrowthGlobal0X128Delta": "fee_growth_global_0_X128_delta",
        "feeGrowthGlobal1X128Delta": "fee_growth_global_1_X128_delta",
        "poolPriceAfter": "pool_price_after",
        "poolPriceBefore": "pool_price_before",
        "tickAfter": "tick_after",
        "tickBefore": "tick_before",
        "poolBalance0": "pool_balance_0",
        "poolBalance1": "pool_balance_1",
        "poolPriceBefore": "pool_price_before",
        "swapError": "swap_error",
        "tickBefore": "tick_before",
    }
    # key is the original key object, and the value is a lambda function that will apply the necessary changes
    # for every key it's the identity function
    # except for:
    # amount_0_delta -> IntegerTrait::<i256>::new(value, false)
    functions_to_apply = {
        "amount_0_delta": format_amount_delta,
        "amount_1_delta": format_amount_delta,
        "execution_price": format_execution_price,
        "pool_price_after": format_pool_price,
        "pool_price_before": format_pool_price,
        "tick_after": format_tick,
        "tick_before": format_tick,
    }

    # remove the spaces and the new lines
    object = object.replace(" ", "")
    object = object.replace("\n", "")

    # remove the '"' from the keys and the values
    object = object.replace('"', "")
    # split the object by ","
    object = object.split(",")
    # remove the last element, which is empty
    object.pop()
    # for each key-value pair
    for key_value in object:
        # split by ":"
        key_value = key_value.split(":")
        # the key is the first element
        key = key_value[0]
        # the value is the second element
        value = key_value[1]
        # save the key-value pair in the dictionary
        values[keys_in_cairo[key]] = value
    
    # for each key-value in values apply the corresponding function
    for key, value in values.items():
        # if the key is in functions_to_apply
        if key in functions_to_apply:
            # apply the function
            values[key] = functions_to_apply[key](value)
    return values

#main
if __name__ == "__main__":
    # read from 'pool2_swap1.txt'
    file = open('./pool2_swaps_torober.txt', 'r')
    objects = file.read()
    # each object is separated by a ;\n from the next object
    objects = objects.split(';\n')
   
   # for each object save only the object that is the content that is between { and }
    parsed_objects = []
    for object in objects:
        # find the first {
        start = object.find('{')
        # find the last }
        end = object.rfind('}')
        # save the object
        object = object[start+1:end]
        # parse the object
        parsed_objects.append(parse_object(object))

    to_print = ""
    for i, object in enumerate(parsed_objects):
        # swap_variable_string = "let swap_expected_result = SwapExpectedResults {"
        swap_variable_string = "\t\t\tSwapExpectedResults {"

        for key, value in object.items():
            swap_variable_string += f'\n\t\t\t\t{key}: {value},'
        swap_variable_string += "\n\t\t\t},"

        if i != len(parsed_objects) - 1:
            swap_variable_string += "\n"
        to_print += swap_variable_string

    # save the result in 'swap_expected_result.txt'
    file = open('swap_expected_result.txt', 'w')
    file.write(to_print)


