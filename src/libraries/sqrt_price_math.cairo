// Functions based on Q64.96 sqrt price and liquidity
// Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
mod SqrtPriceMath {
    use integer::{u256_overflowing_add, u256_overflow_mul};

    use yas::numbers::fixed_point::implementations::impl_64x96::{
        FP64x96Impl, FixedType, FixedTrait, FP64x96Add, FP64x96Sub, FP64x96Mul, FP64x96Div,
        FP64x96PartialEq, FP64x96PartialOrd, Q96_RESOLUTION, ONE, MAX
    };
    use yas::numbers::signed_integer::i256::i256;
    use yas::numbers::signed_integer::{i128::i128, integer_trait::IntegerTrait};
    use yas::utils::math_utils::{FullMath::{div_rounding_up, mul_div, mul_div_rounding_up}, pow};

    /// Returns the next square root price given a token0 delta.
    /// @param sqrtPX96 The initial price (prior to considering the token0 delta).
    /// @param liquidity The quantity of available liquidity.
    /// @param amount The quantity of token0 to be added or removed from virtual reserves.
    /// @param add Indicates whether to add or subtract the token0 amount.
    /// @return The resulting price after adding or removing the amount, based on the 'add' parameter.
    fn get_next_sqrt_price_from_amount0_rounding_up(
        sqrtPX96: FixedType, liquidity: u128, amount: u256, add: bool
    ) -> FixedType {
        if amount == 0 {
            return sqrtPX96;
        }
        assert(sqrtPX96.sign == false, 'sqrtPX96 cannot be negative');

        let numerator = liquidity.into() * pow(2, Q96_RESOLUTION.into());
        let (product, product_has_overflow) = u256_overflow_mul(amount, sqrtPX96.mag);

        if add {
            if !product_has_overflow && product / amount == sqrtPX96.mag {
                let (denominator, denominator_has_overflow) = u256_overflowing_add(
                    numerator, product
                );
                if !denominator_has_overflow && denominator >= numerator {
                    return FP64x96Impl::new(
                        mul_div_rounding_up(numerator, sqrtPX96.mag, denominator), false
                    );
                }
            }
            FP64x96Impl::new(div_rounding_up(numerator, (numerator / sqrtPX96.mag) + amount), false)
        } else {
            // if the product overflows, we know the denominator underflows
            // in addition, we must check that the denominator does not underflow
            assert(FP64x96Impl::new(product / amount, false) == sqrtPX96, 'product overflow');
            assert(numerator > product, 'denominator underflow');
            let denominator = numerator - product;
            FP64x96Impl::new(mul_div_rounding_up(numerator, sqrtPX96.mag, denominator), false)
        }
    }

    /// Returns the next square root price given a token1 delta.
    /// @param sqrtPX96 The initial price (prior to considering the token1 delta).
    /// @param liquidity The quantity of available liquidity.
    /// @param amount The quantity of token1 to be added or removed from virtual reserves.
    /// @param add Indicates whether to add or subtract the token1 amount.
    /// @return The resulting price after adding or removing the `amount`, based on the 'add' parameter.
    fn get_next_sqrt_price_from_amount1_rounding_down(
        sqrtPX96: FixedType, liquidity: u128, amount: u256, add: bool
    ) -> FixedType {
        assert(sqrtPX96.sign == false, 'sqrtPX96 cannot be negative');

        // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
        // in both cases, avoid a mulDiv for most inputs
        if add {
            let mut quotient = if amount <= MAX {
                amount * pow(2, Q96_RESOLUTION.into()) / liquidity.into()
            } else {
                mul_div(amount, ONE, liquidity.into())
            };
            (sqrtPX96 + FP64x96Impl::new(quotient, false))
        } else {
            let mut quotient = if amount <= MAX {
                div_rounding_up(amount * pow(2, Q96_RESOLUTION.into()), liquidity.into())
            } else {
                mul_div_rounding_up(amount, ONE, liquidity.into())
            };
            assert(sqrtPX96 > FP64x96Impl::new(quotient, false), 'sqrtPX96_fp < quotient');
            (sqrtPX96 - FP64x96Impl::new(quotient, false))
        }
    }

    /// Returns the next square root price given an input amount of token0 or token1.
    /// @dev Throws if the price or liquidity is 0, or if the next price is out of bounds.
    /// @param sqrtPX96 The starting price, i.e., before accounting for the input amount.
    /// @param liquidity The amount of usable liquidity.
    /// @param amountIn How much of token0 or token1 is being swapped in.
    /// @param zeroForOne Indicates whether the amount in is token0 or token1.
    /// @return sqrtQX96 The price after adding the input amount to token0 or token1.
    fn get_next_sqrt_price_from_input(
        sqrtPX96: FixedType, liquidity: u128, amount_in: u256, zero_for_one: bool
    ) -> FixedType {
        assert(sqrtPX96.sign == false && liquidity > 0, 'sqrtPX96 & liquidity must be >0');
        if zero_for_one {
            get_next_sqrt_price_from_amount0_rounding_up(sqrtPX96, liquidity, amount_in, true)
        } else {
            get_next_sqrt_price_from_amount1_rounding_down(sqrtPX96, liquidity, amount_in, true)
        }
    }

