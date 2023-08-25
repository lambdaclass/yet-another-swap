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
        let mut aux_ratio = if abs_tick.mag.into() & 0x1_u256 != 0_u256 {
            0xfffcb933bd6fad37aa2d162d1a594001_u256
        } else {
            0x100000000000000000000000000000000_u256
        };

        let two_pow: u256 = 2_u256 ^ 128_u256;
        // Perform conditional ratio adjustments
        if (abs_tick % IntegerTrait::<i32>::new(4, false)) >= IntegerTrait::<i32>::new(2, false) {
            aux_ratio = (aux_ratio * 0xfff97272373d413259a46990580e213a_u256).shr(two_pow);
        }
        if (abs_tick % IntegerTrait::<i32>::new(8, false)) >= IntegerTrait::<i32>::new(4, false) {
            aux_ratio = (aux_ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc_u256).shr(two_pow);
        }
        if (abs_tick % IntegerTrait::<i32>::new(16, false)) >= IntegerTrait::<i32>::new(8, false) {
            aux_ratio = (aux_ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0_u256).shr(two_pow);
        }
        if (abs_tick % IntegerTrait::<i32>::new(32, false)) >= IntegerTrait::<i32>::new(16, false) {
            aux_ratio = (aux_ratio * 0xffcb9843d60f6159c9db58835c926644_u256).shr(two_pow);
        }
        if (abs_tick % IntegerTrait::<i32>::new(64, false)) >= IntegerTrait::<i32>::new(32, false) {
            aux_ratio = (aux_ratio * 0xff973b41fa98c081472e6896dfb254c0_u256).shr(two_pow);
        }
        if (abs_tick % IntegerTrait::<i32>::new(
            128, false
        )) >= IntegerTrait::<i32>::new(64, false) {
            aux_ratio = (aux_ratio * 0xff2ea16466c96a3843ec78b326b52861_u256).shr(two_pow);
        }
        if (abs_tick % IntegerTrait::<i32>::new(
            256, false
        )) >= IntegerTrait::<i32>::new(128, false) {
            aux_ratio = (aux_ratio * 0xfe5dee046a99a2a811c461f1969c3053_u256).shr(two_pow);
        }
        if (abs_tick % IntegerTrait::<i32>::new(
            512, false
        )) >= IntegerTrait::<i32>::new(256, false) {
            aux_ratio = (aux_ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4_u256).shr(two_pow);
        }
        if (abs_tick % IntegerTrait::<i32>::new(
            1024, false
        )) >= IntegerTrait::<i32>::new(512, false) {
            aux_ratio = (aux_ratio * 0xf987a7253ac413176f2b074cf7815e54_u256).shr(two_pow);
        }
        if (abs_tick % IntegerTrait::<i32>::new(
            2048, false
        )) >= IntegerTrait::<i32>::new(1024, false) {
            aux_ratio = (aux_ratio * 0xf3392b0822b70005940c7a398e4b70f3_u256).shr(two_pow);
        }
        if abs_tick % IntegerTrait::<i32>::new(
            4096, false
        ) >= IntegerTrait::<i32>::new(2048, false) {
            aux_ratio = (aux_ratio * 0xe7159475a2c29b7443b29c7fa6e889d9_u256).shr(two_pow);
        }
        if abs_tick % IntegerTrait::<i32>::new(
            8192, false
        ) >= IntegerTrait::<i32>::new(4096, false) {
            aux_ratio = (aux_ratio * 0xd097f3bdfd2022b8845ad8f792aa5825_u256).shr(two_pow);
        }
        if abs_tick % IntegerTrait::<i32>::new(
            16384, false
        ) >= IntegerTrait::<i32>::new(8192, false) {
            aux_ratio = (aux_ratio * 0xa9f746462d870fdf8a65dc1f90e061e5_u256).shr(two_pow);
        }
        if abs_tick % IntegerTrait::<i32>::new(
            32768, false
        ) >= IntegerTrait::<i32>::new(16384, false) {
            aux_ratio = (aux_ratio * 0x70d869a156d2a1b890bb3df62baf32f7_u256).shr(two_pow);
        }
        if abs_tick % IntegerTrait::<i32>::new(
            65536, false
        ) >= IntegerTrait::<i32>::new(32768, false) {
            aux_ratio = (aux_ratio * 0x31be135f97d08fd981231505542fcfa6_u256).shr(two_pow);
        }
        if abs_tick % IntegerTrait::<i32>::new(
            131072, false
        ) >= IntegerTrait::<i32>::new(65536, false) {
            aux_ratio = (aux_ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9_u256).shr(two_pow);
        }
        if abs_tick % IntegerTrait::<i32>::new(
            262144, false
        ) >= IntegerTrait::<i32>::new(131072, false) {
            aux_ratio = (aux_ratio * 0x5d6af8dedb81196699c329225ee604_u256).shr(two_pow);
        }
        if abs_tick % IntegerTrait::<i32>::new(
            524288, false
        ) >= IntegerTrait::<i32>::new(262144, false) {
            aux_ratio = (aux_ratio * 0x2216e584f5fa1ea926041bedfe98_u256).shr(two_pow);
        }
        if abs_tick % IntegerTrait::<i32>::new(
            1048576, false
        ) >= IntegerTrait::<i32>::new(524288, false) {
            aux_ratio = (aux_ratio * 0x48a170391f7dc42444e8fa2_u256).shr(two_pow);
        }

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
}
