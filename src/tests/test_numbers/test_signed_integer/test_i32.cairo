mod TestInteger32 {
    mod ConvertI32toU8 {
        use integer::BoundedInt;

        use yas::numbers::signed_integer::{i32::{i32, i32TryIntou8}, integer_trait::IntegerTrait};

        #[test]
        fn test_positive_conversion_within_range() {
            let val: i32 = IntegerTrait::<i32>::new(100, false);
            let result: u8 = val.try_into().unwrap();
            assert(result == 100, 'result should be 100');
        }

        #[test]
        fn test_zero_conversion() {
            let val: i32 = IntegerTrait::<i32>::new(0, false);
            let result: u8 = val.try_into().unwrap();
            assert(result == 0, 'result should be 0');
        }

        #[test]
        #[should_panic]
        fn test_positive_conversion_above_range() {
            let val: i32 = IntegerTrait::<i32>::new(300, false);
            let result: u8 = val.try_into().unwrap();
        }

        #[test]
        #[should_panic]
        fn test_negative_conversion_clamped() {
            let val: i32 = IntegerTrait::<i32>::new(50, true);
            let result: u8 = val.try_into().unwrap();
        }

        #[test]
        #[should_panic]
        fn test_negative_conversion_below_range() {
            let val: i32 = IntegerTrait::<i32>::new(200, true);
            let result: u8 = val.try_into().unwrap();
        }
    }

    mod ConvertU8toI32 {
        use integer::BoundedInt;

        use yas::numbers::signed_integer::{i32::{i32, u8Intoi32}, integer_trait::IntegerTrait};

        #[test]
        fn test_conversion() {
            let val: u8 = 127;
            let result: i32 = val.into();
            assert(result == IntegerTrait::<i32>::new(127, false), 'result should be 127');
        }

        #[test]
        fn test_zero_conversion() {
            let val: u8 = 0;
            let result: i32 = val.into();
            assert(result == IntegerTrait::<i32>::new(0, false), 'result should be 0');
        }

        #[test]
        fn test_max_value_conversion() {
            let val: u8 = BoundedInt::max();
            let result: i32 = val.into();
            assert(result == IntegerTrait::<i32>::new(255, false), 'result should be 255');
        }
    }

    mod ConvertI32toI16 {
        use yas::numbers::signed_integer::{
            i16::i16, i32::{i32, i32TryIntoi16}, integer_trait::IntegerTrait
        };

        #[test]
        fn test_positive_conversion_within_range() {
            let val: i32 = IntegerTrait::<i32>::new(1000, false);
            let result: i16 = val.try_into().unwrap();
            assert(result == IntegerTrait::<i16>::new(1000, false), 'result should be 1000');
        }

        #[test]
        fn test_zero_conversion() {
            let val: i32 = IntegerTrait::<i32>::new(0, false);
            let result: i16 = val.try_into().unwrap();
            assert(result == IntegerTrait::<i16>::new(0, false), 'result should be 0');
        }

        #[test]
        fn test_negative_conversion_within_range() {
            let val: i32 = IntegerTrait::<i32>::new(500, true);
            let result: i16 = val.try_into().unwrap();
            assert(result == IntegerTrait::<i16>::new(500, true), 'result should be -500');
        }

        #[test]
        #[should_panic]
        fn test_positive_conversion_above_range() {
            let val: i32 = IntegerTrait::<i32>::new(35000, false);
            let result: i16 = val.try_into().unwrap();
        }

        #[test]
        #[should_panic]
        fn test_negative_conversion_below_range() {
            let val: i32 = IntegerTrait::<i32>::new(35000, true);
            let result: i16 = val.try_into().unwrap();
        }
    }

    mod ConvertI32toU32 {
        use integer::BoundedInt;

        use yas::numbers::signed_integer::{i32::{i32, i32TryIntou32}, integer_trait::IntegerTrait};

        #[test]
        fn test_positive_max_conversion() {
            let i32_max: u32 = BoundedInt::max() / 2 - 1;
            let val: i32 = IntegerTrait::<i32>::new(i32_max, false);
            let result: u32 = val.try_into().unwrap();
            assert(result == i32_max, 'result should be 2147483647');
        }

        #[test]
        fn test_zero_conversion() {
            let val: i32 = IntegerTrait::<i32>::new(0, false);
            let result: u32 = val.try_into().unwrap();
            assert(result == 0, 'result should be 0');
        }

        #[test]
        #[should_panic(expected: ('The sign must be positive',))]
        fn test_negative_conversion() {
            let val: i32 = IntegerTrait::<i32>::new(1, true);
            let result: u32 = val.try_into().unwrap();
        }
    }

    mod ConvertI32toU128 {
        use integer::BoundedInt;

        use yas::numbers::signed_integer::{i32::{i32, i32TryIntou128}, integer_trait::IntegerTrait};

        #[test]
        fn test_positive_max_conversion() {
            let i32_max: u32 = BoundedInt::max() / 2 - 1;
            let val: i32 = IntegerTrait::<i32>::new(i32_max, false);
            let result: u128 = val.try_into().unwrap();
            assert(result == i32_max.into(), 'result should be 2147483647');
        }

        #[test]
        fn test_zero_conversion() {
            let val: i32 = IntegerTrait::<i32>::new(0, false);
            let result: u128 = val.try_into().unwrap();
            assert(result == 0, 'result should be 0');
        }

        #[test]
        #[should_panic(expected: ('The sign must be positive',))]
        fn test_negative_conversion() {
            let val: i32 = IntegerTrait::<i32>::new(1, true);
            let result: u128 = val.try_into().unwrap();
        }
    }

    mod ModI32 {
        use yas::numbers::signed_integer::{i32::{i32, mod_i32}, integer_trait::IntegerTrait};

        #[test]
        fn test_positive_mod() {
            let n = IntegerTrait::<i32>::new(1, false); // 1
            let m = IntegerTrait::<i32>::new(256, false); // 256
            assert(mod_i32(n, m) == IntegerTrait::<i32>::new(1, false), '1 mod 256 -> 1');
        }

        #[test]
        fn test_large_positive_mod() {
            let n = IntegerTrait::<i32>::new(257, false); // 257
            let m = IntegerTrait::<i32>::new(256, false); // 256
            assert(mod_i32(n, m) == IntegerTrait::<i32>::new(1, false), '257 mod 256 -> 1');
        }

        #[test]
        fn test_negative_mod() {
            let n = IntegerTrait::<i32>::new(1, true); // -1
            let m = IntegerTrait::<i32>::new(256, false); // 256
            assert(mod_i32(n, m) == IntegerTrait::<i32>::new(255, false), '-1 mod 256 -> 255');
        }

        #[test]
        fn test_large_negative_mod() {
            let n = IntegerTrait::<i32>::new(257, true); // -257
            let m = IntegerTrait::<i32>::new(256, false); // 256
            assert(mod_i32(n, m) == IntegerTrait::<i32>::new(255, false), '-257 mod 256 -> 256');
        }

        #[test]
        fn test_zero_mod() {
            let n = IntegerTrait::<i32>::new(0, false); // 0
            let m = IntegerTrait::<i32>::new(256, false); // 256
            assert(mod_i32(n, m) == IntegerTrait::<i32>::new(0, false), '0 mod 256 -> 0');
        }

        #[test]
        #[should_panic]
        fn test_divisor_negative() {
            let n = IntegerTrait::<i32>::new(150, false); // 150
            let m = IntegerTrait::<i32>::new(256, true); // -256
            let result = mod_i32(n, m);
        }
    }

    mod i32DivNoRound {
        use yas::numbers::signed_integer::{
            i32::{i32, i32_div_no_round}, integer_trait::IntegerTrait
        };

        #[test]
        fn test_numerator_eq_denominator_negative_x_negative() {
            // -24 / -24 = 1   
            let a = IntegerTrait::<i32>::new(24, true);
            let b = IntegerTrait::<i32>::new(24, true);
            let actual = i32_div_no_round(a, b);
            assert(actual.mag == 1, '-24 // -24 should be 1');
            assert(actual.sign == false, '-24 // -24 should be positive');
        }

        #[test]
        fn test_numerator_eq_denominator_positive_x_negative() {
            // 24 / -24 = -1   
            let a = IntegerTrait::<i32>::new(24, false);
            let b = IntegerTrait::<i32>::new(24, true);
            let actual = i32_div_no_round(a, b);
            assert(actual.mag == 1, '24 // -24 should be 1');
            assert(actual.sign == true, '24 // -24 should be negative');
        }

        #[test]
        fn test_numerator_eq_denominator_negative_x_positive() {
            // -24 / 24 = -1   
            let a = IntegerTrait::<i32>::new(24, true);
            let b = IntegerTrait::<i32>::new(24, false);
            let actual = i32_div_no_round(a, b);
            assert(actual.mag == 1, '-24 // 24 should be 1');
            assert(actual.sign == true, '-24 // 24 should be negative');
        }

        #[test]
        fn test_numerator_eq_denominator_positive_x_positive() {
            // 24 / 24 = 1   
            let a = IntegerTrait::<i32>::new(24, false);
            let b = IntegerTrait::<i32>::new(24, false);
            let actual = i32_div_no_round(a, b);
            assert(actual.mag == 1, '24 // 24 should be 1');
            assert(actual.sign == false, '24 // 24 should be negative');
        }

        #[test]
        fn test_negative_x_positive() {
            // -10 / 3 = -3   
            let a = IntegerTrait::<i32>::new(10, true);
            let b = IntegerTrait::<i32>::new(3, false);
            let actual = i32_div_no_round(a, b);
            assert(actual.mag == 3, '-10 // 3 should be 3');
            assert(actual.sign == true, '-10 // 3 should be negative');
        }

        #[test]
        fn test_positive_x_negative() {
            // 5 / -3 = -1   
            let a = IntegerTrait::<i32>::new(5, false);
            let b = IntegerTrait::<i32>::new(3, true);
            let actual = i32_div_no_round(a, b);
            assert(actual.mag == 1, '5 // -3 should be 3');
            assert(actual.sign == true, '5 // -3 should be negative');
        }

        // Test to evaluate rounding behavior and zeros
        #[test]
        fn test_numerator_gt_denominator_positive() {
            let ZERO = IntegerTrait::<i32>::new(0, false);

            // 6 / 10 = 0
            let a = IntegerTrait::<i32>::new(6, false);
            let b = IntegerTrait::<i32>::new(10, false);
            let actual = i32_div_no_round(a, b);
            assert(actual == ZERO, '6 // 10 should be 0');

            // 5 / 10 = 0
            let a = IntegerTrait::<i32>::new(5, false);
            let b = IntegerTrait::<i32>::new(10, false);
            let actual = i32_div_no_round(a, b);
            assert(actual == ZERO, '5 // 10 should be 0');

            // 1 / 10 = 0
            let a = IntegerTrait::<i32>::new(1, false);
            let b = IntegerTrait::<i32>::new(10, false);
            let actual = i32_div_no_round(a, b);
            assert(actual == ZERO, '1 // 10 should be 0');
        }

        // Test to evaluate rounding behavior and zeros
        #[test]
        fn test_numerator_gt_denominator_negative() {
            let ZERO = IntegerTrait::<i32>::new(0, false);

            // -6 / 10 = 0
            let a = IntegerTrait::<i32>::new(6, true);
            let b = IntegerTrait::<i32>::new(10, false);
            let actual = i32_div_no_round(a, b);
            assert(actual == ZERO, '-6 // 10 should be 0');

            // -5 / 10 = 0
            let a = IntegerTrait::<i32>::new(5, true);
            let b = IntegerTrait::<i32>::new(10, false);
            let actual = i32_div_no_round(a, b);
            assert(actual == ZERO, '-5 // 10 should be 0');

            // -1 / 10 = 0
            let a = IntegerTrait::<i32>::new(1, true);
            let b = IntegerTrait::<i32>::new(10, false);
            let actual = i32_div_no_round(a, b);
            assert(actual == ZERO, '-1 // 10 should be 0');

            // 5 / -10 = 0
            let a = IntegerTrait::<i32>::new(5, false);
            let b = IntegerTrait::<i32>::new(10, true);
            let actual = i32_div_no_round(a, b);
            assert(actual == ZERO, '5 // -10 should be 0');
        }

        #[test]
        #[should_panic(expected: ('denominator cannot be 0',))]
        fn test_div_by_zero_should_panic() {
            let a = IntegerTrait::<i32>::new(1, false);
            let b = IntegerTrait::<i32>::new(0, false);
            let actual = i32_div_no_round(a, b);
        }
    }
}
