mod BitMathTests {
    mod MostSignificantBit {
        use core::result::ResultTrait;
        use integer::BoundedInt;
        use yas_core::libraries::bit_math::BitMath::most_significant_bit;

        #[test]
        #[available_gas(200000000)]
        fn msb_happy_path() {
            // 1
            assert(most_significant_bit(1).expect('msb_failed_1') == 0, 'msb should be 0');
        }

        #[test]
        #[available_gas(200000000)]
        fn msb_larger_number() {
            // 10000000
            assert(most_significant_bit(128).expect('msb_failed_128') == 7, 'msb should be 7');
        }

        #[test]
        #[available_gas(200000000)]
        fn msb_bigger_number() {
            // 11110100001001000000
            assert(
                most_significant_bit(1000000).expect('msb_failed_1000000') == 19, 'msb should be 19'
            );
        }

        #[test]
        #[available_gas(200000000)]
        fn msb_maximum_256() {
            assert(
                most_significant_bit(BoundedInt::max()).expect('msb_failed_BoundedInt') == 255,
                'msb should be 255'
            );
        }

        #[test]
        #[available_gas(200000000)]
        fn msb_random_number() {
            // 11000000111001
            assert(
                most_significant_bit(12345).expect('msb_failed_12345') == 13, 'msb should be 13'
            );
        }

        #[test]
        #[should_panic]
        #[available_gas(200000000)]
        fn msb_number_zero() {
            let ret = most_significant_bit(0);
            assert(ret.expect('msb_failed_0') != 0, 'msb should be 0');
        }
    }

    mod LeastSignificantBit {
        use integer::BoundedInt;
        use yas_core::libraries::bit_math::BitMath::least_significant_bit;

        #[test]
        #[available_gas(200000000)]
        fn lsb_happy_path() {
            // 1
            assert(least_significant_bit(1).expect('lsb_failed_1') == 0, 'lsb should be 0');
        }

        #[test]
        #[available_gas(200000000)]
        fn lsb_larger_number() {
            // 10000000
            assert(least_significant_bit(128).expect('lsb_failed_128') == 7, 'lsb should be 7');
        }

        #[test]
        #[available_gas(200000000)]
        fn lsb_bigger_number() {
            // 11110100001001000000
            assert(
                least_significant_bit(1000000).expect('lsb_failed_1000000') == 6, 'lsb should be 6'
            );
        }

        #[test]
        #[available_gas(200000000)]
        fn lsb_maximum_256() {
            // 
            assert(
                least_significant_bit(BoundedInt::max()).expect('lsb_failed_BoundedInt') == 0,
                'lsb should be 0'
            );
        }

        #[test]
        #[available_gas(200000000)]
        fn lsb_random_number() {
            // 11000000111001
            let ret = least_significant_bit(12345);
            assert(ret.expect('lsb_failed_12345') == 0, 'lsb should be 0');
        }

        #[test]
        #[available_gas(200000000)]
        #[should_panic]
        fn lsb_number_zero() {
            let ret = least_significant_bit(0);
            assert(ret.expect('lsb_failed_0') == 0, 'lsb should be 0');
        }
    }
}
