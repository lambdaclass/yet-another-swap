mod BitMathTests {
    mod MostSignificantBit {
        use integer::BoundedInt;
        use yas_core::libraries::bit_math::BitMath::most_significant_bit;

        #[test]
        fn msb_happy_path() {
            // 1
            assert(most_significant_bit(1) == 0, 'msb should be 0');
        }

        #[test]
        fn msb_larger_number() {
            // 10000000
            assert(most_significant_bit(128) == 7, 'msb should be 7');
        }

        #[test]
        fn msb_bigger_number() {
            // 11110100001001000000
            assert(most_significant_bit(1000000) == 19, 'msb should be 19');
        }

        #[test]
        fn msb_maximum_256() {
            assert(most_significant_bit(BoundedInt::max()) == 255, 'msb should be 255');
        }

        #[test]
        fn msb_random_number() {
            // 11000000111001
            assert(most_significant_bit(12345) == 13, 'msb should be 13');
        }

        #[test]
        #[should_panic]
        fn msb_number_zero() {
            let ret = most_significant_bit(0);
        }
    }

    mod LeastSignificantBit {
        use integer::BoundedInt;
        use yas_core::libraries::bit_math::BitMath::{least_significant_bit, check_gt_zero};
        #[test]
        fn lsb_happy_path() {
            // 1
            assert(least_significant_bit(1) == 0, 'lsb should be 0');
        }
        #[test]
        #[should_panic(expected: ('x must be greater than 0',))]
        fn test_check_gt_zero() {
            match check_gt_zero(0) {
                Result::Ok(()) => {},
                Result::Err(err) => { panic_with_felt252(err) },
            }
        }
        #[test]
        fn lsb_larger_number() {
            // 10000000
            assert(least_significant_bit(128) == 7, 'lsb should be 7');
        }

        #[test]
        fn lsb_bigger_number() {
            // 11110100001001000000
            assert(least_significant_bit(1000000) == 6, 'lsb should be 6');
        }

        #[test]
        fn lsb_maximum_256() {
            // 
            assert(least_significant_bit(BoundedInt::max()) == 0, 'lsb should be 0');
        }

        #[test]
        fn lsb_random_number() {
            // 11000000111001
            let ret = least_significant_bit(12345);
            assert(ret == 0, 'lsb should be 0');
        }

        #[test]
        #[should_panic]
        fn lsb_number_zero() {
            let ret = least_significant_bit(0);
        }
    }
}
