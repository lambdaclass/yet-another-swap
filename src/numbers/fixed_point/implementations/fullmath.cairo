mod FullMath {
    use integer::{BoundedInt, u256_wide_mul, u512_safe_div_rem_by_u256, u256_try_as_non_zero};
    use option::OptionTrait;

    // Multiplies two u256 numbers and divides the result by a third.
    // Credits to sphinx-protocol
    // https://github.com/sphinx-protocol/types252/blob/c5d209fe2b4c2cb2a21f9ad463de13d2c5dffa46/src/math/math.cairo#L37  
    // # Arguments
    // * `a` - The multiplicand
    // * `b` - The multiplier
    // * `denominator` - The divisor.
    //
    // # Returns
    // * `result` - The 256-bit result
    fn mul_div(a: u256, b: u256, denominator: u256) -> u256 {
        let product = u256_wide_mul(a, b);
        let (q, _) = u512_safe_div_rem_by_u256(
            product, u256_try_as_non_zero(denominator).expect('mul_div by zero')
        );
        assert(q.limb2 == 0 && q.limb3 == 0, 'mul_div u256 overflow');
        u256 { low: q.limb0, high: q.limb1 }
    }

    // Calculates ceil(a×b÷denominator). Throws if result overflows a uint256 or denominator == 0
    // # Arguments
    // * `a` - The multiplicand
    // * `b` - The multiplier
    // * `denominator` - The divisor.
    //
    // # Returns
    // * `result` - The 256-bit result
    fn mul_div_rounding_up(a: u256, b: u256, denominator: u256) -> u256 {
        let result: u256 = mul_div(a, b, denominator);
        let max_u256: u256 = BoundedInt::max();
        if (mul_mod_n(a, b, denominator) > 0) {
            assert(result < max_u256, 'mul_div_rounding_up overflow');
            return result + 1;
        }
        result
    }

    fn mul_mod_n(a: u256, b: u256, n: u256) -> u256 {
        let (_, r) = u512_safe_div_rem_by_u256(
            u256_wide_mul(a, b), u256_try_as_non_zero(n).expect('mul_div by zero')
        );
        r
    }

    fn div_rounding_up(a: u256, denominator: u256) -> u256 {
        (a + denominator - 1) / denominator
    }
}
