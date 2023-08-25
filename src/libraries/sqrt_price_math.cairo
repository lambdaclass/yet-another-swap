// Functions based on Q64.96 sqrt price and liquidity
// Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
mod SqrtPriceMath {
    use fractal_swap::numbers::fixed_point::implementations::fullmath::FullMath::{
        div_rounding_up, mul_div, mul_div_rounding_up
    };
    use fractal_swap::numbers::fixed_point::implementations::impl_64x96::{
        FP64x96Impl, FixedType, FixedTrait, FP64x96Add, FP64x96Sub, FP64x96Mul, FP64x96Div,
        FP64x96PartialEq, FP64x96PartialOrd, Q96_RESOLUTION, ONE, MAX
    };
    use orion::numbers::signed_integer::i128::{i128};
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;

    use fractal_swap::utils::math_utils::MathUtils::{pow};
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use debug::PrintTrait;

    /// @notice Gets the next sqrt price given a delta of token0
    /// @dev Always rounds up, because in the exact output case (increasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (decreasing price) we need to move the
    /// price less in order to not send too much output.
    /// The most precise formula for this is liquidity * sqrtPX96 / (liquidity +- amount * sqrtPX96),
    /// if this is impossible because of overflow, we calculate liquidity / (liquidity / sqrtPX96 +- amount).
    /// @param sqrtPX96 The starting price, i.e. before accounting for the token0 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token0 to add or remove from virtual reserves
    /// @param add Whether to add or remove the amount of token0
    /// @return The price after adding or removing amount, depending on add
    fn get_next_sqrt_price_from_amount0_rounding_up(
        sqrtPX96: FixedType, liquidity: u128, amount: u256, add: bool
    ) -> FixedType {
        if amount == 0 {
            return sqrtPX96;
        }
        let numerator = liquidity.into() * pow(2, Q96_RESOLUTION.into());
        let product: u256 = amount * sqrtPX96.mag;
        'amount'.print();
        amount.print();
        'sqrtPX96.mag'.print();
        sqrtPX96.mag.print();
        'product'.print();
        product.print();

        let am = product;
        'product / amount'.print();
        am.print();

        if add {
            if product / amount == sqrtPX96.mag {
                let denominator = numerator + product;
                if denominator >= numerator {
                    'fits on 160'.print();
                    return FP64x96Impl::new(
                        mul_div_rounding_up(numerator, sqrtPX96.mag, denominator), false
                    );
                }
            }
            'product causes overflow'.print();
            return FP64x96Impl::new(
                div_rounding_up(numerator, (numerator / sqrtPX96.mag) + amount), false
            );
        } else {
            assert(
                FP64x96Impl::new(product / amount, false) == sqrtPX96 && numerator > product, '!'
            );
            let denominator = numerator - product;
            return FP64x96Impl::new(
                mul_div_rounding_up(numerator, sqrtPX96.mag, denominator), false
            );
        }
    }

    /// @notice Gets the next sqrt price given a delta of token1
    /// @dev Always rounds down, because in the exact output case (decreasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (increasing price) we need to move the
    /// price less in order to not send too much output.
    /// The formula we compute is within <1 wei of the lossless version: sqrtPX96 +- amount / liquidity
    /// @param sqrtPX96 The starting price, i.e., before accounting for the token1 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token1 to add, or remove, from virtual reserves
    /// @param add Whether to add, or remove, the amount of token1
    /// @return The price after adding or removing `amount`
    fn get_next_sqrt_price_from_amount1_rounding_down(
        sqrtPX96: FixedType, liquidity: u128, amount: u256, add: bool
    ) -> FixedType {
        // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
        // in both cases, avoid a mulDiv for most inputs
        // TODO: check FP::new() signs
        if add {
            let mut quotient = if amount <= MAX {
                amount * pow(2, Q96_RESOLUTION.into()) / liquidity.into()
            } else {
                mul_div(amount, ONE, liquidity.into())
            };
            return (sqrtPX96 + FP64x96Impl::new(quotient, false));
        } else {
            let mut quotient = if amount <= MAX {
                div_rounding_up(amount * pow(2, Q96_RESOLUTION.into()), liquidity.into())
            } else {
                mul_div_rounding_up(amount, ONE, liquidity.into())
            };
            assert(sqrtPX96 > FP64x96Impl::new(quotient, false), 'sqrtPX96_fp < quotient');
            return (sqrtPX96 - FP64x96Impl::new(quotient, false));
        }
    }

    /// @notice Gets the next sqrt price given an input amount of token0 or token1
    /// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
    /// @param sqrtPX96 The starting price, i.e., before accounting for the input amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountIn How much of token0, or token1, is being swapped in
    /// @param zeroForOne Whether the amount in is token0 or token1
    /// @return sqrtQX96 The price after adding the input amount to token0 or token1
    fn get_next_sqrt_price_from_input(
        sqrtPX96: FixedType, liquidity: u128, amount_in: u256, zero_for_one: bool
    ) -> FixedType {
        assert(sqrtPX96.sign == false && liquidity > 0, '!');
        if zero_for_one {
            return get_next_sqrt_price_from_amount0_rounding_up(
                sqrtPX96, liquidity, amount_in, true
            );
        } else {
            return get_next_sqrt_price_from_amount1_rounding_down(
                sqrtPX96, liquidity, amount_in, true
            );
        }
    }

