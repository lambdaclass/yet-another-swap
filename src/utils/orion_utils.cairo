mod OrionUtils {
    use integer::BoundedInt;
    use option::{OptionTrait};
    use traits::{Into, TryInto};

    use orion::numbers::signed_integer::i32::i32;
    use orion::numbers::signed_integer::i16::i16;
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;

    fn convert_u8_to_i32(value: u8) -> i32 {
        IntegerTrait::<i32>::new(value.into(), false)
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

    fn mod_i32(n: i32, m: i32) -> i32 {
        ((n % m) + m) % m
    }
}