    /// Returns the next square root price given an output amount of token0 or token1.
    /// @dev Throws if the price or liquidity is 0, or if the next price is out of bounds.
    /// @param sqrtPX96 The starting price before accounting for the output amount.
    /// @param liquidity The amount of usable liquidity.
    /// @param amountOut How much of token0 or token1 is being swapped out.
    /// @param zeroForOne Indicates whether the amount out is token0 or token1.
    /// @return sqrtQX96 The price after removing the output amount of token0 or token1.
    fn get_next_sqrt_price_from_output(
        sqrtPX96: FixedType, liquidity: u128, amount_out: u256, zero_for_one: bool
    ) -> FixedType {
        assert(sqrtPX96.sign == false && liquidity > 0, 'sqrtPX96 & liquidity must be >0');

        if zero_for_one {
            get_next_sqrt_price_from_amount1_rounding_down(sqrtPX96, liquidity, amount_out, false)
        } else {
            get_next_sqrt_price_from_amount0_rounding_up(sqrtPX96, liquidity, amount_out, false)
        }
    }

    /// Returns the amount0 delta between two prices.
    /// @dev Calculates `liquidity / sqrt(lower) - liquidity / sqrt(upper)`,
    /// i.e., `liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))`.
    /// @param sqrtRatioAX96 A sqrt price.
    /// @param sqrtRatioBX96 Another sqrt price.
    /// @param liquidity The amount of usable liquidity.
    /// @param roundUp Indicates whether to round the amount up or down.
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices.
    fn get_amount_0_delta(
        sqrt_ratio_AX96: FixedType, sqrt_ratio_BX96: FixedType, liquidity: u128, round_up: bool
    ) -> u256 {
        let (sqrt_ratio_AX96_1, sqrt_ratio_BX96_1) = if sqrt_ratio_AX96 > sqrt_ratio_BX96 {
            (sqrt_ratio_BX96, sqrt_ratio_AX96)
        } else {
            (sqrt_ratio_AX96, sqrt_ratio_BX96)
        };

        let numerator1 = liquidity.into() * pow(2, Q96_RESOLUTION.into());
        let numerator2 = sqrt_ratio_BX96_1 - sqrt_ratio_AX96_1;
        assert(sqrt_ratio_AX96_1.sign == false, 'sqrt_ratio_AX96 cannot be neg');

        if round_up {
            div_rounding_up(
                mul_div_rounding_up(numerator1, numerator2.mag, sqrt_ratio_BX96_1.mag),
                sqrt_ratio_AX96_1.mag
            )
        } else {
            mul_div(numerator1, numerator2.mag, sqrt_ratio_BX96_1.mag) / sqrt_ratio_AX96_1.mag
        }
    }

    /// Returns the amount1 delta between two prices.
    /// @dev Calculates `liquidity * (sqrt(upper) - sqrt(lower))`.
    /// @param sqrtRatioAX96 A sqrt price.
    /// @param sqrtRatioBX96 Another sqrt price.
    /// @param liquidity The amount of usable liquidity.
    /// @param roundUp Indicates whether to round the amount up or down.
    /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices.
    fn get_amount_1_delta(
        sqrt_ratio_AX96: FixedType, sqrt_ratio_BX96: FixedType, liquidity: u128, round_up: bool
    ) -> u256 {
        let (sqrt_ratio_AX96_1, sqrt_ratio_BX96_1) = if sqrt_ratio_AX96 > sqrt_ratio_BX96 {
            (sqrt_ratio_BX96, sqrt_ratio_AX96)
        } else {
            (sqrt_ratio_AX96, sqrt_ratio_BX96)
        };

        if round_up {
            mul_div_rounding_up(liquidity.into(), (sqrt_ratio_BX96_1 - sqrt_ratio_AX96_1).mag, ONE)
        } else {
            mul_div(liquidity.into(), (sqrt_ratio_BX96_1 - sqrt_ratio_AX96_1).mag, ONE)
        }
    }

    fn get_amount_0_delta_signed_token(
        sqrt_ratio_AX96: FixedType, sqrt_ratio_BX96: FixedType, liquidity: i128
    ) -> i256 {
        if liquidity < IntegerTrait::<i128>::new(0, false) {
            IntegerTrait::<i256>::new(
                get_amount_0_delta(sqrt_ratio_AX96, sqrt_ratio_BX96, liquidity.abs().mag, false),
                true
            )
        } else {
            IntegerTrait::<i256>::new(
                get_amount_0_delta(sqrt_ratio_AX96, sqrt_ratio_BX96, liquidity.mag, true), false
            )
        }
    }

    fn get_amount_1_delta_signed_token(
        sqrt_ratio_AX96: FixedType, sqrt_ratio_BX96: FixedType, liquidity: i128
    ) -> i256 {
        if liquidity < IntegerTrait::<i128>::new(0, false) {
            IntegerTrait::<i256>::new(
                get_amount_1_delta(sqrt_ratio_AX96, sqrt_ratio_BX96, liquidity.abs().mag, false),
                true
            )
        } else {
            IntegerTrait::<i256>::new(
                get_amount_1_delta(sqrt_ratio_AX96, sqrt_ratio_BX96, liquidity.mag, true), false
            )
        }
    }
}
