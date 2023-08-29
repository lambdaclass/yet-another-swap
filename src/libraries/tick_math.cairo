mod TickMath {
    use core::debug::PrintTrait;
    use core::clone::Clone;
    use option::OptionTrait;
    use traits::{Into, TryInto};
    use core::traits::PartialOrd;
    use result::Result;
    use result::ResultTrait;
    use core::integer::u128_overflowing_add;
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;
    use orion::numbers::signed_integer::i32::i32;
    use fractal_swap::numbers::fixed_point::core::{FixedTrait, FixedType};
    use fractal_swap::numbers::fixed_point::implementations::impl_64x96::{
        ONE_u128, ONE, MAX, _felt_abs, _felt_sign, FP64x96Impl, FP64x96Into, FP64x96Add,
        FP64x96AddEq, FP64x96Sub, FP64x96SubEq, FP64x96Mul, FP64x96MulEq, FP64x96Div, FP64x96DivEq,
        FP64x96PartialOrd, FP64x96PartialEq
    };
    use fractal_swap::utils::math_utils::MathUtils::{BitShiftTrait};
    use integer::BoundedInt;
    use fractal_swap::numbers::signed_integer::i256::{i256, bitwise_or};

    /// The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    // const MIN_TICK: i32 = -887272;
    fn MIN_TICK() -> i32 {
        return i32 { mag: 887272, sign: true };
    }

    /// The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    // const MAX_TICK: i32 = -MIN_TICK;
    fn MAX_TICK() -> i32 {
        return i32 { mag: 887272, sign: false };
    }
    /// The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    const MIN_SQRT_RATIO: u256 = 4295128739;
    /// The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    const MAX_SQRT_RATIO: u256 = 1461446703485210103287273052203988822378723970342;

    /// Calculates sqrt(1.0001^tick) * 2^96
    /// Throws if |tick| > max tick
    /// params: 
    ///     - tick: The input tick for the above formula
    /// return: 
    ///     - sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    ///     at the given tick
    fn get_sqrt_ratio_at_tick(tick: i32) -> FixedType {
        let abs_tick = tick.abs();
        assert(abs_tick <= MAX_TICK(), 'T');

        // Initialize ratio with a base value
        let abs_tick_u256: u256 = abs_tick.mag.into();
        let mut aux_ratio = if (abs_tick_u256 & 0x1_u256) != 0_u256 {
            0xfffcb933bd6fad37aa2d162d1a594001_u256
        } else {
            0x100000000000000000000000000000000_u256
        };
        let two_pow: u256 = 2_u256 ^ 128_u256;
        // Perform conditional ratio adjustments
        if (abs_tick_u256 & 0x2_u256) != 0 {
            aux_ratio = (aux_ratio * 0xfff97272373d413259a46990580e213a).shr(128)
        };
        if (abs_tick_u256 & 0x4_u256) != 0 {
            aux_ratio = (aux_ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc).shr(128)
        };
        if (abs_tick_u256 & 0x8_u256) != 0 {
            aux_ratio = (aux_ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0).shr(128)
        };
        if (abs_tick_u256 & 0x10_u256) != 0 {
            aux_ratio = (aux_ratio * 0xffcb9843d60f6159c9db58835c926644).shr(128)
        };
        if (abs_tick_u256 & 0x20_u256) != 0 {
            aux_ratio = (aux_ratio * 0xff973b41fa98c081472e6896dfb254c0).shr(128)
        };
        if (abs_tick_u256 & 0x40_u256) != 0 {
            aux_ratio = (aux_ratio * 0xff2ea16466c96a3843ec78b326b52861).shr(128)
        };
        if (abs_tick_u256 & 0x80_u256) != 0 {
            aux_ratio = (aux_ratio * 0xfe5dee046a99a2a811c461f1969c3053).shr(128)
        };
        if (abs_tick_u256 & 0x100_u256) != 0 {
            aux_ratio = (aux_ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4).shr(128)
        };
        if (abs_tick_u256 & 0x200_u256) != 0 {
            aux_ratio = (aux_ratio * 0xf987a7253ac413176f2b074cf7815e54).shr(128)
        };
        if (abs_tick_u256 & 0x400_u256) != 0 {
            aux_ratio = (aux_ratio * 0xf3392b0822b70005940c7a398e4b70f3).shr(128)
        };
        if (abs_tick_u256 & 0x800_u256) != 0 {
            aux_ratio = (aux_ratio * 0xe7159475a2c29b7443b29c7fa6e889d9).shr(128)
        };
        if (abs_tick_u256 & 0x1000_u256) != 0 {
            aux_ratio = (aux_ratio * 0xd097f3bdfd2022b8845ad8f792aa5825).shr(128)
        };
        if (abs_tick_u256 & 0x2000_u256) != 0 {
            aux_ratio = (aux_ratio * 0xa9f746462d870fdf8a65dc1f90e061e5).shr(128)
        };
        if (abs_tick_u256 & 0x4000_u256) != 0 {
            aux_ratio = (aux_ratio * 0x70d869a156d2a1b890bb3df62baf32f7).shr(128)
        };
        if (abs_tick_u256 & 0x8000_u256) != 0 {
            aux_ratio = (aux_ratio * 0x31be135f97d08fd981231505542fcfa6).shr(128)
        };
        if (abs_tick_u256 & 0x10000_u256) != 0 {
            aux_ratio = (aux_ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9).shr(128)
        };
        if (abs_tick_u256 & 0x20000_u256) != 0 {
            aux_ratio = (aux_ratio * 0x5d6af8dedb81196699c329225ee604).shr(128)
        };
        if (abs_tick_u256 & 0x40000_u256) != 0 {
            aux_ratio = (aux_ratio * 0x2216e584f5fa1ea926041bedfe98).shr(128)
        };
        if (abs_tick_u256 & 0x80000_u256) != 0 {
            aux_ratio = (aux_ratio * 0x48a170391f7dc42444e8fa2).shr(128)
        };

        // Adjust ratio for positive ticks
        if tick > IntegerTrait::<i32>::new(0, false) {
            aux_ratio = BoundedInt::max() / aux_ratio;
        }

        let aux_add = if (aux_ratio % (1.shl(32)) == 0) {
            0
        } else {
            1
        };
        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        let sqrtPriceX96_mag = ((aux_ratio.shr(32)) + aux_add) & ((1.shl(160)) - 1);
        return FixedTrait::new(sqrtPriceX96_mag, false);
    }

    fn _gt(a: u256, b: u256) -> u256 {
        let val = if (a > b) {
            1
        } else {
            0
        };

        return val;
    }

    /// Calculates the greatest tick value such that `getRatioAtTick(tick) <= ratio`.
    /// Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// params:
    ///     - sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96.
    /// return:
    ///     - tick The greatest tick for which the ratio is less than or equal to the input ratio.
    fn get_tick_at_sqrt_ratio(sqrtPriceX96: FixedType) -> i32 {
        // second inequality must be < because the price can never reach the price at the max tick
        assert(
            sqrtPriceX96 >= FixedTrait::new(MIN_SQRT_RATIO, false)
                && sqrtPriceX96 < FixedTrait::new(MAX_SQRT_RATIO, false),
            'R'
        );
        let ratio = sqrtPriceX96.mag.shl(32);
        let mut r = ratio.clone();
        let mut msb = 0;
        // UNTIL HERE EVERYTHING MATCHES THE PYTHON VERSION.

        let f: u256 = _gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF).shl(7);
        msb = msb | f;
        r = r.shr(f);

        let f: u256 = _gt(r, 0xFFFFFFFFFFFFFFFF).shl(6);
        msb = msb | f;
        r = r.shr(f);

        let f: u256 = _gt(r, 0xFFFFFFFF).shl(5);
        msb = msb | f;
        r = r.shr(f);

        let f: u256 = _gt(r, 0xFFFF).shl(4);
        msb = msb | f;
        r = r.shr(f);

        let f: u256 = _gt(r, 0xFF).shl(3);
        msb = msb | f;
        r = r.shr(f);

        let f: u256 = _gt(r, 0xF).shl(2);
        msb = msb | f;
        r = r.shr(f);

        let f: u256 = _gt(r, 0x3).shl(1);
        msb = msb | f;
        r = r.shr(f);

        let f: u256 = _gt(r, 0x1);
        msb = msb | f;

        let mut r = if (msb >= 128) {
            ratio.shr(msb - 127)
        } else {
            ratio.shl(127 - msb)
        };

        // here we need log_2 as i256, and cast msb into i256 before the substraction.
        // let mut log_2: u256 = (msb - 128).shl(64); // -> OLD IMPLEMENTATION.
        let a = IntegerTrait::<i256>::new(128, false);
        let b = IntegerTrait::<i256>::new(64, false);

        let mut log_2: i256 = (IntegerTrait::<i256>::new(msb, false) - a).shl(b);

        r = (r * r).shr(127);
        let f = r.shr(128);
        log_2 = bitwise_or(log_2, IntegerTrait::<i256>::new(f.shl(63), false));
        r = r.shr(f);

        r = (r * r).shr(127);
        let f = r.shr(128);
        log_2 = bitwise_or(log_2, IntegerTrait::<i256>::new(f.shl(62), false));
        r = r.shr(f);

        r = (r * r).shr(127);
        let f = r.shr(128);
        log_2 = bitwise_or(log_2, IntegerTrait::<i256>::new(f.shl(61), false));
        r = r.shr(f);

        r = (r * r).shr(127);
        let f = r.shr(128);
        log_2 = bitwise_or(log_2, IntegerTrait::<i256>::new(f.shl(60), false));
        r = r.shr(f);

        r = (r * r).shr(127);
        let f = r.shr(128);
        log_2 = bitwise_or(log_2, IntegerTrait::<i256>::new(f.shl(59), false));
        r = r.shr(f);

        r = (r * r).shr(127);
        let f = r.shr(128);
        log_2 = bitwise_or(log_2, IntegerTrait::<i256>::new(f.shl(58), false));
        r = r.shr(f);

        r = (r * r).shr(127);
        let f = r.shr(128);
        log_2 = bitwise_or(log_2, IntegerTrait::<i256>::new(f.shl(57), false));
        r = r.shr(f);

        r = (r * r).shr(127);
        let f = r.shr(128);
        log_2 = bitwise_or(log_2, IntegerTrait::<i256>::new(f.shl(56), false));
        r = r.shr(f);

        r = (r * r).shr(127);
        let f = r.shr(128);
        log_2 = bitwise_or(log_2, IntegerTrait::<i256>::new(f.shl(55), false));
        r = r.shr(f);

        r = (r * r).shr(127);
        let f = r.shr(128);
        log_2 = bitwise_or(log_2, IntegerTrait::<i256>::new(f.shl(54), false));
        r = r.shr(f);

        r = (r * r).shr(127);
        let f = r.shr(128);
        log_2 = bitwise_or(log_2, IntegerTrait::<i256>::new(f.shl(53), false));
        r = r.shr(f);

        r = (r * r).shr(127);
        let f = r.shr(128);
        log_2 = bitwise_or(log_2, IntegerTrait::<i256>::new(f.shl(52), false));
        r = r.shr(f);

        r = (r * r).shr(127);
        let f = r.shr(128);
        log_2 = bitwise_or(log_2, IntegerTrait::<i256>::new(f.shl(51), false));
        r = r.shr(f);

        r = (r * r).shr(127);
        let f = r.shr(128);
        log_2 = bitwise_or(log_2, IntegerTrait::<i256>::new(f.shl(50), false));

        let log_sqrt10001 = log_2
            * IntegerTrait::<i256>::new(255738958999603826347141, false); // 128.128 number

        let tickLow = as_i32(
            (log_sqrt10001
                - IntegerTrait::<i256>::new(3402992956809132418596140100660247210, false))
                .shr(IntegerTrait::<i256>::new(128, false))
        );

        let tickHi = as_i32(
            (log_sqrt10001
                + IntegerTrait::<i256>::new(291339464771989622907027621153398088495, false))
                .shr(IntegerTrait::<i256>::new(128, false))
        );

        let tick = if (tickLow == tickHi) {
            tickLow
        } else {
            if (get_sqrt_ratio_at_tick(tickHi) <= sqrtPriceX96) {
                tickHi
            } else {
                tickLow
            }
        };

        return tick;
    }

    fn as_i32(x: i256) -> i32 {
        let mask: u256 = 0xFFFF_FFFF / 2; // Mask for the least significant 32 bits
        return IntegerTrait::<i32>::new((x.mag & mask).try_into().unwrap(), x.sign);
    }
}
