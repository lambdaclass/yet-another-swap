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

    mod Clear {
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

        use fractal_swap::libraries::tick::{
            Info, Tick, ITick, ITickDispatcher, ITickDispatcherTrait
        };

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
}
