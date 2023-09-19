mod YASPoolTests {
    use starknet::{contract_address_const, ContractAddress};
    use starknet::syscalls::deploy_syscall;

    use yas::contracts::yas_pool::{YASPool, IYASPool, IYASPoolDispatcher, IYASPoolDispatcherTrait};
    use yas::numbers::signed_integer::{
        i32::i32, i32::i32_div_no_round, integer_trait::IntegerTrait
    };

    // TODO: Use from constants.cairo and remove this
    fn FACTORY_ADDRESS() -> ContractAddress {
        contract_address_const::<'FACTORY'>()
    }

    fn TOKEN_A() -> ContractAddress {
        contract_address_const::<'TOKEN_A'>()
    }

    fn TOKEN_B() -> ContractAddress {
        contract_address_const::<'TOKEN_B'>()
    }

    fn STATE() -> YASPool::ContractState {
        YASPool::contract_state_for_testing()
    }

    fn max_tick(tick_spacing: i32) -> i32 {
        let MAX_TICK = IntegerTrait::<i32>::new(887272, false);
        i32_div_no_round(MAX_TICK, tick_spacing) * tick_spacing
    }

    fn min_tick(tick_spacing: i32) -> i32 {
        let MIN_TICK = IntegerTrait::<i32>::new(887272, true);
        i32_div_no_round(MIN_TICK, tick_spacing) * tick_spacing
    }

    fn deploy(
        factory: ContractAddress,
        token_0: ContractAddress,
        token_1: ContractAddress,
        fee: u32,
        tick_spacing: i32
    ) -> IYASPoolDispatcher {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        calldata.append(factory.into());
        calldata.append(token_0.into());
        calldata.append(token_1.into());
        calldata.append(fee.into());
        Serde::serialize(@tick_spacing, ref calldata);

        let (address, _) = deploy_syscall(
            YASPool::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), true
        )
            .expect('DEPLOY_FAILED');

        return IYASPoolDispatcher { contract_address: address };
    }

    mod Constructor {
        use super::{FACTORY_ADDRESS, TOKEN_A, TOKEN_B};
        use super::deploy;
        use starknet::{contract_address_const, ContractAddress};

        use yas::contracts::yas_pool::{
            YASPool, IYASPool, IYASPoolDispatcher, IYASPoolDispatcherTrait
        };
        use yas::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};

        #[test]
        #[available_gas(2000000000000)]
        fn test_deployer() {
            let fee = 5;
            let tick_spacing = IntegerTrait::<i32>::new(1, false);
            let yas_pool = deploy(FACTORY_ADDRESS(), TOKEN_A(), TOKEN_B(), fee, tick_spacing);
        }
    }

    mod Initialize {
        use super::{deploy, min_tick, max_tick, STATE};
        // migrate to constants.cairo
        use super::{FACTORY_ADDRESS, TOKEN_A, TOKEN_B};

        use starknet::testing::pop_log;

        use yas::contracts::yas_pool::{
            Slot0, IYASPoolDispatcherTrait, YASPool::{YASPoolImpl, InternalImpl, Initialize}
        };
        use yas::numbers::fixed_point::implementations::impl_64x96::{
            FP64x96Impl, FP64x96Sub, FP64x96PartialEq, FixedType, FixedTrait
        };
        use yas::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};
        use yas::libraries::tick_math::TickMath::{MAX_SQRT_RATIO, MIN_SQRT_RATIO};
        use yas::utils::math_utils::pow;

        #[test]
        #[available_gas(200000000)]
        #[should_panic(expected: ('AI', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_already_initialized() {
            let yas_pool = deploy(
                FACTORY_ADDRESS(), TOKEN_A(), TOKEN_B(), 5, IntegerTrait::<i32>::new(1, false)
            );

            // sqrt_price_X96 is the result of encode_price_sqrt(1, 1) on v3-core typescript impl. 
            let sqrt_price_X96 = FixedTrait::new(79228162514264337593543950336, false);
            yas_pool.initialize(sqrt_price_X96);

            // initialize again with same values
            yas_pool.initialize(sqrt_price_X96);
        }

        #[test]
        #[available_gas(200000000)]
        #[should_panic(expected: ('R', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_price_is_too_low() {
            let yas_pool = deploy(
                FACTORY_ADDRESS(), TOKEN_A(), TOKEN_B(), 5, IntegerTrait::<i32>::new(1, false)
            );

            let sqrt_price_X96 = FixedTrait::new(1, false);
            yas_pool.initialize(sqrt_price_X96);
        }

        #[test]
        #[available_gas(200000000)]
        #[should_panic(expected: ('R', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_price_is_min_sqrt_ratio_minus_1() {
            let yas_pool = deploy(
                FACTORY_ADDRESS(), TOKEN_A(), TOKEN_B(), 5, IntegerTrait::<i32>::new(1, false)
            );

            let sqrt_price_X96 = FixedTrait::new(MIN_SQRT_RATIO - 1, false);
            yas_pool.initialize(sqrt_price_X96);
        }

        #[test]
        #[available_gas(200000000)]
        #[should_panic(expected: ('R', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_price_is_too_high() {
            let yas_pool = deploy(
                FACTORY_ADDRESS(), TOKEN_A(), TOKEN_B(), 5, IntegerTrait::<i32>::new(1, false)
            );

            let sqrt_price_X96 = FixedTrait::new(pow(2, 160) - 1, false);
            yas_pool.initialize(sqrt_price_X96);
        }

        #[test]
        #[available_gas(200000000)]
        #[should_panic(expected: ('R', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_price_is_max_sqrt_ratio() {
            let yas_pool = deploy(
                FACTORY_ADDRESS(), TOKEN_A(), TOKEN_B(), 5, IntegerTrait::<i32>::new(1, false)
            );

            let sqrt_price_X96 = FixedTrait::new(MAX_SQRT_RATIO, false);
            yas_pool.initialize(sqrt_price_X96);
        }

        #[test]
        #[available_gas(200000000)]
        fn test_can_be_initialized_at_min_sqrt_ratio() {
            let mut state = STATE();

            let sqrt_price_X96 = FixedTrait::new(MIN_SQRT_RATIO, false);
            YASPoolImpl::initialize(ref state, sqrt_price_X96);

            let expected = Slot0 {
                sqrt_price_X96: FixedTrait::new(MIN_SQRT_RATIO, false),
                tick: min_tick(IntegerTrait::<i32>::new(1, false)),
                fee_protocol: 0,
                unlocked: true
            };

            assert(InternalImpl::slot_0(@state) == expected, 'slot 0 wrong initialization');
        }

        #[test]
        #[available_gas(200000000)]
        fn test_can_be_initialized_at_max_sqrt_ratio_minus_1() {
            let mut state = STATE();

            let sqrt_price_X96 = FP64x96Impl::new(MAX_SQRT_RATIO - 1, false);
            YASPoolImpl::initialize(ref state, sqrt_price_X96);

            let expected = Slot0 {
                sqrt_price_X96: sqrt_price_X96,
                tick: max_tick(IntegerTrait::<i32>::new(1, false))
                    - IntegerTrait::<i32>::new(1, false),
                fee_protocol: 0,
                unlocked: true
            };

            assert(InternalImpl::slot_0(@state) == expected, 'slot 0 wrong initialization')
        }

        #[test]
        #[available_gas(200000000)]
        fn test_sets_initial_variables() {
            let mut state = STATE();

            // sqrt_price_X96 is the result of encode_price_sqrt(1, 2) on v3-core typescript impl. 
            let sqrt_price_X96 = FP64x96Impl::new(56022770974786139918731938227 - 1, false);
            YASPoolImpl::initialize(ref state, sqrt_price_X96);

            let expected = Slot0 {
                sqrt_price_X96,
                tick: IntegerTrait::<i32>::new(6932, true),
                fee_protocol: 0,
                unlocked: true
            };

            assert(InternalImpl::slot_0(@state) == expected, 'slot 0 wrong initialization')
        }

        #[test]
        #[available_gas(200000000)]
        fn test_emits_a_initialized_event() {
            let yas_pool = deploy(
                FACTORY_ADDRESS(), TOKEN_A(), TOKEN_B(), 5, IntegerTrait::<i32>::new(1, false)
            );

            // sqrt_price_X96 is the result of encode_price_sqrt(1, 2) on v3-core typescript impl. 
            let sqrt_price_X96 = FP64x96Impl::new(56022770974786139918731938227 - 1, false);
            let tick = IntegerTrait::<i32>::new(6932, true);
            yas_pool.initialize(sqrt_price_X96);

            // Verify Initialize event emitted
            let event = pop_log::<Initialize>(yas_pool.contract_address).unwrap();
            assert(event.sqrt_price_X96 == sqrt_price_X96, 'wrong event value price_X96');
            assert(event.tick == tick, 'wrong event value tick');
        }
    }
}
