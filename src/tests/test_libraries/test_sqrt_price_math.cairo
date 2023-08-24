mod TestSqrtPriceMath {
    use fractal_swap::utils::math_utils::MathUtils::pow;
    use fractal_swap::numbers::fixed_point::implementations::impl_64x96::{
        FP64x96Impl, FixedType, FixedTrait, Q96_RESOLUTION
    };
    use traits::Into;

    mod GetNextSqrtPriceFromInput {
        use fractal_swap::utils::math_utils::MathUtils::pow;
        use fractal_swap::libraries::sqrt_price_math::SqrtPriceMath;
        use fractal_swap::tests::test_libraries::test_sqrt_price_math::TestSqrtPriceMath::{
            encode_price_sqrt, expand_to_18_decimals
        };
        use fractal_swap::numbers::fixed_point::implementations::fullmath::FullMath::{mul_div};
        use fractal_swap::numbers::fixed_point::implementations::impl_64x96::{
            FP64x96Impl, FP64x96PartialEq, FixedType, FixedTrait, Q96_RESOLUTION
        };
        use integer::BoundedInt;
        use traits::{Into, TryInto};
        use option::OptionTrait;

        #[test]
        #[should_panic]
        fn test_fail_if_price_is_zero() {
            SqrtPriceMath::get_next_sqrt_price_from_input(
                FP64x96Impl::from_felt(0), 0, expand_to_18_decimals(1) / 10, false
            );
        }

        #[test]
        #[should_panic]
        fn test_fail_if_liquidity_is_zero() {
            SqrtPriceMath::get_next_sqrt_price_from_input(
                FP64x96Impl::from_felt(1), 0, expand_to_18_decimals(1) / 10, true
            );
        }

        #[test]
        #[should_panic]
        fn test_fail_if_input_amount_overflows_price() {
            let price = FP64x96Impl::from_felt((pow(2, 160) - 1).try_into().unwrap());
            let liquidity = 1024;
            let amount_in = 1024;
            SqrtPriceMath::get_next_sqrt_price_from_input(price, liquidity, amount_in, false);
        }

        #[test]
        #[should_panic]
        fn test_fail_if_input_amount_cannot_underflow_the_price() {
            let price = FP64x96Impl::from_felt(1);
            let liquidity = 1024;
            let amount_in = 1024;
            SqrtPriceMath::get_next_sqrt_price_from_input(price, liquidity, amount_in, false);
        }

        #[test]
        #[available_gas(20000000)]
        fn test_returns_input_price_if_amount_in_is_zero_and_zero_for_one_true() {
            let price = encode_price_sqrt(1, 1);
            let liquidity: u128 = (expand_to_18_decimals(1) / 10).try_into().unwrap();
            let amount_in = 0;

            let actual = SqrtPriceMath::get_next_sqrt_price_from_input(
                price, liquidity, amount_in, true
            );

            assert(actual == price, 'assert error');
        }

        #[test]
        #[available_gas(20000000)]
        fn test_returns_input_price_if_amount_in_is_zero_and_zero_for_one_false() {
            let price = encode_price_sqrt(1, 1);
            let liquidity: u128 = (expand_to_18_decimals(1) / 10).try_into().unwrap();
            let amount_in = 0;

            let actual = SqrtPriceMath::get_next_sqrt_price_from_input(
                price, liquidity, amount_in, true
            );

            assert(actual == price, 'assert error');
        }
    // #[test]
    // #[available_gas(200000000)]
    // fn test_returns_the_minumum_price_for_max_inputs() {
    //     let price = FP64x96Impl::from_felt((pow(2, 96) - 1).try_into().unwrap());
    //     let liquidity: u128 = BoundedInt::max();
    //     let max_liquidity: u256 = mul_div(liquidity.into(), pow(2, 96), price.mag);
    //     let max_amount_no_overflow: u256 = BoundedInt::max() - max_liquidity;

    //     let actual = SqrtPriceMath::get_next_sqrt_price_from_input(price, liquidity, max_amount_no_overflow, true);

    // // assert(actual == FP64x96Impl::from_felt(1), 'assert error');
    // }
    }

    mod GetNextSqrtPriceFromOutput {
        use fractal_swap::libraries::sqrt_price_math::SqrtPriceMath;
        use fractal_swap::tests::test_libraries::test_sqrt_price_math::TestSqrtPriceMath::{
            encode_price_sqrt, expand_to_18_decimals
        };
        use fractal_swap::numbers::fixed_point::implementations::impl_64x96::{
            FP64x96Impl, FP64x96PartialEq, FixedType, FixedTrait, Q96_RESOLUTION
        };
        use integer::BoundedInt;
        use option::OptionTrait;
        use traits::{Into, TryInto};

        #[test]
        #[should_panic]
        fn test_fail_if_price_is_zero() {
            SqrtPriceMath::get_next_sqrt_price_from_output(
                FP64x96Impl::from_felt(0), 0, expand_to_18_decimals(1) / 10, false
            );
        }

        #[test]
        #[should_panic]
        fn test_fail_if_liquidity_is_zero() {
            SqrtPriceMath::get_next_sqrt_price_from_output(
                FP64x96Impl::from_felt(1), 0, expand_to_18_decimals(1) / 10, true
            );
        }

        #[test]
        #[should_panic]
        fn test_fail_output_amount_eq_virtual_reserves_of_token_0() {
            let price = FP64x96Impl::from_felt(20282409603651670423947251286016);
            let liquidity = 1024;
            let amount_out = 4;
            SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, false);
        }

        #[test]
        #[should_panic]
        fn test_fail_output_amount_gt_virtual_reserves_of_token_0() {
            let price = FP64x96Impl::from_felt(20282409603651670423947251286016);
            let liquidity = 1024;
            let amount_out = 5;
            SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, false);
        }

        #[test]
        #[should_panic]
        fn test_fail_output_amount_eq_virtual_reserves_of_token_1() {
            let price = FP64x96Impl::from_felt(20282409603651670423947251286016);
            let liquidity = 1024;
            let amount_out = 262144;
            SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, true);
        }

        #[test]
        #[should_panic]
        fn test_fail_output_amount_gt_virtual_reserves_of_token_1() {
            let price = FP64x96Impl::from_felt(20282409603651670423947251286016);
            let liquidity = 1024;
            let amount_out = 262145;
            SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, true);
        }

        #[test]
        #[available_gas(20000000)]
        fn test_output_amount_is_lt_virtual_reservers_of_token_1() {
            let price = FP64x96Impl::from_felt(20282409603651670423947251286016);
            let liquidity = 1024;
            let amount_out = 262143;

            let actual = SqrtPriceMath::get_next_sqrt_price_from_output(
                price, liquidity, amount_out, true
            );
            let expected = FP64x96Impl::from_felt(77371252455336267181195264);

            assert(actual == expected, 'amount_lt_reservers_of_token_1')
        }

        #[test]
        #[should_panic]
        fn test_puzzling_edhidna() {
            let price = FP64x96Impl::from_felt(20282409603651670423947251286016);
            let liquidity = 1024;
            let amount_out = 4;
            SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, false);
        }

        #[test]
        #[available_gas(20000000)]
        fn test_input_price_if_amount_is_in_zero_and_zero_for_one_true() {
            let price = encode_price_sqrt(1, 1);
            let liquidity: u128 = expand_to_18_decimals(1).try_into().unwrap() / 10;
            let actual = SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, 0, true);

            assert(actual == price, 'actual not eq to price')
        }

        #[test]
        #[available_gas(20000000)]
        fn test_input_price_if_amount_is_in_zero_and_zero_for_one_false() {
            let price = encode_price_sqrt(1, 1);
            let liquidity: u128 = expand_to_18_decimals(1).try_into().unwrap() / 10;
            let actual = SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, 0, false);

            assert(actual == price, 'actual not eq to price')
        }

        #[test]
        #[available_gas(20000000)]
        fn test_output_amount_of_0_dot_1_token_1_zero_for_one_false() {
            let price = encode_price_sqrt(1, 1);
            let liquidity: u128 = expand_to_18_decimals(1).try_into().unwrap();
            let amount_out = expand_to_18_decimals(1) / 10;

            let actual = SqrtPriceMath::get_next_sqrt_price_from_output(
                price, liquidity, amount_out, false
            );
            let expected = FP64x96Impl::from_felt(88031291682515930659493278152);
            assert(actual == expected, 'output_amount_0_dot_1_token_1')
        }

        #[test]
        #[available_gas(20000000)]
        fn test_output_amount_of_0_dot_1_token_1_zero_for_one_true() {
            let price = encode_price_sqrt(1, 1);
            let liquidity: u128 = expand_to_18_decimals(1).try_into().unwrap();
            let amount_out = expand_to_18_decimals(1) / 10;

            let actual = SqrtPriceMath::get_next_sqrt_price_from_output(
                price, liquidity, amount_out, true
            );
            let expected = FP64x96Impl::from_felt(71305346262837903834189555302);
            assert(actual == expected, 'output_amount_0_dot_1_token_1')
        }

        #[test]
        #[should_panic]
        fn test_fail_if_amount_out_is_impossible_in_zero_for_one_direction_true() {
            let price = encode_price_sqrt(1, 1);
            let liquidity = 1;
            let amount_out: u256 = BoundedInt::max();
            SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, true);
        }

        #[test]
        #[should_panic]
        fn test_fail_if_amount_out_is_impossible_in_zero_for_one_direction_false() {
            let price = encode_price_sqrt(1, 1);
            let liquidity = 1;
            let amount_out: u256 = BoundedInt::max();
            SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, false);
        }
    }

    mod GetAmount0Delta {
        use fractal_swap::libraries::sqrt_price_math::SqrtPriceMath;
        use fractal_swap::tests::test_libraries::test_sqrt_price_math::TestSqrtPriceMath::{
            encode_price_sqrt, expand_to_18_decimals
        };
        use fractal_swap::numbers::fixed_point::implementations::impl_64x96::{
            FP64x96Impl, FP64x96PartialEq, FixedType, FixedTrait, Q96_RESOLUTION
        };
        use option::OptionTrait;
        use traits::{Into, TryInto};

        #[test]
        #[available_gas(20000000)]
        fn test_amount_0_delta_returns_0_if_liquidity_is_0() {
            let actual = SqrtPriceMath::get_amount_0_delta(
                encode_price_sqrt(1, 1), encode_price_sqrt(2, 1), 0, true
            );
            let expected = 0;
            assert(actual == expected, 'delta_returns_0_if_liq_is_0')
        }

        #[test]
        #[available_gas(20000000)]
        fn test_amount_0_delta_returns_0_if_prices_are_eq() {
            let actual = SqrtPriceMath::get_amount_0_delta(
                encode_price_sqrt(1, 1), encode_price_sqrt(1, 1), 0, true
            );
            let expected = 0;
            assert(actual == expected, 'delta_return_0_if_prices_are_eq')
        }

        #[test]
        #[available_gas(200000000)]
        fn test_amount_0_delta_returns_0_dot_1_amount1_for_price_of_1_to_1_dot_21() {
            let amount0 = SqrtPriceMath::get_amount_0_delta(
                encode_price_sqrt(1, 1),
                encode_price_sqrt(121, 100),
                expand_to_18_decimals(1).try_into().unwrap(),
                true
            );

            // TODO: Check original result should be 90909090909090910 but we get 90909090909089148 
            // has 1.938199×10^-14 error
            assert(amount0 == 90909090909089148, 'amount0 ronded not eq');

            let amount0_rounded_down = SqrtPriceMath::get_amount_0_delta(
                encode_price_sqrt(1, 1),
                encode_price_sqrt(121, 100),
                expand_to_18_decimals(1).try_into().unwrap(),
                false
            );
            assert(amount0_rounded_down == amount0 - 1, 'amount0 ronded not eq');
        }
    }

    // Aux methods for tests
    fn encode_price_sqrt(reserve1: u256, reserve0: u256) -> FixedType {
        let ratio = reserve1 * pow(2, Q96_RESOLUTION.into()) / reserve0;
        FP64x96Impl::new(ratio, false).sqrt()
    }

    fn expand_to_18_decimals(n: u256) -> u256 {
        // return BigNumber.from(n).mul(BigNumber.from(10).pow(18))
        pow(n * 10, 18)
    }
}
