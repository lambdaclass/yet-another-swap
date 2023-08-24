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

    fn _conditional_ratio_adjustments_1(
        mut ratio: FixedType, abs_tick: i32, two_pow: FixedType
    ) -> FixedType {
        if (abs_tick % IntegerTrait::<i32>::new(4, false)) >= IntegerTrait::<i32>::new(2, false) {
            ratio = (ratio * FixedTrait::from_felt(0xfff97272373d413259a46990580e213a)) / two_pow;
        }
        if (abs_tick % IntegerTrait::<i32>::new(8, false)) >= IntegerTrait::<i32>::new(4, false) {
            ratio = (ratio * FixedTrait::from_felt(0xfff2e50f5f656932ef12357cf3c7fdcc)) / two_pow;
        }
        if (abs_tick % IntegerTrait::<i32>::new(16, false)) >= IntegerTrait::<i32>::new(8, false) {
            ratio = (ratio * FixedTrait::from_felt(0xffe5caca7e10e4e61c3624eaa0941cd0)) / two_pow;
        }
        if (abs_tick % IntegerTrait::<i32>::new(32, false)) >= IntegerTrait::<i32>::new(16, false) {
            ratio = (ratio * FixedTrait::from_felt(0xffcb9843d60f6159c9db58835c926644)) / two_pow;
        }
        if (abs_tick % IntegerTrait::<i32>::new(64, false)) >= IntegerTrait::<i32>::new(32, false) {
            ratio = (ratio * FixedTrait::from_felt(0xff973b41fa98c081472e6896dfb254c0)) / two_pow;
        }
        if (abs_tick % IntegerTrait::<i32>::new(
            128, false
        )) >= IntegerTrait::<i32>::new(64, false) {
            ratio = (ratio * FixedTrait::from_felt(0xff2ea16466c96a3843ec78b326b52861)) / two_pow;
        }
        return ratio;
    }

    fn _conditional_ratio_adjustments_2(
        mut ratio: FixedType, abs_tick: i32, two_pow: FixedType
    ) -> FixedType {
        if (abs_tick % IntegerTrait::<i32>::new(
            256, false
        )) >= IntegerTrait::<i32>::new(128, false) {
            ratio = (ratio * FixedTrait::from_felt(0xfe5dee046a99a2a811c461f1969c3053)) / two_pow;
        }
        if (abs_tick % IntegerTrait::<i32>::new(
            512, false
        )) >= IntegerTrait::<i32>::new(256, false) {
            ratio = (ratio * FixedTrait::from_felt(0xfcbe86c7900a88aedcffc83b479aa3a4)) / two_pow;
        }
        if (abs_tick % IntegerTrait::<i32>::new(
            1024, false
        )) >= IntegerTrait::<i32>::new(512, false) {
            ratio = (ratio * FixedTrait::from_felt(0xf987a7253ac413176f2b074cf7815e54)) / two_pow;
        }
        if (abs_tick % IntegerTrait::<i32>::new(
            2048, false
        )) >= IntegerTrait::<i32>::new(1024, false) {
            ratio = (ratio * FixedTrait::from_felt(0xf3392b0822b70005940c7a398e4b70f3)) / two_pow;
        }
        if abs_tick % IntegerTrait::<i32>::new(
            4096, false
        ) >= IntegerTrait::<i32>::new(2048, false) {
            ratio = (ratio * FixedTrait::from_felt(0xe7159475a2c29b7443b29c7fa6e889d9)) / two_pow;
        }
        return ratio;
    }

    fn _conditional_ratio_adjustments_3(
        mut ratio: FixedType, abs_tick: i32, two_pow: FixedType
    ) -> FixedType {
        if abs_tick % IntegerTrait::<i32>::new(
            8192, false
        ) >= IntegerTrait::<i32>::new(4096, false) {
            ratio = (ratio * FixedTrait::from_felt(0xd097f3bdfd2022b8845ad8f792aa5825)) / two_pow;
        }
        if abs_tick % IntegerTrait::<i32>::new(
            16384, false
        ) >= IntegerTrait::<i32>::new(8192, false) {
            ratio = (ratio * FixedTrait::from_felt(0xa9f746462d870fdf8a65dc1f90e061e5)) / two_pow;
        }
        if abs_tick % IntegerTrait::<i32>::new(
            32768, false
        ) >= IntegerTrait::<i32>::new(16384, false) {
            ratio = (ratio * FixedTrait::from_felt(0x70d869a156d2a1b890bb3df62baf32f7)) / two_pow;
        }
        return ratio;
    }

    fn _conditional_ratio_adjustments_4(
        mut ratio: FixedType, abs_tick: i32, two_pow: FixedType
    ) -> FixedType {
        if abs_tick % IntegerTrait::<i32>::new(
            65536, false
        ) >= IntegerTrait::<i32>::new(32768, false) {
            ratio = (ratio * FixedTrait::from_felt(0x31be135f97d08fd981231505542fcfa6)) / two_pow;
        }
        if abs_tick % IntegerTrait::<i32>::new(
            131072, false
        ) >= IntegerTrait::<i32>::new(65536, false) {
            ratio = (ratio * FixedTrait::from_felt(0x9aa508b5b7a84e1c677de54f3e99bc9)) / two_pow;
        }
        if abs_tick % IntegerTrait::<i32>::new(
            262144, false
        ) >= IntegerTrait::<i32>::new(131072, false) {
            ratio = (ratio * FixedTrait::from_felt(0x5d6af8dedb81196699c329225ee604)) / two_pow;
        }

        return ratio;
    }

    fn _conditional_ratio_adjustments_5(
        mut ratio: FixedType, abs_tick: i32, two_pow: FixedType
    ) -> FixedType {
        if abs_tick % IntegerTrait::<i32>::new(
            524288, false
        ) >= IntegerTrait::<i32>::new(262144, false) {
            ratio = (ratio * FixedTrait::from_felt(0x2216e584f5fa1ea926041bedfe98)) / two_pow;
        }
        if abs_tick % IntegerTrait::<i32>::new(
            1048576, false
        ) >= IntegerTrait::<i32>::new(524288, false) {
            ratio = (ratio * FixedTrait::from_felt(0x48a170391f7dc42444e8fa2)) / two_pow;
        }

        return ratio;
    }

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

        let zero: i32 = IntegerTrait::<i32>::new(0, false);
        // Initialize ratio with a base value
        let mut ratio = if abs_tick % IntegerTrait::<i32>::new(2, false) != zero {
            FixedTrait::from_felt(0xfffcb933bd6fad37aa2d162d1a594001)
        } else {
            FixedTrait::from_felt(0x100000000000000000000000000000000)
        };

        // Perform conditional ratio adjustments
        let two_pow = 2 ^ 128_u8;
        let two_pow = FixedTrait::from_felt(two_pow.into());
        let ratio = _conditional_ratio_adjustments_1(ratio, abs_tick, two_pow);
        let ratio = _conditional_ratio_adjustments_2(ratio, abs_tick, two_pow);
        let ratio = _conditional_ratio_adjustments_3(ratio, abs_tick, two_pow);
        let ratio = _conditional_ratio_adjustments_4(ratio, abs_tick, two_pow);
        let ratio = _conditional_ratio_adjustments_5(ratio, abs_tick, two_pow);

        // Calculate square root
        return ratio.sqrt();
    }
}
