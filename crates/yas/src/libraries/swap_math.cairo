/// Computes the result of a swap within ticks
/// Contains methods for computing the result of a swap within a single tick price range, i.e., a single tick.
mod SwapMath {
    use yas::utils::math_utils::FullMath::{div_rounding_up, mul_div, mul_div_rounding_up};
    use yas::numbers::fixed_point::implementations::impl_64x96::{
        FP64x96Impl, FixedType, FixedTrait, FP64x96Add, FP64x96Sub, FP64x96Mul, FP64x96Div,
        FP64x96PartialEq, FP64x96PartialOrd, Q96_RESOLUTION, ONE, MAX
    };
    use yas::numbers::signed_integer::i256::i256;
    use yas::libraries::sqrt_price_math::SqrtPriceMath::{
        get_amount_0_delta, get_amount_1_delta, get_next_sqrt_price_from_input,
        get_next_sqrt_price_from_output
    };
    use integer::{u256_overflowing_add, u256_overflow_mul};
    use yas::numbers::signed_integer::integer_trait::IntegerTrait;

    const _1e6: u256 = 1000000; // 10 ** 6 

    /// Computes the result of swapping some amount in, or amount out, given the parameters of the swap
    /// @param sqrt_ratio_currentX96 The current sqrt price of the pool
    /// @param sqrt_ratio_targetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
    /// @param liquidity The usable liquidity
    /// @param amount_remaining How much input or output amount is remaining to be swapped in/out
    /// @param fee_pips The fee taken from the input amount, expressed in hundredths of a bip
    /// @return sqrt_ratio_nextX96 The price after swapping the amount in/out, not to exceed the price target
    /// @return amount_in The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    /// @return amount_out The amount to be received, of either token0 or token1, based on the direction of the swap
    /// @return fee_amount The amount of input that will be taken as a fee
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
        let mut amount_in = 0;
        let mut amount_out = 0;

        if exact_in {
            // at this point, amount_remaining is positive bc exact_in == true
            let amount_remaining_less_fee = mul_div(
                amount_remaining.mag, _1e6 - fee_pips.into(), _1e6
            );
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

            sqrt_ratio_nextX96 =
                if amount_remaining.mag >= amount_out {
                    sqrt_ratio_targetX96
                } else {
                    get_next_sqrt_price_from_output(
                        sqrt_ratio_currentX96, liquidity, amount_remaining.mag, zero_for_one
                    )
                };
        }

        let max = sqrt_ratio_targetX96 == sqrt_ratio_nextX96;

        if zero_for_one {
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

        if !exact_in && amount_out > amount_remaining.mag {
            amount_out = amount_remaining.mag;
        }

        let fee_amount = if exact_in && sqrt_ratio_nextX96 != sqrt_ratio_targetX96 {
            amount_remaining.mag - amount_in
        } else {
            mul_div_rounding_up(amount_in, fee_pips.into(), _1e6 - fee_pips.into())
        };

        (sqrt_ratio_nextX96, amount_in, amount_out, fee_amount)
    }
}
