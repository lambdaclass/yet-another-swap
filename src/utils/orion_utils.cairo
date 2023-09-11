mod OrionUtils {
    use integer::BoundedInt;
    use option::{OptionTrait};
    use traits::{Into, TryInto};

    use orion::numbers::signed_integer::i16::i16;
    use orion::numbers::signed_integer::i32::i32;
    use orion::numbers::signed_integer::i128::i128;
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;

    use yas::numbers::signed_integer::i256::i256;

    impl u8Intoi32 of Into<u8, i32> {
        fn into(self: u8) -> i32 {
            IntegerTrait::<i32>::new(self.into(), false)
        }
    }

    impl i32TryIntou8 of TryInto<i32, u8> {
        fn try_into(self: i32) -> Option<u8> {
            assert(self.sign == false, 'The sign must be positive');
            let max: u8 = BoundedInt::max();
            assert(self.mag <= max.into(), 'Overflow of magnitude');
            self.mag.try_into()
        }
    }

    impl i32TryIntoi16 of TryInto<i32, i16> {
        fn try_into(self: i32) -> Option<i16> {
            Option::Some(IntegerTrait::<i16>::new(self.mag.try_into().unwrap(), self.sign))
        }
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
