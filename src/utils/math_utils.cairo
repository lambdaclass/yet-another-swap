use integer::BoundedInt;

mod Constants {
    const Q128: u256 = 0x100000000000000000000000000000000;
}

mod FullMath {
    use integer::{
        BoundedInt, u256_wide_mul, u256_safe_divmod, u512_safe_div_rem_by_u256, u256_try_as_non_zero
    };

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
            result + 1
        } else {
            result
        }
    }

    fn mul_mod_n(a: u256, b: u256, n: u256) -> u256 {
        let (_, r) = u512_safe_div_rem_by_u256(
            u256_wide_mul(a, b), u256_try_as_non_zero(n).expect('mul_mod_n by zero')
        );
        r
    }

    fn div_rounding_up(a: u256, denominator: u256) -> u256 {
        let (quotient, remainder, _) = u256_safe_divmod(
            a, u256_try_as_non_zero(denominator).expect('div_rounding_up by zero')
        );
        if remainder != 0 {
            quotient + 1
        } else {
            quotient
        }
    }
}

mod BitShift {
    use super::pow;
    use integer::BoundedInt;

    use yas::numbers::signed_integer::{
        i32::{i32, ensure_non_negative_zero, i32_check_sign_zero}, i256::i256,
        integer_trait::IntegerTrait
    };

    trait BitShiftTrait<T> {
        fn shl(self: @T, n: T) -> T;
        fn shr(self: @T, n: T) -> T;
    }

    impl U256BitShift of BitShiftTrait<u256> {
        #[inline(always)]
        fn shl(self: @u256, n: u256) -> u256 {
            *self * pow(2, n)
        }

        #[inline(always)]
        fn shr(self: @u256, n: u256) -> u256 {
            *self / pow(2, n)
        }
    }

    impl I256BitShift of BitShiftTrait<i256> {
        #[inline(always)]
        fn shl(self: @i256, n: i256) -> i256 {
            let mut new_mag = self.mag.shl(n.mag);
            if *self.sign && n.mag == 128 {
                new_mag += 1_u256;
            };
            // Left shift operation: mag << n
            if *self.sign {
                new_mag = new_mag & BoundedInt::<u256>::max() / 2;
            } else {
                new_mag = new_mag & ((BoundedInt::<u256>::max() / 2) - 1);
            };

            IntegerTrait::<i256>::new(new_mag, *self.sign)
        }

        #[inline(always)]
        fn shr(self: @i256, n: i256) -> i256 {
            let mut new_mag = self.mag.shr(n.mag);
            let mut new_sign = *self.sign;
            if *self.sign && n.mag == 128 {
                new_mag += 1_u256;
            };
            if new_mag == 0 {
                if *self.sign {
                    new_sign = true;
                    new_mag = 1;
                } else {
                    new_sign == false;
                };
            };
            // Right shift operation: mag >> n
            IntegerTrait::<i256>::new(new_mag, new_sign)
        }
    }

    impl U32BitShift of BitShiftTrait<u32> {
        #[inline(always)]
        fn shl(self: @u32, n: u32) -> u32 {
            *self * pow(2, n.into()).try_into().unwrap()
        }

        #[inline(always)]
        fn shr(self: @u32, n: u32) -> u32 {
            *self / pow(2, n.into()).try_into().unwrap()
        }
    }

    impl U8BitShift of BitShiftTrait<u8> {
        #[inline(always)]
        fn shl(self: @u8, n: u8) -> u8 {
            *self * pow(2, n.into()).try_into().unwrap()
        }

        #[inline(always)]
        fn shr(self: @u8, n: u8) -> u8 {
            *self / pow(2, n.into()).try_into().unwrap()
        }
    }
}

/// Raise a number to a power.
/// * `base` - The number to raise.
/// * `exp` - The exponent.
/// # Returns
/// * `u256` - The result of base raised to the power of exp.
fn pow(base: u256, exp: u256) -> u256 {
    if exp == 0 {
        1
    } else if exp == 1 {
        base
    } else if (exp & 1) == 1 {
        base * pow(base * base, exp / 2)
    } else {
        pow(base * base, exp / 2)
    }
}

/// @notice Performs modular subtraction of two unsigned 256-bit integers, a and b.
/// @param a The first operand for subtraction.
/// @param b The second operand for subtraction.
/// @return The result of (a - b) modulo 2^256.
fn mod_subtraction(a: u256, b: u256) -> u256 {
    if b > a {
        (BoundedInt::max() - b) + a + 1
    } else {
        a - b
    }
}
