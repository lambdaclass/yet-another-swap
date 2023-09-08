mod OrionUtilsTests {
    mod ConvertI32toU8 {
        use integer::BoundedInt;

        use orion::numbers::signed_integer::i32::i32;
        use orion::numbers::signed_integer::integer_trait::IntegerTrait;

        use yas::utils::orion_utils::OrionUtils::i32TryIntou8;

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

        use orion::numbers::signed_integer::i32::i32;
        use orion::numbers::signed_integer::integer_trait::IntegerTrait;

        use yas::utils::orion_utils::OrionUtils::u8Intoi32;

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
        use orion::numbers::signed_integer::i16::i16;
        use orion::numbers::signed_integer::i32::i32;
        use orion::numbers::signed_integer::integer_trait::IntegerTrait;

        use yas::utils::orion_utils::OrionUtils::i32TryIntoi16;

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

    mod ModI32 {
        use orion::numbers::signed_integer::i32::i32;
        use orion::numbers::signed_integer::integer_trait::IntegerTrait;

        use yas::utils::orion_utils::OrionUtils::mod_i32;

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
}
