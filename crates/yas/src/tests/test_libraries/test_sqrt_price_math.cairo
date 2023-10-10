mod TestSqrtPriceMath {
    use yas::numbers::fixed_point::implementations::impl_64x96::{
        FP64x96Impl, FixedType, FixedTrait,
    };
    use yas::utils::math_utils::pow;

    mod GetNextSqrtPriceFromInput {
        use super::{encode_price_sqrt_1_1, encode_price_sqrt_121_100};

        use integer::BoundedInt;

        use yas::libraries::sqrt_price_math::SqrtPriceMath;
        use yas::numbers::fixed_point::implementations::impl_64x96::{
            FP64x96Impl, FP64x96PartialEq, FixedType, FixedTrait
        };
        use yas::tests::test_libraries::test_sqrt_price_math::TestSqrtPriceMath::expand_to_18_decimals;
        use yas::utils::math_utils::{pow, FullMath::mul_div};

        // fails if price is zero
        #[test]
        #[should_panic]
        fn test_fail_if_price_is_zero() {
            SqrtPriceMath::get_next_sqrt_price_from_input(
                FixedTrait::from_felt(0), 0, expand_to_18_decimals(1) / 10, false
            );
        }

        // fails if liquidity is zero
        #[test]
        #[should_panic]
        fn test_fail_if_liquidity_is_zero() {
            SqrtPriceMath::get_next_sqrt_price_from_input(
                FixedTrait::from_felt(1), 0, expand_to_18_decimals(1) / 10, true
            );
        }

        // fails if input amount overflows the price
        #[test]
        #[should_panic]
        fn test_fail_if_input_amount_overflows_price() {
            let price = FixedTrait::from_felt((pow(2, 160) - 1).try_into().unwrap());
            let liquidity = 1024;
            let amount_in = 1024;
            SqrtPriceMath::get_next_sqrt_price_from_input(price, liquidity, amount_in, false);
        }

        // any input amount cannot underflow the price  
        #[test]
        #[should_panic]
        fn test_fail_if_input_amount_cannot_underflow_the_price() {
            let price = FixedTrait::from_felt(1);
            let liquidity = 1024;
            let amount_in = 1024;
            SqrtPriceMath::get_next_sqrt_price_from_input(price, liquidity, amount_in, false);
        }

        // returns input price if amount in is zero and zeroForOne = true
        #[test]
        #[available_gas(20000000)]
        fn test_returns_input_price_if_amount_in_is_zero_and_zero_for_one_true() {
            let price = encode_price_sqrt_1_1();
            let liquidity: u128 = (expand_to_18_decimals(1) / 10).try_into().unwrap();
            let amount_in = 0;

            let actual = SqrtPriceMath::get_next_sqrt_price_from_input(
                price, liquidity, amount_in, true
            );

            assert(actual == price, 'assert error');
        }

        // returns input price if amount in is zero and zeroForOne = false
        #[test]
        #[available_gas(20000000)]
        fn test_returns_input_price_if_amount_in_is_zero_and_zero_for_one_false() {
            let price = encode_price_sqrt_1_1();
            let liquidity: u128 = (expand_to_18_decimals(1) / 10).try_into().unwrap();
            let amount_in = 0;

            let actual = SqrtPriceMath::get_next_sqrt_price_from_input(
                price, liquidity, amount_in, true
            );

            assert(actual == price, 'assert error');
        }

        // returns the minimum price for max inputs
        #[test]
        #[available_gas(200000000)]
        fn test_returns_the_minumum_price_for_max_inputs() {
            let price = FixedTrait::new((pow(2, 159)), false);
            let liquidity: u128 = BoundedInt::max();
            let max_liquidity: u256 = mul_div(liquidity.into(), pow(2, 96), price.mag);
            let max_amount_no_overflow: u256 = BoundedInt::max()
                - liquidity.into() * pow(2, 96) / price.mag;

            let actual = SqrtPriceMath::get_next_sqrt_price_from_input(
                price, liquidity, max_amount_no_overflow, true
            );
            assert(actual == FixedTrait::from_felt(1), 'assert error');
        }

        // input amount of 0.1 token1
        #[test]
        #[available_gas(200000000)]
        fn test_input_amount_of_0_dot_1_token_1() {
            let price = encode_price_sqrt_1_1();
            let liquidity: u128 = expand_to_18_decimals(1).try_into().unwrap();
            let amount = expand_to_18_decimals(1) / 10;

            let actual = SqrtPriceMath::get_next_sqrt_price_from_input(
                price, liquidity, amount, false
            );
            assert(actual == FixedTrait::from_felt(87150978765690771352898345369), 'assert error');
        }

        // input amount of 0.1 token0
        #[test]
        #[available_gas(200000000)]
        fn test_input_amount_of_0_dot_1_token_0() {
            let price = encode_price_sqrt_1_1();
            let liquidity: u128 = expand_to_18_decimals(1).try_into().unwrap();
            let amount = expand_to_18_decimals(1) / 10;

            let actual = SqrtPriceMath::get_next_sqrt_price_from_input(
                price, liquidity, amount, true
            );
            assert(actual == FixedTrait::from_felt(72025602285694852357767227579), 'assert error');
        }

        // amountIn > type(uint96).max and zeroForOne = true
        #[test]
        #[available_gas(200000000)]
        fn test_amount_in_gt_uint_96_and_zero_for_one_true() {
            let price = encode_price_sqrt_1_1();
            let liquidity: u128 = expand_to_18_decimals(10).try_into().unwrap();
            let amount = pow(2, 100);

            let actual = SqrtPriceMath::get_next_sqrt_price_from_input(
                price, liquidity, amount, true
            );
            assert(actual == FixedTrait::from_felt(624999999995069620), 'assert error');
        }

        // can return 1 with enough amountIn and zeroForOne = true
        #[test]
        #[available_gas(200000000)]
        fn test_can_return_1_with_enough_amount_and_zero_for_one() {
            let price = encode_price_sqrt_1_1();
            let liquidity: u128 = 1;
            let amount = BoundedInt::max() / 2;

            let actual = SqrtPriceMath::get_next_sqrt_price_from_input(
                price, liquidity, amount, true
            );
            assert(actual == FixedTrait::from_felt(1), 'assert error');
        }
    }

    mod GetNextSqrtPriceFromOutput {
        use super::{encode_price_sqrt_1_1, encode_price_sqrt_121_100};

        use integer::BoundedInt;

        use yas::libraries::sqrt_price_math::SqrtPriceMath;
        use yas::numbers::fixed_point::implementations::impl_64x96::{
            FP64x96Impl, FP64x96PartialEq, FixedType, FixedTrait
        };
        use yas::tests::test_libraries::test_sqrt_price_math::TestSqrtPriceMath::expand_to_18_decimals;

        // fails if price is zero
        #[test]
        #[should_panic]
        fn test_fail_if_price_is_zero() {
            SqrtPriceMath::get_next_sqrt_price_from_output(
                FixedTrait::from_felt(0), 0, expand_to_18_decimals(1) / 10, false
            );
        }

        // fails if liquidity is zero
        #[test]
        #[should_panic]
        fn test_fail_if_liquidity_is_zero() {
            SqrtPriceMath::get_next_sqrt_price_from_output(
                FixedTrait::from_felt(1), 0, expand_to_18_decimals(1) / 10, true
            );
        }

        // fails if output amount is exactly the virtual reserves of token0
        #[test]
        #[should_panic]
        fn test_fail_output_amount_eq_virtual_reserves_of_token_0() {
            let price = FixedTrait::from_felt(20282409603651670423947251286016);
            let liquidity = 1024;
            let amount_out = 4;
            SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, false);
        }

        // fails if output amount is greater than virtual reserves of token0
        #[test]
        #[should_panic]
        fn test_fail_output_amount_gt_virtual_reserves_of_token_0() {
            let price = FixedTrait::from_felt(20282409603651670423947251286016);
            let liquidity = 1024;
            let amount_out = 5;
            SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, false);
        }

        // fails if output amount is exactly the virtual reserves of token1
        #[test]
        #[should_panic]
        fn test_fail_output_amount_eq_virtual_reserves_of_token_1() {
            let price = FixedTrait::from_felt(20282409603651670423947251286016);
            let liquidity = 1024;
            let amount_out = 262144;
            SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, true);
        }

        // fails if output amount is greater than virtual reserves of token1
        #[test]
        #[should_panic]
        fn test_fail_output_amount_gt_virtual_reserves_of_token_1() {
            let price = FixedTrait::from_felt(20282409603651670423947251286016);
            let liquidity = 1024;
            let amount_out = 262145;
            SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, true);
        }

        // succeeds if output amount is just less than the virtual reserves of token1
        #[test]
        #[available_gas(20000000)]
        fn test_output_amount_is_lt_virtual_reservers_of_token_1() {
            let price = FixedTrait::from_felt(20282409603651670423947251286016);
            let liquidity = 1024;
            let amount_out = 262143;

            let actual = SqrtPriceMath::get_next_sqrt_price_from_output(
                price, liquidity, amount_out, true
            );
            let expected = FixedTrait::from_felt(77371252455336267181195264);

            assert(actual == expected, 'amount_lt_reservers_of_token_1')
        }

        // puzzling echidna test
        #[test]
        #[should_panic]
        fn test_puzzling_edhidna() {
            let price = FixedTrait::from_felt(20282409603651670423947251286016);
            let liquidity = 1024;
            let amount_out = 4;
            SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, false);
        }

        // returns input price if amount in is zero and zeroForOne = true
        #[test]
        #[available_gas(20000000)]
        fn test_input_price_if_amount_is_in_zero_and_zero_for_one_true() {
            let price = encode_price_sqrt_1_1();
            let liquidity: u128 = expand_to_18_decimals(1).try_into().unwrap() / 10;
            let actual = SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, 0, true);

            assert(actual == price, 'actual not eq to price')
        }

        // returns input price if amount in is zero and zeroForOne = false
        #[test]
        #[available_gas(20000000)]
        fn test_input_price_if_amount_is_in_zero_and_zero_for_one_false() {
            let price = encode_price_sqrt_1_1();
            let liquidity: u128 = expand_to_18_decimals(1).try_into().unwrap() / 10;
            let actual = SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, 0, false);

            assert(actual == price, 'actual not eq to price')
        }

        // output amount of 0.1 token1
        #[test]
        #[available_gas(20000000)]
        fn test_output_amount_of_0_dot_1_token_1_zero_for_one_false() {
            let price = encode_price_sqrt_1_1();
            let liquidity: u128 = expand_to_18_decimals(1).try_into().unwrap();
            let amount_out = expand_to_18_decimals(1) / 10;

            let actual = SqrtPriceMath::get_next_sqrt_price_from_output(
                price, liquidity, amount_out, false
            );
            let expected = FixedTrait::from_felt(88031291682515930659493278152);
            assert(actual == expected, 'output_amount_0_dot_1_token_1')
        }

        // output amount of 0.1 token1
        #[test]
        #[available_gas(20000000)]
        fn test_output_amount_of_0_dot_1_token_1_zero_for_one_true() {
            let price = encode_price_sqrt_1_1();
            let liquidity: u128 = expand_to_18_decimals(1).try_into().unwrap();
            let amount_out = expand_to_18_decimals(1) / 10;

            let actual = SqrtPriceMath::get_next_sqrt_price_from_output(
                price, liquidity, amount_out, true
            );
            let expected = FixedTrait::from_felt(71305346262837903834189555302);
            assert(actual == expected, 'output_amount_0_dot_1_token_1')
        }

        // reverts if amountOut is impossible in zero for one direction
        #[test]
        #[should_panic]
        fn test_fail_if_amount_out_is_impossible_in_zero_for_one_direction_true() {
            let price = encode_price_sqrt_1_1();
            let liquidity = 1;
            let amount_out: u256 = BoundedInt::max();
            SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, true);
        }

        // reverts if amountOut is impossible in one for zero direction
        #[test]
        #[should_panic]
        fn test_fail_if_amount_out_is_impossible_in_zero_for_one_direction_false() {
            let price = encode_price_sqrt_1_1();
            let liquidity = 1;
            let amount_out: u256 = BoundedInt::max();
            SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, false);
        }
    }

    mod GetAmount0Delta {
        use super::{
            encode_price_sqrt_1_1, encode_price_sqrt_2_1, encode_price_sqrt_121_100,
            encode_price_sqrt_pow_2_90_1, encode_price_sqrt_pow_2_96_1
        };

        use yas::libraries::sqrt_price_math::SqrtPriceMath;
        use yas::numbers::fixed_point::implementations::impl_64x96::{
            FP64x96Impl, FP64x96PartialEq, FixedType, FixedTrait
        };
        use yas::tests::test_libraries::test_sqrt_price_math::TestSqrtPriceMath::expand_to_18_decimals;
        use yas::utils::math_utils::pow;

        // returns 0 if liquidity is 0
        #[test]
        #[available_gas(20000000)]
        fn test_amount_0_delta_returns_0_if_liquidity_is_0() {
            let actual = SqrtPriceMath::get_amount_0_delta(
                encode_price_sqrt_1_1(), encode_price_sqrt_2_1(), 0, true
            );
            let expected = 0;
            assert(actual == expected, 'delta_returns_0_if_liq_is_0')
        }

        // returns 0 if prices are equal
        #[test]
        #[available_gas(20000000)]
        fn test_amount_0_delta_returns_0_if_prices_are_eq() {
            let actual = SqrtPriceMath::get_amount_0_delta(
                encode_price_sqrt_1_1(), encode_price_sqrt_1_1(), 0, true
            );
            let expected = 0;
            assert(actual == expected, 'delta_return_0_if_prices_are_eq')
        }

        // returns 0.1 amount1 for price of 1 to 1.21
        #[test]
        #[available_gas(200000000)]
        fn test_amount_0_delta_returns_0_dot_1_amount1_for_price_of_1_to_1_dot_21() {
            let amount0 = SqrtPriceMath::get_amount_0_delta(
                encode_price_sqrt_1_1(),
                encode_price_sqrt_121_100(),
                expand_to_18_decimals(1).try_into().unwrap(),
                true
            );

            assert(amount0 == 90909090909090910, 'amount0 ronded not eq');

            let amount0_rounded_down = SqrtPriceMath::get_amount_0_delta(
                encode_price_sqrt_1_1(),
                encode_price_sqrt_121_100(),
                expand_to_18_decimals(1).try_into().unwrap(),
                false
            );
            assert(amount0_rounded_down == amount0 - 1, 'amount0 ronded not eq');
        }

        // works for prices that overflow
        #[test]
        #[available_gas(200000000)]
        fn test_works_for_prices_that_overflow() {
            let amount_0_up = SqrtPriceMath::get_amount_0_delta(
                encode_price_sqrt_pow_2_90_1(),
                encode_price_sqrt_pow_2_96_1(),
                expand_to_18_decimals(1).try_into().unwrap(),
                true
            );

            let amount_0_down = SqrtPriceMath::get_amount_0_delta(
                encode_price_sqrt_pow_2_90_1(),
                encode_price_sqrt_pow_2_96_1(),
                expand_to_18_decimals(1).try_into().unwrap(),
                false
            );
            assert(amount_0_up == amount_0_down + 1, 'amount_0_up != amount_0_down+1');
        }
    }

    mod GetAmount1Delta {
        use super::{encode_price_sqrt_1_1, encode_price_sqrt_2_1, encode_price_sqrt_121_100};

        use yas::libraries::sqrt_price_math::SqrtPriceMath;
        use yas::numbers::fixed_point::implementations::impl_64x96::{
            FP64x96Impl, FP64x96PartialEq, FixedType, FixedTrait
        };
        use yas::tests::test_libraries::test_sqrt_price_math::TestSqrtPriceMath::expand_to_18_decimals;
        use yas::utils::math_utils::pow;

        // returns 0 if liquidity is 0
        #[test]
        #[available_gas(20000000)]
        fn test_returns_0_if_liquidity_is_0() {
            let actual = SqrtPriceMath::get_amount_1_delta(
                encode_price_sqrt_1_1(), encode_price_sqrt_2_1(), 0, true
            );
            assert(actual == 0, 'returns_0_if_liquidity_is_0')
        }

        // returns 0 if prices are equal
        #[test]
        #[available_gas(20000000)]
        fn test_returns_0_if_prices_are_eq() {
            let actual = SqrtPriceMath::get_amount_1_delta(
                encode_price_sqrt_1_1(),
                encode_price_sqrt_1_1(),
                expand_to_18_decimals(1).try_into().unwrap(),
                true
            );
            assert(actual == 0, 'returns_0_if_prices_are_eq')
        }

        // returns 0.1 amount1 for price of 1 to 1.21
        #[test]
        #[available_gas(20000000)]
        fn test_returns_0_dot_1_amount_1_for_price_1_to_1_dot_21() {
            let price_a = encode_price_sqrt_1_1();
            let price_b = encode_price_sqrt_121_100();

            let liquidity: u128 = expand_to_18_decimals(1).try_into().unwrap();

            let actual = SqrtPriceMath::get_amount_1_delta(price_a, price_b, liquidity, true);

            assert(actual == 100000000000000000, 'wrong 1delta amount price');

            let actual_rounded_down = SqrtPriceMath::get_amount_1_delta(
                encode_price_sqrt_1_1(),
                encode_price_sqrt_121_100(),
                expand_to_18_decimals(1).try_into().unwrap(),
                false
            );
            assert(actual_rounded_down == actual - 1, 'wrong 1delta round amount price')
        }
    }

    // AUX
    // Due to issues with the calculations, the implementation of encode_sqrt_price(a, b)
    // was removed in favor of using constant values. What we are interested in testing are the 
    // methods of the SqrtPriceMath library.

    // returns result of encode_price_sqrt(1, 1) on v3-core typescript impl. 
    fn encode_price_sqrt_1_1() -> FixedType {
        FixedTrait::new(79228162514264337593543950336, false)
    }

    // next value is the result of encode_price_sqrt(121, 100) on v3-core typescript impl. 
    fn encode_price_sqrt_121_100() -> FixedType {
        FixedTrait::new(87150978765690771352898345369, false)
    }

    // next value is the result of encode_price_sqrt(2, 1) on v3-core typescript impl. 
    fn encode_price_sqrt_2_1() -> FixedType {
        FixedTrait::new(112045541949572279837463876454, false)
    }

    // next value is the result of encode_price_sqrt(pow(2, 90), 1) on v3-core typescript impl. 
    fn encode_price_sqrt_pow_2_90_1() -> FixedType {
        FixedTrait::new(2787593149816327920953038481947722450866090, false)
    }

    // next value is the result of encode_price_sqrt(pow(2, 96), 1) on v3-core typescript impl. 
    fn encode_price_sqrt_pow_2_96_1() -> FixedType {
        FixedTrait::new(22300745198530623480214298539844178181255951, false)
    }

    fn expand_to_18_decimals(n: u256) -> u256 {
        n * pow(10, 18)
    }
}
