def get_sqrt_ratio_at_tick(tick):
    abs_tick = abs(tick)
    print(f'abs_tick: {abs_tick}')
    MAX_TICK = 887272  # Definir el valor máximo de tick
    if abs_tick > MAX_TICK:
        raise ValueError('T')

    ratio = 0xfffcb933bd6fad37aa2d162d1a594001 if abs_tick & 0x1 != 0 else 0x100000000000000000000000000000000
    print(f'ratio before: {ratio}')
    if abs_tick & 0x2 != 0:
        ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128
    if abs_tick & 0x4 != 0:
        ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128
    if abs_tick & 0x8 != 0:
        ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128
    if abs_tick & 0x10 != 0:
        ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128
    if abs_tick & 0x20 != 0:
        ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128
    if abs_tick & 0x40 != 0:
        ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128
    if abs_tick & 0x80 != 0:
        ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128
    if abs_tick & 0x100 != 0:
        ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128
    if abs_tick & 0x200 != 0:
        ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128
    if abs_tick & 0x400 != 0:
        ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128
    if abs_tick & 0x800 != 0:
        ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128
    if abs_tick & 0x1000 != 0:
        ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128
    if abs_tick & 0x2000 != 0:
        ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128
    if abs_tick & 0x4000 != 0:
        ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128
    if abs_tick & 0x8000 != 0:
        ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128
    if abs_tick & 0x10000 != 0:
        ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128
    if abs_tick & 0x20000 != 0:
        ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128
    if abs_tick & 0x40000 != 0:
        ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128
    if abs_tick & 0x80000 != 0:
        ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128
    print(f'ratio after: {ratio}')
    if tick > 0:
        ratio = 2**256 // ratio
    print(f'ratio after tick > 0: {ratio}')
    # Dividir por 2^32 redondeando hacia arriba de Q128.128 a Q128.96
    sqrt_price_x96 = (ratio >> 32) + (1 if ratio % (1 << 32) != 0 else 0)
    print(f'sqrt_price_x96: {sqrt_price_x96}')
    
    return sqrt_price_x96

# Llamada de ejemplo con un valor de tick
tick_value = 887272  # Valor de tick
sqrt_result = get_sqrt_ratio_at_tick(tick_value)
print(sqrt_result)
# # Supongamos que tienes los valores de high y low en formato u128
# high = 0x963efd37  # valor del componente high en u128
# low = 0x16422c5ab4ac44e64f727e3136cf9e26   # valor del componente low en u128

# # Combina high y low para obtener el valor en u256
# value_u256 = (high << 128) + low

# # Convierte el valor de u256 a decimal
# value_decimal = int(value_u256)

# print(value_decimal)
