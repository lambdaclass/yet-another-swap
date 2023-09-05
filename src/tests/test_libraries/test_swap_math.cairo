mod TestSwapMath {
    use fractal_swap::utils::math_utils::MathUtils::pow;
    use fractal_swap::numbers::fixed_point::implementations::impl_64x96::{
        FP64x96Impl, FP64x96Div, FixedType, FixedTrait, Q96_RESOLUTION, ONE, MAX
    };
    use traits::Into;
    use integer::{u256_sqrt, u256_safe_div_rem, u256_try_as_non_zero};
    use debug::PrintTrait;

    // Aux methods for tests
    fn encode_price_sqrt(reserve1: u256, reserve0: u256) -> FixedType {
        let reserve1X96U256 = reserve1 * pow(2, 96);
        let reserve0X96U256 = reserve0 * pow(2, 96);

        let mul_res = integer::u256_wide_mul(reserve1X96U256, ONE);
        let b_inv = MAX / reserve0X96U256;
        let res_div_u256 = u256 { high: mul_res.limb1, low: mul_res.limb0 } / reserve0X96U256
            + u256 { high: mul_res.limb3, low: mul_res.limb2 } * b_inv;

        let root = integer::u256_sqrt(res_div_u256);
        let scale_root = integer::u256_sqrt(ONE);
        let res_u256 = root.into() * ONE / scale_root.into();

        FP64x96Impl::new(res_u256, false)
    }

    fn expand_to_18_decimals(n: u256) -> u256 {
        n * pow(10, 18)
    }

    mod ComputeSwapStep {
        use fractal_swap::libraries::sqrt_price_math::SqrtPriceMath;
        use fractal_swap::libraries::swap_math::SwapMath;
        use fractal_swap::numbers::fixed_point::implementations::impl_64x96::{
            FP64x96Impl, FP64x96PartialEq, FP64x96PartialOrd, FP64x96Div, FixedType, FixedTrait,
            Q96_RESOLUTION, ONE, MAX
        };
        use fractal_swap::numbers::signed_integer::i256::i256;
        use fractal_swap::tests::test_libraries::test_swap_math::TestSwapMath::{
            encode_price_sqrt, expand_to_18_decimals
        };
        use orion::numbers::signed_integer::integer_trait::IntegerTrait;

        use debug::PrintTrait;

        // exact amount in that gets capped at price target in one for zero
        #[test]
        #[available_gas(200000000)]
        fn test_amount_in_gets_capped_at_price_target_in_one_for_zero() {
            let price = encode_price_sqrt(1, 1);
            let price_target = encode_price_sqrt(101, 100);
            let liquidity: u128 = expand_to_18_decimals(2).try_into().unwrap();
            let amount = IntegerTrait::<i256>::new(expand_to_18_decimals(1), false);
            let fee = 600;
            let zero_for_one = false;

            let (sqrtQ, amount_in, amount_out, fee_amount) = SwapMath::compute_swap_step(
                price, price_target, liquidity, amount, fee
            );

            // TODO: Check outputs 
            // [.sol]
            // sqrtRatioNextX96: 79623317895830914510639640423 
            // amount_in: 9975124224178055, 
            // amount_out: 9925619580021728 
            // fee_amount: 5988667735148    
            // [.cairo]
            // sqrt_ratio_nextX96 79623317895830855645443129344
            // amount_in 9975124224176569 
            // amount_out 9925619580020257
            // fee_amount 5988667735148 

            assert(amount_in == 9975124224176569, 'incorrect amount_in');
            assert(fee_amount == 5988667735148, 'incorrect fee_amount');
            assert(amount_out == 9925619580020257, 'incorrect amount_out');
            assert(
                amount_in + fee_amount < SwapMath::i256_into_u256(amount),
                'entire amount is not used'
            );

            let price_after_whole_input_amount = SqrtPriceMath::get_next_sqrt_price_from_input(
                price, liquidity, SwapMath::i256_into_u256(amount), zero_for_one
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
            let price = encode_price_sqrt(1, 1);
            let price_target = encode_price_sqrt(101, 100);
            let liquidity: u128 = expand_to_18_decimals(2).try_into().unwrap();
            let amount = IntegerTrait::<i256>::new(expand_to_18_decimals(1), true);
            let fee = 600;
            let zero_for_one = false;

            let (sqrtQ, amount_in, amount_out, fee_amount) = SwapMath::compute_swap_step(
                price, price_target, liquidity, amount, fee
            );

            //     // TODO: Check outputs 
            //     // [.sol]
            //     // sqrtRatioNextX96: 79623317895830914510639640423 
            //     // amount_in: 9975124224178055, 
            //     // amount_out: 9925619580021728 
            //     // fee_amount: 5988667735148    
            //     // [.cairo]
            //     // sqrt_ratio_nextX96 79623317895830855645443129344
            //     // amount_in 9975124224176569 
            //     // amount_out 9925619580020257
            //     // fee_amount 5988667735148 

            assert(amount_in == 9975124224176569, 'incorrect amount_in');
            assert(fee_amount == 5988667735148, 'incorrect fee_amount');
            assert(amount_out == 9925619580020257, 'incorrect amount_out');
            assert(amount_out < expand_to_18_decimals(1), 'entire amount out isnt returned');

            let price_after_whole_input_amount = SqrtPriceMath::get_next_sqrt_price_from_output(
                price, liquidity, expand_to_18_decimals(1), zero_for_one
            );

            assert(sqrtQ == price_target, 'price is capped at price target');
            assert(
                sqrtQ < price_after_whole_input_amount, 'price < price after whole input'
            ); // price is less than price after whole input amount
        }

        // exact amount in that is fully spent in one for zero
        #[test]
        #[available_gas(200000000)]
        fn test_amount_in_that_is_fully_spent_in_one_for_zero() {
            let price = encode_price_sqrt(1, 1);
            let price_target = encode_price_sqrt(1000, 100);
            let liquidity: u128 = expand_to_18_decimals(2).try_into().unwrap();
            let amount = IntegerTrait::<i256>::new(expand_to_18_decimals(1), false);
            let fee = 600;
            let zero_for_one = false;

            let (sqrtQ, amount_in, amount_out, fee_amount) = SwapMath::compute_swap_step(
                price, price_target, liquidity, amount, fee
            );

            // TODO: Check outputs (in this case .cairo == .sol)
            // [.sol]
            // sqrtRatioNextX96: 118818475322642227089037862318 
            // amount_in: 999400000000000000, 
            // amount_out: 666399946655997866 
            // fee_amount: 600000000000000    
            // [.cairo]
            // sqrt_ratio_nextX96 118818475322642227089037862318
            // amount_in 999400000000000000 
            // amount_out 666399946655997866
            // fee_amount 600000000000000 

            assert(amount_in == 999400000000000000, 'incorrect amount_in');
            assert(fee_amount == 600000000000000, 'incorrect fee_amount');
            assert(amount_out == 666399946655997866, 'incorrect amount_out');
            assert(
                amount_in + fee_amount == SwapMath::i256_into_u256(amount),
                'entire amount is not used'
            );

            let price_after_whole_import_amount_less_fee =
                SqrtPriceMath::get_next_sqrt_price_from_input(
                price, liquidity, SwapMath::i256_into_u256(amount) - fee_amount, zero_for_one
            );

            assert(sqrtQ < price_target, 'price is capped at price target');
            assert(
                sqrtQ == price_after_whole_import_amount_less_fee, 'price = p_after_amount_less_fee'
            ); // price is less than price after whole input amount
        }

        // exact amount out that is fully received in one for zero
        #[test]
        #[available_gas(200000000)]
        fn test_amount_out_that_is_fully_received_in_one_for_zero() {
            let price = encode_price_sqrt(1, 1);
            let price_target = encode_price_sqrt(10000, 100);
            let liquidity: u128 = expand_to_18_decimals(2).try_into().unwrap();
            let amount = IntegerTrait::<i256>::new(expand_to_18_decimals(1), true);
            let fee = 600;
            let zero_for_one = false;

            let (sqrtQ, amount_in, amount_out, fee_amount) = SwapMath::compute_swap_step(
                price, price_target, liquidity, amount, fee
            );

            // TODO: Check outputs (in this case .cairo == .sol)
            // [.sol]
            // sqrtRatioNextX96: 158456325028528675187087900672 
            // amount_in: 2000000000000000000, 
            // amount_out: 1000000000000000000 
            // fee_amount: 1200720432259356    
            // [.cairo]
            // sqrt_ratio_nextX96 158456325028528675187087900672
            // amount_in 2000000000000000000 
            // amount_out 1000000000000000000
            // fee_amount 1200720432259356 

            assert(amount_in == 2000000000000000000, 'incorrect amount_in');
            assert(fee_amount == 1200720432259356, 'incorrect fee_amount');
            assert(amount_out == expand_to_18_decimals(1), 'incorrect amount_out');

            let price_after_whole_output_amount = SqrtPriceMath::get_next_sqrt_price_from_output(
                price, liquidity, expand_to_18_decimals(1), zero_for_one
            );

            assert(sqrtQ < price_target, 'price doest reach price target');
            assert(
                sqrtQ == price_after_whole_output_amount, 'price = price after whole input'
            ); // price is less than price after whole input amount
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
            // TODO: Check outputs (in this case .cairo == .sol)
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

            // TODO: Check outputs (in this case .cairo == .sol)
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
            let amount_remaining = IntegerTrait::<i256>::new(4, true);
            let fee_pips = 3000;

            let (sqrtQ, amount_in, amount_out, fee_amount) = SwapMath::compute_swap_step(
                sqrtP, sqrtP_target, liquidity, amount_remaining, fee_pips
            );

            // TODO: Check outputs
            'fee_amount//'.print();
            fee_amount.print();
            // [.sol]
            // fee_amount: 10 
            // [.cairo]
            // fee_amount: 79 
            assert(amount_in == 26215, 'incorrect amount_in');
            assert(amount_out == 0, 'incorrect amount_out');
            assert(sqrtQ == sqrtP_target, 'incorrect sqrtQ');
        // assert(fee_amount == 10, 'incorrect fee_amount');
        }

        // handles intermediate insufficient liquidity in one for zero exact output case
        #[test]
        #[available_gas(200000000)]
        fn test_handles_intermediate_insufficient_liq_in_zero_for_on_exact_output_case() {
            let sqrtP = FP64x96Impl::new(20282409603651670423947251286016, false);
            let sqrtP_target = FP64x96Impl::new(sqrtP.mag * 9 / 10, false);
            let liquidity: u128 = 1024;
            let amount_remaining = IntegerTrait::<i256>::new(263000, true);
            let fee_pips = 3000;

            let (sqrtQ, amount_in, amount_out, fee_amount) = SwapMath::compute_swap_step(
                sqrtP, sqrtP_target, liquidity, amount_remaining, fee_pips
            );

            // TODO: Check outputs (in this case .cairo == .sol)
            assert(amount_in == 1, 'incorrect amount_in');
            assert(fee_amount == 1, 'incorrect fee_amount');
            assert(amount_out == 26214, 'incorrect amount_out');
            assert(sqrtQ == sqrtP_target, 'incorrect sqrtQ');
        }
    }
}
