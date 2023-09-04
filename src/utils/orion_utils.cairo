mod OrionUtils {
    use integer::BoundedInt;
    use option::{OptionTrait};
    use traits::{Into, TryInto};

    use orion::numbers::signed_integer::i32::i32;
    use orion::numbers::signed_integer::i16::i16;
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;

    impl u8Intoi32 of Into<u8, i32> {
        fn into(self: u8) -> i32 {
            IntegerTrait::<i32>::new(self.into(), false)
        }
    }

    fn convert_i32_to_i16(value: i32) -> i16 {
        IntegerTrait::<i16>::new(value.mag.try_into().unwrap(), value.sign)
    }

    fn convert_i32_to_u8(value: i32) -> u8 {
        assert(value.sign == false, 'The sign must be positive');
        let max: u8 = BoundedInt::max();
        assert(value.mag <= max.into(), 'Overflow of magnitude');
        value.mag.try_into().unwrap()
    }

    /// Computes the mathematical modulo of two i32 numbers.
    /// Unlike Orion '%' operator, which can return negative remainders,
    /// our function ensures the result is always positive.
    ///
    /// Parameters:
    /// - n: The dividend, can be positive or negative.
    /// - m: The divisor, should be positive.
    fn mod_i32(n: i32, m: i32) -> i32 {
        assert(m.sign == false, 'm should be positive');
        ((n % m) + m) % m
    }
}
