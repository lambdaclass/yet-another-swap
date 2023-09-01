/// Computes the result of a swap within ticks
/// Contains methods for computing the result of a swap within a single tick price range, i.e., a single tick.
mod SwapMath {
    use fractal_swap::numbers::fixed_point::implementations::fullmath::FullMath::{
        div_rounding_up, mul_div, mul_div_rounding_up
    };
    use fractal_swap::numbers::fixed_point::implementations::impl_64x96::{
        FP64x96Impl, FixedType, FixedTrait, FP64x96Add, FP64x96Sub, FP64x96Mul, FP64x96Div,
        FP64x96PartialEq, FP64x96PartialOrd, Q96_RESOLUTION, ONE, MAX
    };
    use fractal_swap::numbers::signed_integer::i256::i256;
    use fractal_swap::libraries::sqrt_price_math::SqrtPriceMath::{
        get_amount_0_delta, get_amount_1_delta, get_next_sqrt_price_from_input,
        get_next_sqrt_price_from_output
    };
    use integer::{u256_overflowing_add, u256_overflow_mul};
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;
    use option::OptionTrait;
    use debug::PrintTrait;

    const _1e6: u256 = 1000000; // 10 ** 6 

    fn compute_swap_step(
        sqrt_ratio_currentX96: FixedType,
        sqrt_ratio_targetX96: FixedType,
        liquidity: u128,
        amount_remaining: i256,
        fee_pips: u32
    ) -> (FixedType, u256, u256, u256) {
        let zero_for_one = sqrt_ratio_currentX96 >= sqrt_ratio_targetX96;
        let exact_in = amount_remaining >= IntegerTrait::<i256>::new(0, false);
        let mut sqrt_ratio_nextX96 = FP64x96Impl::new(1, false);
        let mut amount_in = 0; // TODO: validate
        let mut amount_out = 0; // TODO: validate
        
        if exact_in {
            'exact in'.print();

            // at this point, amount_remaining is positive bc exact_in == true
            let amount_remaining_less_fee = mul_div(i256_into_u256(amount_remaining), _1e6 - fee_pips.into(), _1e6);
            amount_in =
                if zero_for_one {
                    get_amount_0_delta(sqrt_ratio_targetX96, sqrt_ratio_currentX96, liquidity, true)
                } else {
                    get_amount_1_delta(sqrt_ratio_currentX96, sqrt_ratio_targetX96, liquidity, true)
                };

            sqrt_ratio_nextX96 =
                if amount_remaining_less_fee >= amount_in {
                    sqrt_ratio_targetX96
                } else {
                    get_next_sqrt_price_from_input(
                        sqrt_ratio_currentX96, liquidity, amount_remaining_less_fee, zero_for_one
                    )
                };
        } else {
            'not exact in'.print();
            amount_out =
                if zero_for_one {
                    get_amount_1_delta(
                        sqrt_ratio_targetX96, sqrt_ratio_currentX96, liquidity, false
                    )
                } else {
                    get_amount_0_delta(
                        sqrt_ratio_currentX96, sqrt_ratio_targetX96, liquidity, false
                    )
                };

            let amount_remaining_flip_sign = IntegerTrait::<i256>::new(
                amount_remaining.mag, !amount_remaining.sign
            );
            if (amount_remaining_flip_sign >= u256_into_i256(amount_out)) {
                sqrt_ratio_nextX96 = sqrt_ratio_targetX96;
            } else {
                sqrt_ratio_nextX96 =
                    get_next_sqrt_price_from_output(
                        sqrt_ratio_currentX96, liquidity, i256_into_u256(amount_remaining_flip_sign), zero_for_one
                    );
            }
        }

        // 'before max'.print();
        // 'amount_in'.print();
        // amount_in.print();
        // 'amount_out'.print();
        // amount_out.print();
        // 'sqrt_ratio_nextX96'.print();
        // sqrt_ratio_nextX96.mag.print();
        
        let max = sqrt_ratio_targetX96 == sqrt_ratio_nextX96;
        'max'.print();
        max.print();
        // 'sqrt_ratio_targetX96'.print();
        // sqrt_ratio_targetX96.mag.print();

        'sqrt_ratio_nextX96'.print();
        sqrt_ratio_nextX96.mag.print();

        if zero_for_one {
            'zero_for_one T'.print();
            amount_in =
                if max && exact_in {
                    amount_in
                } else {
                    get_amount_0_delta(sqrt_ratio_nextX96, sqrt_ratio_currentX96, liquidity, true)
                };

            amount_out =
                if max && !exact_in {
                    amount_out
                } else {
                    get_amount_1_delta(sqrt_ratio_nextX96, sqrt_ratio_currentX96, liquidity, false)
                };
        } else {
            'zero_for_one F'.print();
            amount_in =
                if max && exact_in {
                    amount_in
                } else {
                    get_amount_1_delta(sqrt_ratio_currentX96, sqrt_ratio_nextX96, liquidity, true)
                };

            amount_out =
                if max && !exact_in {
                    amount_out
                } else {
                    get_amount_0_delta(sqrt_ratio_currentX96, sqrt_ratio_nextX96, liquidity, false) 
                };
        }

        'after max'.print();
        'amount_in'.print();
        amount_in.print();
        'amount_out'.print();
        amount_out.print();

        let amount_remaining_flip_sign = IntegerTrait::<i256>::new(amount_remaining.mag, !amount_remaining.sign);
        if !exact_in && amount_out > i256_into_u256(amount_remaining_flip_sign) {
            amount_out = i256_into_u256(amount_remaining_flip_sign);
        }

        let fee_amount = if exact_in && sqrt_ratio_nextX96 != sqrt_ratio_targetX96 {
            amount_remaining.mag - amount_in
        } else {
            mul_div_rounding_up(amount_in, fee_pips.into(), _1e6 - fee_pips.into())
        };

        // 'fee_amount'.print();
        // fee_amount.print();

        // 'sqrt_ratio_nextX96'.print();
        // sqrt_ratio_nextX96.mag.print();
        (sqrt_ratio_nextX96, amount_in, amount_out, fee_amount)
    }

    // TODO: Migrate this to i256 impl
    fn i256_into_u256(input: i256) -> u256 {
        assert(input.sign == false, 'u256 cannot be negative');
        input.mag
    }

    fn u256_into_i256(input: u256) -> i256 {
        IntegerTrait::<i256>::new(input, false)
    }
}
