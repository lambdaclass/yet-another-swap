mod TickTests {
    use starknet::syscalls::deploy_syscall;
    use fractal_swap::utils::math_utils::MathUtils::pow;
    use fractal_swap::libraries::tick::{Tick, ITick, ITickDispatcher, ITickDispatcherTrait};
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;
    use orion::numbers::signed_integer::i32::i32;
    use fractal_swap::utils::orion_utils::OrionUtils::i32TryIntou128;


    use traits::{Into, TryInto};
    use option::Option;

    fn deploy() -> ITickDispatcher {
        let calldata: Array<felt252> = ArrayTrait::new();
        let (address, _) = deploy_syscall(
            Tick::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), true
        )
            .expect('DEPLOY_FAILED');
        return (ITickDispatcher { contract_address: address });
    }

    fn get_max_liquidity_per_tick(tick_spacing: i32) -> u128 {
        let denominator: u128 = ((get_max_tick(tick_spacing) - get_min_tick(tick_spacing))
            / tick_spacing
            + IntegerTrait::<i32>::new(1, false))
            .try_into()
            .unwrap();
        let numerator: u256 = (pow(2, 128) - 1);
        let result: u128 = (numerator / denominator.into()).try_into().unwrap();
        result
    }

    fn get_min_tick(tick_spacing: i32) -> i32 {
        (IntegerTrait::<i32>::new(887272, true) / tick_spacing) * tick_spacing
    }

    fn get_max_tick(tick_spacing: i32) -> i32 {
        (IntegerTrait::<i32>::new(887272, false) / tick_spacing) * tick_spacing
    }

    mod TickSpacingToMaxLiquidityPerTick {
        use super::{deploy, get_max_liquidity_per_tick};
        use integer::BoundedInt;

        use fractal_swap::libraries::tick::{
            Info, Tick, ITick, ITickDispatcher, ITickDispatcherTrait
        };

        use orion::numbers::signed_integer::i32::i32;
        use orion::numbers::signed_integer::i64::i64;
        use orion::numbers::signed_integer::i128::i128;
        use orion::numbers::signed_integer::integer_trait::IntegerTrait;

        // returns the correct value for low fee
        #[test]
        #[available_gas(30000000)]
        fn test_low_fee_returns_correct_value() {
            let tick = deploy();

            let tick_id = IntegerTrait::<i32>::new(2, false);
            tick
                .set_tick(
                    tick_id,
                    Info {
                        fee_growth_outside_0X128: 1,
                        fee_growth_outside_1X128: 2,
                        liquidity_gross: 3,
                        liquidity_net: IntegerTrait::<i128>::new(4, false),
                        seconds_per_liquidity_outside_X128: 5,
                        tick_cumulative_outside: IntegerTrait::<i64>::new(6, false),
                        seconds_outside: 7,
                        initialized: true
                    }
                );

            let tick_spacing_low_fee = IntegerTrait::<i32>::new(10, false);
            let result = tick.tick_spacing_to_max_liquidity_per_tick(tick_spacing_low_fee);

            assert(result == 1917569901783203986719870431555990, '110.8 bits');
            assert(result == get_max_liquidity_per_tick(tick_spacing_low_fee), '110.8 bits');
        }

        // returns the correct value for medium fee
        #[test]
        #[available_gas(30000000)]
        fn test_medium_fee_returns_correct_value() {
            let tick = deploy();

            let tick_id = IntegerTrait::<i32>::new(2, false);
            tick
                .set_tick(
                    tick_id,
                    Info {
                        fee_growth_outside_0X128: 1,
                        fee_growth_outside_1X128: 2,
                        liquidity_gross: 3,
                        liquidity_net: IntegerTrait::<i128>::new(4, false),
                        seconds_per_liquidity_outside_X128: 5,
                        tick_cumulative_outside: IntegerTrait::<i64>::new(6, false),
                        seconds_outside: 7,
                        initialized: true
                    }
                );

            let tick_spacing_medium_fee = IntegerTrait::<i32>::new(60, false);
            let result = tick.tick_spacing_to_max_liquidity_per_tick(tick_spacing_medium_fee);

            // TODO: Check results
            // .cai 11505354575363080317263139282924270
            // .sol 11505743598341114571880798222544994
            assert(result == 11505743598341114571880798222544994, '113.1 bits');
            assert(result == get_max_liquidity_per_tick(tick_spacing_medium_fee), '113.1 bits');
        }

        // returns the correct value for high fee
        #[test]
        #[available_gas(30000000)]
        fn test_high_fee_returns_correct_value() {
            let tick = deploy();

            let tick_id = IntegerTrait::<i32>::new(2, false);
            tick
                .set_tick(
                    tick_id,
                    Info {
                        fee_growth_outside_0X128: 1,
                        fee_growth_outside_1X128: 2,
                        liquidity_gross: 3,
                        liquidity_net: IntegerTrait::<i128>::new(4, false),
                        seconds_per_liquidity_outside_X128: 5,
                        tick_cumulative_outside: IntegerTrait::<i64>::new(6, false),
                        seconds_outside: 7,
                        initialized: true
                    }
                );

            let tick_spacing_high_fee = IntegerTrait::<i32>::new(200, false);
            let result = tick.tick_spacing_to_max_liquidity_per_tick(tick_spacing_high_fee);

            assert(result == 38350317471085141830651933667504588, '114.7 bits');
            assert(result == get_max_liquidity_per_tick(tick_spacing_high_fee), '114.7 bits');
        }

        // returns the correct value for entire range
        #[test]
        #[available_gas(30000000)]
        fn test_returns_correct_value_for_entire_range() {
            let tick = deploy();

            let tick_id = IntegerTrait::<i32>::new(2, false);
            tick
                .set_tick(
                    tick_id,
                    Info {
                        fee_growth_outside_0X128: 1,
                        fee_growth_outside_1X128: 2,
                        liquidity_gross: 3,
                        liquidity_net: IntegerTrait::<i128>::new(4, false),
                        seconds_per_liquidity_outside_X128: 5,
                        tick_cumulative_outside: IntegerTrait::<i64>::new(6, false),
                        seconds_outside: 7,
                        initialized: true
                    }
                );

            let tick_spacing_high_fee = IntegerTrait::<i32>::new(887272, false);
            let expected: u128 = BoundedInt::max() / 3;
            let result = tick.tick_spacing_to_max_liquidity_per_tick(tick_spacing_high_fee);

            assert(result == expected, '126 bits');
            assert(
                result == get_max_liquidity_per_tick(IntegerTrait::<i32>::new(887272, false)),
                '126 bits'
            );
        }

        // returns the correct value for 2302
        #[test]
        #[available_gas(30000000)]
        fn test_returns_correct_value_for_2302() {
            let tick = deploy();

            let tick_id = IntegerTrait::<i32>::new(2, false);
            tick
                .set_tick(
                    tick_id,
                    Info {
                        fee_growth_outside_0X128: 1,
                        fee_growth_outside_1X128: 2,
                        liquidity_gross: 3,
                        liquidity_net: IntegerTrait::<i128>::new(4, false),
                        seconds_per_liquidity_outside_X128: 5,
                        tick_cumulative_outside: IntegerTrait::<i64>::new(6, false),
                        seconds_outside: 7,
                        initialized: true
                    }
                );

            let tick_spacing_high_fee = IntegerTrait::<i32>::new(2302, false);
            let result = tick
                .tick_spacing_to_max_liquidity_per_tick(IntegerTrait::<i32>::new(2302, false));

            assert(result == 441351967472034323558203122479595605, ' 118 bits');
            assert(
                result == get_max_liquidity_per_tick(IntegerTrait::<i32>::new(2302, false)),
                '118 bits'
            );
        }
    }
}
