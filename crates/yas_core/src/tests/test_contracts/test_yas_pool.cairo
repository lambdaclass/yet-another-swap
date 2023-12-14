mod YASPoolTests {
    use starknet::{contract_address_const, ContractAddress};
    use starknet::syscalls::deploy_syscall;
    use integer::BoundedInt;

    use yas_core::contracts::yas_pool::{
        YASPool, YASPool::ContractState, YASPool::InternalImpl, IYASPool, IYASPoolDispatcher,
        IYASPoolDispatcherTrait
    };

    use yas_core::numbers::signed_integer::{
        i32::i32, i32::i32_div_no_round, i64::i64, i128::i128, integer_trait::IntegerTrait
    };
    use yas_core::libraries::{
        tick::{Tick, Tick::TickImpl},
        position::{Info, Position, Position::PositionImpl, PositionKey}
    };
    use yas_core::tests::utils::constants::PoolConstants::OWNER;

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
        use super::deploy;

        use starknet::{contract_address_const, ContractAddress};

        use yas_core::contracts::yas_pool::{
            YASPool, IYASPool, IYASPoolDispatcher, IYASPoolDispatcherTrait
        };
        use yas_core::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};
        use yas_core::tests::utils::constants::PoolConstants::{FACTORY_ADDRESS, TOKEN_A, TOKEN_B};

        #[test]
        #[available_gas(2000000000000)]
        fn test_deployer() {
            let fee = 5;
            let tick_spacing = IntegerTrait::<i32>::new(1, false);
            let yas_pool = deploy(FACTORY_ADDRESS(), TOKEN_A(), TOKEN_B(), fee, tick_spacing);
        }
    }

    mod Initialize {
        use super::deploy;
        use starknet::testing::pop_log;

        use yas_core::contracts::yas_pool::{
            IYASPoolDispatcherTrait, YASPool::{YASPoolImpl, InternalImpl, Initialize, Slot0}
        };
        use yas_core::numbers::fixed_point::implementations::impl_64x96::{
            FP64x96Impl, FP64x96Sub, FP64x96PartialEq, FixedType, FixedTrait
        };
        use yas_core::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};
        use yas_core::libraries::tick_math::TickMath::{MAX_SQRT_RATIO, MIN_SQRT_RATIO};
        use yas_core::tests::utils::constants::PoolConstants::{
            FACTORY_ADDRESS, TOKEN_A, TOKEN_B, STATE, min_tick, max_tick, encode_price_sqrt_1_1,
            encode_price_sqrt_1_2
        };
        use yas_core::utils::{math_utils::pow, utils::Slot0PartialEq};

        #[test]
        #[available_gas(200000000)]
        #[should_panic(expected: ('AI', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_already_initialized() {
            let yas_pool = deploy(
                FACTORY_ADDRESS(), TOKEN_A(), TOKEN_B(), 5, IntegerTrait::<i32>::new(1, false)
            );

            let sqrt_price_X96 = encode_price_sqrt_1_1();
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
                fee_protocol: 0
            };

            assert(InternalImpl::get_slot_0(@state) == expected, 'slot 0 wrong initialization');
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
                fee_protocol: 0
            };

            assert(InternalImpl::get_slot_0(@state) == expected, 'slot 0 wrong initialization')
        }

        #[test]
        #[available_gas(200000000)]
        fn test_sets_initial_variables() {
            let mut state = STATE();

            let sqrt_price_X96 = encode_price_sqrt_1_2();
            YASPoolImpl::initialize(ref state, sqrt_price_X96);

            let expected = Slot0 {
                sqrt_price_X96, tick: IntegerTrait::<i32>::new(6932, true), fee_protocol: 0
            };

            assert(InternalImpl::get_slot_0(@state) == expected, 'slot 0 wrong initialization')
        }

        #[test]
        #[available_gas(200000000)]
        fn test_emits_a_initialized_event() {
            let yas_pool = deploy(
                FACTORY_ADDRESS(), TOKEN_A(), TOKEN_B(), 5, IntegerTrait::<i32>::new(1, false)
            );

            let sqrt_price_X96 = encode_price_sqrt_1_2();
            let tick = IntegerTrait::<i32>::new(6932, true);
            yas_pool.initialize(sqrt_price_X96);

            // Verify Initialize event emitted
            let event = pop_log::<Initialize>(yas_pool.contract_address).unwrap();
            assert(event.sqrt_price_X96 == sqrt_price_X96, 'wrong event value price_X96');
            assert(event.tick == tick, 'wrong event value tick');
        }
    }

    mod UpdatePosition {
        use super::{
            deploy, mock_contract_states, mock_position_key_and_info, mock_ticks, mock_tick_infos,
            init_default
        };
        use integer::BoundedInt;

        use yas_core::contracts::yas_pool::{
            IYASPoolDispatcherTrait, YASPool, YASPool::InternalTrait,
            YASPool::{YASPoolImpl, InternalImpl, Initialize, Slot0}
        };
        use yas_core::numbers::signed_integer::{
            i32::i32, i64::i64, i128::i128, integer_trait::IntegerTrait
        };
        use yas_core::tests::utils::constants::PoolConstants::{
            FACTORY_ADDRESS, TOKEN_A, TOKEN_B, STATE, min_tick, max_tick, encode_price_sqrt_1_1,
            encode_price_sqrt_1_2
        };
        use yas_core::tests::utils::constants::FactoryConstants::OWNER;
        use yas_core::libraries::{
            tick::{Tick, Tick::TickImpl},
            position::{Info, Position, Position::PositionImpl, PositionKey}
        };

        #[test]
        #[available_gas(200000000)]
        fn test_add_liquidity_when_call_update_position_then_position_is_updated() {
            let (mut pool_state, mut position_state, mut tick_state) = mock_contract_states();

            // Setup YASPool
            init_default(ref pool_state);

            // Setup and set Position
            let (position_key, position_info) = mock_position_key_and_info(
                Zeroable::zero(), IntegerTrait::<i32>::new(9, false)
            );
            Position::InternalImpl::set_position(ref position_state, position_key, position_info);

            // Setup and set tick
            let tick = IntegerTrait::<i32>::new(5, false);

            // Init ticks [0, 1, .., 9] with mocked Tick::Info
            mock_ticks(
                ref tick_state,
                position_key.tick_lower,
                position_key.tick_upper,
                mock_tick_infos(infos_len: 10)
            );

            // add 100 of liq into position
            let delta_liquidity = IntegerTrait::<i128>::new(100, false);
            let result = InternalImpl::update_position(
                @pool_state, position_key, delta_liquidity, tick
            );

            assert(result.liquidity == 1100, 'wrong liquidity');
        }

        #[test]
        #[available_gas(200000000)]
        fn test_sub_liquidity_when_call_update_position_then_position_is_updated() {
            let (mut pool_state, mut position_state, mut tick_state) = mock_contract_states();

            // Setup YASPool
            init_default(ref pool_state);

            // Setup and set Position
            let (position_key, position_info) = mock_position_key_and_info(
                IntegerTrait::<i32>::new(99, false), IntegerTrait::<i32>::new(102, false)
            );
            Position::InternalImpl::set_position(ref position_state, position_key, position_info);

            // Setup tick
            let tick = IntegerTrait::<i32>::new(100, false);

            // Init ticks [99, 100, 101, 102]
            mock_ticks(
                ref tick_state,
                position_key.tick_lower,
                position_key.tick_upper,
                mock_tick_infos(infos_len: 4)
            );

            let delta_liquidity = IntegerTrait::<i128>::new(100, true);
            let tickinfo = Tick::InternalImpl::get_tick(@tick_state, tick);
            let result = InternalImpl::update_position(
                @pool_state, position_key, delta_liquidity, tick
            );

            assert(result.liquidity == 900, 'wrong liquidity');
        }

        #[test]
        #[available_gas(200000000)]
        #[should_panic(expected: ('LS',))]
        fn test_sub_liquidity_gt_available_when_call_update_position_should_panic() {
            let (mut pool_state, mut position_state, mut tick_state) = mock_contract_states();

            // Setup YASPool
            init_default(ref pool_state);

            // Setup and set Position
            let (position_key, position_info) = mock_position_key_and_info(
                IntegerTrait::<i32>::new(5, true), IntegerTrait::<i32>::new(5, false)
            );
            Position::InternalImpl::set_position(ref position_state, position_key, position_info);

            // Setup and set tick
            let tick = IntegerTrait::<i32>::new(2, true);

            // Init ticks [-5, -4, .., 4, 5] with mocked Tick::Info
            mock_ticks(
                ref tick_state,
                position_key.tick_lower,
                position_key.tick_upper,
                mock_tick_infos(infos_len: 11)
            );

            // liquidity available in that tick is 100, if we try to sub > 100 should be panic
            let delta_liquidity = IntegerTrait::<i128>::new(101, true);
            InternalImpl::update_position(@pool_state, position_key, delta_liquidity, tick);
        }

        #[test]
        #[available_gas(200000000)]
        #[should_panic(expected: ('LO',))]
        fn test_add_liquidity_gt_max_liq_when_call_update_position_should_panic() {
            let (mut pool_state, mut position_state, mut tick_state) = mock_contract_states();

            // Setup YASPool
            init_default(ref pool_state);
            pool_state.set_max_liquidity_per_tick(1500);

            // Setup and set Position
            let (position_key, position_info) = mock_position_key_and_info(
                Zeroable::zero(), IntegerTrait::<i32>::new(9, false)
            );
            Position::InternalImpl::set_position(ref position_state, position_key, position_info);

            // Setup and set tick
            let tick = IntegerTrait::<i32>::new(5, false);

            // Init ticks [0, 1, .., 9] with mocked Tick::Info
            mock_ticks(
                ref tick_state,
                position_key.tick_lower,
                position_key.tick_upper,
                mock_tick_infos(infos_len: 10)
            );

            // mocked Tick::Info has 100 of liquidity gross,
            // we set 1500 for max_liq so 1501 should panic
            let delta_liquidity = IntegerTrait::<i128>::new(1401, false);
            InternalImpl::update_position(@pool_state, position_key, delta_liquidity, tick);
        }
    }

    mod CheckTicks {
        use yas_core::contracts::yas_pool::YASPool;
        use yas_core::libraries::tick_math::TickMath;
        use yas_core::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};

        #[test]
        #[available_gas(60000)]
        fn test_valid_ticks() {
            let tick_lower = IntegerTrait::<i32>::new(100, true);
            let tick_upper = IntegerTrait::<i32>::new(100, false);
            match YASPool::check_ticks(tick_lower, tick_upper) {
                Result::Ok(()) => {},
                Result::Err(err) => {
                    panic_with_felt252(err)
                },
            }
        }

        #[test]
        #[available_gas(60000)]
        fn test_valid_tick_lower() {
            let tick_lower = TickMath::MIN_TICK();
            let tick_upper = IntegerTrait::<i32>::new(100, false);
            match YASPool::check_ticks(tick_lower, tick_upper) {
                Result::Ok(()) => {},
                Result::Err(err) => {
                    panic_with_felt252(err)
                },
            }
        }

        #[test]
        #[available_gas(60000)]
        fn test_valid_tick_upper() {
            let tick_lower = IntegerTrait::<i32>::new(100, true);
            let tick_upper = TickMath::MAX_TICK();
            match YASPool::check_ticks(tick_lower, tick_upper) {
                Result::Ok(()) => {},
                Result::Err(err) => {
                    panic_with_felt252(err)
                },
            }
        }

        #[test]
        #[available_gas(60000)]
        #[should_panic(expected: ('TLU',))]
        fn test_tick_upper_lower_invalid() {
            let tick_lower = IntegerTrait::<i32>::new(100, false);
            let tick_upper = IntegerTrait::<i32>::new(100, true);
            match YASPool::check_ticks(tick_lower, tick_upper) {
                Result::Ok(()) => {},
                Result::Err(err) => {
                    panic_with_felt252(err)
                },
            }
        }

        #[test]
        #[available_gas(60000)]
        #[should_panic(expected: ('TLM',))]
        fn test_invalid_min_tick() {
            let tick_lower = TickMath::MIN_TICK() - IntegerTrait::<i32>::new(1, false);
            let tick_upper = TickMath::MIN_TICK();
            match YASPool::check_ticks(tick_lower, tick_upper) {
                Result::Ok(()) => {},
                Result::Err(err) => {
                    panic_with_felt252(err)
                },
            }
        }

        #[test]
        #[available_gas(60000)]
        #[should_panic(expected: ('TUM',))]
        fn test_invalid_max_tick() {
            let tick_lower = TickMath::MAX_TICK();
            let tick_upper = TickMath::MAX_TICK() + IntegerTrait::<i32>::new(1, false);
            match YASPool::check_ticks(tick_lower, tick_upper) {
                Result::Ok(()) => {},
                Result::Err(err) => {
                    panic_with_felt252(err)
                },
            }
        }

        #[test]
        #[available_gas(60000)]
        fn test_valid_min_max_ticks() {
            let tick_lower = TickMath::MIN_TICK();
            let tick_upper = TickMath::MAX_TICK();
            match YASPool::check_ticks(tick_lower, tick_upper) {
                Result::Ok(()) => {},
                Result::Err(err) => {
                    panic_with_felt252(err)
                },
            }
        }
    }

    mod Mint {
        use yas_core::contracts::yas_pool::YASPool::InternalTrait;
        use super::{
            setup, get_min_tick_and_max_tick, deploy, MIN_TICK, MAX_TICK, tick_spacing, FeeAmount,
            fee_amount
        };

        use starknet::{ContractAddress, ClassHash, SyscallResultTrait, contract_address_const};
        use starknet::syscalls::deploy_syscall;
        use starknet::testing::{set_contract_address, set_caller_address};

        use yas_core::contracts::yas_pool::{
            YASPool, YASPool::ContractState, YASPool::YASPoolImpl, YASPool::InternalImpl, IYASPool,
            IYASPoolDispatcher, IYASPoolDispatcherTrait
        };
        use yas_core::contracts::yas_factory::{
            YASFactory, IYASFactory, IYASFactoryDispatcher, IYASFactoryDispatcherTrait
        };
        use yas_core::contracts::yas_router::{
            YASRouter, IYASRouterDispatcher, IYASRouterDispatcherTrait
        };
        use yas_core::numbers::fixed_point::implementations::impl_64x96::{
            FP64x96Impl, FixedType, FixedTrait
        };
        use yas_core::libraries::tick::{Tick, Tick::TickImpl};
        use yas_core::libraries::position::{Info, Position, Position::PositionImpl, PositionKey};
        use yas_core::tests::utils::constants::PoolConstants::{
            FACTORY_ADDRESS, TOKEN_A, TOKEN_B, WALLET, STATE, encode_price_sqrt_1_1
        };
        use yas_core::contracts::yas_erc20::{
            ERC20, ERC20::ERC20Impl, IERC20Dispatcher, IERC20DispatcherTrait
        };
        use yas_core::numbers::signed_integer::{
            i32::i32, i32::i32_div_no_round, integer_trait::IntegerTrait
        };

        use yas_core::utils::math_utils::pow;

        #[test]
        #[available_gas(2000000000)]
        #[should_panic(expected: ('LOK', 'ENTRYPOINT_FAILED'))]
        fn test_fails_not_initialized() {
            let yas_pool = deploy(
                FACTORY_ADDRESS(),
                TOKEN_A(),
                TOKEN_B(),
                fee_amount(FeeAmount::MEDIUM),
                IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false)
            );
            let sqrt_price_X96 = encode_price_sqrt_1_1();
            //yas_pool.initialize(sqrt_price_X96); //don't, test is about not initializing
            let (min_tick, max_tick) = get_min_tick_and_max_tick();

            let (amount0, amount1): (u256, u256) = yas_pool
                .mint(
                    recipient: yas_pool.contract_address,
                    tick_lower: min_tick,
                    tick_upper: max_tick,
                    amount: 1,
                    data: array![]
                );
        }

        mod FailureCases {
            use super::{
                setup, MIN_TICK, MAX_TICK, tick_spacing, FeeAmount, fee_amount,
                IERC20DispatcherTrait, FACTORY_ADDRESS, TOKEN_A, TOKEN_B, WALLET,
                encode_price_sqrt_1_1
            };
            use yas_core::numbers::signed_integer::{
                i32::i32, i32::i32_div_no_round, integer_trait::IntegerTrait
            };
            use yas_core::contracts::yas_pool::{
                YASPool, YASPool::ContractState, YASPool::YASPoolImpl, YASPool::InternalImpl,
                IYASPool, IYASPoolDispatcher, IYASPoolDispatcherTrait
            };
            use yas_core::contracts::yas_router::{
                YASRouter, IYASRouterDispatcher, IYASRouterDispatcherTrait
            };

            #[test]
            #[available_gas(2000000000)]
            #[should_panic(expected: ('TLU', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_fails_tick_lower_greater_than_tick_upper() {
                let (yas_pool, _, _, yas_router, _, _) = setup();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        IntegerTrait::<i32>::new(1, false),
                        Zeroable::zero(),
                        1
                    );
            }

            #[test]
            #[available_gas(2000000000)]
            #[should_panic(expected: ('TLM', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_fails_tick_lower_than_min() {
                let (yas_pool, _, _, yas_router, _, _) = setup();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        MIN_TICK() - IntegerTrait::<i32>::new(1, false),
                        Zeroable::zero(),
                        1
                    );
            }

            #[test]
            #[available_gas(2000000000)]
            #[should_panic(expected: ('TUM', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_fails_tick_greater_than_max() {
                let (yas_pool, _, _, yas_router, _, _) = setup();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        Zeroable::zero(),
                        MAX_TICK() + IntegerTrait::<i32>::new(1, false),
                        1
                    );
            }

            #[test]
            #[available_gas(2000000000)]
            #[should_panic(expected: ('LO', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_fails_amount_exceeds_the_max() {
                let (yas_pool, _, _, yas_router, min_tick, max_tick) = setup();
                let max_liquidity_gross = yas_pool.get_max_liquidity_per_tick();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + yas_pool.get_tick_spacing(),
                        max_tick - yas_pool.get_tick_spacing(),
                        max_liquidity_gross + 1
                    );
            }

            #[test]
            #[available_gas(2000000000)]
            fn test_amount_max() {
                let (yas_pool, _, _, yas_router, min_tick, max_tick) = setup();
                let max_liquidity_gross = yas_pool.get_max_liquidity_per_tick();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + yas_pool.get_tick_spacing(),
                        max_tick - yas_pool.get_tick_spacing(),
                        max_liquidity_gross
                    );
            }

            #[test]
            #[available_gas(2000000000)]
            #[should_panic(expected: ('LO', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_fails_amount_at_tick_greater_than_max() {
                let (yas_pool, _, _, yas_router, min_tick, max_tick) = setup();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + yas_pool.get_tick_spacing(),
                        max_tick - yas_pool.get_tick_spacing(),
                        1000
                    );
                let max_liquidity_gross = yas_pool.get_max_liquidity_per_tick();

                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + yas_pool.get_tick_spacing(),
                        max_tick - yas_pool.get_tick_spacing(),
                        max_liquidity_gross - 1000 + 1
                    );
            }

            #[test]
            #[available_gas(2000000000)]
            #[should_panic(expected: ('LO', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_fails_amount_at_tick_greater_than_max_2() {
                let (yas_pool, _, _, yas_router, min_tick, max_tick) = setup();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + yas_pool.get_tick_spacing(),
                        max_tick - yas_pool.get_tick_spacing(),
                        1000
                    );
                let max_liquidity_gross = yas_pool.get_max_liquidity_per_tick();

                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + yas_pool.get_tick_spacing() * IntegerTrait::<i32>::new(2, false),
                        max_tick - yas_pool.get_tick_spacing(),
                        max_liquidity_gross - 1000 + 1
                    );
            }

            #[test]
            #[available_gas(2000000000)]
            #[should_panic(expected: ('LO', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_fails_amount_at_tick_greater_than_max_3() {
                let (yas_pool, _, _, yas_router, min_tick, max_tick) = setup();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + yas_pool.get_tick_spacing(),
                        max_tick - yas_pool.get_tick_spacing(),
                        1000
                    );
                let max_liquidity_gross = yas_pool.get_max_liquidity_per_tick();

                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + yas_pool.get_tick_spacing(),
                        max_tick - yas_pool.get_tick_spacing() * IntegerTrait::<i32>::new(2, false),
                        max_liquidity_gross - 1000 + 1
                    );
            }

            #[test]
            #[available_gas(2000000000)]
            fn test_success_amount_at_tick_greater_than_max_4() {
                let (yas_pool, _, _, yas_router, min_tick, max_tick) = setup();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + yas_pool.get_tick_spacing(),
                        max_tick - yas_pool.get_tick_spacing(),
                        1000
                    );
                let max_liquidity_gross = yas_pool.get_max_liquidity_per_tick();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + yas_pool.get_tick_spacing(),
                        max_tick - yas_pool.get_tick_spacing(),
                        max_liquidity_gross - 1000
                    );
            }

            #[test]
            #[available_gas(2000000000)]
            #[should_panic(
                expected: (
                    'amount must be greater than 0', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'
                )
            )] //set panic code
            fn test_fails_amount_is_zero() {
                let (yas_pool, _, _, yas_router, min_tick, max_tick) = setup();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + yas_pool.get_tick_spacing(),
                        max_tick - yas_pool.get_tick_spacing(),
                        Zeroable::zero()
                    );
            }
        }

        mod SuccessCases {
            use super::{
                setup, MIN_TICK, MAX_TICK, tick_spacing, FeeAmount, fee_amount,
                IERC20DispatcherTrait, FACTORY_ADDRESS, TOKEN_A, TOKEN_B, WALLET, STATE,
                encode_price_sqrt_1_1
            };
            use super::super::{get_min_tick_and_max_tick};
            use yas_core::numbers::signed_integer::{
                i32::i32, i32::i32_div_no_round, integer_trait::IntegerTrait
            };
            use yas_core::contracts::yas_pool::{
                YASPool, YASPool::ContractState, YASPool::InternalImpl, IYASPool,
                IYASPoolDispatcher, IYASPoolDispatcherTrait
            };
            use yas_core::contracts::yas_router::{
                YASRouter, IYASRouterDispatcher, IYASRouterDispatcherTrait
            };

            #[test]
            #[available_gas(200000000)]
            fn test_initial_balances() {
                let (yas_pool, token_0, token_1, _, _, _) = setup();

                let balance_token_0 = token_0.balanceOf(yas_pool.contract_address);
                let balance_token_1 = token_1.balanceOf(yas_pool.contract_address);

                assert(balance_token_0 == 9996, 'wrong balance token 0');
                assert(balance_token_1 == 1000, 'wrong balance token 1');
            }

            #[test]
            #[available_gas(200000000)]
            fn test_initial_tick() {
                let (yas_pool, _, _, _, _, _) = setup();

                let tick = yas_pool.get_slot_0().tick;

                assert(tick == IntegerTrait::<i32>::new(23028, true), 'wrong initial tick');
            }

            mod AboveCurrentPrice {
                use yas_core::contracts::yas_pool::{IYASPoolDispatcherTrait};
                use super::{
                    get_min_tick_and_max_tick, setup, MIN_TICK, MAX_TICK, tick_spacing, FeeAmount,
                    fee_amount, IERC20DispatcherTrait, FACTORY_ADDRESS, TOKEN_A, TOKEN_B, WALLET,
                    encode_price_sqrt_1_1
                };
                use super::super::pow;
                use yas_core::numbers::signed_integer::{
                    i32::i32, i32::i32_div_no_round, integer_trait::IntegerTrait
                };

                use yas_core::contracts::yas_router::{
                    YASRouter, IYASRouterDispatcher, IYASRouterDispatcherTrait
                };
                use yas_core::libraries::tick::{Tick, Tick::TickImpl};

                #[test]
                #[available_gas(200000000)]
                fn test_transfers_token_0_only() {
                    let (yas_pool, token_0, token_1, yas_router, _, _) = setup();

                    yas_router
                        .mint(
                            yas_pool.contract_address,
                            WALLET(),
                            IntegerTrait::<i32>::new(22980, true),
                            Zeroable::zero(),
                            10000
                        );
                    assert(
                        token_0.balanceOf(yas_pool.contract_address) == 9996 + 21549,
                        'token_0 not transferred'
                    );
                    assert(
                        token_1.balanceOf(yas_pool.contract_address) == 1000, 'token_1 transferred'
                    );
                }

                #[test]
                #[available_gas(200000000)]
                fn test_max_tick_max_lvrg() {
                    let (yas_pool, token_0, token_1, yas_router, _, max_tick) = setup();
                    let big_number = pow(2, 102).try_into().unwrap();
                    yas_router
                        .mint(
                            yas_pool.contract_address,
                            WALLET(),
                            max_tick - yas_pool.get_tick_spacing(),
                            max_tick,
                            big_number
                        );

                    assert(
                        token_0.balanceOf(yas_pool.contract_address) == 9996 + 828011525,
                        'wrong token_0 amount'
                    );
                    assert(
                        token_1.balanceOf(yas_pool.contract_address) == 1000, 'wrong token_1 amount'
                    );
                }

                #[test]
                #[available_gas(200000000000)]
                fn test_max_tick() {
                    let (yas_pool, token_0, token_1, yas_router, _, max_tick) = setup();

                    yas_router
                        .mint(
                            yas_pool.contract_address,
                            WALLET(),
                            IntegerTrait::<i32>::new(22980, true),
                            max_tick,
                            10000
                        );
                    assert(
                        token_0.balanceOf(yas_pool.contract_address) == 9996 + 31549,
                        'wrong token_0 amount'
                    );
                    assert(
                        token_1.balanceOf(yas_pool.contract_address) == 1000, 'wrong token_1 amount'
                    );
                }

                // // WIP: test of 'removing works'
                // TODO: missing burn() func
                // https://github.com/Uniswap/v3-core/blob/main/test/UniswapV3Pool.spec.ts#L276
                // //#[test]
                // //#[available_gas(200000000)]
                // fn test_burn() {
                //     let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
                //     yas_router
                //         .mint(
                //             yas_pool.contract_address,
                //             WALLET(),
                //             IntegerTrait::<i32>::new(240, true),
                //             Zeroable::zero(),
                //             10000
                //         );
                //     //yas_pool.burn(-240, 0, 10000)
                //     assert(1 == 2, 'burn() function not created');
                // }

                #[test]
                #[available_gas(200000000)]
                fn test_add_liquidityGross() {
                    let (yas_pool, _, _, yas_router, _, _) = setup();
                    yas_router
                        .mint(
                            yas_pool.contract_address,
                            WALLET(),
                            IntegerTrait::<i32>::new(240, true),
                            Zeroable::zero(),
                            100
                        );

                    assert(
                        yas_pool
                            .get_tick(IntegerTrait::<i32>::new(240, true))
                            .liquidity_gross == 100,
                        'wrong liquidity_gross amount 1'
                    );
                    assert(
                        yas_pool.get_tick(Zeroable::zero()).liquidity_gross == 100,
                        'wrong liquidity_gross amount 2'
                    );
                    assert(
                        yas_pool.get_tick(yas_pool.get_tick_spacing()).liquidity_gross == 0,
                        'wrong liquidity_gross amount 3'
                    );
                    assert(
                        yas_pool
                            .get_tick(
                                IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM) * 2, false)
                            )
                            .liquidity_gross == 0,
                        'wrong liquidity_gross amount 4'
                    );

                    yas_router
                        .mint(
                            yas_pool.contract_address,
                            WALLET(),
                            IntegerTrait::<i32>::new(240, true),
                            yas_pool.get_tick_spacing(),
                            150
                        );

                    assert(
                        yas_pool
                            .get_tick(IntegerTrait::<i32>::new(240, true))
                            .liquidity_gross == 250,
                        'wrong liquidity_gross amount 5'
                    );
                    assert(
                        yas_pool.get_tick(Zeroable::zero()).liquidity_gross == 100,
                        'wrong liquidity_gross amount 6'
                    );
                    assert(
                        yas_pool.get_tick(yas_pool.get_tick_spacing()).liquidity_gross == 150,
                        'wrong liquidity_gross amount 7'
                    );
                    assert(
                        yas_pool
                            .get_tick(
                                IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM) * 2, false)
                            )
                            .liquidity_gross == 0,
                        'wrong liquidity_gross amount 8'
                    );

                    yas_router
                        .mint(
                            yas_pool.contract_address,
                            WALLET(),
                            Zeroable::zero(),
                            IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM) * 2, false),
                            60
                        );

                    assert(
                        yas_pool
                            .get_tick(IntegerTrait::<i32>::new(240, true))
                            .liquidity_gross == 250,
                        'wrong liquidity_gross amount 9'
                    );
                    assert(
                        yas_pool.get_tick(Zeroable::zero()).liquidity_gross == 160,
                        'wrong liquidity_gross amount 10'
                    );
                    assert(
                        yas_pool.get_tick(yas_pool.get_tick_spacing()).liquidity_gross == 150,
                        'wrong liquidity_gross amount 11'
                    );
                    assert(
                        yas_pool
                            .get_tick(
                                IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM) * 2, false)
                            )
                            .liquidity_gross == 60,
                        'wrong liquidity_gross amount 12'
                    );
                }
            // // WIP: test of 'removes liquidity from liquidityGross'
            // TODO: missing burn() func.
            // https://github.com/Uniswap/v3-core/blob/main/test/UniswapV3Pool.spec.ts#L302
            // //#[test]
            // //#[available_gas(200000000)]
            // fn test_remove_liquidityGross() {
            //     let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
            //     yas_router
            //         .mint(
            //             yas_pool.contract_address,
            //             WALLET(),
            //             IntegerTrait::<i32>::new(240, true),
            //             Zeroable::zero(),
            //             100
            //         );
            //     yas_router
            //         .mint(
            //             yas_pool.contract_address,
            //             WALLET(),
            //             IntegerTrait::<i32>::new(240, true),
            //             Zeroable::zero(),
            //             40
            //         );
            //     //burn
            //     assert(1 == 2, 'burn() func doesnt exist yet');
            //     assert(
            //         yas_pool.get_tick(IntegerTrait::<i32>::new(240, true)).liquidity_gross == 500,
            //         'wrong liquidity_gross amount'
            //     );
            //     assert(
            //         yas_pool.get_tick(Zeroable::zero()).liquidity_gross == 50,
            //         'wrong liquidity_gross amount 2'
            //     );
            // }

            // WIP: test of 'clears tick lower if last position is removed'
            // TODO: missing burn() func
            // https://github.com/Uniswap/v3-core/blob/main/test/UniswapV3Pool.spec.ts#L310
            // //#[test]
            // //#[available_gas(200000000)]
            // fn test_clear_tick_lower() {
            //     let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
            //     yas_router
            //         .mint(
            //             yas_pool.contract_address,
            //             WALLET(),
            //             IntegerTrait::<i32>::new(240, true),
            //             Zeroable::zero(),
            //             100
            //         );
            //     //burn
            //     assert(1 == 2, 'burn() func doesnt exist yet');
            //     let tick_info = yas_pool.get_tick(IntegerTrait::<i32>::new(240, true));
            //     assert(tick_info.liquidity_gross == 0, 'wrong liquidity_gross amount');
            //     assert(
            //         tick_info.fee_growth_outside_0X128 == 0, 'wrong fee_growth_outside_0X128'
            //     );
            //     assert(
            //         tick_info.fee_growth_outside_1X128 == 0, 'wrong fee_growth_outside_1X128'
            //     );
            //     assert(1 == 2, 'burn() func doesnt exist yet');
            // }

            // // WIP: test of 'clears tick upper if last position is removed'
            // // TODO: missing burn() func
            // https://github.com/Uniswap/v3-core/blob/main/test/UniswapV3Pool.spec.ts#L319
            // //#[test]
            // //#[available_gas(200000000)]
            // fn test_clear_tick_upper() {
            //     let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
            //     yas_router
            //         .mint(
            //             yas_pool.contract_address,
            //             WALLET(),
            //             IntegerTrait::<i32>::new(240, true),
            //             Zeroable::zero(),
            //             100
            //         );
            //     //burn
            //     assert(1 == 2, 'burn() func doesnt exist yet');
            //     let tick_info = yas_pool.get_tick(Zeroable::zero());
            //     assert(tick_info.liquidity_gross == 0, 'wrong liquidity_gross amount');
            //     assert(
            //         tick_info.fee_growth_outside_0X128 == 0, 'wrong fee_growth_outside_0X128'
            //     );
            //     assert(
            //         tick_info.fee_growth_outside_1X128 == 0, 'wrong fee_growth_outside_1X128'
            //     );
            // }

            // // WIP: test of 'only clears the tick that is not used at all'
            // // TODO: missing burn() func
            // https://github.com/Uniswap/v3-core/blob/main/test/UniswapV3Pool.spec.ts#L327
            // //#[test]
            // //#[available_gas(200000000)]
            // fn test_clear_tick_unused() {
            //     let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
            //     yas_router
            //         .mint(
            //             yas_pool.contract_address,
            //             WALLET(),
            //             IntegerTrait::<i32>::new(240, true),
            //             Zeroable::zero(),
            //             100
            //         );
            //     yas_router
            //         .mint(
            //             yas_pool.contract_address,
            //             WALLET(),
            //             IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), true),
            //             Zeroable::zero(),
            //             250
            //         );
            //     //burn
            //     assert(1 == 2, 'burn() func doesnt exist yet');
            //     let tick_info = yas_pool.get_tick(IntegerTrait::<i32>::new(240, true));
            //     assert(tick_info.liquidity_gross == 0, 'wrong liquidity_gross amount');
            //     assert(
            //         tick_info.fee_growth_outside_0X128 == 0, 'wrong fee_growth_outside_0X128'
            //     );
            //     assert(
            //         tick_info.fee_growth_outside_1X128 == 0, 'wrong fee_growth_outside_1X128'
            //     );
            //     let tick_info = yas_pool.get_tick(-yas_pool.get_tick_spacing());
            //     assert(tick_info.liquidity_gross == 250, 'wrong liquidity_gross amount');
            //     assert(
            //         tick_info.fee_growth_outside_0X128 == 0, 'wrong fee_growth_outside_0X128'
            //     );
            //     assert(
            //         tick_info.fee_growth_outside_1X128 == 0, 'wrong fee_growth_outside_1X128'
            //     );
            // }

            }

            mod IncludingCurrentPrice {
                use yas_core::contracts::yas_pool::{IYASPoolDispatcherTrait};
                use super::{
                    get_min_tick_and_max_tick, setup, tick_spacing, FeeAmount, fee_amount,
                    IERC20DispatcherTrait, WALLET
                };
                use yas_core::numbers::signed_integer::{
                    i32::i32, i32::i32_div_no_round, integer_trait::IntegerTrait
                };
                use yas_core::contracts::yas_router::{
                    YASRouter, IYASRouterDispatcher, IYASRouterDispatcherTrait
                };

                #[test]
                #[available_gas(200000000)]
                fn test_curr_price_both() {
                    let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
                    yas_router
                        .mint(
                            yas_pool.contract_address,
                            WALLET(),
                            min_tick + yas_pool.get_tick_spacing(),
                            max_tick - yas_pool.get_tick_spacing(),
                            100
                        );

                    assert(
                        token_0.balanceOf(yas_pool.contract_address) == 9996 + 317,
                        'token_0 wrong amount'
                    );
                    assert(
                        token_1.balanceOf(yas_pool.contract_address) == 1000 + 32,
                        'token_1 wrong amount'
                    );
                }

                #[test]
                #[available_gas(200000000)]
                fn test_init_lower_tick() {
                    let (yas_pool, _, _, yas_router, min_tick, max_tick) = setup();
                    yas_router
                        .mint(
                            yas_pool.contract_address,
                            WALLET(),
                            min_tick + yas_pool.get_tick_spacing(),
                            max_tick - yas_pool.get_tick_spacing(),
                            100
                        );

                    assert(
                        yas_pool
                            .get_tick(min_tick + yas_pool.get_tick_spacing())
                            .liquidity_gross == 100,
                        'wrong liquidity_gross amount 1'
                    );
                }

                #[test]
                #[available_gas(200000000)]
                fn test_init_upper_tick() {
                    let (yas_pool, _, _, yas_router, min_tick, max_tick) = setup();
                    yas_router
                        .mint(
                            yas_pool.contract_address,
                            WALLET(),
                            min_tick + yas_pool.get_tick_spacing(),
                            max_tick - yas_pool.get_tick_spacing(),
                            100
                        );
                    assert(
                        yas_pool
                            .get_tick(max_tick - yas_pool.get_tick_spacing())
                            .liquidity_gross == 100,
                        'wrong liquidity_gross amount 1'
                    );
                }

                #[test]
                #[available_gas(200000000)]
                fn test_min_max_tick() {
                    let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
                    yas_router.mint(yas_pool.contract_address, WALLET(), min_tick, max_tick, 10000);

                    assert(
                        token_0.balanceOf(yas_pool.contract_address) == 9996 + 31623,
                        'token_0 wrong amount'
                    );
                    assert(
                        token_1.balanceOf(yas_pool.contract_address) == 1000 + 3163,
                        'token_1 wrong amount'
                    );
                }
            // // WIP: test of 'removing works'
            // // TODO: missing burn() func
            // https://github.com/Uniswap/v3-core/blob/main/test/UniswapV3Pool.spec.ts#L393
            // //#[test]
            // //#[available_gas(200000000)]
            // fn test_remove() {
            //     let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
            //     yas_router
            //         .mint(
            //             yas_pool.contract_address,
            //             WALLET(),
            //             min_tick + yas_pool.get_tick_spacing(),
            //             max_tick - yas_pool.get_tick_spacing(),
            //             100
            //         );
            //     //yas_pool.burn()
            //     assert(1 == 2, 'missing burn() func');
            // }

            }

            mod BelowCurrentPrice {
                use yas_core::contracts::yas_pool::{IYASPoolDispatcherTrait};
                use super::{
                    get_min_tick_and_max_tick, setup, tick_spacing, FeeAmount, fee_amount,
                    IERC20DispatcherTrait, WALLET
                };
                use super::super::pow;
                use yas_core::numbers::signed_integer::{
                    i32::i32, i32::i32_div_no_round, integer_trait::IntegerTrait
                };
                use yas_core::contracts::yas_router::{
                    YASRouter, IYASRouterDispatcher, IYASRouterDispatcherTrait
                };

                #[test]
                #[available_gas(200000000)]
                fn test_below_only_token1() {
                    let (yas_pool, token_0, token_1, yas_router, _, _) = setup();
                    yas_router
                        .mint(
                            yas_pool.contract_address,
                            WALLET(),
                            IntegerTrait::<i32>::new(46080, true),
                            IntegerTrait::<i32>::new(23040, true),
                            10000
                        );

                    assert(
                        token_0.balanceOf(yas_pool.contract_address) == 9996, 'token_0 wrong amount'
                    );
                    assert(
                        token_1.balanceOf(yas_pool.contract_address) == 1000 + 2162,
                        'token_1 wrong amount'
                    );
                }

                #[test]
                #[available_gas(200000000)]
                fn test_below_maxtick_maxlvrg() {
                    let (yas_pool, token_0, token_1, yas_router, min_tick, _) = setup();
                    yas_router
                        .mint(
                            yas_pool.contract_address,
                            WALLET(),
                            min_tick,
                            min_tick + yas_pool.get_tick_spacing(),
                            pow(2, 102).try_into().unwrap()
                        );

                    assert(
                        token_0.balanceOf(yas_pool.contract_address) == 9996, 'token_0 wrong amount'
                    );
                    assert(
                        token_1.balanceOf(yas_pool.contract_address) == 1000 + 828011520,
                        'token_1 wrong amount'
                    );
                }

                #[test]
                #[available_gas(200000000)]
                fn test_below_min_tick() {
                    let (yas_pool, token_0, token_1, yas_router, min_tick, _) = setup();
                    yas_router
                        .mint(
                            yas_pool.contract_address,
                            WALLET(),
                            min_tick,
                            IntegerTrait::<i32>::new(23040, true),
                            10000
                        );

                    assert(
                        token_0.balanceOf(yas_pool.contract_address) == 9996, 'token_0 wrong amount'
                    );
                    assert(
                        token_1.balanceOf(yas_pool.contract_address) == 1000 + 3161,
                        'token_1 wrong amount'
                    );
                }
            // WIP: test of 'removing works'
            // TODO: missing burn() func
            // https://github.com/Uniswap/v3-core/blob/main/test/UniswapV3Pool.spec.ts#L449
            // #[test]
            // #[available_gas(200000000)]
            // fn test_below_remove() {
            //     let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
            //     yas_router
            //         .mint(
            //             yas_pool.contract_address,
            //             WALLET(),
            //             IntegerTrait::<i32>::new(46080, true),
            //             IntegerTrait::<i32>::new(46020, true),
            //             10000
            //         );
            //     //pool.burn()
            //     //assert(token_0.balanceOf(yas_pool.contract_address) == 0, 'token_0 wrong amount');
            //     //assert(token_1.balanceOf(yas_pool.contract_address) == 3, 'token_1 wrong amount');
            //     assert(1 == 2, 'no burn() function');
            // }

            }
        }
    // // WIP: test of 'protocol fees accumulate as expected during swap'
    // // TODO: missing setFeeProtocol() func
    // https://github.com/Uniswap/v3-core/blob/main/test/UniswapV3Pool.spec.ts#L482
    // //#[test]
    // //#[available_gas(200000000)]
    // fn test_protocol_fees_accum() {
    //let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
    //assert(1 == 2, 'no setFeeProtocol() function');
    // yas_router
    //     .mint(
    //         yas_pool.contract_address,
    //         WALLET(),
    //         min_tick + yas_pool.get_tick_spacing(),
    //         max_tick - yas_pool.get_tick_spacing(),
    //         1000000000000000000 //?
    //     );
    // }

    // // WIP: test of 'positions are protected before protocol fee is turned on'
    // // TODO: missing setFeeProtocol() func
    // https://github.com/Uniswap/v3-core/blob/main/test/UniswapV3Pool.spec.ts#L494
    // //#[test]
    // //#[available_gas(200000000)]
    // fn test_positions_protected() {
    //let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
    // yas_router
    //     .mint(
    //         yas_pool.contract_address,
    //         WALLET(),
    //         min_tick + yas_pool.get_tick_spacing(),
    //         max_tick - yas_pool.get_tick_spacing(),
    //         1000000000000000000 //?
    //     );
    //assert(1 == 2, 'no setFeeProtocol() function');
    // }

    // WIP: test of 'poke is not allowed on uninitialized position'
    //TODO: missing burn() func
    // https://github.com/Uniswap/v3-core/blob/main/test/UniswapV3Pool.spec.ts#L509
    // //#[test]
    // //#[available_gas(200000000)]
    // fn test_unallow_poke_on_uninit_pos() {
    //let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
    // yas_router
    //     .mint(
    //         yas_pool.contract_address,
    //         WALLET(),
    //         min_tick + yas_pool.get_tick_spacing(),
    //         max_tick - yas_pool.get_tick_spacing(),
    //         1000000000000000000 //?
    //     );
    //assert(1 == 2, 'no burn() function');
    // }

    }

    mod Swap {
        use super::{
            setup_with, setup_pool_for_swap_test, mint_positions, swap_test_case,
            round_for_price_comparison, calculate_execution_price, get_significant_figures
        };

        use yas_core::numbers::fixed_point::implementations::impl_64x96::{
            FP64x96Impl, FP64x96Sub, FP64x96PartialEq, FP64x96Zeroable, FixedType, FixedTrait
        };
        use yas_core::numbers::signed_integer::{i32::i32, i256::i256, integer_trait::IntegerTrait};
        use yas_core::contracts::yas_erc20::{
            ERC20, ERC20::ERC20Impl, IERC20Dispatcher, IERC20DispatcherTrait
        };
        use yas_core::contracts::yas_factory::{
            YASFactory, IYASFactory, IYASFactoryDispatcher, IYASFactoryDispatcherTrait
        };
        use yas_core::contracts::yas_router::{
            YASRouter, IYASRouterDispatcher, IYASRouterDispatcherTrait
        };
        use yas_core::tests::utils::constants::PoolConstants::{
            TOKEN_A, TOKEN_B, POOL_ADDRESS, WALLET
        };

        use yas_core::tests::utils::constants::FactoryConstants::{fee_amount, FeeAmount};

        use yas_core::contracts::yas_pool::{IYASPoolDispatcherTrait};

        use yas_core::tests::utils::swap_cases::{
            SwapTestHelper, SwapTestHelper::PoolTestCase, SwapTestHelper::SwapTestCase,
            SwapTestHelper::SwapExpectedResults, SwapTestHelper::{POOL_CASES, SWAP_CASES}
        };
        use integer::BoundedInt;

        use debug::PrintTrait;

        #[test]
        #[available_gas(200000000000)]
        fn test_swap_token_1_for_token_0() {
            let POSITIVE = false;
            // this price represent 1 ETH ~= 3019294,467836 USDC
            let INITIAL_PRICE = 45584610003121481572705762227159;

            let (yas_pool, yas_router, token_0, token_1) = setup_with(
                initial_price: FP64x96Impl::new(INITIAL_PRICE, POSITIVE),
                usdc_amount: 300000000000000, // 300000000000000 USDC
                eth_amount: 10000000000, // 10000000000 ETH
                mint_amount: 100000000000000000000000
            );

            // 1 ETH
            let eth_amount = IntegerTrait::<i256>::new(1000000000000000000, POSITIVE);

            // 3019294,467836 USDC
            let usdc_swapped_expected = 3019294467836;
            // 1 ETH
            let eth_swapped_expected = 1000000000000000000;

            // will trade ETH for USDC (USDC token_0, ETH token_1) so, ZFO false
            let zero_for_one = false;

            // When selling token 0 (zeroForOne is true) sqrtPriceLimitX96 must be
            // between the current price and the minimal sqrt(P) since selling token 0
            // moves the price down. Likewise, when selling token 1, sqrtPriceLimitX96
            // must be between the current price and the maximal sqrt(P) ​because price moves up.

            // In the while loop, we want to satisfy two conditions: full swap amount has not been
            // filled and current price isn’t equal to sqrtPriceLimitX96:
            let price_limit = FP64x96Impl::new(INITIAL_PRICE * 1000, POSITIVE);

            // Check balance before swap
            let user_token_0_balance_bf = token_0.balanceOf(WALLET());
            let user_token_1_balance_bf = token_1.balanceOf(WALLET());

            // Execute swap
            yas_router
                .swap(yas_pool.contract_address, WALLET(), zero_for_one, eth_amount, price_limit);

            // Check balance after swap
            let user_token_0_balance_af = token_0.balanceOf(WALLET());
            let user_token_1_balance_af = token_1.balanceOf(WALLET());

            assert(
                usdc_swapped_expected == user_token_0_balance_af - user_token_0_balance_bf,
                'wrong USDC swap amount'
            );
            assert(
                eth_swapped_expected == user_token_1_balance_bf - user_token_1_balance_af,
                'wrong ETH swap amount'
            );
        }

        #[test]
        #[available_gas(200000000000)]
        fn test_swap_token_0_for_token_1() {
            let POSITIVE = false;
            // this price represent 1 ETH ~= 3019294,467836 USDC
            let INITIAL_PRICE = 45584610003121481572705762227159;

            let (yas_pool, yas_router, token_0, token_1) = setup_with(
                initial_price: FP64x96Impl::new(INITIAL_PRICE, POSITIVE),
                usdc_amount: 300000000000000, // 300000000000000 USDC
                eth_amount: 10000000000, // 10000000000 ETH
                mint_amount: 100000000000000000000000
            );

            // 3019294,467836 USDC
            let usdc_amount = IntegerTrait::<i256>::new(3019293995782, POSITIVE);

            // 3019294,467836 USDC
            let usdc_swapped_expected = 3019293995782;
            // 0,999000059110060056 ETH
            let eth_swapped_expected = 999000059110060056;

            // will trade USDC for ETH (USDC token_0, ETH token_1) so, ZFO true
            let zero_for_one = true;

            // When selling token 0 (zeroForOne is true) sqrtPriceLimitX96 must be
            // between the current price and the minimal sqrt(P) since selling token 0
            // moves the price down. Likewise, when selling token 1, sqrtPriceLimitX96
            // must be between the current price and the maximal sqrt(P) ​because price moves up.

            // In the while loop, we want to satisfy two conditions: full swap amount has not been
            // filled and current price isn’t equal to sqrtPriceLimitX96:
            let price_limit = FP64x96Impl::new(INITIAL_PRICE / 1000, POSITIVE);

            // Check balance before swap
            let user_token_0_balance_bf = token_0.balanceOf(WALLET());
            let user_token_1_balance_bf = token_1.balanceOf(WALLET());

            // Execute swap
            yas_router
                .swap(yas_pool.contract_address, WALLET(), zero_for_one, usdc_amount, price_limit);

            // Check balance after swap
            let user_token_0_balance_af = token_0.balanceOf(WALLET());
            let user_token_1_balance_af = token_1.balanceOf(WALLET());

            assert(
                usdc_swapped_expected == user_token_0_balance_bf - user_token_0_balance_af,
                'wrong USDC swap amount'
            );
            assert(
                eth_swapped_expected == user_token_1_balance_af - user_token_1_balance_bf,
                'wrong ETH swap amount'
            );
        }

        mod PoolCase0 {
            use super::test_pool;
            use yas_core::tests::utils::pool_0::{SWAP_CASES_POOL_0, SWAP_EXPECTED_RESULTS_POOL_0};
            use yas_core::tests::utils::swap_cases::SwapTestHelper::POOL_CASES;
            use debug::PrintTrait;

            const PRECISION: u256 = 5;

            #[test]
            #[available_gas(200000000000)]
            fn test_pool_0_success_cases() {
                let pool_case = POOL_CASES()[0];
                let expected_cases = SWAP_EXPECTED_RESULTS_POOL_0();
                let (success_swap_cases, _) = SWAP_CASES_POOL_0();
                test_pool(pool_case, expected_cases, success_swap_cases, PRECISION);
            }


            #[test]
            #[available_gas(200000000000)]
            #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_pool_0_panics_0() {
                let PANIC_CASE = 0;
                let pool_case = POOL_CASES()[0];
                let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_0();
                let expected_cases =
                    SWAP_EXPECTED_RESULTS_POOL_0(); //get random case, is never executed
                test_pool(
                    pool_case,
                    array![*expected_cases[PANIC_CASE]],
                    array![*panic_swap_cases[PANIC_CASE]],
                    Zeroable::zero()
                );
            }

            #[test]
            #[available_gas(200000000000)]
            #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_pool_0_panics_1() {
                let PANIC_CASE = 1;
                let pool_case = POOL_CASES()[0];
                let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_0();
                let expected_cases =
                    SWAP_EXPECTED_RESULTS_POOL_0(); //get random case, is never executed
                test_pool(
                    pool_case,
                    array![*expected_cases[PANIC_CASE]],
                    array![*panic_swap_cases[PANIC_CASE]],
                    Zeroable::zero()
                );
            }
        }

        mod PoolCase1 {
            use super::test_pool;
            use yas_core::tests::utils::pool_1::{SWAP_CASES_POOL_1, SWAP_EXPECTED_RESULTS_POOL_1};
            use yas_core::tests::utils::swap_cases::SwapTestHelper::POOL_CASES;

            const PRECISION: u256 = 5;

            #[test]
            #[available_gas(200000000000)]
            fn test_pool_1_success_cases() {
                let pool_case = POOL_CASES()[1];
                let expected_cases = SWAP_EXPECTED_RESULTS_POOL_1();
                let (success_swap_cases, _) = SWAP_CASES_POOL_1();
                test_pool(pool_case, expected_cases, success_swap_cases, PRECISION);
            }

            #[test]
            #[available_gas(200000000000)]
            #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_pool_1_panics_0() {
                let PANIC_CASE = 0;
                let pool_case = POOL_CASES()[1];
                let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_1();
                let expected_cases = SWAP_EXPECTED_RESULTS_POOL_1();
                test_pool(
                    pool_case,
                    array![*expected_cases[PANIC_CASE]],
                    array![*panic_swap_cases[PANIC_CASE]],
                    Zeroable::zero()
                );
            }

            #[test]
            #[available_gas(200000000000)]
            #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_pool_1_panics_1() {
                let PANIC_CASE = 1;
                let pool_case = POOL_CASES()[1];
                let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_1();
                let expected_cases = SWAP_EXPECTED_RESULTS_POOL_1();
                test_pool(
                    pool_case,
                    array![*expected_cases[PANIC_CASE]],
                    array![*panic_swap_cases[PANIC_CASE]],
                    Zeroable::zero()
                );
            }
        }

        mod PoolCase2 {
            use super::test_pool;
            use yas_core::tests::utils::pool_2::{SWAP_CASES_POOL_2, SWAP_EXPECTED_RESULTS_POOL_2};
            use yas_core::tests::utils::swap_cases::SwapTestHelper::POOL_CASES;

            const PRECISION: u256 = 5;

            #[test]
            #[available_gas(200000000000)]
            fn test_pool_2_success_cases() {
                let pool_case = POOL_CASES()[2];
                let expected_cases = SWAP_EXPECTED_RESULTS_POOL_2();
                let (success_swap_cases, _) = SWAP_CASES_POOL_2();
                test_pool(pool_case, expected_cases, success_swap_cases, PRECISION);
            }

            #[test]
            #[available_gas(200000000000)]
            #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_pool_2_panics_0() {
                let PANIC_CASE = 0;
                let pool_case = POOL_CASES()[2];
                let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_2();
                let expected_cases = SWAP_EXPECTED_RESULTS_POOL_2();
                test_pool(
                    pool_case,
                    array![*expected_cases[PANIC_CASE]],
                    array![*panic_swap_cases[PANIC_CASE]],
                    Zeroable::zero()
                );
            }

            #[test]
            #[available_gas(200000000000)]
            #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_pool_2_panics_1() {
                let PANIC_CASE = 1;
                let pool_case = POOL_CASES()[2];
                let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_2();
                let expected_cases = SWAP_EXPECTED_RESULTS_POOL_2();
                test_pool(
                    pool_case,
                    array![*expected_cases[PANIC_CASE]],
                    array![*panic_swap_cases[PANIC_CASE]],
                    Zeroable::zero()
                );
            }
        }

        mod PoolCase4 {
            use super::test_pool;
            use yas_core::tests::utils::pool_4::{SWAP_CASES_POOL_4, SWAP_EXPECTED_RESULTS_POOL_4};
            use yas_core::tests::utils::swap_cases::SwapTestHelper::{POOL_CASES};
            use debug::PrintTrait;

            const PRECISION: u256 = 5;

            #[test]
            #[available_gas(200000000000)]
            fn test_pool_4_success_cases() {
                let pool_case = POOL_CASES()[4];
                let expected_cases = SWAP_EXPECTED_RESULTS_POOL_4();
                let (success_swap_cases, _) = SWAP_CASES_POOL_4();
                test_pool(pool_case, expected_cases, success_swap_cases, PRECISION);
            }

            #[test]
            #[available_gas(200000000000)]
            #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_pool_4_panics_0() {
                let PANIC_CASE = 0;
                let pool_case = POOL_CASES()[4];
                let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_4();
                let expected_cases =
                    SWAP_EXPECTED_RESULTS_POOL_4(); //get random case, is never executed
                test_pool(
                    pool_case,
                    array![*expected_cases[PANIC_CASE]],
                    array![*panic_swap_cases[PANIC_CASE]],
                    PRECISION
                );
            }
            #[test]
            #[available_gas(200000000000)]
            #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_pool_4_panics_1() { //done
                let PANIC_CASE = 1;
                let pool_case = POOL_CASES()[4];
                let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_4();
                let expected_cases =
                    SWAP_EXPECTED_RESULTS_POOL_4(); //get random case, is never executed
                test_pool(
                    pool_case,
                    array![*expected_cases[PANIC_CASE]],
                    array![*panic_swap_cases[PANIC_CASE]],
                    PRECISION
                );
            }
            #[test]
            #[available_gas(200000000000)]
            #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_pool_4_panics_2() {
                let PANIC_CASE = 2;
                let pool_case = POOL_CASES()[4];
                let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_4();
                let expected_cases =
                    SWAP_EXPECTED_RESULTS_POOL_4(); //get random case, is never executed
                test_pool(
                    pool_case,
                    array![*expected_cases[PANIC_CASE]],
                    array![*panic_swap_cases[PANIC_CASE]],
                    PRECISION
                );
            }
            #[test]
            #[available_gas(200000000000)]
            #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_pool_4_panics_3() {
                let PANIC_CASE = 3;
                let pool_case = POOL_CASES()[4];
                let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_4();
                let expected_cases =
                    SWAP_EXPECTED_RESULTS_POOL_4(); //get random case, is never executed
                test_pool(
                    pool_case,
                    array![*expected_cases[PANIC_CASE]],
                    array![*panic_swap_cases[PANIC_CASE]],
                    PRECISION
                );
            }
        }

        mod PoolCase5 {
            use super::test_pool;
            use yas_core::tests::utils::pool_5::{SWAP_CASES_POOL_5, SWAP_EXPECTED_RESULTS_POOL_5};
            use yas_core::tests::utils::swap_cases::SwapTestHelper::POOL_CASES;

            const PRECISION: u256 = 5;

            #[test]
            #[available_gas(200000000000)]
            fn test_pool_5_success_cases() {
                let pool_case = POOL_CASES()[5];
                let expected_cases = SWAP_EXPECTED_RESULTS_POOL_5();
                let (success_swap_cases, _) = SWAP_CASES_POOL_5();
                test_pool(pool_case, expected_cases, success_swap_cases, PRECISION);
            }

            #[test]
            #[available_gas(200000000000)]
            #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_pool_5_panics_0() {
                let PANIC_CASE = 0;
                let pool_case = POOL_CASES()[5];
                let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_5();
                let expected_cases = SWAP_EXPECTED_RESULTS_POOL_5();
                test_pool(
                    pool_case,
                    array![*expected_cases[PANIC_CASE]],
                    array![*panic_swap_cases[PANIC_CASE]],
                    PRECISION
                );
            }
            #[test]
            #[available_gas(200000000000)]
            #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_pool_5_panics_1() {
                let PANIC_CASE = 1;
                let pool_case = POOL_CASES()[5];
                let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_5();
                let expected_cases = SWAP_EXPECTED_RESULTS_POOL_5();
                test_pool(
                    pool_case,
                    array![*expected_cases[PANIC_CASE]],
                    array![*panic_swap_cases[PANIC_CASE]],
                    PRECISION
                );
            }
        }

        mod PoolCase6 {
            use super::test_pool;
            use yas_core::tests::utils::pool_6::{SWAP_CASES_POOL_6, SWAP_EXPECTED_RESULTS_POOL_6};
            use yas_core::tests::utils::swap_cases::SwapTestHelper::POOL_CASES;

            const PRECISION: u256 = 5;

            #[test]
            #[available_gas(200000000000)]
            fn test_pool_6_success_cases() {
                let pool_case = POOL_CASES()[6];
                let expected_cases = SWAP_EXPECTED_RESULTS_POOL_6();
                let (success_swap_cases, _) = SWAP_CASES_POOL_6();
                test_pool(pool_case, expected_cases, success_swap_cases, PRECISION);
            }

            #[test]
            #[available_gas(200000000000)]
            #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_pool_6_panics_0() {
                let PANIC_CASE = 0;
                let pool_case = POOL_CASES()[6];
                let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_6();
                let expected_cases =
                    SWAP_EXPECTED_RESULTS_POOL_6(); //get random case, is never executed
                test_pool(
                    pool_case,
                    array![*expected_cases[PANIC_CASE]],
                    array![*panic_swap_cases[PANIC_CASE]],
                    Zeroable::zero()
                );
            }

            #[test]
            #[available_gas(200000000000)]
            #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_pool_6_panics_1() {
                let PANIC_CASE = 1;
                let pool_case = POOL_CASES()[6];
                let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_6();
                let expected_cases =
                    SWAP_EXPECTED_RESULTS_POOL_6(); //get random case, is never executed
                test_pool(
                    pool_case,
                    array![*expected_cases[PANIC_CASE]],
                    array![*panic_swap_cases[PANIC_CASE]],
                    Zeroable::zero()
                );
            }
        }

        mod PoolCase9 {
            use super::test_pool;
            use yas_core::tests::utils::pool_9::{SWAP_CASES_POOL_9, SWAP_EXPECTED_RESULTS_POOL_9};
            use yas_core::tests::utils::swap_cases::SwapTestHelper::POOL_CASES;
            use debug::PrintTrait;

            const PRECISION: u256 = 5;

            #[test]
            #[available_gas(200000000000)]
            fn test_pool_9_success_cases() {
                let pool_case = POOL_CASES()[9];
                let expected_cases = SWAP_EXPECTED_RESULTS_POOL_9();
                let (success_swap_cases, _) = SWAP_CASES_POOL_9();
                test_pool(pool_case, expected_cases, success_swap_cases, PRECISION);
            }

            #[test]
            #[available_gas(200000000000)]
            #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_pool_9_panics_0() {
                let PANIC_CASE = 0;
                let pool_case = POOL_CASES()[9];
                let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_9();
                let expected_cases =
                    SWAP_EXPECTED_RESULTS_POOL_9(); //get random case, is never executed
                test_pool(
                    pool_case,
                    array![*expected_cases[PANIC_CASE]],
                    array![*panic_swap_cases[PANIC_CASE]],
                    Zeroable::zero()
                );
            }

            #[test]
            #[available_gas(200000000000)]
            #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_pool_9_panics_1() {
                let PANIC_CASE = 1;
                let pool_case = POOL_CASES()[9];
                let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_9();
                let expected_cases =
                    SWAP_EXPECTED_RESULTS_POOL_9(); //get random case, is never executed
                test_pool(
                    pool_case,
                    array![*expected_cases[PANIC_CASE]],
                    array![*panic_swap_cases[PANIC_CASE]],
                    Zeroable::zero()
                );
            }
        }

        fn test_pool(
            pool_case: @PoolTestCase,
            expected_cases: Array<SwapExpectedResults>,
            swap_cases: Array<SwapTestCase>,
            precision_required: u256,
        ) {
            let mut i = 0;
            assert(expected_cases.len() == swap_cases.len(), 'wrong amount of expected cases');
            loop {
                if i == expected_cases.len() {
                    break;
                }
                'case'.print();
                // restart Pool
                let (yas_pool, yas_router, token_0, token_1) = setup_pool_for_swap_test(
                    initial_price: *pool_case.starting_price,
                    fee_amount: *pool_case.fee_amount,
                    mint_positions: pool_case.mint_positions,
                );
                let swap_case = swap_cases[i];
                let expected = expected_cases[i];

                // Save values before swap for compare
                let user_token_0_balance_bf = token_0.balanceOf(WALLET());
                let user_token_1_balance_bf = token_1.balanceOf(WALLET());
                let (fee_growth_global_0_X128_bf, fee_growth_global_1_X128_bf) = yas_pool
                    .get_fee_growth_globals();

                let pool_balance_0_bf = token_0.balanceOf(yas_pool.contract_address);
                let pool_balance_1_bf = token_1.balanceOf(yas_pool.contract_address);
                let slot0_bf = yas_pool.get_slot_0();

                let mut amount_to_swap = IntegerTrait::<i256>::new(0, false); //Zeroable::zero();
                if *swap_case.has_exact_out {
                    if *swap_case.exact_out { //exact OUT
                        amount_to_swap =
                            IntegerTrait::<i256>::new(
                                *swap_case.amount_specified.mag, true
                            ); //swap(-x) when amount=amount_out
                    } else { //exact IN, normal swap.
                        amount_to_swap = *swap_case
                            .amount_specified; //swap(x) when amount=amount_in
                    }
                } else {
                    amount_to_swap = IntegerTrait::<i256>::new((BoundedInt::max() / 2) - 1, false);
                }
                // Execute swap
                let (token_0_swapped_amount, token_1_swapped_amount) = swap_test_case(
                    yas_router,
                    yas_pool,
                    token_0,
                    token_1,
                    *swap_case.zero_for_one,
                    amount_to_swap,
                    *swap_case.sqrt_price_limit
                );

                // Save values after swap to get deltas
                let (fee_growth_global_0_X128_af, fee_growth_global_1_X128_af) = yas_pool
                    .get_fee_growth_globals();

                let user_token_0_balance_af = token_0.balanceOf(WALLET());
                let user_token_1_balance_af = token_1.balanceOf(WALLET());
                let (fee_growth_global_0_X128_af, fee_growth_global_1_X128_af) = yas_pool
                    .get_fee_growth_globals();
                let (fee_growth_global_0_X128_delta, fee_growth_global_1_X128_delta) = (
                    fee_growth_global_0_X128_af - fee_growth_global_0_X128_bf,
                    fee_growth_global_1_X128_af - fee_growth_global_1_X128_bf
                );
                let slot0_af = yas_pool.get_slot_0();

                // Generate swap result values to compare with expected
                let (fee_growth_global_0_X128_delta, fee_growth_global_1_X128_delta) = (
                    fee_growth_global_0_X128_af - fee_growth_global_0_X128_bf,
                    fee_growth_global_1_X128_af - fee_growth_global_1_X128_bf
                );
                let execution_price = calculate_execution_price(
                    token_0_swapped_amount, token_1_swapped_amount
                );

                let pool_balance_0_af = token_0.balanceOf(yas_pool.contract_address);
                let pool_balance_1_af = token_1.balanceOf(yas_pool.contract_address);

                // let pool_price_bf = round_for_price_comparison(slot0_bf.sqrt_price_X96.mag, *expected.pool_price_before);
                // let pool_price_af = round_for_price_comparison(slot0_af.sqrt_price_X96.mag, *expected.pool_price_after);

                let pool_price_bf = slot0_bf.sqrt_price_X96.mag;
                let pool_price_af = slot0_af.sqrt_price_X96.mag;

                let tick_bf = slot0_bf.tick;
                let tick_af = slot0_af.tick;

                let actual = SwapExpectedResults {
                    amount_0_before: pool_balance_0_bf,
                    amount_0_delta: IntegerTrait::<i256>::new(pool_balance_0_af, false)
                        - IntegerTrait::<i256>::new(pool_balance_0_bf, false),
                    amount_1_before: pool_balance_1_bf,
                    amount_1_delta: IntegerTrait::<i256>::new(pool_balance_1_af, false)
                        - IntegerTrait::<i256>::new(pool_balance_1_bf, false),
                    execution_price: execution_price,
                    fee_growth_global_0_X128_delta: fee_growth_global_0_X128_delta,
                    fee_growth_global_1_X128_delta: fee_growth_global_1_X128_delta,
                    pool_price_after: pool_price_af,
                    pool_price_before: pool_price_bf,
                    tick_after: tick_af,
                    tick_before: tick_bf,
                };

                assert_swap_result_equals(actual, expected, precision_required);
                i += 1;
            };
        }

        fn assert_swap_result_equals(
            actual: SwapExpectedResults, expected: @SwapExpectedResults, precision: u256
        ) {
            //very useful for debugging, don't delete until all pools are finished:
            'amount_0_delta'.print();
            actual.amount_0_delta.mag.print();

            // 'amount_1_delta'.print();
            // actual.amount_1_delta.mag.print();

            'execution_price'.print();
            get_significant_figures(actual.execution_price, 10).print();
            get_significant_figures(*expected.execution_price, 10).print();
            // 'fee_growth_global_0_X128_delta'.print();
            // actual.fee_growth_global_0_X128_delta.print();
            // 'fee_growth_global_1_X128_delta'.print();
            // actual.fee_growth_global_1_X128_delta.print();

            // 'pool_price_before'.print();
            // actual.pool_price_before.print();
            // 'pool_price_after'.print();
            // get_significant_figures(actual.pool_price_after, pool_price_sig_figures).print();
            // get_significant_figures(*expected.pool_price_after, pool_price_sig_figures).print();

            // 'pool_price_before'.print();
            // actual.pool_price_before.print();
            // 'pool_price_after'.print();
            // actual.pool_price_after.print();

            // 'tick_after'.print();
            // actual.tick_after.mag.print();
            // '-'.print();

            assert(actual.amount_0_before == *expected.amount_0_before, 'wrong amount_0_before');
            assert(actual.amount_0_delta == *expected.amount_0_delta, 'wrong amount_0_delta');
            assert(actual.amount_1_before == *expected.amount_1_before, 'wrong amount_1_before');
            assert(actual.amount_1_delta == *expected.amount_1_delta, 'wrong amount_1_delta');

            //13 SF in x96 is way more accurate than uniswap precision
            assert(
                get_significant_figures(
                    actual.execution_price, 10
                ) == get_significant_figures(*expected.execution_price, 10),
                'wrong execution_price'
            );

            assert(
                actual.fee_growth_global_0_X128_delta == *expected.fee_growth_global_0_X128_delta,
                'wrong fee_growth_global_0_X128'
            );
            assert(
                actual.fee_growth_global_1_X128_delta == *expected.fee_growth_global_1_X128_delta,
                'wrong fee_growth_global_1_X128'
            );
            assert(
                actual.pool_price_before == *expected.pool_price_before, 'wrong pool_price_before'
            );
            //could add a significant figures comparison here to accept some degree of error
            assert(
                get_significant_figures(
                    actual.pool_price_after, precision
                ) == get_significant_figures(*expected.pool_price_after, precision),
                'wrong pool_price_after'
            );

            assert(actual.tick_after == *expected.tick_after, 'wrong tick_after');
            assert(actual.tick_before == *expected.tick_before, 'wrong tick_before');
        }
    }

    mod Burn {
        use super::{setup, get_min_tick_and_max_tick};

        use core::zeroable::Zeroable;
        use yas_core::contracts::yas_pool::YASPool::InternalTrait;
        use super::{deploy, mock_contract_states};

        use starknet::{ContractAddress, ClassHash, SyscallResultTrait, contract_address_const};
        use starknet::syscalls::deploy_syscall;
        use starknet::testing::{set_contract_address, set_caller_address};

        use yas_core::contracts::yas_pool::{
            YASPool, YASPool::ContractState, YASPool::YASPoolImpl, YASPool::InternalImpl, IYASPool,
            IYASPoolDispatcher, IYASPoolDispatcherTrait
        };
        use yas_core::contracts::yas_factory::{
            YASFactory, IYASFactory, IYASFactoryDispatcher, IYASFactoryDispatcherTrait
        };
        use yas_core::contracts::yas_router::{
            YASRouter, IYASRouterDispatcher, IYASRouterDispatcherTrait
        };
        use yas_core::numbers::fixed_point::implementations::impl_64x96::{
            FP64x96Impl, FixedType, FixedTrait
        };
        use yas_core::libraries::tick::{Tick, Tick::TickImpl};
        use yas_core::libraries::tick_math::{TickMath::MIN_TICK, TickMath::MAX_TICK};
        use yas_core::libraries::position::{Info, Position, Position::PositionImpl, PositionKey};
        use yas_core::tests::utils::constants::PoolConstants::{TOKEN_A, TOKEN_B, WALLET, OTHER};
        use yas_core::tests::utils::constants::FactoryConstants::{
            FeeAmount, fee_amount, tick_spacing
        };
        use yas_core::libraries::tick_math::TickMath::{MAX_SQRT_RATIO, MIN_SQRT_RATIO};
        use yas_core::contracts::yas_erc20::{ERC20, ERC20::ERC20Impl, IERC20Dispatcher};
        use yas_core::numbers::signed_integer::{
            i32::i32, i32::i32_div_no_round, i256::i256, integer_trait::IntegerTrait
        };

        fn swap_exact_0_for_1(
            yas_router: IYASRouterDispatcher,
            yas_pool: ContractAddress,
            amount: u256,
            to: ContractAddress
        ) {
            let sqrt_price_X96 = FixedTrait::new(MIN_SQRT_RATIO + 1, false);
            yas_router.swap(yas_pool, to, true, amount.into(), sqrt_price_X96);
        }

        fn swap_exact_1_for_0(
            yas_router: IYASRouterDispatcher,
            yas_pool: ContractAddress,
            amount: u256,
            to: ContractAddress
        ) {
            let sqrt_price_X96 = FP64x96Impl::new(MAX_SQRT_RATIO - 1, false);
            yas_router.swap(yas_pool, to, false, amount.into(), sqrt_price_X96);
        }

        fn check_tick_is_clear(yas_pool: IYASPoolDispatcher, tick: i32) {
            let tick_info = yas_pool.get_tick(tick);
            assert(tick_info.liquidity_gross == 0, 'wrong liquidity_gross');
            assert(tick_info.fee_growth_outside_0X128 == 0, 'wrong fee_growth_outside_0X128');
            assert(tick_info.fee_growth_outside_1X128 == 0, 'wrong fee_growth_outside_1X128');
            assert(tick_info.liquidity_net.is_zero(), 'wrong liquidity_net');
        }

        fn check_tick_is_not_clear(yas_pool: IYASPoolDispatcher, tick: i32) {
            let tick_info = yas_pool.get_tick(tick);
            assert(tick_info.liquidity_gross != 0, 'wrong liquidity_gross');
        }

        #[test]
        #[available_gas(200000000000)]
        fn test_does_not_clear_the_position_fee_growth_snapshot_if_no_more_liquidity() {
            let (yas_pool, _, _, yas_router, min_tick, max_tick) = setup();
            yas_router
                .mint(yas_pool.contract_address, OTHER(), min_tick, max_tick, 1000000000000000000);
            swap_exact_0_for_1(
                yas_router, yas_pool.contract_address, 1000000000000000000, WALLET()
            );
            swap_exact_1_for_0(
                yas_router, yas_pool.contract_address, 1000000000000000000, WALLET()
            );
            set_contract_address(OTHER());
            yas_pool.burn(min_tick, max_tick, 1000000000000000000);

            let info_position = yas_pool
                .get_position(
                    PositionKey { owner: OTHER(), tick_lower: min_tick, tick_upper: max_tick }
                );

            assert(info_position.liquidity == 0, 'wrong liquidity');
            assert(info_position.tokens_owed_0 != 0, 'wrong tokens_owed_0');
            assert(info_position.tokens_owed_1 != 0, 'wrong tokens_owed_1');
        // TODO: Uncomment when the swap has tests. Right now it looks like there is a difference in the returned fee value
        // assert(
        //     info_position.fee_growth_inside_0_last_X128 == 340282366920938463463374607431768211,
        //     'wrong fee_growth_ins_0_lastX128'
        // );
        // assert(
        //     info_position.fee_growth_inside_1_last_X128 == 340282366920938576890830247744589365,
        //     'wrong fee_growth_ins_1_lastX128'
        // );
        }

        #[test]
        #[available_gas(200000000000)]
        fn test_clears_the_tick_if_its_the_last_position_using_it() {
            let (yas_pool, _, _, yas_router, min_tick, max_tick) = setup();
            let tick_spacing = IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false);
            let tick_lower = min_tick + tick_spacing;
            let tick_upper = max_tick - tick_spacing;
            yas_router.mint(yas_pool.contract_address, WALLET(), tick_lower, tick_upper, 1);
            swap_exact_0_for_1(
                yas_router, yas_pool.contract_address, 1000000000000000000, WALLET()
            );

            set_contract_address(WALLET());
            yas_pool.burn(tick_lower, tick_upper, 1);

            check_tick_is_clear(yas_pool, tick_lower);
            check_tick_is_clear(yas_pool, tick_upper);
        }

        #[test]
        #[available_gas(200000000000)]
        fn test_clears_only_the_lower_tick_if_upper_is_still_used() {
            let (yas_pool, _, _, yas_router, min_tick, max_tick) = setup();
            let tick_spacing = IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false);
            let tick_lower = min_tick + tick_spacing;
            let tick_upper = max_tick - tick_spacing;
            yas_router.mint(yas_pool.contract_address, WALLET(), tick_lower, tick_upper, 1);
            yas_router
                .mint(
                    yas_pool.contract_address, WALLET(), tick_lower + tick_spacing, tick_upper, 1
                );
            swap_exact_0_for_1(
                yas_router, yas_pool.contract_address, 1000000000000000000, WALLET()
            );

            set_contract_address(WALLET());
            yas_pool.burn(tick_lower, tick_upper, 1);

            check_tick_is_clear(yas_pool, tick_lower);
            check_tick_is_not_clear(yas_pool, tick_upper);
        }

        #[test]
        #[available_gas(200000000000)]
        fn test_clears_only_the_upper_tick_if_lower_is_still_used() {
            let (yas_pool, _, _, yas_router, min_tick, max_tick) = setup();
            let tick_spacing = IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false);
            let tick_lower = min_tick + tick_spacing;
            let tick_upper = max_tick - tick_spacing;
            yas_router.mint(yas_pool.contract_address, WALLET(), tick_lower, tick_upper, 1);
            yas_router
                .mint(
                    yas_pool.contract_address, WALLET(), tick_lower, tick_upper - tick_spacing, 1
                );
            swap_exact_0_for_1(
                yas_router, yas_pool.contract_address, 1000000000000000000, WALLET()
            );

            set_contract_address(WALLET());
            yas_pool.burn(tick_lower, tick_upper, 1);

            check_tick_is_not_clear(yas_pool, tick_lower);
            check_tick_is_clear(yas_pool, tick_upper);
        }
    }

    // YASPool mint() aux functions
    use starknet::{ClassHash, SyscallResultTrait};
    use starknet::testing::{set_contract_address, set_caller_address};

    use yas_core::contracts::yas_factory::{
        YASFactory, IYASFactory, IYASFactoryDispatcher, IYASFactoryDispatcherTrait
    };
    use yas_core::libraries::tick_math::{TickMath::MIN_TICK, TickMath::MAX_TICK};
    use yas_core::numbers::fixed_point::implementations::impl_64x96::{
        FP64x96Impl, FixedType, FixedTrait, FP64x96Zeroable
    };

    use yas_core::contracts::yas_router::{
        YASRouter, IYASRouterDispatcher, IYASRouterDispatcherTrait
    };
    use yas_core::tests::utils::constants::PoolConstants::{
        TOKEN_A, TOKEN_B, POOL_ADDRESS, WALLET, encode_price_sqrt_1_1, encode_price_sqrt_1_10
    };
    use yas_core::tests::utils::constants::FactoryConstants::{
        POOL_CLASS_HASH, FeeAmount, fee_amount, tick_spacing
    };
    use yas_core::contracts::yas_erc20::{
        ERC20, ERC20::ERC20Impl, IERC20Dispatcher, IERC20DispatcherTrait
    };
    use yas_core::numbers::signed_integer::{i256::i256};
    use yas_core::libraries::tick_math::TickMath::{MAX_SQRT_RATIO, MIN_SQRT_RATIO};
    use yas_core::utils::math_utils::{
        FullMath::{div_rounding_up, mul_div, mul_div_rounding_up}, pow
    };

    use yas_core::tests::utils::swap_cases::SwapTestHelper;

    use debug::PrintTrait;


    fn setup() -> (
        IYASPoolDispatcher, IERC20Dispatcher, IERC20Dispatcher, IYASRouterDispatcher, i32, i32
    ) {
        let yas_router: IYASRouterDispatcher = deploy_yas_router(); // 0x1
        let yas_factory: IYASFactoryDispatcher = deploy_factory(OWNER(), POOL_CLASS_HASH()); // 0x2

        // Deploy ERC20 tokens with factory address
        let token_0 = deploy_erc20('YAS0', '$YAS0', BoundedInt::max(), OWNER()); // 0x3
        let token_1 = deploy_erc20('YAS1', '$YAS1', BoundedInt::max(), OWNER()); // 0x4

        set_contract_address(OWNER());
        token_0.transfer(WALLET(), BoundedInt::max());
        token_1.transfer(WALLET(), BoundedInt::max());

        // Give permissions to expend WALLET() tokens
        set_contract_address(WALLET());
        token_1.approve(yas_router.contract_address, BoundedInt::max());
        token_0.approve(yas_router.contract_address, BoundedInt::max());

        let yas_pool_address = yas_factory // 0x5
            .create_pool(
                token_0.contract_address, token_1.contract_address, fee_amount(FeeAmount::MEDIUM)
            );
        let yas_pool = IYASPoolDispatcher { contract_address: yas_pool_address };

        set_contract_address(OWNER());
        yas_pool.initialize(encode_price_sqrt_1_10());

        let (min_tick, max_tick) = get_min_tick_and_max_tick();
        set_contract_address(WALLET());
        yas_router.mint(yas_pool_address, WALLET(), min_tick, max_tick, 3161);

        (yas_pool, token_0, token_1, yas_router, min_tick, max_tick)
    }

    fn setup_with(
        initial_price: FixedType, usdc_amount: u256, eth_amount: u256, mint_amount: u128
    ) -> (IYASPoolDispatcher, IYASRouterDispatcher, IERC20Dispatcher, IERC20Dispatcher) {
        let yas_router = deploy_yas_router(); // 0x1
        let yas_factory = deploy_factory(OWNER(), POOL_CLASS_HASH()); // 0x2

        // Deploy ERC20 tokens with factory address
        // in testnet TOKEN0 is USDC and TOKEN1 is ETH
        let USDC = 1000000 * usdc_amount;
        let ETH = 1000000000000000000 * eth_amount;
        let token_0 = deploy_erc20('USDC', 'USDC', USDC, OWNER()); // 0x3 // 100k usdc (100k * 10^6)
        let token_1 = deploy_erc20('ETH', 'ETH', ETH, OWNER()); // 0x4 // 50 ETH (50 * 10^18)

        set_contract_address(OWNER());
        token_0.transfer(WALLET(), USDC);
        token_1.transfer(WALLET(), ETH);

        // Give permissions to expend WALLET() tokens
        set_contract_address(WALLET());
        token_1.approve(yas_router.contract_address, BoundedInt::max());
        token_0.approve(yas_router.contract_address, BoundedInt::max());

        let yas_pool_address = yas_factory // 0x5
            .create_pool(
                token_0.contract_address, token_1.contract_address, fee_amount(FeeAmount::LOW)
            );
        let yas_pool = IYASPoolDispatcher { contract_address: yas_pool_address };

        set_contract_address(OWNER());
        yas_pool.initialize(initial_price);

        let (min_tick, max_tick) = get_min_tick_and_max_tick();

        set_contract_address(WALLET());
        yas_router.mint(yas_pool_address, WALLET(), min_tick, max_tick, mint_amount);

        (yas_pool, yas_router, token_0, token_1)
    }

    fn calculate_execution_price(
        token_0_swapped_amount: u256, token_1_swapped_amount: u256
    ) -> u256 {
        if token_0_swapped_amount == 0
            && token_1_swapped_amount == 0 { //this avoids 0/0 , if no tokens swapped: exec_price = 0
            0
        } else if token_0_swapped_amount == 0 { //this avoids x/0 , case that makes price tend to Infinity
            '-Infinity'
                .into() //Since uniswap divides deltas to calculate exec_price, all prices are multiplied by -1 so that all prices are > 0. Therefore, this value ends up as -Infinity 
        } else { //this is every other case, price = 0/x = 0, or price = x/y = z
            let mut unrounded = (token_1_swapped_amount * pow(2, 96)) / token_0_swapped_amount;
            unrounded
        }
    }

    fn get_significant_figures(number: u256, sig_figures: u256) -> u256 {
        let order = get_order_of_magnitude(number);
        let mut my_number = number;
        if sig_figures >= order {
            number
        } else {
            let rounder = pow(10, order - sig_figures);
            let mid_point = (rounder / 2) - 1;
            let round_decider = number % rounder;
            if round_decider > mid_point {
                // my_number = number + (rounder - round_decider);
                number + (rounder - round_decider)
            } else {
                // my_number = number - round_decider;
                number - round_decider
            }
        // (number / pow(10, order - sig_figures) ) * pow(10, order - sig_figures)
        }
    }

    fn get_order_of_magnitude(number: u256) -> u256 {
        let mut order = 0;
        let mut my_number = number;
        loop {
            if my_number >= 1 {
                my_number = my_number / 10;
                order = order + 1;
            } else {
                break;
            };
        };
        order
    }

    fn round_for_price_comparison(sqrt_price_X96: u256, expected_price: u256) -> u256 {
        let mut square = (sqrt_price_X96 * sqrt_price_X96);
        let mut i = 0;
        let mut move_decimal_point = 0;
        let mut in_decimal = 0;
        loop {
            move_decimal_point = mul_div(square, pow(10, i), pow(2, 96));
            in_decimal = move_decimal_point / pow(2, 96);
            if in_decimal < (expected_price * 10) - 1 {
                i = i + 1;
            } else {
                break;
            };
        };

        let (rounder, half) = if in_decimal > 999999 {
            (100, 49)
        } else {
            (10, 4)
        };
        let round_decider = in_decimal % rounder;
        if round_decider > half {
            //round up
            in_decimal = in_decimal + (rounder - round_decider);
        } else {
            //round down
            in_decimal = in_decimal - round_decider;
        }
        in_decimal / 10
    }

    fn swap_test_case(
        yas_router: IYASRouterDispatcher,
        yas_pool: IYASPoolDispatcher,
        token_0: IERC20Dispatcher,
        token_1: IERC20Dispatcher,
        zero_for_one: bool,
        amount_specified: i256,
        sqrt_price_limit: FixedType
    ) -> (u256, u256) {
        let NEGATIVE = true;
        let POSITIVE = false;
        let sqrt_price_limit_usable = if !sqrt_price_limit.is_zero() {
            sqrt_price_limit
        } else {
            if zero_for_one {
                FP64x96Impl::new(MIN_SQRT_RATIO + 1, POSITIVE)
            } else {
                FP64x96Impl::new(MAX_SQRT_RATIO - 1, POSITIVE)
            }
        };

        let user_token_0_balance_bf = token_0.balanceOf(WALLET());
        let user_token_1_balance_bf = token_1.balanceOf(WALLET());

        yas_router
            .swap(
                yas_pool.contract_address,
                WALLET(),
                zero_for_one,
                amount_specified,
                sqrt_price_limit_usable
            );

        let user_token_0_balance_af = token_0.balanceOf(WALLET());
        let user_token_1_balance_af = token_1.balanceOf(WALLET());

        let (token_0_swapped_amount, token_1_swapped_amount) = if zero_for_one {
            (
                user_token_0_balance_bf - user_token_0_balance_af,
                user_token_1_balance_af - user_token_1_balance_bf
            )
        } else {
            (
                user_token_0_balance_af - user_token_0_balance_bf,
                user_token_1_balance_bf - user_token_1_balance_af
            )
        };

        (token_0_swapped_amount, token_1_swapped_amount)
    }

    fn setup_pool_for_swap_test(
        initial_price: FixedType, fee_amount: u32, mint_positions: @Array<SwapTestHelper::Position>,
    ) -> (IYASPoolDispatcher, IYASRouterDispatcher, IERC20Dispatcher, IERC20Dispatcher) {
        let yas_router = deploy_yas_router(); // 0x1
        let yas_factory = deploy_factory(OWNER(), POOL_CLASS_HASH()); // 0x2

        // Deploy ERC20 tokens with factory address
        // in testnet TOKEN0 is USDC and TOKEN1 is ETH
        let token_0 = deploy_erc20('USDC', 'USDC', BoundedInt::max(), OWNER()); // 0x3
        let token_1 = deploy_erc20('ETH', 'ETH', BoundedInt::max(), OWNER()); // 0x4

        set_contract_address(OWNER());
        token_0.transfer(WALLET(), BoundedInt::max());
        token_1.transfer(WALLET(), BoundedInt::max());

        // Give permissions to expend WALLET() tokens
        set_contract_address(WALLET());
        token_1.approve(yas_router.contract_address, BoundedInt::max());
        token_0.approve(yas_router.contract_address, BoundedInt::max());

        let yas_pool_address = yas_factory // 0x5
            .create_pool(token_0.contract_address, token_1.contract_address, fee_amount);
        let yas_pool = IYASPoolDispatcher { contract_address: yas_pool_address };

        set_contract_address(OWNER());
        yas_pool.initialize(initial_price);

        set_contract_address(WALLET());

        mint_positions(yas_router, yas_pool_address, mint_positions);

        (yas_pool, yas_router, token_0, token_1)
    }

    fn mint_positions(
        yas_router: IYASRouterDispatcher,
        yas_pool_address: ContractAddress,
        mint_positions: @Array<SwapTestHelper::Position>
    ) {
        let mut i = 0;
        loop {
            if i == mint_positions.len() {
                break;
            }
            let position = *mint_positions[i];
            yas_router
                .mint(
                    yas_pool_address,
                    WALLET(),
                    position.tick_lower,
                    position.tick_upper,
                    position.liquidity
                );
            i += 1;
        };
    }

    fn deploy_erc20(
        name: felt252, symbol: felt252, initial_supply: u256, recipent: ContractAddress
    ) -> IERC20Dispatcher {
        let mut calldata = array![name, symbol];
        Serde::serialize(@initial_supply, ref calldata);
        calldata.append(recipent.into());

        let (address, _) = deploy_syscall(
            ERC20::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), true
        )
            .unwrap_syscall();

        return IERC20Dispatcher { contract_address: address };
    }

    fn deploy_yas_router() -> IYASRouterDispatcher {
        let (address, _) = deploy_syscall(
            YASRouter::TEST_CLASS_HASH.try_into().unwrap(), 0, array![].span(), true
        )
            .unwrap_syscall();

        return IYASRouterDispatcher { contract_address: address };
    }

    fn deploy_factory(
        deployer: ContractAddress, pool_class_hash: ClassHash
    ) -> IYASFactoryDispatcher {
        let (address, _) = deploy_syscall(
            YASFactory::TEST_CLASS_HASH.try_into().unwrap(),
            0,
            array![deployer.into(), pool_class_hash.into()].span(),
            true
        )
            .unwrap_syscall();

        return IYASFactoryDispatcher { contract_address: address };
    }

    fn get_min_tick_and_max_tick() -> (i32, i32) {
        let tick_spacing = IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false);
        let min_tick = i32_div_no_round(MIN_TICK(), tick_spacing) * tick_spacing;
        let max_tick = i32_div_no_round(MAX_TICK(), tick_spacing) * tick_spacing;
        (min_tick, max_tick)
    }

    fn get_min_tick_and_max_tick_with_fee(fee_amount: u32) -> (i32, i32) {
        let tick_spacing = IntegerTrait::<i32>::new(fee_amount, false);
        let min_tick = i32_div_no_round(MIN_TICK(), tick_spacing) * tick_spacing;
        let max_tick = i32_div_no_round(MAX_TICK(), tick_spacing) * tick_spacing;
        (min_tick, max_tick)
    }

    // YASPool update_position() aux functions
    fn init_default(ref pool_state: ContractState) {
        pool_state.set_fee(500);
        pool_state.set_tick_spacing(IntegerTrait::<i32>::new(1, false));
        pool_state.set_max_liquidity_per_tick(BoundedInt::max());
        pool_state.set_fee_growth_globals(0, 0);
    }

    fn mock_contract_states() -> (
        YASPool::ContractState, Position::ContractState, Tick::ContractState
    ) {
        let position_state = YASPool::InternalImpl::get_position_state(
            YASPool::contract_state_for_testing()
        );
        let tick_state = YASPool::InternalImpl::get_tick_state(
            YASPool::contract_state_for_testing()
        );
        (YASPool::contract_state_for_testing(), position_state, tick_state)
    }

    fn mock_position_key_and_info(lower: i32, upper: i32) -> (PositionKey, Position::Info) {
        let position_key = PositionKey { owner: OWNER(), tick_lower: lower, tick_upper: upper, };
        let position_info = Info {
            liquidity: 1000,
            fee_growth_inside_0_last_X128: 0,
            fee_growth_inside_1_last_X128: 0,
            tokens_owed_0: 0,
            tokens_owed_1: 0,
        };
        (position_key, position_info)
    }

    fn mock_tick_infos(infos_len: u32) -> Array<Tick::Info> {
        let mut ret = array![];
        let mut i = 0;
        loop {
            if i == infos_len {
                break;
            }
            ret
                .append(
                    Tick::Info {
                        fee_growth_outside_0X128: 0,
                        fee_growth_outside_1X128: 0,
                        liquidity_gross: 100,
                        liquidity_net: IntegerTrait::<i128>::new(0, false),
                        seconds_per_liquidity_outside_X128: 0,
                        tick_cumulative_outside: IntegerTrait::<i64>::new(0, false),
                        seconds_outside: 0,
                        initialized: true
                    }
                );
            i += 1;
        };
        ret
    }

    fn mock_ticks(
        ref tick_state: Tick::ContractState, mut from: i32, to: i32, infos: Array<Tick::Info>
    ) {
        assert(from <= to, 'init_mock_ticks - from > to');
        let mut ticks = array![];
        loop {
            if from > to {
                break;
            }
            ticks.append(from);
            from += IntegerTrait::<i32>::new(1, false);
        };
        Tick::InternalImpl::set_ticks(ref tick_state, ticks, infos);
    }
}
