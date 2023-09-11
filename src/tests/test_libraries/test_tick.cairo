mod TickTests {
    use result::ResultTrait;
    use starknet::syscalls::deploy_syscall;

    use orion::numbers::signed_integer::i32::i32;
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;

    use yas::libraries::tick::{Tick, ITick, ITickDispatcher, ITickDispatcherTrait};
    use yas::utils::math_utils::MathUtils::pow;

    fn deploy() -> ITickDispatcher {
        let calldata: Array<felt252> = ArrayTrait::new();
        let (address, _) = deploy_syscall(
            Tick::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), true
        )
            .expect('DEPLOY_FAILED');
        return (ITickDispatcher { contract_address: address });
    }

    mod Clear {
        use super::deploy;
        use integer::BoundedInt;

        use yas::libraries::tick::{Info, Tick, ITick, ITickDispatcher, ITickDispatcherTrait};

        use orion::numbers::signed_integer::i32::i32;
        use orion::numbers::signed_integer::i64::i64;
        use orion::numbers::signed_integer::i128::i128;
        use orion::numbers::signed_integer::integer_trait::IntegerTrait;

        #[test]
        #[available_gas(30000000)]
        fn test_deletes_all_the_data_in_the_tick() {
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

            tick.clear(tick_id);

            let result = tick.get_tick(tick_id);
            assert(result.fee_growth_outside_0X128 == 0, 'fee_growth_0X128 should be 0');
            assert(result.fee_growth_outside_1X128 == 0, 'fee_growth_1X128 should be 0');
            assert(result.seconds_outside == 0, 'seconds_outside should be 0');
            assert(
                result.seconds_per_liquidity_outside_X128 == 0, 'sec_per_liqui_X128 should be 0'
            );
            assert(
                result.tick_cumulative_outside == IntegerTrait::<i64>::new(0, false),
                'tick_cumulative should be 0'
            );
            assert(result.liquidity_gross == 0, 'liquidity_gross should be 0');
            assert(
                result.liquidity_net == IntegerTrait::<i128>::new(0, false),
                'liquidity_net should be 0'
            );
            assert(result.initialized == false, 'initialized should be false');
        }
    }

    mod Cross {
        use super::deploy;
        use integer::BoundedInt;

        use yas::libraries::tick::{Info, Tick, ITick, ITickDispatcher, ITickDispatcherTrait};

        use orion::numbers::signed_integer::i32::i32;
        use orion::numbers::signed_integer::i64::i64;
        use orion::numbers::signed_integer::i128::i128;
        use orion::numbers::signed_integer::integer_trait::IntegerTrait;

        #[test]
        #[available_gas(30000000)]
        fn test_flips_the_growth_variables() {
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

            tick.cross(tick_id, 7, 9, 8, IntegerTrait::<i64>::new(15, false), 10);

            let result = tick.get_tick(tick_id);
            assert(result.fee_growth_outside_0X128 == 6, 'fee_growth_0X128 should be 6');
            assert(result.fee_growth_outside_1X128 == 7, 'fee_growth_1X128 should be 7');
            assert(
                result.seconds_per_liquidity_outside_X128 == 3, 'sec_per_liqui_X128 should be 3'
            );
            assert(
                result.tick_cumulative_outside == IntegerTrait::<i64>::new(9, false),
                'tick_cumulative should be 9'
            );
            assert(result.seconds_outside == 3, 'seconds_outside should be 3');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_two_flips_are_no_op() {
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

            tick.cross(tick_id, 7, 9, 8, IntegerTrait::<i64>::new(15, false), 10);
            tick.cross(tick_id, 7, 9, 8, IntegerTrait::<i64>::new(15, false), 10);

            let result = tick.get_tick(tick_id);
            assert(result.fee_growth_outside_0X128 == 1, 'fee_growth_0X128 should be 1');
            assert(result.fee_growth_outside_1X128 == 2, 'fee_growth_1X128 should be 2');
            assert(
                result.seconds_per_liquidity_outside_X128 == 5, 'sec_per_liqui_X128 should be 5'
            );
            assert(
                result.tick_cumulative_outside == IntegerTrait::<i64>::new(6, false),
                'tick_cumulative should be 6'
            );
            assert(result.seconds_outside == 7, 'seconds_outside should be 7');
        }
    }

    mod GetFeeGrowthInside {
        use super::deploy;
        use integer::BoundedInt;

        use yas::libraries::tick::{Info, Tick, ITick, ITickDispatcher, ITickDispatcherTrait};

        use orion::numbers::signed_integer::i32::i32;
        use orion::numbers::signed_integer::i64::i64;
        use orion::numbers::signed_integer::i128::i128;
        use orion::numbers::signed_integer::integer_trait::IntegerTrait;

        #[test]
        #[available_gas(30000000)]
        fn test_returns_all_for_two_uninitialized_ticks_if_tick_is_inside() {
            let tick = deploy();

            let (fee_growth_inside_0X128, fee_growth_inside_1X128) = tick
                .get_fee_growth_inside(
                    IntegerTrait::<i32>::new(2, true),
                    IntegerTrait::<i32>::new(2, false),
                    IntegerTrait::<i32>::new(0, false),
                    15,
                    15
                );

            assert(fee_growth_inside_0X128 == 15, 'fee_gro_0X128 should be 15');
            assert(fee_growth_inside_1X128 == 15, 'fee_gro_1X128 should be 15');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_returns_0_for_two_uninitialized_ticks_if_tick_is_above() {
            let tick = deploy();

            let (fee_growth_inside_0X128, fee_growth_inside_1X128) = tick
                .get_fee_growth_inside(
                    IntegerTrait::<i32>::new(2, true),
                    IntegerTrait::<i32>::new(2, false),
                    IntegerTrait::<i32>::new(4, false),
                    15,
                    15
                );

            assert(fee_growth_inside_0X128 == 0, 'fee_gro_0X128 should be 0');
            assert(fee_growth_inside_1X128 == 0, 'fee_gro_1X128 should be 0');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_returns_0_for_two_uninitialized_ticks_if_tick_is_below() {
            let tick = deploy();

            let (fee_growth_inside_0X128, fee_growth_inside_1X128) = tick
                .get_fee_growth_inside(
                    IntegerTrait::<i32>::new(2, true),
                    IntegerTrait::<i32>::new(2, false),
                    IntegerTrait::<i32>::new(4, true),
                    15,
                    15
                );

            assert(fee_growth_inside_0X128 == 0, 'fee_gro_0X128 should be 0');
            assert(fee_growth_inside_1X128 == 0, 'fee_gro_1X128 should be 0');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_subtracts_upper_tick_if_below() {
            let tick = deploy();

            tick
                .set_tick(
                    IntegerTrait::<i32>::new(2, false),
                    Info {
                        fee_growth_outside_0X128: 2,
                        fee_growth_outside_1X128: 3,
                        liquidity_gross: 0,
                        liquidity_net: IntegerTrait::<i128>::new(0, false),
                        seconds_per_liquidity_outside_X128: 0,
                        tick_cumulative_outside: IntegerTrait::<i64>::new(0, false),
                        seconds_outside: 0,
                        initialized: true
                    }
                );

            let (fee_growth_inside_0X128, fee_growth_inside_1X128) = tick
                .get_fee_growth_inside(
                    IntegerTrait::<i32>::new(2, true),
                    IntegerTrait::<i32>::new(2, false),
                    IntegerTrait::<i32>::new(0, false),
                    15,
                    15
                );

            assert(fee_growth_inside_0X128 == 13, 'fee_gro_0X128 should be 13');
            assert(fee_growth_inside_1X128 == 12, 'fee_gro_1X128 should be 12');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_subtracts_lower_tick_if_above() {
            let tick = deploy();

            tick
                .set_tick(
                    IntegerTrait::<i32>::new(2, true),
                    Info {
                        fee_growth_outside_0X128: 2,
                        fee_growth_outside_1X128: 3,
                        liquidity_gross: 0,
                        liquidity_net: IntegerTrait::<i128>::new(0, false),
                        seconds_per_liquidity_outside_X128: 0,
                        tick_cumulative_outside: IntegerTrait::<i64>::new(0, false),
                        seconds_outside: 0,
                        initialized: true
                    }
                );

            let (fee_growth_inside_0X128, fee_growth_inside_1X128) = tick
                .get_fee_growth_inside(
                    IntegerTrait::<i32>::new(2, true),
                    IntegerTrait::<i32>::new(2, false),
                    IntegerTrait::<i32>::new(0, false),
                    15,
                    15
                );

            assert(fee_growth_inside_0X128 == 13, 'fee_gro_0X128 should be 13');
            assert(fee_growth_inside_1X128 == 12, 'fee_gro_1X128 should be 12');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_subtracts_upper_and_lower_tick_if_inside() {
            let tick = deploy();

            tick
                .set_tick(
                    IntegerTrait::<i32>::new(2, true),
                    Info {
                        fee_growth_outside_0X128: 2,
                        fee_growth_outside_1X128: 3,
                        liquidity_gross: 0,
                        liquidity_net: IntegerTrait::<i128>::new(0, false),
                        seconds_per_liquidity_outside_X128: 0,
                        tick_cumulative_outside: IntegerTrait::<i64>::new(0, false),
                        seconds_outside: 0,
                        initialized: true
                    }
                );

            tick
                .set_tick(
                    IntegerTrait::<i32>::new(2, false),
                    Info {
                        fee_growth_outside_0X128: 4,
                        fee_growth_outside_1X128: 1,
                        liquidity_gross: 0,
                        liquidity_net: IntegerTrait::<i128>::new(0, false),
                        seconds_per_liquidity_outside_X128: 0,
                        tick_cumulative_outside: IntegerTrait::<i64>::new(0, false),
                        seconds_outside: 0,
                        initialized: true
                    }
                );

            let (fee_growth_inside_0X128, fee_growth_inside_1X128) = tick
                .get_fee_growth_inside(
                    IntegerTrait::<i32>::new(2, true),
                    IntegerTrait::<i32>::new(2, false),
                    IntegerTrait::<i32>::new(0, false),
                    15,
                    15
                );

            assert(fee_growth_inside_0X128 == 9, 'fee_gro_0X128 should be 9');
            assert(fee_growth_inside_1X128 == 11, 'fee_gro_1X128 should be 11');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_works_correctly_with_overflow_on_inside_tick() {
            let tick = deploy();

            tick
                .set_tick(
                    IntegerTrait::<i32>::new(2, true),
                    Info {
                        fee_growth_outside_0X128: BoundedInt::max() - 3,
                        fee_growth_outside_1X128: BoundedInt::max() - 2,
                        liquidity_gross: 0,
                        liquidity_net: IntegerTrait::<i128>::new(0, false),
                        seconds_per_liquidity_outside_X128: 0,
                        tick_cumulative_outside: IntegerTrait::<i64>::new(0, false),
                        seconds_outside: 0,
                        initialized: true
                    }
                );

            tick
                .set_tick(
                    IntegerTrait::<i32>::new(2, false),
                    Info {
                        fee_growth_outside_0X128: 3,
                        fee_growth_outside_1X128: 5,
                        liquidity_gross: 0,
                        liquidity_net: IntegerTrait::<i128>::new(0, false),
                        seconds_per_liquidity_outside_X128: 0,
                        tick_cumulative_outside: IntegerTrait::<i64>::new(0, false),
                        seconds_outside: 0,
                        initialized: true
                    }
                );

            let (fee_growth_inside_0X128, fee_growth_inside_1X128) = tick
                .get_fee_growth_inside(
                    IntegerTrait::<i32>::new(2, true),
                    IntegerTrait::<i32>::new(2, false),
                    IntegerTrait::<i32>::new(0, false),
                    15,
                    15
                );

            assert(fee_growth_inside_0X128 == 16, 'fee_gro_0X128 should be 16');
            assert(fee_growth_inside_1X128 == 13, 'fee_gro_1X128 should be 13');
        }
    }

    mod TickSpacingToMaxLiquidityPerTick {
        use super::deploy;
        use integer::BoundedInt;

        use orion::numbers::signed_integer::{i32::i32, i64::i64, i128::i128};
        use orion::numbers::signed_integer::integer_trait::IntegerTrait;

        use yas::utils::math_utils::MathUtils::{i32_div, pow};
        use yas::libraries::tick::{Info, Tick, ITick, ITickDispatcher, ITickDispatcherTrait};

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

            assert(result == 11505743598341114571880798222544994, '113.1 bits');
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
        }
    }
}
