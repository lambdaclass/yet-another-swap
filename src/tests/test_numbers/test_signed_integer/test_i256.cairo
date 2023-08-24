mod TestInteger256 {

    mod New { 
        use fractal_swap::numbers::signed_integer::i256::i256;
        use orion::numbers::signed_integer::integer_trait::IntegerTrait;
        use integer::BoundedInt;

        // Test new i256 max
        #[test]
        fn test_i256_max() {
            let i256_max = BoundedInt::max() / 2;
            let a = IntegerTrait::<i256>::new(i256_max - 1, false);

            assert(a.mag == i256_max - 1, 'new max pos value error');
            assert(a.sign == false, 'new max pos sign');

            let a = IntegerTrait::<i256>::new(i256_max, true);
            assert(a.mag == i256_max, 'new max neg value error');
            assert(a.sign == true, 'new max neg sign');
        }

        // Test new i256 min
        #[test]
        fn test_i256_min() {
            let a = IntegerTrait::<i256>::new(0, false);
            assert(a.mag == 0, 'new min value error');
            assert(a.sign == false, 'new max pos sign');

            let a = IntegerTrait::<i256>::new(1, true);
            assert(a.mag == 1, 'new min value error');
            assert(a.sign == true, 'new max neg sign');
        }
    }

    mod Add {
        use fractal_swap::numbers::signed_integer::i256::i256;
        use orion::numbers::signed_integer::integer_trait::IntegerTrait;
        use integer::BoundedInt;

        // Test addition of two positive integers
        #[test]
        fn test_positive_x_positive() {
            let a = IntegerTrait::<i256>::new(129, false);
            let b = IntegerTrait::<i256>::new(10, false);
            let result = a + b;
            assert(result.mag == 139, '129 + 10 = 139');
            assert(result.sign == false, '42 + 13 -> positive');
        }

        // Test addition of two negative integers
        #[test]
        fn test_negative_x_negative() {
            let a = IntegerTrait::<i256>::new(129, true);
            let b = IntegerTrait::<i256>::new(10, true);
            let result = a + b;
            assert(result.mag == 139, '- 129 - 10 = -139');
            assert(result.sign == true, '- 42 - 13 -> negative');
        }

        // Test addition of a positive integer and a negative integer with the same magnitude
        #[test]
        fn test_positive_x_negative_same_mag() {
            let a = IntegerTrait::<i256>::new(42, false);
            let b = IntegerTrait::<i256>::new(42, true);
            let result = a + b;
            assert(result.mag == 0, '42 - 42 = 0');
            assert(result.sign == false, '42 - 42 -> positive');
        }

        // Test addition of a positive integer and a negative integer with different magnitudes
        #[test]
        fn test_positive_x_negative_diff_mag() {
            let a = IntegerTrait::<i256>::new(42, false);
            let b = IntegerTrait::<i256>::new(13, true);
            let result = a + b;
            assert(result.mag == 29, '42 - 13 = 29');
            assert(result.sign == false, '42 - 13 -> positive');
        }

        // Test addition of a negative integer and a positive integer with different magnitudes
        #[test]
        fn test_negative_x_positive_diff_mag() {
            let a = IntegerTrait::<i256>::new(42, true);
            let b = IntegerTrait::<i256>::new(13, false);
            let result = a + b;
            assert(result.mag == 29, '-42 + 13 = -29');
            assert(result.sign == true, '-42 + 13 -> negative');
        }

        // Test addition overflow
        #[test]
        #[should_panic]
        fn test_overflow() {
            let i256_max = BoundedInt::max() / 2;
            let a = IntegerTrait::<i256>::new(i256_max - 1, false);
            let b = IntegerTrait::<i256>::new(1, false);
            let result = a + b;
        }
    }

    mod Sub {
        use fractal_swap::numbers::signed_integer::i256::i256;
        use orion::numbers::signed_integer::integer_trait::IntegerTrait;
        use integer::BoundedInt;

        use debug::PrintTrait;

        // Test subtraction of two positive integers with larger first
        #[test]
        fn test_positive_x_positive_larger_first() {
            let a = IntegerTrait::<i256>::new(42, false);
            let b = IntegerTrait::<i256>::new(13, false);
            let result = a - b;
            assert(result.mag == 29, '42 - 13 = 29');
            assert(result.sign == false, '42 - 13 -> positive');
        }
    
        // Test subtraction of two positive integers with larger second
        #[test]
        fn test_positive_x_positive_larger_second() {
            let a = IntegerTrait::<i256>::new(13, false);
            let b = IntegerTrait::<i256>::new(42, false);
            let result = a - b;
            assert(result.mag == 29, '13 - 42 = -29');
            assert(result.sign == true, '13 - 42 -> negative');
        }

        // Test subtraction of two negative integers with larger first
        #[test]
        fn test_negative_x_negative_larger_first() {
            let a = IntegerTrait::<i256>::new(42, true);
            let b = IntegerTrait::<i256>::new(13, true);
            let result = a - b;
            assert(result.mag == 29, '-42 - -13 = 29');
            assert(result.sign == true, '-42 - -13 -> negative');
        }

        // Test subtraction of two negative integers with larger second
        #[test]
        fn test_negative_x_negative_larger_second() {
            let a = IntegerTrait::<i256>::new(13, true);
            let b = IntegerTrait::<i256>::new(42, true);
            let result = a - b;
            assert(result.mag == 29, '-13 - -42 = 29');
            assert(result.sign == false, '-13 - -42 -> positive');
        }

        // Test subtraction of a positive integer and a negative integer with the same magnitude
        #[test]
        fn test_positive_x_negative_same_mag() {
            let a = IntegerTrait::<i256>::new(42, false);
            let b = IntegerTrait::<i256>::new(42, true);
            let result = a - b;
            assert(result.mag == 84, '42 - -42 = 84');
            assert(result.sign == false, '42 - -42 -> postive');
        }

        // Test subtraction of a negative integer and a positive integer with the same magnitude
        #[test]
        fn test_negative_x_positive_same_mag() {
            let a = IntegerTrait::<i256>::new(42, true);
            let b = IntegerTrait::<i256>::new(42, false);
            let result = a - b;
            assert(result.mag == 84, '-42 - 42 = -84');
            assert(result.sign == true, '-42 - 42 -> negative');
        }

        // Test subtraction of a positive integer and a negative integer with different magnitudes
        #[test]
        fn test_positive_x_negative_diff_mag() {
        let a = IntegerTrait::<i256>::new(100, false);
        let b = IntegerTrait::<i256>::new(42, true);
        let result = a - b;
        assert(result.mag == 142, '100 - - 42 = 142');
        assert(result.sign == false, '100 - - 42 -> postive');
        }

        // Test subtraction of a negative integer and a positive integer with different magnitudes
        #[test]
        fn test_negative_x_positive_diff_mag() {
            let a = IntegerTrait::<i256>::new(42, true);
            let b = IntegerTrait::<i256>::new(100, false);
            let result = a - b;
            assert(result.mag == 142, '-42 - 100 = -142');
            assert(result.sign == true, '-42 - 100 -> negative');
        }
 
        // Test subtraction resulting in zero
        #[test]
        fn test_result_in_zero() {
            let a = IntegerTrait::<i256>::new(42, false);
            let b = IntegerTrait::<i256>::new(42, false);
            let result = a - b;
            assert(result.mag == 0, '42 - 42 = 0');
            assert(result.sign == false, '42 - 42 -> positive');
        }

        // Test subtraction overflow
        #[test]
        #[should_panic]
        fn test_overflow() {
            let i256_max = BoundedInt::max() / 2;
            let a = IntegerTrait::<i256>::new(i256_max, true);
            let b = IntegerTrait::<i256>::new(1, false);
            let result = a - b;
        }
    }

    mod Mul {
        use fractal_swap::numbers::signed_integer::i256::i256;
        use orion::numbers::signed_integer::integer_trait::IntegerTrait;
        use integer::BoundedInt;

        // Test multiplication of positive integers
        #[test]
        fn test_positive_x_positive() {
            let a = IntegerTrait::<i256>::new(10, false);
            let b = IntegerTrait::<i256>::new(5, false);
            let result = a * b;
            assert(result.mag == 50, '10 * 5 = 50');
            assert(result.sign == false, '10 * 5 -> positive');
        }

        // Test multiplication of negative integers
        #[test]
        fn test_negative_x_negative() {
            let a = IntegerTrait::<i256>::new(10, true);
            let b = IntegerTrait::<i256>::new(5, true);
            let result = a * b;
            assert(result.mag == 50, '-10 * -5 = 50');
            assert(result.sign == false, '-10 * -5 -> positive');
        }

        // Test multiplication of positive and negative integers
        #[test]
        fn test_positive_x_negative() {
            let a = IntegerTrait::<i256>::new(10, false);
            let b = IntegerTrait::<i256>::new(5, true);
            let result = a * b;
            assert(result.mag == 50, '10 * -5 = -50');
            assert(result.sign == true, '10 * -5 -> negative');
        }

        // Test multiplication of negative and positive integers
        #[test]
        fn test_negative_x_positive() {
            let a = IntegerTrait::<i256>::new(10, true);
            let b = IntegerTrait::<i256>::new(5, false);
            let result = a * b;
            assert(result.mag == 50, '10 * -5 = -50');
            assert(result.sign == true, '10 * -5 -> negative');
        }
        
        // Test multiplication by zero
        #[test]
        fn test_by_zero() {
            let a = IntegerTrait::<i256>::new(10, false);
            let b = IntegerTrait::<i256>::new(0, false);
            let result = a * b;
            assert(result.mag == 0, '10 * 0 = 0');
            assert(result.sign == false, '10 * 0 -> positive');
        }

        // Test multiplication overflow
        #[test]
        #[should_panic]
        fn test_overflow() {
            let i256_max = BoundedInt::max() / 2;
            let a = IntegerTrait::<i256>::new(i256_max - 1, false);
            let b = IntegerTrait::<i256>::new(2, false);
            let result = a * b;
        }
    }

    mod DivRem { 
        use fractal_swap::numbers::signed_integer::i256::i256;
        use orion::numbers::signed_integer::integer_trait::IntegerTrait;
        use integer::BoundedInt;

        // Test division and remainder of positive integers
        #[test]
        fn test_rem_positive_x_positive() {
            let a = IntegerTrait::<i256>::new(13, false);
            let b = IntegerTrait::<i256>::new(5, false);
            let (q, r) = a.div_rem(b);
            assert(q.mag == 2 && r.mag == 3, '13 // 5 = 2 r 3');
            assert((q.sign == false) & (r.sign == false), '13 // 5 -> positive');
        }

        // Test division and remainder of negative integers
        #[test]
        fn test_rem_negative_x_negative() {
            let a = IntegerTrait::<i256>::new(13, true);
            let b = IntegerTrait::<i256>::new(5, true);
            let (q, r) = a.div_rem(b);
            assert(q.mag == 2 && r.mag == 3, '-13 // -5 = 2 r -3');
            assert(q.sign == false && r.sign == true, '-13 // -5 -> positive');
        }

        // Test division and remainder of positive and negative integers
        #[test]
        fn test_rem_positive_x_negative() {
            let a = IntegerTrait::<i256>::new(13, false);
            let b = IntegerTrait::<i256>::new(5, true);
            let (q, r) = a.div_rem(b);
            assert(q.mag == 3 && r.mag == 2, '13 // -5 = -3 r -2');
            assert(q.sign == true && r.sign == true, '13 // -5 -> negative');
        }

        // Test division and remainder with a negative dividend and positive divisor
        #[test]
        fn test_rem_negative_x_positive() {
            let a = IntegerTrait::<i256>::new(13, true);
            let b = IntegerTrait::<i256>::new(5, false);
            let (q, r) = a.div_rem(b);
            assert(q.mag == 3 && r.mag == 2, '-13 // 5 = -3 r 2');
            assert(q.sign == true && r.sign == false, '-13 // 5 -> negative');
        }
        
        // Test division with a = zero
        #[test]
        fn test_rem_z_eq_zero() {
            let a = IntegerTrait::<i256>::new(0, false);
            let b = IntegerTrait::<i256>::new(10, false);
            let (q, r) = a.div_rem(b);
            assert(q.mag == 0 && r.mag == 0, '0 // 10 = 0 r 0');
            assert(q.sign == false && r.sign == false, '0 // 10 -> positive');
        }

        // Test division by zero
        #[test]
        #[should_panic]
        fn test_rem_by_zero() {
            let a = IntegerTrait::<i256>::new(1, false);
            let b = IntegerTrait::<i256>::new(0, false);
            let (q, r) = a.div_rem(b);
        }
    }
}
