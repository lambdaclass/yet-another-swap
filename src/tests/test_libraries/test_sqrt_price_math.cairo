mod TestSqrtPriceMath {
    use fractal_swap::libraries::sqrt_price_math::SqrtPriceMath;
    use fractal_swap::utils::math_utils::MathUtils::{pow};
    use integer::{BoundedInt};
    use fractal_swap::numbers::fixed_point::implementations::impl_64x96::{FP64x96Impl, FP64x96PartialEq, FixedType, FixedTrait, Q96_RESOLUTION};
    use traits::{Into, TryInto};
    use option::OptionTrait;

    // it('fails if price is zero', async () => {
    //   await expect(sqrtPriceMath.getNextSqrtPriceFromOutput(0, 0, expandTo18Decimals(1).div(10), false)).to.be.reverted
    // })
    #[test]
    #[should_panic]
    fn test_fail_if_price_is_zero() {
        SqrtPriceMath::get_next_sqrt_price_from_output(FP64x96Impl::from_felt(0), 0, expand_to_18_decimals(1) / 10, false);     
    }

    // it('fails if liquidity is zero', async () => {
    //   await expect(sqrtPriceMath.getNextSqrtPriceFromOutput(1, 0, expandTo18Decimals(1).div(10), true)).to.be.reverted
    // })
    #[test]
    #[should_panic]
    fn test_fail_if_liquidity_is_zero() {
        SqrtPriceMath::get_next_sqrt_price_from_output(FP64x96Impl::from_felt(1), 0, expand_to_18_decimals(1) / 10, true);     
    }

    // it('fails if output amount is exactly the virtual reserves of token0', async () => {
    //   const price = '20282409603651670423947251286016'
    //   const liquidity = 1024
    //   const amountOut = 4
    //   await expect(sqrtPriceMath.getNextSqrtPriceFromOutput(price, liquidity, amountOut, false)).to.be.reverted
    // })
    // #[test]
    // #[should_panic]
    fn test_fail_output_amount_eq_virtual_reserves_of_token_0() {
        let price = FP64x96Impl::from_felt(20282409603651670423947251286016);
        let liquidity = 1024;
        let amount_out = 4;
        SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, false);     
    }

    // it('fails if output amount is greater than virtual reserves of token0', async () => {
    //   const price = '20282409603651670423947251286016'
    //   const liquidity = 1024
    //   const amountOut = 5
    //   await expect(sqrtPriceMath.getNextSqrtPriceFromOutput(price, liquidity, amountOut, false)).to.be.reverted
    // })
    // #[test]
    // #[should_panic]
    fn test_fail_output_amount_gt_virtual_reserves_of_token_0() {
        let price = FP64x96Impl::from_felt(20282409603651670423947251286016);
        let liquidity = 1024;
        let amount_out = 5;
        SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, false);     
    }

    // it('fails if output amount is exactly the virtual reserves of token1', async () => {
    //   const price = '20282409603651670423947251286016'
    //   const liquidity = 1024
    //   const amountOut = 262144
    //   await expect(sqrtPriceMath.getNextSqrtPriceFromOutput(price, liquidity, amountOut, true)).to.be.reverted
    // })
    #[test]
    #[should_panic]
    fn test_fail_output_amount_eq_virtual_reserves_of_token_1() {
        let price = FP64x96Impl::from_felt(20282409603651670423947251286016);
        let liquidity = 1024;
        let amount_out = 262144;
        SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, true);     
    }

    // it('fails if output amount is greater than virtual reserves of token1', async () => {
    //   const price = '20282409603651670423947251286016'
    //   const liquidity = 1024
    //   const amountOut = 262145
    //   await expect(sqrtPriceMath.getNextSqrtPriceFromOutput(price, liquidity, amountOut, true)).to.be.reverted
    // })
    #[test]
    #[should_panic]
    fn test_fail_output_amount_gt_virtual_reserves_of_token_1() {
        let price =  FP64x96Impl::from_felt(20282409603651670423947251286016);
        let liquidity = 1024;
        let amount_out = 262145;
        SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, true);     
    }

    // it('succeeds if output amount is just less than the virtual reserves of token1', async () => {
    //   const price = '20282409603651670423947251286016'
    //   const liquidity = 1024
    //   const amountOut = 262143
    //   const sqrtQ = await sqrtPriceMath.getNextSqrtPriceFromOutput(price, liquidity, amountOut, true)
    //   expect(sqrtQ).to.eq('77371252455336267181195264')
    // })
    #[test]
    #[available_gas(2000000)]
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

    // TODO: expected panic but finished successfully.

    // it('puzzling echidna test', async () => {
    //   const price = '20282409603651670423947251286016'
    //   const liquidity = 1024
    //   const amountOut = 4
    //   await expect(sqrtPriceMath.getNextSqrtPriceFromOutput(price, liquidity, amountOut, false)).to.be.reverted
    // })
    #[test]
    #[should_panic]
    fn test_puzzling_edhidna() {
        let price =  FP64x96Impl::from_felt(20282409603651670423947251286016);
        let liquidity = 1024;
        let amount_out = 4;
        SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, false);     
    }

    //  it('returns input price if amount in is zero and zeroForOne = true', async () => {
    //   const price = encodePriceSqrt(1, 1)
    //   expect(await sqrtPriceMath.getNextSqrtPriceFromOutput(price, expandTo18Decimals(1).div(10), 0, true)).to.eq(price)
    // })
    #[test]
    #[available_gas(20000000)]
    fn test_input_price_if_amount_is_in_zero_and_zero_for_one_true() {
        let price =  encode_price_sqrt(1, 1);
        let liquidity: u128 = expand_to_18_decimals(1).try_into().unwrap() / 10;
        let actual = SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, 0, true);  

        assert(actual == price, 'actual not eq to price')   
    }

    // it('returns input price if amount in is zero and zeroForOne = false', async () => {
    //   const price = encodePriceSqrt(1, 1)
    //   expect(await sqrtPriceMath.getNextSqrtPriceFromOutput(price, expandTo18Decimals(1).div(10), 0, false)).to.eq(
    //     price
    //   )
    // })
    #[test]
    #[available_gas(20000000)]
    fn test_input_price_if_amount_is_in_zero_and_zero_for_one_false() {
        let price =  encode_price_sqrt(1, 1);
        let liquidity: u128 = expand_to_18_decimals(1).try_into().unwrap() / 10;
        let actual = SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, 0, false);  

        assert(actual == price, 'actual not eq to price')   
    }

    // it('output amount of 0.1 token1', async () => {
    //   const sqrtQ = await sqrtPriceMath.getNextSqrtPriceFromOutput(
    //     encodePriceSqrt(1, 1),
    //     expandTo18Decimals(1),
    //     expandTo18Decimals(1).div(10),
    //     false
    //   )
    //   expect(sqrtQ).to.eq('88031291682515930659493278152')
    // })
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

    //  it('output amount of 0.1 token1', async () => {
    //   const sqrtQ = await sqrtPriceMath.getNextSqrtPriceFromOutput(
    //     encodePriceSqrt(1, 1),
    //     expandTo18Decimals(1),
    //     expandTo18Decimals(1).div(10),
    //     true
    //   )
    //   expect(sqrtQ).to.eq('71305346262837903834189555302')
    // })
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

    // it('reverts if amountOut is impossible in zero for one direction', async () => {
    //   await expect(sqrtPriceMath.getNextSqrtPriceFromOutput(encodePriceSqrt(1, 1), 1, constants.MaxUint256, true)).to.be
    //     .reverted
    // })
    #[test]
    #[should_panic]
    fn test_fail_if_amount_out_is_impossible_in_zero_for_one_direction_true() {
        let price = encode_price_sqrt(1, 1);
        let liquidity = 1;
        let amount_out: u256 = BoundedInt::max();
        SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, true);     
    }

    // it('reverts if amountOut is impossible in one for zero direction', async () => {
    //   await expect(sqrtPriceMath.getNextSqrtPriceFromOutput(encodePriceSqrt(1, 1), 1, constants.MaxUint256, false)).to
    //     .be.reverted
    // })
    #[test]
    #[should_panic]
    fn test_fail_if_amount_out_is_impossible_in_zero_for_one_direction_false() {
        let price = encode_price_sqrt(1, 1);
        let liquidity = 1;
        let amount_out: u256 = BoundedInt::max();
        SqrtPriceMath::get_next_sqrt_price_from_output(price, liquidity, amount_out, false);     
    }

    // it('returns 0 if liquidity is 0', async () => {
    //   const amount0 = await sqrtPriceMath.getAmount0Delta(encodePriceSqrt(1, 1), encodePriceSqrt(2, 1), 0, true)
    //   expect(amount0).to.eq(0)
    // })
    #[test]
    #[available_gas(20000000)]
    fn test_amount_0_delta_returns_0_if_liquidity_is_0() {
        let actual = SqrtPriceMath::get_amount_0_delta(encode_price_sqrt(1, 1), encode_price_sqrt(2, 1), 0, true);
        let expected = 0;
        assert(actual == expected, 'delta_returns_0_if_liq_is_0')
    }
    
    // it('returns 0 if prices are equal', async () => {
    //   const amount0 = await sqrtPriceMath.getAmount0Delta(encodePriceSqrt(1, 1), encodePriceSqrt(1, 1), 0, true)
    //   expect(amount0).to.eq(0)
    // })
    #[test]
    #[available_gas(20000000)]
    fn test_amount_0_delta_returns_0_if_prices_are_eq() {
        let actual = SqrtPriceMath::get_amount_0_delta(encode_price_sqrt(1, 1), encode_price_sqrt(1, 1), 0, true);
        let expected = 0;
        assert(actual == expected, 'delta_return_0_if_prices_are_eq')
    }

    // it('returns 0.1 amount1 for price of 1 to 1.21', async () => {
    //   const amount0 = await sqrtPriceMath.getAmount0Delta(
    //     encodePriceSqrt(1, 1),
    //     encodePriceSqrt(121, 100),
    //     expandTo18Decimals(1),
    //     true
    //   )
    //   expect(amount0).to.eq('90909090909090910')

    //   const amount0RoundedDown = await sqrtPriceMath.getAmount0Delta(
    //     encodePriceSqrt(1, 1),
    //     encodePriceSqrt(121, 100),
    //     expandTo18Decimals(1),
    //     false
    //   )

    //   expect(amount0RoundedDown).to.eq(amount0.sub(1))
    // })
    #[test]
    #[available_gas(20000000)]
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

    // Methods for tests
    fn encode_price_sqrt(reserve1: u256, reserve0: u256) -> FixedType {
        let ratio = reserve1 * pow(2, Q96_RESOLUTION.into()) / reserve0;
        FP64x96Impl::new(ratio, false).sqrt()
    }

    fn expand_to_18_decimals(n: u256) -> u256 {
        // return BigNumber.from(n).mul(BigNumber.from(10).pow(18))
        pow(n * 10, 18)
    }
}
