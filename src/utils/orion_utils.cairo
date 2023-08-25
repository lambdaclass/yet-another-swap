mod OrionUtils {
    use option::{OptionTrait};
    use traits::{Into, TryInto};

    use orion::numbers::signed_integer::i32::i32;
    use orion::numbers::signed_integer::i16::i16;
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;

    fn convert_u8_to_i32(value: u8) -> i32 {
        IntegerTrait::<i32>::new(value.into(), false)
    }

    fn convert_i32_to_i16(value: i32) -> i16 {
        let value_u16: u16 = value.mag.try_into().unwrap();
        IntegerTrait::<i16>::new(value_u16, value.sign)
    }

    fn convert_i32_to_u8(value: i32) -> u8 {
        value.mag.try_into().unwrap()
    }
}
