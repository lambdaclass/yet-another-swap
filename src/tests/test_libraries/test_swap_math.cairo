mod TestSwapMath {
    use yas::utils::math_utils::pow;
    use yas::numbers::fixed_point::implementations::impl_64x96::{
        FP64x96Impl, FP64x96Div, FixedType, FixedTrait, Q96_RESOLUTION, ONE, MAX
    };

    fn expand_to_18_decimals(n: u256) -> u256 {
        n * pow(10, 18)
    }

    mod ComputeSwapStep {
        use yas::libraries::sqrt_price_math::SqrtPriceMath;
        use yas::libraries::swap_math::SwapMath;
        use yas::numbers::fixed_point::implementations::impl_64x96::{
            FP64x96Impl, FP64x96PartialEq, FP64x96PartialOrd, FP64x96Div, FixedType, FixedTrait,
            Q96_RESOLUTION, ONE, MAX
        };
        use yas::numbers::signed_integer::i256::{i256, i256TryIntou256};
        use yas::tests::test_libraries::test_swap_math::TestSwapMath::expand_to_18_decimals;

        use yas::numbers::signed_integer::integer_trait::IntegerTrait;

        // exact amount in that gets capped at price target in one for zero
        #[test]
        #[available_gas(200000000)]
        fn test_amount_in_gets_capped_at_price_target_in_one_for_zero() {
            // price is the result of encode_price_sqrt(1, 1) on v3-core typescript impl. 
            let price = FP64x96Impl::new(79228162514264337593543950336, false);
            // price_target is the result of encode_price_sqrt(101, 100) on v3-core typescript impl. 
            let price_target = FP64x96Impl::new(79623317895830914510639640423, false);
            let liquidity: u128 = expand_to_18_decimals(2).try_into().unwrap();
            let amount = IntegerTrait::<i256>::new(expand_to_18_decimals(1), false);
            let fee = 600;
            let zero_for_one = false;

            let (sqrtQ, amount_in, amount_out, fee_amount) = SwapMath::compute_swap_step(
                price, price_target, liquidity, amount, fee
            );

            assert(amount_in == 9975124224178055, 'incorrect amount_in');
            assert(fee_amount == 5988667735148, 'incorrect fee_amount');
            assert(amount_out == 9925619580021728, 'incorrect amount_out');
            assert(
                amount_in + fee_amount < amount.try_into().unwrap(), 'entire amount is not used'
            );

            let price_after_whole_input_amount = SqrtPriceMath::get_next_sqrt_price_from_input(
                price, liquidity, amount.try_into().unwrap(), zero_for_one
            );

            assert(sqrtQ == price_target, 'price is capped at price target');
            assert(
                sqrtQ < price_after_whole_input_amount, 'price < price after whole input'
            ); // price is less than price after whole input amount
        }

        // exact amount out that gets capped at price target in one for zero
        #[test]
        #[available_gas(200000000)]
        fn test_amount_out_gets_capped_at_price_target_in_one_for_zero() {
            // price is the result of encode_price_sqrt(1, 1) on v3-core typescript impl. 
            let price = FP64x96Impl::new(79228162514264337593543950336, false);
            // price_target is the result of encode_price_sqrt(101, 100) on v3-core typescript impl. 
            let price_target = FP64x96Impl::new(79623317895830914510639640423, false);
            let liquidity: u128 = expand_to_18_decimals(2).try_into().unwrap();
            let amount = IntegerTrait::<i256>::new(expand_to_18_decimals(1), true);
            let fee = 600;
            let zero_for_one = false;

            let (sqrtQ, amount_in, amount_out, fee_amount) = SwapMath::compute_swap_step(
                price, price_target, liquidity, amount, fee
            );

            assert(amount_in == 9975124224178055, 'incorrect amount_in');
            assert(fee_amount == 5988667735148, 'incorrect fee_amount');
            assert(amount_out == 9925619580021728, 'incorrect amount_out');
            assert(amount_out < expand_to_18_decimals(1), 'entire amount out isnt returned');

            let price_after_whole_input_amount = SqrtPriceMath::get_next_sqrt_price_from_output(
                price, liquidity, expand_to_18_decimals(1), zero_for_one
            );

            assert(sqrtQ == price_target, 'price is capped at price target');
            assert(sqrtQ < price_after_whole_input_amount, 'price < price after whole input');
        }

        // exact amount in that is fully spent in one for zero
        #[test]
        #[available_gas(200000000)]
        fn test_amount_in_that_is_fully_spent_in_one_for_zero() {
            // price is the result of encode_price_sqrt(1, 1) on v3-core typescript impl. 
            let price = FP64x96Impl::new(79228162514264337593543950336, false);
            // price_target is the result of encode_price_sqrt(1000, 100) on v3-core typescript impl. 
            let price_target = FP64x96Impl::new(250541448375047931186413801569, false);

            let liquidity: u128 = expand_to_18_decimals(2).try_into().unwrap();
            let amount = IntegerTrait::<i256>::new(expand_to_18_decimals(1), false);
            let fee = 600;
            let zero_for_one = false;

            let (sqrtQ, amount_in, amount_out, fee_amount) = SwapMath::compute_swap_step(
                price, price_target, liquidity, amount, fee
            );

            assert(amount_in == 999400000000000000, 'incorrect amount_in');
            assert(fee_amount == 600000000000000, 'incorrect fee_amount');
            assert(amount_out == 666399946655997866, 'incorrect amount_out');
            assert(
                amount_in + fee_amount == amount.try_into().unwrap(), 'entire amount is not used'
            );

            let price_after_whole_import_amount_less_fee =
                SqrtPriceMath::get_next_sqrt_price_from_input(
                price, liquidity, amount.try_into().unwrap() - fee_amount, zero_for_one
            );

            assert(sqrtQ < price_target, 'price is capped at price target');
            assert(
                sqrtQ == price_after_whole_import_amount_less_fee, 'price = p_after_amount_less_fee'
            );
        }

        // exact amount out that is fully received in one for zero
        #[test]
        #[available_gas(200000000)]
        fn test_amount_out_that_is_fully_received_in_one_for_zero() {
            // price is the result of encode_price_sqrt(1, 1) on v3-core typescript impl. 
            let price = FP64x96Impl::new(79228162514264337593543950336, false);
            // price_target is the result of encode_price_sqrt(10000, 100) on v3-core typescript impl. 
            let price_target = FP64x96Impl::new(792281625142643375935439503360, false);

            let liquidity: u128 = expand_to_18_decimals(2).try_into().unwrap();
            let amount = IntegerTrait::<i256>::new(expand_to_18_decimals(1), true);
            let fee = 600;
            let zero_for_one = false;

            let (sqrtQ, amount_in, amount_out, fee_amount) = SwapMath::compute_swap_step(
                price, price_target, liquidity, amount, fee
            );

            assert(amount_in == 2000000000000000000, 'incorrect amount_in');
            assert(fee_amount == 1200720432259356, 'incorrect fee_amount');
            assert(amount_out == expand_to_18_decimals(1), 'incorrect amount_out');

            let price_after_whole_output_amount = SqrtPriceMath::get_next_sqrt_price_from_output(
                price, liquidity, expand_to_18_decimals(1), zero_for_one
            );

            assert(sqrtQ < price_target, 'price doest reach price target');
            assert(sqrtQ == price_after_whole_output_amount, 'price = price after whole out');
        }

        // amount out is capped at the desired amount out
        #[test]
        #[available_gas(200000000)]
        fn test_amount_out_is_capped_at_the_desired_amount_out() {
            let price = FP64x96Impl::new(417332158212080721273783715441582, false);
            let price_target = FP64x96Impl::new(1452870262520218020823638996, false);
            let liquidity: u128 = 159344665391607089467575320103;
            let amount = IntegerTrait::<i256>::new(1, true);
            let fee = 1;

            let (sqrtQ, amount_in, amount_out, fee_amount) = SwapMath::compute_swap_step(
                price, price_target, liquidity, amount, fee
            );

            assert(amount_in == 1, 'incorrect amount_in');
            assert(fee_amount == 1, 'incorrect fee_amount');
            assert(amount_out == 1, 'incorrect amount_out'); // would be 2 if not capped
            assert(
                sqrtQ == FP64x96Impl::new(417332158212080721273783715441581, false),
                'incorrect sqrtQ'
            );
        }

        // target price of 1 uses partial input amount
        #[test]
        #[available_gas(200000000)]
        fn test_target_price_of_1_uses_partial_input_amount() {
            let price = FP64x96Impl::new(2, false);
            let price_target = FP64x96Impl::new(1, false);
            let liquidity: u128 = 1;
            let amount = IntegerTrait::<i256>::new(3915081100057732413702495386755767, false);
            let fee = 1;

            let (sqrtQ, amount_in, amount_out, fee_amount) = SwapMath::compute_swap_step(
                price, price_target, liquidity, amount, fee
            );
            assert(amount_in == 39614081257132168796771975168, 'incorrect amount_in');
            assert(fee_amount == 39614120871253040049813, 'incorrect fee_amount');
            assert(
                amount_in + fee_amount <= 3915081100057732413702495386755767,
                'incorrect amount_in+fee_amount'
            );
            assert(amount_out <= 0, 'incorrect amount_out');
            assert(sqrtQ == FP64x96Impl::new(1, false), 'incorrect sqrtQ');
        }

        // entire input amount taken as fee
        #[test]
        #[available_gas(200000000)]
        fn test_entire_input_amount_taken_as_fee() {
            let price = FP64x96Impl::new(2413, false);
            let price_target = FP64x96Impl::new(79887613182836312, false);
            let liquidity: u128 = 1985041575832132834610021537970;
            let amount = IntegerTrait::<i256>::new(10, false);
            let fee = 1872;

            let (sqrtQ, amount_in, amount_out, fee_amount) = SwapMath::compute_swap_step(
                price, price_target, liquidity, amount, fee
            );

            assert(amount_in == 0, 'incorrect amount_in');
            assert(fee_amount == 10, 'incorrect fee_amount');
            assert(amount_out <= 0, 'incorrect amount_out');
            assert(sqrtQ == FP64x96Impl::new(2413, false), 'incorrect sqrtQ');
        }

        // handles intermediate insufficient liquidity in zero for one exact output case
        #[test]
        #[available_gas(200000000)]
        fn test_handles_intermediate_insufficient_liq_in_zero_for_one_exact_output_case() {
            let sqrtP = FP64x96Impl::new(20282409603651670423947251286016, false);
            let sqrtP_target = FP64x96Impl::new(sqrtP.mag * 11 / 10, false);
            let liquidity: u128 = 1024;
            // virtual reserves of one are only 4
            // https://www.wolframalpha.com/input/?i=1024+%2F+%2820282409603651670423947251286016+%2F+2**96%29
            let amount_remaining = IntegerTrait::<i256>::new(4, true);
            let fee_pips = 3000;

            let (sqrtQ, amount_in, amount_out, fee_amount) = SwapMath::compute_swap_step(
                sqrtP, sqrtP_target, liquidity, amount_remaining, fee_pips
            );

            assert(amount_in == 26215, 'incorrect amount_in');
            assert(amount_out == 0, 'incorrect amount_out');
            assert(sqrtQ == sqrtP_target, 'incorrect sqrtQ');
            assert(fee_amount == 79, 'incorrect fee_amount');
        }

        // handles intermediate insufficient liquidity in one for zero exact output case
        #[test]
        #[available_gas(200000000)]
        fn test_handles_intermediate_insufficient_liq_in_zero_for_on_exact_output_case() {
            let sqrtP = FP64x96Impl::new(20282409603651670423947251286016, false);
            let sqrtP_target = FP64x96Impl::new(sqrtP.mag * 9 / 10, false);
            let liquidity: u128 = 1024;
            // virtual reserves of zero are only 262144
            // https://www.wolframalpha.com/input/?i=1024+*+%2820282409603651670423947251286016+%2F+2**96%29
            let amount_remaining = IntegerTrait::<i256>::new(263000, true);
            let fee_pips = 3000;

            let (sqrtQ, amount_in, amount_out, fee_amount) = SwapMath::compute_swap_step(
                sqrtP, sqrtP_target, liquidity, amount_remaining, fee_pips
            );

            assert(amount_in == 1, 'incorrect amount_in');
            assert(fee_amount == 1, 'incorrect fee_amount');
            assert(amount_out == 26214, 'incorrect amount_out');
            assert(sqrtQ == sqrtP_target, 'incorrect sqrtQ');
        }
    }
}
