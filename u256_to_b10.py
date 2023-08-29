# Supongamos que tienes los valores de high y low en formato u128
high = 0x0  # valor del componente high en u128
low = 0x1000276a300000000   # valor del componente low en u128

# Combina high y low para obtener el valor en u256
value_u256 = (high << 128) + low

# Convierte el valor de u256 a decimal
value_decimal = int(value_u256)

print(value_decimal)
