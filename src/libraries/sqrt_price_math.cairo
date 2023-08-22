// Functions based on Q64.96 sqrt price and liquidity
// Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
mod SqrtPriceMath {
    use fractal_swap::numbers::fixed_point::implementations::impl_64x96::{
        FP64x96Impl, FixedType, FixedTrait, FP64x96Add, FP64x96Sub, FP64x96Mul, FP64x96Div, FP64x96PartialEq,
        FP64x96PartialOrd, Q96_RESOLUTION, ONE, MAX
    };
    use fractal_swap::utils::math_utils::MathUtils::{BitShiftTrait};
    use traits::{Into, TryInto};
    use option::OptionTrait;

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
        sqrtPX96: u256, liquidity: u128, amount: u256, add: bool
    ) -> u256 {
        if amount == 0 {
            return sqrtPX96;
        }

        // TODO: remove unwrap
        let sqrtPX96_fp = FP64x96Impl::from_felt(sqrtPX96.try_into().unwrap());
        let amount_fp = FP64x96Impl::from_felt(amount.try_into().unwrap());
        let mut mutable_liquidity = liquidity;
        let numerator_fp = FP64x96Impl::from_felt(mutable_liquidity.shl(Q96_RESOLUTION).into());
        let product = amount_fp * sqrtPX96_fp;

        if add {
            if product / amount_fp == sqrtPX96_fp {
                let denominator = numerator_fp + product;
                if denominator >= numerator_fp {
                    // return uint160(FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator));
                    // mulDivRoundingUp = ceil(a×b÷denominator)
                    return (numerator_fp * sqrtPX96_fp / denominator).ceil().mag;
                }
            // return uint160(UnsafeMath.divRoundingUp(numerator1, (numerator1 / sqrtPX96).add(amount)));
            // divRoundingUp =  ceil(x / y)
            }
            return (numerator_fp / ((numerator_fp / sqrtPX96_fp) + amount_fp).ceil()).mag;
        } else {
            // require((product = amount * sqrtPX96) / amount == sqrtPX96 && numerator1 > product);
            assert(product / amount_fp == sqrtPX96_fp && numerator_fp > product, '!');
            let denominator = numerator_fp - product;
            // return FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator).toUint160();
            return (numerator_fp * sqrtPX96_fp / denominator).ceil().mag;
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
        sqrtPX96: u256, liquidity: u128, amount: u256, add: bool
    ) -> u256 {
        // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
        // in both cases, avoid a mulDiv for most inputs
        // TODO: Fix shift mutable error
        // TODO: remove unwrap()
        let amount_fp = FP64x96Impl::from_felt(amount.try_into().unwrap());
        let mut mutable_amount = amount;
        let shifted_amount = mutable_amount.shl(Q96_RESOLUTION.into());
        let liquidity_fp = FP64x96Impl::from_felt(liquidity.into());
        let sqrtPX96_fp = FP64x96Impl::from_felt(sqrtPX96.try_into().unwrap());

        if add {
            let mut quotient = if amount <= MAX {
                // TODO: remove unwrap()
                FP64x96Impl::from_felt((shifted_amount.try_into().unwrap() / liquidity).into())
            } else {
                // floor(a×b÷denominator)
                (amount_fp * FP64x96Impl::from_felt(ONE.try_into().unwrap()) / liquidity_fp).floor()
            };
            return (sqrtPX96_fp + quotient).mag;
        } else {
            let mut quotient = if amount <= MAX {
                (FP64x96Impl::from_felt(shifted_amount.try_into().unwrap()) / liquidity_fp).ceil()
            // ceil(x / y) 
            } else {
                // ceil(a×b÷denominator)
                (amount_fp * FP64x96Impl::from_felt(ONE.try_into().unwrap()) / liquidity_fp).ceil()
            };
            return (sqrtPX96_fp - quotient).mag;
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
        sqrtPX96: u256, liquidity: u128, amount_in: u256, zero_for_one: bool
    ) -> u256 {
        assert(sqrtPX96 > 0 && liquidity > 0, '!');
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
        sqrtPX96: u256, liquidity: u128, amount_out: u256, zero_for_one: bool
    ) -> u256 {
        assert(sqrtPX96 > 0 && liquidity > 0, '!');

        if zero_for_one {
            return get_next_sqrt_price_from_amount1_rounding_down(
                sqrtPX96, liquidity, amount_out, true
            );
        } else {
            return get_next_sqrt_price_from_amount0_rounding_up(
                sqrtPX96, liquidity, amount_out, true
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
        sqrt_ratio_AX96: u256, sqrt_ratio_BX96: u256, liquidity: u128, round_up: bool
    ) -> u256 {
        // TODO: Search for an alternative to declare a variable without assignment? btw its safe
        let mut sqrt_ratio_AX96_fp = FP64x96Impl::from_felt(1);
        let mut sqrt_ratio_BX96_fp = FP64x96Impl::from_felt(1);

        if sqrt_ratio_AX96 > sqrt_ratio_BX96 {
            sqrt_ratio_AX96_fp = FP64x96Impl::from_felt(sqrt_ratio_BX96.try_into().unwrap());
            sqrt_ratio_BX96_fp = FP64x96Impl::from_felt(sqrt_ratio_AX96.try_into().unwrap());
        } else {
            sqrt_ratio_AX96_fp = FP64x96Impl::from_felt(sqrt_ratio_AX96.try_into().unwrap());
            sqrt_ratio_BX96_fp = FP64x96Impl::from_felt(sqrt_ratio_BX96.try_into().unwrap());
        }

        let mut mutable_liquidity = liquidity;
        let numerator1_fp = FP64x96Impl::from_felt(
            mutable_liquidity.shl(Q96_RESOLUTION.into()).into()
        );
        let numerator2_fp = sqrt_ratio_BX96_fp - sqrt_ratio_AX96_fp;

        assert(sqrt_ratio_AX96_fp.sign == false, '!');

        if round_up {
            // divRoundingUp(mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96), sqrtRatioAX96)
            // divRoundingUp =  ceil(x / y)
            // mulDivRoundingUp = ceil(a×b÷denominator)
            return ((numerator1_fp * numerator2_fp / sqrt_ratio_BX96_fp).ceil()
                / sqrt_ratio_AX96_fp)
                .ceil()
                .mag;
        } else {
            // return mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
            // muldiv = floor(a×b÷denominator)
            return (numerator1_fp * numerator2_fp / sqrt_ratio_BX96_fp).floor().mag;
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
        sqrt_ratio_AX96: u256, sqrt_ratio_BX96: u256, liquidity: u128, round_up: bool
    ) -> u256 {
        // TODO: Search for an alternative to declare a variable without assignment? 
        let mut sqrt_ratio_AX96_fp = FP64x96Impl::from_felt(1);
        let mut sqrt_ratio_BX96_fp = FP64x96Impl::from_felt(1);

        if sqrt_ratio_AX96 > sqrt_ratio_BX96 {
            sqrt_ratio_AX96_fp = FP64x96Impl::from_felt(sqrt_ratio_BX96.try_into().unwrap());
            sqrt_ratio_BX96_fp = FP64x96Impl::from_felt(sqrt_ratio_AX96.try_into().unwrap());
        } else {
            sqrt_ratio_AX96_fp = FP64x96Impl::from_felt(sqrt_ratio_AX96.try_into().unwrap());
            sqrt_ratio_BX96_fp = FP64x96Impl::from_felt(sqrt_ratio_BX96.try_into().unwrap());
        }

        let liquidity_fp = FP64x96Impl::from_felt(liquidity.into());

        if round_up {
            // mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96)
            // mulDivRoundingUp = ceil(a×b÷denominator)
            return (liquidity_fp * (sqrt_ratio_BX96_fp - sqrt_ratio_AX96_fp) / FP64x96Impl::from_felt(ONE.try_into().unwrap())).ceil().mag;
        } else {
            // FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
            // floor(a×b÷denominator)
            return (liquidity_fp * (sqrt_ratio_BX96_fp - sqrt_ratio_AX96_fp) / FP64x96Impl::from_felt(ONE.try_into().unwrap())).floor().mag;
        }
    }  

    /// @notice Helper that gets signed token0 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount0 delta
    /// @return amount0 Amount of token0 corresponding to the passed liquidityDelta between the two prices
    // fn get_amount_0_delta_wo_round(sqrt_ratio_AX96: u256, sqrt_ratio_BX96: u256, liquidity: u128) -> FixedType {
    //     if liquidity < 0 {
    //         return FP64x96Impl::from_felt(-get_amount_0_delta(sqrt_ratio_AX96, sqrt_ratio_BX96, -liquidity, false).try_into().unwrap());
    //     } else {
    //         return FP64x96Impl::from_felt(get_amount_0_delta(sqrt_ratio_AX96, sqrt_ratio_BX96, liquidity, true).try_into().unwrap());
    //     } 
    // }

    /// @notice Helper that gets signed token1 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount1 delta
    /// @return amount1 Amount of token1 corresponding to the passed liquidityDelta between the two prices
    // function getAmount1Delta(
    //     uint160 sqrtRatioAX96,
    //     uint160 sqrtRatioBX96,
    //     int128 liquidity
    // ) internal pure returns (int256 amount1) {
    //     return
    //         liquidity < 0
    //             ? -getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
    //             : getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
    // }
    //     fn get_amount_1_delta_wo_round(sqrt_ratio_AX96: u256, sqrt_ratio_BX96: u256, liquidity: u128) -> FixedType {
    //     if liquidity < 0 {
    //         return FP64x96Impl::from_felt(-get_amount_1_delta(sqrt_ratio_AX96, sqrt_ratio_BX96, -liquidity, false).try_into().unwrap());
    //     } else {
    //         return FP64x96Impl::from_felt(get_amount_1_delta(sqrt_ratio_AX96, sqrt_ratio_BX96, liquidity, true).try_into().unwrap());
    //     } 
    // }
}
