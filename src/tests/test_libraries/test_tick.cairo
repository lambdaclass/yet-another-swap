mod TickTests {
    use array::ArrayTrait;
    use result::ResultTrait;
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use starknet::syscalls::deploy_syscall;

    use orion::numbers::signed_integer::i32::i32;
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;

    use fractal_swap::libraries::tick::{Tick, ITick, ITickDispatcher, ITickDispatcherTrait};

    fn deploy() -> ITickDispatcher {
        let calldata: Array<felt252> = ArrayTrait::new();
        let (address, _) = deploy_syscall(
            Tick::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), true
        )
            .expect('DEPLOY_FAILED');
        return (ITickDispatcher { contract_address: address });
    }

    mod GetFeeGrowthInside {
        use super::deploy;
        use integer::BoundedInt;

        use fractal_swap::libraries::tick::{
            Info, Tick, ITick, ITickDispatcher, ITickDispatcherTrait
        };

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
}
