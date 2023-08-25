mod TickMath {
    use option::OptionTrait;
    use traits::{Into, TryInto};
    use core::traits::PartialOrd;
    use result::Result;
    use result::ResultTrait;
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;
    use orion::numbers::signed_integer::i32::i32;
    use cubit::f128::{FixedTrait, ONE_u128};
    use cubit::f128::Fixed;

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
    const MIN_SQRT_RATIO: u256 = 0x10000000000000000;
    /// The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    const MAX_SQRT_RATIO: u256 = 0xffffffff00000000;

    /// Calculates sqrt(1.0001^tick) * 2^96
    /// Throws if |tick| > max tick
    /// params: 
    ///     - tick: The input tick for the above formula
    /// return: 
    ///     - sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    ///     at the given tick
    fn get_sqrt_ratio_at_tick(tick: i32) -> Fixed {
        let abs_tick = tick.abs();
        assert(abs_tick <= MAX_TICK(), 'T');

        // sqrt(1.0001^tick) * 2^96
        let a = FixedTrait::new(18448588748116922571, false); // 1.0001
        let tick_fp = FixedTrait::new(tick.mag.into(), tick.sign);
        let pow = a.pow(tick_fp);
        let sqrt = pow.sqrt();
        let two_pow = FixedTrait::ONE();
        return sqrt * two_pow;
    }
}
