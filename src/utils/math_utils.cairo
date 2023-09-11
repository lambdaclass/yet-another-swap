mod MathUtils {
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use integer::BoundedInt;
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;
    use orion::numbers::signed_integer::i32::{i32, ensure_non_negative_zero, i32_check_sign_zero};

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

    fn pow(x: u256, n: u256) -> u256 {
        if n == 0 {
            1
        } else if n == 1 {
            x
        } else if (n & 1) == 1 {
            x * pow(x * x, n / 2)
        } else {
            pow(x * x, n / 2)
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

    /// TODO: Replace when the implementation of integers in Cairo is released. 
    /// @notice This function is an override for Orion's integer division. 
    /// This is necessary because the behavior for the division of negative 
    /// numbers works incorrectly when it comes to rounding.
    fn i32_div(a: i32, b: i32) -> i32 {
        assert(b.mag != 0, 'denominator cannot be 0');
        i32_check_sign_zero(a);

        if b.mag > a.mag {
            return IntegerTrait::new(0, false);
        }

        ensure_non_negative_zero(a.mag / b.mag, a.sign ^ b.sign)
    }
}
