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

    mod Update {
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
        fn test_flips_from_zero_to_nonzero() {
            let tick = deploy();

            let flipped = tick
                .update(
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i128>::new(1, false),
                    0,
                    0,
                    0,
                    IntegerTrait::<i64>::new(0, false),
                    0,
                    false,
                    3
                );
            assert(flipped == true, 'flipped should be true');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_does_not_flip_from_nonzero_to_greater_nonzero() {
            let tick = deploy();

            tick
                .update(
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i128>::new(1, false),
                    0,
                    0,
                    0,
                    IntegerTrait::<i64>::new(0, false),
                    0,
                    false,
                    3
                );

            let flipped = tick
                .update(
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i128>::new(1, false),
                    0,
                    0,
                    0,
                    IntegerTrait::<i64>::new(0, false),
                    0,
                    false,
                    3
                );

            assert(flipped == false, 'flipped should be false');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_flips_from_nonzero_to_zero() {
            let tick = deploy();

            tick
                .update(
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i128>::new(1, false),
                    0,
                    0,
                    0,
                    IntegerTrait::<i64>::new(0, false),
                    0,
                    false,
                    3
                );

            let flipped = tick
                .update(
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i128>::new(1, true),
                    0,
                    0,
                    0,
                    IntegerTrait::<i64>::new(0, false),
                    0,
                    false,
                    3
                );

            assert(flipped == true, 'flipped should be true');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_does_not_flip_from_nonzero_to_lesser_nonzero() {
            let tick = deploy();

            tick
                .update(
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i128>::new(2, false),
                    0,
                    0,
                    0,
                    IntegerTrait::<i64>::new(0, false),
                    0,
                    false,
                    3
                );

            let flipped = tick
                .update(
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i128>::new(1, true),
                    0,
                    0,
                    0,
                    IntegerTrait::<i64>::new(0, false),
                    0,
                    false,
                    3
                );

            assert(flipped == false, 'flipped should be false');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_nets_the_liquidity_based_on_upper_flag() {
            let tick = deploy();

            tick
                .update(
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i128>::new(2, false),
                    0,
                    0,
                    0,
                    IntegerTrait::<i64>::new(0, false),
                    0,
                    false,
                    10
                );

            tick
                .update(
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i128>::new(1, false),
                    0,
                    0,
                    0,
                    IntegerTrait::<i64>::new(0, false),
                    0,
                    true,
                    10
                );

            tick
                .update(
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i128>::new(3, false),
                    0,
                    0,
                    0,
                    IntegerTrait::<i64>::new(0, false),
                    0,
                    true,
                    10
                );

            tick
                .update(
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i32>::new(0, false),
                    IntegerTrait::<i128>::new(1, false),
                    0,
                    0,
                    0,
                    IntegerTrait::<i64>::new(0, false),
                    0,
                    false,
                    10
                );

            let tick_id = IntegerTrait::<i32>::new(0, false);
            let result = tick.get_tick(tick_id);
            assert(result.liquidity_gross == 2 + 1 + 3 + 1, 'liquidity_gross should be 7');
            assert(
                result.liquidity_net == IntegerTrait::<i128>::new(2 - 1 - 3 + 1, true),
                'liquidity_net should be -1'
            );
        }

        #[test]
        #[available_gas(30000000)]
        fn test_assumes_all_growth_happens_below_ticks_lte_current_tick() {
            let tick = deploy();

            let tick_id = IntegerTrait::<i32>::new(1, false);
            let max_liquidity: u128 = BoundedInt::max();
            tick
                .update(
                    tick_id,
                    IntegerTrait::<i32>::new(1, false),
                    IntegerTrait::<i128>::new(1, false),
                    1,
                    2,
                    3,
                    IntegerTrait::<i64>::new(4, false),
                    5,
                    false,
                    max_liquidity
                );

            let result = tick.get_tick(tick_id);
            assert(result.fee_growth_outside_0X128 == 1, 'fee_growth_0X128 should be 1');
            assert(result.fee_growth_outside_1X128 == 2, 'fee_growth_1X128 should be 2');
            assert(
                result.seconds_per_liquidity_outside_X128 == 3, 'sec_per_liqui_X128 should be 3'
            );
            assert(
                result.tick_cumulative_outside == IntegerTrait::<i64>::new(4, false),
                'tick_cumulative should be 4'
            );
            assert(result.seconds_outside == 5, 'seconds_outside should be 5');
            assert(result.initialized == true, 'initialized should be true');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_does_not_set_any_growth_fields_if_tick_is_already_initialized() {
            let tick = deploy();

            let max_liquidity: u128 = BoundedInt::max();
            tick
                .update(
                    IntegerTrait::<i32>::new(1, false),
                    IntegerTrait::<i32>::new(1, false),
                    IntegerTrait::<i128>::new(1, false),
                    1,
                    2,
                    3,
                    IntegerTrait::<i64>::new(4, false),
                    5,
                    false,
                    max_liquidity
                );
            tick
                .update(
                    IntegerTrait::<i32>::new(1, false),
                    IntegerTrait::<i32>::new(1, false),
                    IntegerTrait::<i128>::new(1, false),
                    6,
                    7,
                    8,
                    IntegerTrait::<i64>::new(9, false),
                    10,
                    false,
                    max_liquidity
                );

            let tick_id = IntegerTrait::<i32>::new(1, false);
            let result = tick.get_tick(tick_id);
            assert(result.fee_growth_outside_0X128 == 1, 'fee_growth_0X128 should be 1');
            assert(result.fee_growth_outside_1X128 == 2, 'fee_growth_1X128 should be 2');
            assert(
                result.seconds_per_liquidity_outside_X128 == 3, 'sec_per_liqui_X128 should be 3'
            );
            assert(
                result.tick_cumulative_outside == IntegerTrait::<i64>::new(4, false),
                'tick_cumulative should be 4'
            );
            assert(result.seconds_outside == 5, 'seconds_outside should be 5');
            assert(result.initialized == true, 'initialized should be true');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_does_not_set_any_growth_fields_for_ticks_gt_current_tick() {
            let tick = deploy();

            let max_liquidity: u128 = BoundedInt::max();
            tick
                .update(
                    IntegerTrait::<i32>::new(2, false),
                    IntegerTrait::<i32>::new(1, false),
                    IntegerTrait::<i128>::new(1, false),
                    1,
                    2,
                    3,
                    IntegerTrait::<i64>::new(4, false),
                    5,
                    false,
                    max_liquidity
                );

            let tick_id = IntegerTrait::<i32>::new(2, false);
            let result = tick.get_tick(tick_id);
            assert(result.fee_growth_outside_0X128 == 0, 'fee_growth_0X128 should be 0');
            assert(result.fee_growth_outside_1X128 == 0, 'fee_growth_1X128 should be 0');
            assert(
                result.seconds_per_liquidity_outside_X128 == 0, 'sec_per_liqui_X128 should be 0'
            );
            assert(
                result.tick_cumulative_outside == IntegerTrait::<i64>::new(0, false),
                'tick_cumulative should be 0'
            );
            assert(result.seconds_outside == 0, 'seconds_outside should be 0');
            assert(result.initialized == true, 'initialized should be true');
        }
    }
}
