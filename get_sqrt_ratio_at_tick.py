def get_sqrt_ratio_at_tick(tick):
    abs_tick = abs(tick)
    print(f'abs_tick: {abs_tick}')
    MAX_TICK = 887272  # Definir el valor máximo de tick
    if abs_tick > MAX_TICK:
        raise ValueError('T')

    ratio = 0xfffcb933bd6fad37aa2d162d1a594001 if abs_tick & 0x1 != 0 else 0x100000000000000000000000000000000
    print(f'aux ratio: {ratio}')
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
    print(f'adjusted ratio: {ratio}')
    # Dividir por 2^32 redondeando hacia arriba de Q128.128 a Q128.96
    sqrt_price_x96 = (ratio >> 32) + (1 if ratio % (1 << 32) != 0 else 0)
    print(f'result: {sqrt_price_x96}')
    
    return sqrt_price_x96

import math

def getTickAtSqrtRatio(sqrtPriceX96):
    MIN_SQRT_RATIO = 4295128739
    MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342

    if not (MIN_SQRT_RATIO <= sqrtPriceX96 < MAX_SQRT_RATIO):
        raise ValueError("Invalid sqrtPriceX96 value")

    ratio = sqrtPriceX96 << 32
    print(f'ratio: {ratio}')
    r = ratio
    msb = 0

    for shift in range(7, -1, -1):
        if r > 2**256 - 1:
            f = 1 << shift
            msb |= f
            r >>= f
    
    print(f'msb: {msb}')
    if msb >= 128:
        r = ratio >> (msb - 127)
    else:
        'overflow'.print();
        r = ratio << (127 - msb)

    log_2 = (msb - 128) << 64

    for _ in range(13):
        r = (r * r) >> 127
        f = r >> 128
        log_2 |= f << (63 - _)
        r >>= f

    log_sqrt10001 = log_2 * 255738958999603826347141

    tickLow = int((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128) & 0xFFFFFF
    tickHi = (log_sqrt10001 + 291339464771989622907027621153398088495) >> 128  & 0xFFFFFF

    print(f'tickHi: {tickHi}')
    if tickLow == tickHi:
        return tickLow
    else:
        # Aquí tendrías que reemplazar esta parte con la llamada a la función getSqrtRatioAtTick(tickHi)
        # y luego comparar si es menor o igual a sqrtPriceX96
        return tickHi if get_sqrt_ratio_at_tick(tickHi) <= sqrtPriceX96 else tickLow

# Ejemplo de uso
sqrtPriceX96 = 4295128739
tick = getTickAtSqrtRatio(sqrtPriceX96)
print("Tick:", tick)
assert(tick == -887272)