    /// @notice Gets the next sqrt price given an output amount of token0 or token1
    /// @dev Throws if price or liquidity are 0 or the next price is out of bounds
    /// @param sqrtPX96 The starting price before accounting for the output amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountOut How much of token0, or token1, is being swapped out
    /// @param zeroForOne Whether the amount out is token0 or token1
    /// @return sqrtQX96 The price after removing the output amount of token0 or token1
    fn get_next_sqrt_price_from_output(
        sqrtPX96: FixedType, liquidity: u128, amount_out: u256, zero_for_one: bool
    ) -> FixedType {
        assert(sqrtPX96.sign == false && liquidity > 0, 'sqrtPX96 & liquidity must be >0');

        if zero_for_one {
            return get_next_sqrt_price_from_amount1_rounding_down(
                sqrtPX96, liquidity, amount_out, false
            );
        } else {
            return get_next_sqrt_price_from_amount0_rounding_up(
                sqrtPX96, liquidity, amount_out, false
            );
        }
    }

    /// @notice Gets the amount0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
    fn get_amount_0_delta(
        sqrt_ratio_AX96: FixedType, sqrt_ratio_BX96: FixedType, liquidity: u128, round_up: bool
    ) -> u256 {
        let mut sqrt_ratio_AX96_1 = sqrt_ratio_AX96;
        let mut sqrt_ratio_BX96_1 = sqrt_ratio_BX96;

        if sqrt_ratio_AX96 > sqrt_ratio_BX96 {
            sqrt_ratio_AX96_1 = sqrt_ratio_BX96;
            sqrt_ratio_BX96_1 = sqrt_ratio_AX96;
        }

        let numerator1 = FP64x96Impl::new(liquidity.into() * pow(2, Q96_RESOLUTION.into()), false);
        let numerator2 = sqrt_ratio_BX96_1 - sqrt_ratio_AX96_1;
        assert(sqrt_ratio_AX96_1.sign == false, 'sqrt_ratio_AX96 cannot be neg');

        if round_up {
            return div_rounding_up(
                mul_div_rounding_up(numerator1.mag, numerator2.mag, sqrt_ratio_BX96_1.mag),
                sqrt_ratio_AX96_1.mag
            );
        } else {
            return mul_div(numerator1.mag, numerator2.mag, sqrt_ratio_BX96_1.mag)
                / sqrt_ratio_AX96_1.mag;
        }
    }

    /// @notice Gets the amount1 delta between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up, or down
    /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
    fn get_amount_1_delta(
        sqrt_ratio_AX96: FixedType, sqrt_ratio_BX96: FixedType, liquidity: u128, round_up: bool
    ) -> u256 {
        let mut sqrt_ratio_AX96_1 = sqrt_ratio_AX96;
        let mut sqrt_ratio_BX96_1 = sqrt_ratio_BX96;

        if sqrt_ratio_AX96 > sqrt_ratio_BX96 {
            sqrt_ratio_AX96_1 = sqrt_ratio_BX96;
            sqrt_ratio_BX96_1 = sqrt_ratio_AX96;
        }

        let liquidity_fp = FP64x96Impl::from_felt(liquidity.into());

        if round_up {
            return mul_div_rounding_up(
                liquidity.into(), (sqrt_ratio_BX96_1 - sqrt_ratio_AX96_1).mag, ONE
            );
        } else {
            // FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
            return mul_div(liquidity.into(), (sqrt_ratio_BX96_1 - sqrt_ratio_AX96_1).mag, ONE);
        }
    }
// TODO: block by i256 PR
// fn get_amount_0_delta_signed_token(sqrt_ratio_AX96: FixedType, sqrt_ratio_BX96: FixedType, liquidity: i128) -> i256 {
//     if liquidity < IntegerTrait::<i128>::new(0, false) {
//         return FP64x96Impl::new(get_amount_0_delta(sqrt_ratio_AX96, sqrt_ratio_BX96, liquidity.abs().mag, false), true);
//     } else {
//         return FP64x96Impl::new(get_amount_0_delta(sqrt_ratio_AX96, sqrt_ratio_BX96, liquidity.mag, true), false);
//     } 
// }

// // TODO: this should return i256
// fn get_amount_1_delta_signed_token(sqrt_ratio_AX96: FixedType, sqrt_ratio_BX96: FixedType, liquidity: i128) -> i256 {
//     if liquidity < IntegerTrait::<i128>::new(0, false) {
//         return FP64x96Impl::new(get_amount_1_delta(sqrt_ratio_AX96, sqrt_ratio_BX96, liquidity.abs().mag, false), true);
//     } else {
//         return FP64x96Impl::new(get_amount_1_delta(sqrt_ratio_AX96, sqrt_ratio_BX96, liquidity.mag, true), false);
//     } 
// }
}
