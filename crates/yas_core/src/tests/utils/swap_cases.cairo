mod SwapTestHelper {

    use yas_core::libraries::tick_math::TickMath::{
        MIN_TICK, MAX_TICK, MIN_SQRT_RATIO, MAX_SQRT_RATIO
    };

    use yas_core::tests::utils::constants::FactoryConstants::{
        tick_spacing, FeeAmount, fee_amount
    };

    use yas_core::numbers::fixed_point::implementations::impl_64x96::{
        FP64x96Impl, FP64x96Sub, FP64x96PartialEq, FixedType, FixedTrait
    };
    
    use yas_core::numbers::signed_integer::{
        i32::i32, i32::i32_div_no_round, i256::i256, integer_trait::IntegerTrait
    };

    use array::ArrayTrait;
    
    use integer::BoundedInt;


    //check this headers
    #[derive(Copy, Drop, Serde)]
    struct SwapTestCase {
        zero_for_one: bool,
        exact_out: bool,
        amount_specified: i256,
        sqrt_price_limit: FixedType,
    }

    #[derive(Drop, Serde)]
    struct PoolTestCase {
        //// description: felt252// ? some are too long to fit
        fee_amount: u32,
        starting_price: FixedType,
        mint_positions: Array<Position>
    }

    #[derive(Copy, Drop, Serde)]
    struct Position {
        tick_lower: i32,
        tick_upper: i32,
        liquidity: u128
    }

    #[derive(Copy, Drop, Serde)]
    struct SwapExpectedResults {
        amount_0_before: u256,
        amount_0_delta: u256,
        amount_1_before: u256,
        amount_1_delta: u256,
        execution_price: u256,
        fee_growth_global_0_X128_delta: u256,
        fee_growth_global_1_X128_delta: u256,
        pool_price_after: u256,
        pool_price_before: u256,
        tick_after: i32,
        tick_before: i32,
    }

    fn get_pool_case(number: u32) -> @PoolTestCase {
        let pools = array![
            PoolTestCase {
                // description: 'low fee, 1:1 price, 2e18 max range liquidity',
                fee_amount: fee_amount(FeeAmount::LOW),
                starting_price: encode_price_sqrt_1_1(),
                mint_positions: array![
                    Position {
                        tick_lower: get_min_tick(FeeAmount::LOW),
                        tick_upper: get_max_tick(FeeAmount::LOW),
                        liquidity: 2000000000000000000,
                    },
                ],
            },
            PoolTestCase {
                // description: 'medium fee, 1:1 price, 2e18 max range liquidity',
                fee_amount: fee_amount(FeeAmount::MEDIUM),
                starting_price: encode_price_sqrt_1_1(),
                mint_positions: array![
                    Position {
                        tick_lower: get_min_tick(FeeAmount::MEDIUM),
                        tick_upper: get_max_tick(FeeAmount::MEDIUM),
                        liquidity: 2000000000000000000,
                    },
                ],
            },
            PoolTestCase {
                // description: 'high fee, 1:1 price, 2e18 max range liquidity',
                fee_amount: fee_amount(FeeAmount::HIGH),
                starting_price: encode_price_sqrt_1_1(),
                mint_positions: array![
                    Position {
                        tick_lower: get_min_tick(FeeAmount::HIGH),
                        tick_upper: get_max_tick(FeeAmount::HIGH),
                        liquidity: 2000000000000000000,
                    },
                ],
            },
            PoolTestCase {
                // description: 'medium fee, 10:1 price, 2e18 max range liquidity',
                fee_amount: fee_amount(FeeAmount::MEDIUM),
                starting_price: encode_price_sqrt_10_1(),
                mint_positions: array![
                    Position {
                        tick_lower: get_min_tick(FeeAmount::MEDIUM),
                        tick_upper: get_max_tick(FeeAmount::MEDIUM),
                        liquidity: 2000000000000000000,
                    },
                ],
            },
            PoolTestCase {
                // description: 'medium fee, 1:10 price, 2e18 max range liquidity',
                fee_amount: fee_amount(FeeAmount::MEDIUM),
                starting_price: encode_price_sqrt_1_10(),
                mint_positions: array![
                    Position {
                        tick_lower: get_min_tick(FeeAmount::MEDIUM),
                        tick_upper: get_max_tick(FeeAmount::MEDIUM),
                        liquidity: 2000000000000000000,
                    },
                ],
            },
            PoolTestCase {
                // description: 'medium fee, 1:1 price, 0 liquidity, all liquidity around current price',
                fee_amount: fee_amount(FeeAmount::MEDIUM),
                starting_price: encode_price_sqrt_1_1(),
                mint_positions: array![
                    Position {
                        tick_lower: get_min_tick(FeeAmount::MEDIUM),
                        tick_upper: IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), true),
                        liquidity: 2000000000000000000,
                    },
                    Position {
                        tick_lower: IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),//tick_spacing(FeeAmount::MEDIUM),
                        tick_upper: get_max_tick(FeeAmount::MEDIUM),
                        liquidity: 2000000000000000000,
                    },
                ],
            },
            PoolTestCase {
                // description: 'medium fee, 1:1 price, additional liquidity around current price',
                fee_amount: fee_amount(FeeAmount::MEDIUM),
                starting_price: encode_price_sqrt_1_1(),
                mint_positions: array![
                    Position {
                        tick_lower: get_min_tick(FeeAmount::MEDIUM),
                        tick_upper: get_max_tick(FeeAmount::MEDIUM),
                        liquidity: 2000000000000000000,
                    },
                    Position {
                        tick_lower: get_min_tick(FeeAmount::MEDIUM),
                        tick_upper: IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), true),//-tick_spacing(FeeAmount::MEDIUM),
                        liquidity: 2000000000000000000,
                    },
                    Position {
                        tick_lower: IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),//tick_spacing(FeeAmount::MEDIUM),
                        tick_upper: get_max_tick(FeeAmount::MEDIUM),
                        liquidity: 2000000000000000000,
                    },
                ],
            },
            PoolTestCase {
                // description: 'low fee, large liquidity around current price (stable swap)',
                fee_amount: fee_amount(FeeAmount::LOW),
                starting_price: encode_price_sqrt_1_1(),
                mint_positions: array![
                    Position {
                        tick_lower: IntegerTrait::<i32>::new(tick_spacing(FeeAmount::LOW), true),//-tick_spacing(FeeAmount::LOW),
                        tick_upper: IntegerTrait::<i32>::new(tick_spacing(FeeAmount::LOW), false),//tick_spacing(FeeAmount::LOW),
                        liquidity: 2000000000000000000,
                    },
                ],
            },
            PoolTestCase {
                // description: 'medium fee, token0 liquidity only',
                fee_amount: fee_amount(FeeAmount::MEDIUM),
                starting_price: encode_price_sqrt_1_1(),
                mint_positions: array![
                    Position {
                        tick_lower: Zeroable::zero(),
                        tick_upper: IntegerTrait::<i32>::new(2000 * tick_spacing(FeeAmount::MEDIUM), false),//2000 * tick_spacing(FeeAmount::MEDIUM),
                        liquidity: 2000000000000000000,
                    },
                ],
            },
            PoolTestCase {
                // description: 'medium fee, token1 liquidity only',
                fee_amount: fee_amount(FeeAmount::MEDIUM),
                starting_price: encode_price_sqrt_1_1(),
                mint_positions: array![
                    Position {
                        tick_lower: IntegerTrait::<i32>::new(2000 * tick_spacing(FeeAmount::MEDIUM), true),//-2000 * tick_spacing(FeeAmount::MEDIUM),
                        tick_upper: Zeroable::zero(),
                        liquidity: 2000000000000000000,
                    },
                ],
            },
            PoolTestCase {
                // description: 'close to max price',
                fee_amount: fee_amount(FeeAmount::MEDIUM),
                starting_price: encode_price_sqrt_2p127_1(),
                mint_positions: array![
                    Position {
                        tick_lower: get_min_tick(FeeAmount::MEDIUM),
                        tick_upper: get_max_tick(FeeAmount::MEDIUM),
                        liquidity: 2000000000000000000,
                    },
                ],
            },
            PoolTestCase {
                // description: 'close to min price',
                fee_amount: fee_amount(FeeAmount::MEDIUM),
                starting_price: encode_price_sqrt_1_2p127(),
                mint_positions: array![
                    Position {
                        tick_lower: get_min_tick(FeeAmount::MEDIUM),
                        tick_upper: get_max_tick(FeeAmount::MEDIUM),
                        liquidity: 2000000000000000000,
                    },
                ],
            },
            PoolTestCase {
                // description: 'max full range liquidity at 1:1 price with default fee',
                fee_amount: fee_amount(FeeAmount::MEDIUM),
                starting_price: encode_price_sqrt_1_1(),
                mint_positions: array![
                    Position {
                        tick_lower: get_min_tick(FeeAmount::MEDIUM),
                        tick_upper: get_max_tick(FeeAmount::MEDIUM),
                        liquidity: tick_spacing_to_max_liquidity_per_tick(IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false)),
                    },
                ],
            },
            PoolTestCase {
                // description: 'initialized at the max ratio',
                fee_amount: fee_amount(FeeAmount::MEDIUM),
                starting_price: FP64x96Impl::new(MAX_SQRT_RATIO - 1, false),
                mint_positions: array![
                    Position {
                        tick_lower: get_min_tick(FeeAmount::MEDIUM),
                        tick_upper: get_max_tick(FeeAmount::MEDIUM),
                        liquidity: 2000000000000000000,
                    }
                ]
            },
            PoolTestCase {
                // description: 'initialized at the min ratio',
                fee_amount: fee_amount(FeeAmount::MEDIUM),
                starting_price: FP64x96Impl::new(MIN_SQRT_RATIO, false),
                mint_positions: array![
                    Position {
                        tick_lower: get_min_tick(FeeAmount::MEDIUM),
                        tick_upper: get_max_tick(FeeAmount::MEDIUM),
                        liquidity: 2000000000000000000,
                    },
                ],
            },
        ];

        //ret:    
        pools[number]
    }

    fn get_swap_case(number: u32) -> SwapTestCase {
        let swaps = array![
            SwapTestCase {
                zero_for_one: true,
                exact_out: false,
                amount_specified: IntegerTrait::<i256>::new(1000000000000000000, false),
                sqrt_price_limit: FP64x96Impl::new(0, false)
            },
            SwapTestCase {
                zero_for_one: false,
                exact_out: false,
                amount_specified: IntegerTrait::<i256>::new(1000000000000000000, false),
                sqrt_price_limit: FP64x96Impl::new(0, false)
            },
            SwapTestCase {
                zero_for_one: true,
                exact_out: true,
                amount_specified: IntegerTrait::<i256>::new(1000000000000000000, false),
                sqrt_price_limit: FP64x96Impl::new(0, false)
            },
            SwapTestCase {
                zero_for_one: false,
                exact_out: true,
                amount_specified: IntegerTrait::<i256>::new(1000000000000000000, false),
                sqrt_price_limit: FP64x96Impl::new(0, false)
            },
            // swap large amounts in/out with a price limit
            SwapTestCase {
                zero_for_one: true,
                exact_out: false,
                amount_specified: IntegerTrait::<i256>::new(1000000000000000000, false),
                sqrt_price_limit: encode_price_sqrt_50_100(),
            },
            SwapTestCase {
                zero_for_one: false,
                exact_out: false,
                amount_specified: IntegerTrait::<i256>::new(1000000000000000000, false),
                sqrt_price_limit: encode_price_sqrt_200_100(),
            },
            SwapTestCase {
                zero_for_one: true,
                exact_out: true,
                amount_specified: IntegerTrait::<i256>::new(1000000000000000000, false),
                sqrt_price_limit: encode_price_sqrt_50_100(),
            },
            SwapTestCase {
                zero_for_one: false,
                exact_out: true,
                amount_specified: IntegerTrait::<i256>::new(1000000000000000000, false),
                sqrt_price_limit: encode_price_sqrt_200_100(),
            },
            // swap small amounts in/out
            SwapTestCase {
                zero_for_one: true,
                exact_out: false,
                amount_specified: IntegerTrait::<i256>::new(1000, false),
                sqrt_price_limit: FP64x96Impl::new(0, false)
            },
            SwapTestCase {
                zero_for_one: false,
                exact_out: false,
                amount_specified: IntegerTrait::<i256>::new(1000, false),
                sqrt_price_limit: FP64x96Impl::new(0, false)
            },
            SwapTestCase {
                zero_for_one: true,
                exact_out: true,
                amount_specified: IntegerTrait::<i256>::new(1000, false),
                sqrt_price_limit: FP64x96Impl::new(0, false)
            },
            SwapTestCase {
                zero_for_one: false,
                exact_out: true,
                amount_specified: IntegerTrait::<i256>::new(1000, false),
                sqrt_price_limit: FP64x96Impl::new(0, false)
            },
            // swap arbitrary input to price
            SwapTestCase {
                exact_out: false, // non specified
                amount_specified: Zeroable::zero(), // non specified
                sqrt_price_limit: encode_price_sqrt_5_2(),
                zero_for_one: false,
            },
            SwapTestCase {
                exact_out: false, // non specified
                amount_specified: Zeroable::zero(), // non specified
                sqrt_price_limit: encode_price_sqrt_2_5(),
                zero_for_one: true,
            },
            SwapTestCase {
                exact_out: false, // non specified
                amount_specified: Zeroable::zero(), // non specified
                sqrt_price_limit: encode_price_sqrt_5_2(),
                zero_for_one: true,
            },
            SwapTestCase {
                exact_out: false, // non specified
                amount_specified: Zeroable::zero(), // non specified
                sqrt_price_limit: encode_price_sqrt_2_5(),
                zero_for_one: false,
            }
        ];

        //ret
        *swaps[number]
    }

    fn get_expected(number: u32) -> SwapExpectedResults {
    let expected = array![];
    *expected[number]
    }


    //Helper Functions:

    // sqrt_price_X96 is the result of encode_price_sqrt_50_100() on v3-core typescript impl. 
    fn encode_price_sqrt_50_100() -> FixedType {
        FP64x96Impl::new(56022770974786139918731938227, false)
    }
        
    // sqrt_price_X96 is the result of encode_price_sqrt_200_100() on v3-core typescript impl. 
    fn encode_price_sqrt_200_100() -> FixedType {
        FP64x96Impl::new(112045541949572279837463876454, false)
    }

    // sqrt_price_X96 is the result of encode_price_sqrt_5_2() on v3-core typescript impl. 
    fn encode_price_sqrt_5_2() -> FixedType {
        FP64x96Impl::new(125270724187523965593206900784, false)
    }

    // sqrt_price_X96 is the result of encode_price_sqrt_2_5() on v3-core typescript impl. 
    fn encode_price_sqrt_2_5() -> FixedType {
        FP64x96Impl::new(50108289675009586237282760313, false)
    }

    // returns result of encode_price_sqrt_1_1() on v3-core typescript impl. 
    fn encode_price_sqrt_1_1() -> FixedType {
        FP64x96Impl::new(79228162514264337593543950336, false)
    }

    // returns result of encode_price_sqrt_1_10() on v3-core typescript impl. 
    fn encode_price_sqrt_1_10() -> FixedType {
        FP64x96Impl::new(25054144837504793118641380156, false)
    }

    // returns result of encode_price_sqrt_10_1() on v3-core typescript impl. 
    fn encode_price_sqrt_10_1() -> FixedType {
        FP64x96Impl::new(250541448375047931186413801569, false)
    }

    // returns result of encode_price_sqrt(2**127, 1) on v3-core typescript impl. 
    fn encode_price_sqrt_2p127_1() -> FixedType {
        FP64x96Impl::new(1033437718471923706666374484006904511252097097914, false)
    }

    // returns result of encode_price_sqrt(1, 2**127) on v3-core typescript impl. 
    fn encode_price_sqrt_1_2p127() -> FixedType {
        FP64x96Impl::new(6085630636, false)
    }

    fn get_min_tick(amount: FeeAmount) -> i32 {
        let tick_spacing = IntegerTrait::<i32>::new(tick_spacing(amount), false);
        i32_div_no_round(MIN_TICK(), tick_spacing) * tick_spacing
    }

    fn get_max_tick(amount: FeeAmount) -> i32 {
        let tick_spacing = IntegerTrait::<i32>::new(tick_spacing(amount), false);
        i32_div_no_round(MAX_TICK(), tick_spacing) * tick_spacing
    }

    /// @notice Derives max liquidity per tick from given tick spacing
    /// @dev Executed within the pool constructor
    /// @param tick_spacing The amount of required tick separation, realized in multiples of `tick_spacing`
    ///     e.g., a tick_spacing of 3 requires ticks to be initialized every 3rd tick i.e., ..., -6, -3, 0, 3, 6, ...
    /// @return The max liquidity per tick
    fn tick_spacing_to_max_liquidity_per_tick(tick_spacing: i32) -> u128 {
        let MIN_TICK = IntegerTrait::<i32>::new(887272, true);
        let MAX_TICK = IntegerTrait::<i32>::new(887272, false);

        let min_tick = i32_div_no_round(MIN_TICK, tick_spacing) * tick_spacing;
        let max_tick = i32_div_no_round(MAX_TICK, tick_spacing) * tick_spacing;
        let num_ticks = i32_div_no_round((max_tick - min_tick), tick_spacing)
            + IntegerTrait::<i32>::new(1, false);

        let max_u128: u128 = BoundedInt::max();
        max_u128 / num_ticks.try_into().expect('num ticks cannot be negative!')
    }
}