mod TestFullMath {
    mod MulDiv {
        use fractal_swap::utils::fullmath::FullMath::mul_div;
        use integer::BoundedInt;

        const Q128: u256 = 340282366920938463463374607431768211456;

        // reverts if denominator is 0  
        #[test]
        #[should_panic]
        fn test_fail_denominator_is_0() {
            mul_div(Q128, 5, 0);
        }

        // reverts if denominator is 0 and numerator overflows  
        #[test]
        #[should_panic]
        fn test_fail_denominator_is_0_and_numerator_overflows() {
            mul_div(Q128, Q128, 0);
        }

        // reverts if output overflows uint256
        #[test]
        #[should_panic]
        fn test_fail_if_output_overflows_u256() {
            mul_div(Q128, Q128, 1);
        }
        // reverts on overflow with all max inputs 
        #[test]
        #[should_panic]
        fn test_fail_on_overflow_with_all_max_inputs() {
            mul_div(BoundedInt::max(), BoundedInt::max(), BoundedInt::max() - 1);
        }

        // all max inputs
        #[test]
        #[available_gas(2000000)]
        fn test_all_max_inputs() {
            let actual = mul_div(BoundedInt::max(), BoundedInt::max(), BoundedInt::max());
            assert(actual == BoundedInt::max(), 'all_max_inputs');
        }

        // accurate without phantom overflow
        #[test]
        #[available_gas(2000000)]
        fn test_accurate_without_phantom_overflow() {
            let actual = mul_div(Q128, 50 * Q128 / 100, 150 * Q128 / 100);
            let expected = Q128 / 3;
            assert(actual == expected, 'accurate w/o phantom overflow');
        }

        // accurate with phantom overflow
        #[test]
        #[available_gas(2000000)]
        fn test_accurate_with_phantom_overflow() {
            let actual = mul_div(Q128, 35 * Q128, 8 * Q128);
            let expected = 4375 * Q128 / 1000;
            assert(actual == expected, 'accurate with phantom overflow');
        }

        // accurate with phantom overflow and repeating decimal
        #[test]
        #[available_gas(2000000)]
        fn test_accurate_with_phantom_overflow_repeat_decimal() {
            let actual = mul_div(Q128, 1000 * Q128, 3000 * Q128);
            let expected = Q128 / 3;
            assert(actual == expected, 'accurate with phantom overflow');
        }
    }

    mod MulDivRoundingUp {
        use fractal_swap::utils::fullmath::FullMath::mul_div_rounding_up;
        use integer::BoundedInt;

        const Q128: u256 = 340282366920938463463374607431768211456;

        // reverts if denominator is 0
        #[test]
        #[should_panic]
        fn test_fail_if_denominator_is_0() {
            mul_div_rounding_up(Q128, 5, 0);
        }

        // reverts if denominator is 0 and numerator overflows
        #[test]
        #[should_panic]
        fn test_fail_if_denominator_is_0_and_numerator_overflow() {
            mul_div_rounding_up(Q128, Q128, 0);
        }

        // reverts if output overflows uint256
        #[test]
        #[should_panic]
        fn test_fail_if_output_overflows_u256() {
            mul_div_rounding_up(Q128, Q128, 1);
        }

        // reverts on overflow with all max inputs  
        #[test]
        #[should_panic]
        fn test_fail_on_overflow_with_all_max_inputs() {
            mul_div_rounding_up(BoundedInt::max(), BoundedInt::max(), BoundedInt::max() - 1);
        }

        // reverts if mulDiv overflows 256 bits after rounding up
        #[test]
        #[should_panic]
        fn test_fail_if_mul_div_overflows_256_bits_after_rounding_up() {
            mul_div_rounding_up(
                535006138814359, 432862656469423142931042426214547535783388063929571229938474969, 2
            );
        }

        // reverts if mulDiv overflows 256 bits after rounding up case 2
        #[test]
        #[should_panic]
        fn test_fail_if_mul_div_overflows_256_bits_after_rounding_up_2() {
            mul_div_rounding_up(
                115792089237316195423570985008687907853269984659341747863450311749907997002549,
                115792089237316195423570985008687907853269984659341747863450311749907997002550,
                115792089237316195423570985008687907853269984653042931687443039491902864365164
            );
        }

        // all max inputs 
        #[test]
        #[available_gas(2000000)]
        fn test_all_max_inputs() {
            let actual = mul_div_rounding_up(
                BoundedInt::max(), BoundedInt::max(), BoundedInt::max()
            );
            assert(actual == BoundedInt::max(), 'all_max_inputs');
        }

        // accurate without phantom overflow
        #[test]
        #[available_gas(2000000)]
        fn test_accurate_without_phantom_overflow() {
            let actual = mul_div_rounding_up(Q128, 50 * Q128 / 100, 150 * Q128 / 100);
            let expected = Q128 / 3 + 1;
            assert(actual == expected, 'accurate w/o phantom overflow');
        }

        // accurate with phantom overflow
        #[test]
        #[available_gas(2000000)]
        fn test_accurate_with_phantom_overflowl() {
            let actual = mul_div_rounding_up(Q128, 35 * Q128, 8 * Q128);
            let expected = 4375 * Q128 / 1000;
            assert(actual == expected, 'acc with phantom overflow');
        }

        // accurate with phantom overflow and repeating decimal
        #[test]
        #[available_gas(2000000)]
        fn test_accurate_with_phantom_overflow_repeat_decimal() {
            let actual = mul_div_rounding_up(Q128, 1000 * Q128, 3000 * Q128);
            let expected = Q128 / 3 + 1;
            assert(actual == expected, 'accurate with phantom overflow');
        }
    }

    mod MulModN {
        use fractal_swap::utils::fullmath::FullMath::mul_mod_n;
        use fractal_swap::utils::math_utils::MathUtils::pow;
        use integer::BoundedInt;

        #[test]
        #[available_gas(2000000)]
        fn test_mul_mod_n_positive_numbers() {
            let a: u256 = 12345.into();
            let b: u256 = 67890.into();
            let n: u256 = 100000.into();

            let result = mul_mod_n(a, b, n);

            assert(result == (a * b) % n, 'wrong mul mod n');
        }

        #[test]
        #[should_panic]
        fn test_mul_mod_n_zero_n() {
            let a: u256 = 1;
            let b: u256 = 1;
            let n: u256 = 0;

            mul_mod_n(a, b, n);
        }

        #[test]
        fn test_mul_mod_n_zero_a_or_b() {
            let a: u256 = 0.into(); // Prueba con a igual a cero
            let b: u256 = 67890.into();
            let n: u256 = 100000.into();

            let result = mul_mod_n(a, b, n);

            assert(result == 0, 'wrong mul mod n');
        }
    }
}
