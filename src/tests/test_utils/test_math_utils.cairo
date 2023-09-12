mod BitShift {
    use yas::utils::math_utils::MathUtils::{BitShiftTrait, pow};
    use integer::BoundedInt;
    use yas::numbers::signed_integer::i256::i256;
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;

    #[test]
    #[available_gas(20000000)]
    fn test_shift_left_i256_1_positive() {
        let x = IntegerTrait::<i256>::new(1, false);
        let n = IntegerTrait::<i256>::new(1, false);
        let expected_result_right = IntegerTrait::<i256>::new(0, false);
        let expected_result_left = IntegerTrait::<i256>::new(2, false);
        assert(x.shr(n) == expected_result_right, '1 >> 1 == 0');
        assert(x.shl(n) == expected_result_left, '1 << 1 == 2');

        let n = IntegerTrait::<i256>::new(2, false);
        let expected_result_right = IntegerTrait::<i256>::new(0, false);
        let expected_result_left = IntegerTrait::<i256>::new(4, false);
        assert(x.shr(n) == expected_result_right, '1 >> 2 == 0');
        assert(x.shl(n) == expected_result_left, '1 << 2 == 4');

        let n = IntegerTrait::<i256>::new(128, false);
        let expected_result_right = IntegerTrait::<i256>::new(0, false);
        let expected_result_left = IntegerTrait::<i256>::new(
            340282366920938463463374607431768211456, false
        );
        assert(x.shr(n) == expected_result_right, '1 >> 128 == 0');
        assert(x.shl(n) == expected_result_left, '1 << 128');

        let n = IntegerTrait::<i256>::new(254, false);
        let expected_result_right = IntegerTrait::<i256>::new(0, false);
        let expected_result_left = IntegerTrait::<i256>::new(
            28948022309329048855892746252171976963317496166410141009864396001978282409984, false
        );
        assert(x.shr(n) == expected_result_right, '1 >> 254 == 0');
    // THIS TEST FAILS WITH INT OUT RANGE.
    // assert(x.shl(n) == expected_result_left, '1 << 254');
    }

    #[test]
    #[available_gas(20000000)]
    fn test_shift_left_i256_1_negative() {
        let x = IntegerTrait::<i256>::new(1, true); // -1
        let n = IntegerTrait::<i256>::new(1, false);
        let expected_result_right = IntegerTrait::<i256>::new(1, true);
        let expected_result_left = IntegerTrait::<i256>::new(2, true);
        assert(x.shr(n) == expected_result_right, '-1 >> 1');
        assert(x.shl(n) == expected_result_left, '-1 << 1');

        let n = IntegerTrait::<i256>::new(2, false);
        let expected_result_right = IntegerTrait::<i256>::new(1, true);
        let expected_result_left = IntegerTrait::<i256>::new(4, true);
        assert(x.shr(n) == expected_result_right, '-1 >> 2');
        assert(x.shl(n) == expected_result_left, '-1 << 24');

        let n = IntegerTrait::<i256>::new(128, false);
        let expected_result_right = IntegerTrait::<i256>::new(1, true);
        let expected_result_left = IntegerTrait::<i256>::new(
            340282366920938463463374607431768211456, true
        );
        assert(x.shr(n) == expected_result_right, '-1 >> 128');
        // assert(x.shl(n) == expected_result_left, '-1 << 128');

        let n = IntegerTrait::<i256>::new(254, false);
        let expected_result_right = IntegerTrait::<i256>::new(1, true);
        let expected_result_left = IntegerTrait::<i256>::new(
            28948022309329048855892746252171976963317496166410141009864396001978282409984, true
        );
        assert(x.shr(n) == expected_result_right, '-1 >> 254');
        assert(x.shl(n) == expected_result_left, '-1 << 254');
    }

    #[test]
    #[available_gas(20000000)]
    fn test_shift_left_i256_zero() {
        let x = IntegerTrait::<i256>::new(0, false);

        let n = IntegerTrait::<i256>::new(1, false);
        let expected_result_right = IntegerTrait::<i256>::new(0, false);
        let expected_result_left = IntegerTrait::<i256>::new(0, false);
        assert(x.shr(n) == expected_result_right, '0 >> 1');
        assert(x.shl(n) == expected_result_left, '0 << 1');

        let n = IntegerTrait::<i256>::new(2, false);
        let expected_result_right = IntegerTrait::<i256>::new(0, false);
        let expected_result_left = IntegerTrait::<i256>::new(0, false);
        assert(x.shr(n) == expected_result_right, '0 >> 2');
        assert(x.shl(n) == expected_result_left, '0 << 2');

        let n = IntegerTrait::<i256>::new(128, false);
        let expected_result_right = IntegerTrait::<i256>::new(0, false);
        let expected_result_left = IntegerTrait::<i256>::new(0, false);
        assert(x.shr(n) == expected_result_right, '0 >> 128');
        assert(x.shl(n) == expected_result_left, '0 << 128');

        let n = IntegerTrait::<i256>::new(254, false);
        let expected_result_right = IntegerTrait::<i256>::new(0, false);
        let expected_result_left = IntegerTrait::<i256>::new(0, false);
        assert(x.shr(n) == expected_result_right, '0 >> 254');
        assert(x.shl(n) == expected_result_left, '0 << 254');

        let n = IntegerTrait::<i256>::new(255, false);
        let expected_result_right = IntegerTrait::<i256>::new(0, false);
        let expected_result_left = IntegerTrait::<i256>::new(0, false);
        assert(x.shr(n) == expected_result_right, '0 >> 255');
        assert(x.shl(n) == expected_result_left, '0 << 255');
    }

    #[test]
    #[available_gas(20000000)]
    fn test_shift_left_i256_MAX() {
        let x = IntegerTrait::<i256>::new((BoundedInt::max() / 2) - 1, false);

        let n = IntegerTrait::<i256>::new(1, false);
        let expected_result_right = IntegerTrait::<i256>::new(
            28948022309329048855892746252171976963317496166410141009864396001978282409983, false
        );
        let expected_result_left = IntegerTrait::<i256>::new(
            57896044618658097711785492504343953926634992332820282019728792003956564819964, false
        );
        assert(x.shr(n) == expected_result_right, 'MAX >> 1');
        // THIS IS AN ERROR AND SHOULD BE INVALID.
        assert(x.shl(n) == expected_result_left, 'MAX << 1');
    // let n = IntegerTrait::<i256>::new(2, false);
    // let expected_result_right = IntegerTrait::<i256>::new(
    //     14474011154664524427946373126085988481658748083205070504932198000989141204991, false
    // );
    // let expected_result_left = IntegerTrait::<i256>::new(0, false);
    // assert(x.shr(n) == expected_result_right, 'MAX >> 2');
    // assert(x.shl(n) == expected_result_left, 'MAX << 2');

    // let n = IntegerTrait::<i256>::new(128, false);
    // let expected_result_right = IntegerTrait::<i256>::new(
    //     170141183460469231731687303715884105728, false
    // );
    // let expected_result_left = IntegerTrait::<i256>::new(0, false);
    // assert(x.shr(n) == expected_result_right, 'MAX >> 128');
    // assert(x.shl(n) == expected_result_left, 'MAX << 128');

    // let n = IntegerTrait::<i256>::new(254, false);
    // let expected_result_right = IntegerTrait::<i256>::new(2, false);
    // let expected_result_left = IntegerTrait::<i256>::new(0, false);
    // assert(x.shr(n) == expected_result_right, 'MAX >> 254');
    // assert(x.shl(n) == expected_result_left, 'MAX << 254');

    // let n = IntegerTrait::<i256>::new(255, false);
    // let expected_result_right = IntegerTrait::<i256>::new(1, false);
    // let expected_result_left = IntegerTrait::<i256>::new(0, false);
    // assert(x.shr(n) == expected_result_right, 'MAX >> 255');
    // assert(x.shl(n) == expected_result_left, 'MAX << 255');
    }

    #[test]
    #[available_gas(20000000)]
    fn test_shift_left_i256_MIN() {
        // We need to specify left shifts overflow behavior.
        let x = IntegerTrait::<i256>::new(BoundedInt::max() / 2, true);

        let n = IntegerTrait::<i256>::new(1, false);
        let expected_result_right = IntegerTrait::<i256>::new(
            28948022309329048855892746252171976963317496166410141009864396001978282409984, true
        );
        // assert(x.shr(n) == expected_result_right, 'MIN >> 1');
        // let expected_result_left = IntegerTrait::<i256>::new(115792089237316195423570985008687907853269984665640564039457584007913129639934, true);
        // assert(x.shl(n) == expected_result_left, 'MIN << 1');

        let n = IntegerTrait::<i256>::new(2, false);
        let expected_result_right = IntegerTrait::<i256>::new(
            14474011154664524427946373126085988481658748083205070504932198000989141204992, true
        );
        // assert(x.shr(n) == expected_result_right, 'MIN >> 2');
        // let expected_result_left = IntegerTrait::<i256>::new(0, true);
        // assert(x.shl(n) == expected_result_left, 'MIN << 2');

        let n = IntegerTrait::<i256>::new(128, false);
        let expected_result_right = IntegerTrait::<i256>::new(
            170141183460469231731687303715884105728, true
        );
        // assert(x.shr(n) == expected_result_right, 'MIN >> 128');
        // let expected_result_left = IntegerTrait::<i256>::new(0, true);
        // assert(x.shl(n) == expected_result_left, 'MIN << 128');

        let n = IntegerTrait::<i256>::new(254, false);
        let expected_result_right = IntegerTrait::<i256>::new(2, true);
        // assert(x.shr(n) == expected_result_right, 'MIN >> 254');
        // let expected_result_left = IntegerTrait::<i256>::new(0, true);
        // assert(x.shl(n) == expected_result_left, 'MIN << 254');

        let n = IntegerTrait::<i256>::new(255, false);
        let expected_result_right = IntegerTrait::<i256>::new(1, true);
    //assert(x.shr(n) == expected_result_right, 'MIN >> 255');
    // let expected_result_left = IntegerTrait::<i256>::new(0, true);
    // assert(x.shl(n) == expected_result_left, 'MIN << 255');
    }


    #[test]
    #[available_gas(2000000)]
    fn test_shift_left_u256_1() {
        let input: u256 = 1;
        let result = input.shl(1);
        assert(result == 2, 'test_shift_left_1');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_shift_left_u256_zero() {
        let input: u256 = 0;
        let result = input.shl(5);
        assert(result == 0, 'test_shift_left_zero');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_shift_right_u256_1() {
        let input: u256 = 4;
        let result = input.shr(1);
        assert(result == 2, 'test_shift_left_zero');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_shift_right_u256_max() {
        let input: u256 = BoundedInt::max();
        let result = input.shr(1);
        assert(result == BoundedInt::max() / 2, 'test_shift_left_zero');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_shift_right_u256_zero() {
        let input: u256 = 0;
        let result = input.shr(5);
        assert(result == 0, 'test_shift_left_zero');
    }

    // TODO: The current implementation does not support left shift overflow
    // input: 1111 (let's assume it's the max)
    // call: shift_left(BoundedInt::max(), 1);
    // output: should be 1110
    // #[test]
    // #[available_gas(2000000)]
    // fn test_shift_left_max() {
    //     let result = shift_left(BoundedInt::max(), 1);
    //     assert(result == BoundedInt::max() - 1, 'test_shift_left_max');
    // }

    #[test]
    #[available_gas(2000000)]
    fn test_shift_left_u32_1() {
        let input: u32 = 1;
        let result = input.shl(1);
        assert(result == 2, 'test_shift_left_1');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_shift_left_u32_zero() {
        let input: u256 = 0;
        let result = input.shl(5);
        assert(result == 0, 'test_shift_left_zero');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_shift_right_u32_1() {
        let input: u32 = 4;
        let result = input.shr(1);
        assert(result == 2, 'test_shift_left_zero');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_shift_right_u32_max() {
        let input: u32 = BoundedInt::max();
        let result = input.shr(1);
        assert(result == BoundedInt::max() / 2, 'test_shift_left_zero');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_shift_right_u32_zero() {
        let input: u32 = 0;
        let result = input.shr(5);
        assert(result == 0, 'test_shift_left_zero');
    }
}

mod Pow {
    use yas::utils::math_utils::MathUtils::pow;
    #[test]
    #[available_gas(2000000)]
    fn test_pow_by_0_should_return_1() {
        let result = pow(120, 0);
        assert(result == 1, 'pow_by_0_should_return_1');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_pow_by_1_should_return_same_number() {
        let result = pow(120, 1);
        assert(result == 120, 'pow_by_1_should_return_same_num');
    }

    // before impl panic with 2^n for n ≥ 64
    #[test]
    #[available_gas(2000000)]
    fn test_pow() {
        let result = pow(2, 64);
        assert(result == 18446744073709551616, 'test_pow_by_64');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_pow_by_255() {
        let result = pow(2, 255);
        assert(
            result == 57896044618658097711785492504343953926634992332820282019728792003956564819968,
            'test_pow_by_255'
        );
    }
}

mod ModSubtractionTests {
    use integer::BoundedInt;

    use yas::utils::math_utils::MathUtils::mod_subtraction;

    #[test]
    #[available_gas(2000000)]
    fn test_positive_subtraction() {
        let result = mod_subtraction(500, 100);
        assert(result == 400, 'result should be 400');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_subtract_from_zero() {
        let result = mod_subtraction(500, 0);
        assert(result == 500, 'result should be 500');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_subtract_to_overflow() {
        let result = mod_subtraction(0, 500);
        assert(result == BoundedInt::max() - 499, 'result should be max_u256 - 499');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_subtract_max_from_zero() {
        let result = mod_subtraction(0, 1);
        assert(result == BoundedInt::max(), 'result should be max_u256');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_subtract_zero() {
        let result = mod_subtraction(0, 0);
        assert(result == 0, 'result should be 0');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_subtract_max_from_small() {
        let result = mod_subtraction(15, BoundedInt::max());
        assert(result == 15 + 1, 'result should be 15 + 1');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_subtract_max_from_max() {
        let result = mod_subtraction(BoundedInt::max(), BoundedInt::max());
        assert(result == 0, 'result should be 0');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_subtract_zero_from_max() {
        let result = mod_subtraction(0, BoundedInt::max());
        assert(result == 1, 'result should be 1');
    }
}

mod i32Div {
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;
    use orion::numbers::signed_integer::i32::i32;
    use yas::utils::math_utils::MathUtils::i32_div;

    #[test]
    fn test_numerator_eq_denominator_negative_x_negative() {
        // -24 / -24 = 1   
        let a = IntegerTrait::<i32>::new(24, true);
        let b = IntegerTrait::<i32>::new(24, true);
        let actual = i32_div(a, b);
        assert(actual.mag == 1, '-24 // -24 should be 1');
        assert(actual.sign == false, '-24 // -24 should be positive');
    }

    #[test]
    fn test_numerator_eq_denominator_positive_x_negative() {
        // 24 / -24 = -1   
        let a = IntegerTrait::<i32>::new(24, false);
        let b = IntegerTrait::<i32>::new(24, true);
        let actual = i32_div(a, b);
        assert(actual.mag == 1, '24 // -24 should be 1');
        assert(actual.sign == true, '24 // -24 should be negative');
    }

    #[test]
    fn test_numerator_eq_denominator_negative_x_positive() {
        // -24 / 24 = -1   
        let a = IntegerTrait::<i32>::new(24, true);
        let b = IntegerTrait::<i32>::new(24, false);
        let actual = i32_div(a, b);
        assert(actual.mag == 1, '-24 // 24 should be 1');
        assert(actual.sign == true, '-24 // 24 should be negative');
    }

    #[test]
    fn test_numerator_eq_denominator_positive_x_positive() {
        // 24 / 24 = 1   
        let a = IntegerTrait::<i32>::new(24, false);
        let b = IntegerTrait::<i32>::new(24, false);
        let actual = i32_div(a, b);
        assert(actual.mag == 1, '24 // 24 should be 1');
        assert(actual.sign == false, '24 // 24 should be negative');
    }

    #[test]
    fn test_negative_x_positive() {
        // -10 / 3 = -3   
        let a = IntegerTrait::<i32>::new(10, true);
        let b = IntegerTrait::<i32>::new(3, false);
        let actual = i32_div(a, b);
        assert(actual.mag == 3, '-10 // 3 should be 3');
        assert(actual.sign == true, '-10 // 3 should be negative');
    }

    #[test]
    fn test_positive_x_negative() {
        // 5 / -3 = -1   
        let a = IntegerTrait::<i32>::new(5, false);
        let b = IntegerTrait::<i32>::new(3, true);
        let actual = i32_div(a, b);
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
        let actual = i32_div(a, b);
        assert(actual == ZERO, '6 // 10 should be 0');

        // 5 / 10 = 0
        let a = IntegerTrait::<i32>::new(5, false);
        let b = IntegerTrait::<i32>::new(10, false);
        let actual = i32_div(a, b);
        assert(actual == ZERO, '5 // 10 should be 0');

        // 1 / 10 = 0
        let a = IntegerTrait::<i32>::new(1, false);
        let b = IntegerTrait::<i32>::new(10, false);
        let actual = i32_div(a, b);
        assert(actual == ZERO, '1 // 10 should be 0');
    }

    // Test to evaluate rounding behavior and zeros
    #[test]
    fn test_numerator_gt_denominator_negative() {
        let ZERO = IntegerTrait::<i32>::new(0, false);

        // -6 / 10 = 0
        let a = IntegerTrait::<i32>::new(6, true);
        let b = IntegerTrait::<i32>::new(10, false);
        let actual = i32_div(a, b);
        assert(actual == ZERO, '-6 // 10 should be 0');

        // -5 / 10 = 0
        let a = IntegerTrait::<i32>::new(5, true);
        let b = IntegerTrait::<i32>::new(10, false);
        let actual = i32_div(a, b);
        assert(actual == ZERO, '-5 // 10 should be 0');

        // -1 / 10 = 0
        let a = IntegerTrait::<i32>::new(1, true);
        let b = IntegerTrait::<i32>::new(10, false);
        let actual = i32_div(a, b);
        assert(actual == ZERO, '-1 // 10 should be 0');

        // 5 / -10 = 0
        let a = IntegerTrait::<i32>::new(5, false);
        let b = IntegerTrait::<i32>::new(10, true);
        let actual = i32_div(a, b);
        assert(actual == ZERO, '5 // -10 should be 0');
    }

    #[test]
    #[should_panic(expected: ('denominator cannot be 0',))]
    fn test_div_by_zero_should_panic() {
        let a = IntegerTrait::<i32>::new(1, false);
        let b = IntegerTrait::<i32>::new(0, false);
        let actual = i32_div(a, b);
    }
}
