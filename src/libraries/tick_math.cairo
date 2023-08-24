mod TickMath {
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
        let ratio = if (i32::rem(abs_tick, 2)) != 0 {
            0xfffcb933bd6fad37aa2d162d1a594001
        } else {
            0x100000000000000000000000000000000
        };

        // Perform conditional ratio adjustments
        if (i32::rem(abs_tick, 4)) >= 2 {
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) / 2.pow(128);
        }
        if (i32::rem(abs_tick, 8)) >= 4 {
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) / 2.pow(128);
        }
        if (i32::rem(abs_tick, 16)) >= 8 {
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) / 2.pow(128);
        }
        if (i32::rem(abs_tick, 32)) >= 16 {
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) / 2.pow(128);
        }
        if (i32::rem(abs_tick, 64)) >= 32 {
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) / 2.pow(128);
        }
        if (i32::rem(abs_tick, 128)) >= 64 {
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) / 2.pow(128);
        }
        if (i32::rem(abs_tick, 256)) >= 128 {
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) / 2.pow(128);
        }
        if (i32::rem(abs_tick, 512)) >= 256 {
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) / 2.pow(128);
        }
        if (i32::rem(abs_tick, 1024)) >= 512 {
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) / 2.pow(128);
        }
        if (i32::rem(abs_tick, 2048)) >= 1024 {
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) / 2.pow(128);
        }
        if (i32::rem(abs_tick, 4096)) >= 2048 {
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) / 2.pow(128);
        }
        if (i32::rem(abs_tick, 8192)) >= 4096 {
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) / 2.pow(128);
        }
        if (i32::rem(abs_tick, 16384)) >= 8192 {
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) / 2.pow(128);
        }
        if (i32::rem(abs_tick, 32768)) >= 16384 {
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) / 2.pow(128);
        }
        if (i32::rem(abs_tick, 65536)) >= 32768 {
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) / 2.pow(128);
        }
        if (i32::rem(abs_tick, 131072)) >= 65536 {
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) / 2.pow(128);
        }
        if (i32::rem(abs_tick, 262144)) >= 131072 {
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) / 2.pow(128);
        }
        if (i32::rem(abs_tick, 524288)) >= 262144 {
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) / 2.pow(128);
        }
        if (i32::rem(abs_tick, 1048576)) >= 524288 {
            ratio = (ratio * 0x48a170391f7dc42444e8fa2) / 2.pow(128);
        }

        // Adjust ratio for positive ticks
        if tick > 0 {
            ratio = max_uint256_value / ratio;
        }

        // Calculate square root
        return ratio.sqrt();
    }
}
