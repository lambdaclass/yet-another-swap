mod BitShift {
    use yas::utils::math_utils::MathUtils::{BitShiftTrait, pow};
    use integer::BoundedInt;
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
