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

        use yas_core::utils::math_utils::{
            FullMath::{div_rounding_up, mul_div, mul_div_rounding_up}, pow
        };

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
            //yas_pool.initialize(sqrt_price_X96); //don't
            let (min_tick, max_tick) = get_min_tick_and_max_tick();

            let (amount0, amount1): (u256, u256) = yas_pool
                .mint(
                    recipient: yas_pool.contract_address,
                    tick_lower: min_tick,
                    tick_upper: max_tick,
                    amount: 1,
                    data: ArrayTrait::<felt252>::new()
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
                let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
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
                let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        IntegerTrait::<i32>::new(887273, true),
                        Zeroable::zero(),
                        1
                    );
            }

            #[test]
            #[available_gas(2000000000)]
            #[should_panic(expected: ('TUM', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_fails_tick_greater_than_max() {
                let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        Zeroable::zero(),
                        IntegerTrait::<i32>::new(887273, false),
                        1
                    );
            }

            #[test]
            #[available_gas(2000000000)]
            #[should_panic(expected: ('LO', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_fails_amount_greater_than_max() {
                let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
                let grater_than_max_amount: u128 = yas_pool.max_liquidity_per_tick() + 1;
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                        max_tick - IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                        grater_than_max_amount
                    );
            }

            #[test]
            #[available_gas(2000000000)]
            fn test_amount_max() {
                let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
                let maxLiquidityGross: u128 = yas_pool.max_liquidity_per_tick();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                        max_tick - IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                        maxLiquidityGross
                    );
            }

            #[test]
            #[available_gas(2000000000)]
            #[should_panic(expected: ('LO', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_fails_amount_at_tick_greater_than_max() {
                let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                        max_tick - IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                        1000
                    );
                let max_liquidity_gross: u128 = yas_pool.max_liquidity_per_tick();

                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                        max_tick - IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                        max_liquidity_gross - 1000 + 1
                    );
            }

            #[test]
            #[available_gas(2000000000)]
            #[should_panic(expected: ('LO', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_fails_amount_at_tick_greater_than_max_2() {
                let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                        max_tick - IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                        1000
                    );
                let maxLiquidityGross: u128 = yas_pool.max_liquidity_per_tick();

                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick
                            + IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false)
                                * IntegerTrait::<i32>::new(2, false),
                        max_tick - IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                        maxLiquidityGross - 1000 + 1
                    );
            }

            #[test]
            #[available_gas(2000000000)]
            #[should_panic(expected: ('LO', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
            fn test_fails_amount_at_tick_greater_than_max_3() {
                let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                        max_tick - IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                        1000
                    );
                let maxLiquidityGross: u128 = yas_pool.max_liquidity_per_tick();

                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                        max_tick
                            - IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false)
                                * IntegerTrait::<i32>::new(2, false),
                        maxLiquidityGross - 1000 + 1
                    );
            }

            #[test]
            #[available_gas(2000000000)]
            fn test_success_amount_at_tick_greater_than_max_4() {
                let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                        max_tick - IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                        1000
                    );
                let maxLiquidityGross: u128 = yas_pool.max_liquidity_per_tick();
                yas_router
                    .mint(
                        yas_pool.contract_address,
                        WALLET(),
                        min_tick + IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                        max_tick - IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                        maxLiquidityGross - 1000
                    );
            }

            #[test]
            #[available_gas(2000000000)]
            #[should_panic(
                expected: ('amount must be greater than 0', 'ENTRYPOINT_FAILED')
            )] //set panic code
            fn test_fails_amount_is_zero() {
                let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
                let (amount0, amount1): (u256, u256) = yas_pool
                    .mint(
                        recipient: yas_pool.contract_address,
                        tick_lower: min_tick,
                        tick_upper: max_tick,
                        amount: 0,
                        data: ArrayTrait::<felt252>::new()
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
                let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();

                let balance_token_0 = token_0.balanceOf(yas_pool.contract_address);
                let balance_token_1 = token_1.balanceOf(yas_pool.contract_address);

                assert(balance_token_0 == 9996, 'wrong balance token 0');
                assert(balance_token_1 == 1000, 'wrong balance token 1');
            }

            #[test]
            #[available_gas(200000000)]
            fn test_initial_tick() {
                let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
                let (expected_min_tick, expected_max_tick) = get_min_tick_and_max_tick();

                let tick = yas_pool.slot_0().tick;

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
                    let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();

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
                    let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
                    let BigNumber: u128 = pow(2, 102).try_into().unwrap();
                    yas_router
                        .mint(
                            yas_pool.contract_address,
                            WALLET(),
                            max_tick
                                - IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                            max_tick,
                            BigNumber
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
                    let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();

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

                // TODO: missing burn() func
                // // WIP: 'removing works'
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
                    let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
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
                        yas_pool.get_tick(yas_pool.tick_spacing()).liquidity_gross == 0,
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
                            yas_pool.tick_spacing(),
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
                        yas_pool.get_tick(yas_pool.tick_spacing()).liquidity_gross == 150,
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
                        yas_pool.get_tick(yas_pool.tick_spacing()).liquidity_gross == 150,
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
                // TODO: missing burn() func.
                // // TODO: 'removes liquidity from liquidityGross'
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

                // TODO: missing burn() func
                // TODO: 'clears tick lower if last position is removed'
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

                // // TODO: missing burn() func
                // // TODO: 'clears tick upper if last position is removed'
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

                // // TODO: missing burn() func
                // // TODO: 'only clears the tick that is not used at all'
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
                //     let tick_info = yas_pool.get_tick(-yas_pool.tick_spacing());
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
                use super::super::pow;
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
                            min_tick + yas_pool.tick_spacing(),
                            max_tick - yas_pool.tick_spacing(),
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
                    let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
                    yas_router
                        .mint(
                            yas_pool.contract_address,
                            WALLET(),
                            min_tick + yas_pool.tick_spacing(),
                            max_tick - yas_pool.tick_spacing(),
                            100
                        );

                    assert(
                        yas_pool
                            .get_tick(min_tick + yas_pool.tick_spacing())
                            .liquidity_gross == 100,
                        'wrong liquidity_gross amount 1'
                    );
                }

                #[test]
                #[available_gas(200000000)]
                fn test_init_upper_tick() {
                    let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
                    yas_router
                        .mint(
                            yas_pool.contract_address,
                            WALLET(),
                            min_tick + yas_pool.tick_spacing(),
                            max_tick - yas_pool.tick_spacing(),
                            100
                        );
                    assert(
                        yas_pool
                            .get_tick(max_tick - yas_pool.tick_spacing())
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
                // // TODO: missing burn() func
                // // TODO: 'removing works'
                // https://github.com/Uniswap/v3-core/blob/main/test/UniswapV3Pool.spec.ts#L393
                // //#[test]
                // //#[available_gas(200000000)]
                // fn test_remove() {
                //     let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
                //     yas_router
                //         .mint(
                //             yas_pool.contract_address,
                //             WALLET(),
                //             min_tick + yas_pool.tick_spacing(),
                //             max_tick - yas_pool.tick_spacing(),
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
                    let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
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
                    let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
                    yas_router
                        .mint(
                            yas_pool.contract_address,
                            WALLET(),
                            min_tick,
                            min_tick + yas_pool.tick_spacing(),
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
                    let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
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
                // TODO: missing burn() func
                // TODO: 'removing works'
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
        // // TODO: missing setFeeProtocol() func
        // // TODO: 'protocol fees accumulate as expected during swap'
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
        //         min_tick + yas_pool.tick_spacing(),
        //         max_tick - yas_pool.tick_spacing(),
        //         1000000000000000000 //?
        //     );
        // }

        // // TODO: missing setFeeProtocol() func
        // // TODO: 'positions are protected before protocol fee is turned on'
        // https://github.com/Uniswap/v3-core/blob/main/test/UniswapV3Pool.spec.ts#L494
        // //#[test]
        // //#[available_gas(200000000)]
        // fn test_positions_protected() {
        //let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
        // yas_router
        //     .mint(
        //         yas_pool.contract_address,
        //         WALLET(),
        //         min_tick + yas_pool.tick_spacing(),
        //         max_tick - yas_pool.tick_spacing(),
        //         1000000000000000000 //?
        //     );
        //assert(1 == 2, 'no setFeeProtocol() function');
        // }

        //TODO: missing burn() func
        // test: 'poke is not allowed on uninitialized position'
        // https://github.com/Uniswap/v3-core/blob/main/test/UniswapV3Pool.spec.ts#L509
        // //#[test]
        // //#[available_gas(200000000)]
        // fn test_unallow_poke_on_uninit_pos() {
        //let (yas_pool, token_0, token_1, yas_router, min_tick, max_tick) = setup();
        // yas_router
        //     .mint(
        //         yas_pool.contract_address,
        //         WALLET(),
        //         min_tick + yas_pool.tick_spacing(),
        //         max_tick - yas_pool.tick_spacing(),
        //         1000000000000000000 //?
        //     );
        //assert(1 == 2, 'no burn() function');
        // }

    }

    // YASPool mint() aux functions
    use starknet::{ClassHash, SyscallResultTrait};
    use starknet::testing::{set_contract_address, set_caller_address};

    use yas_core::contracts::yas_factory::{
        YASFactory, IYASFactory, IYASFactoryDispatcher, IYASFactoryDispatcherTrait
    };
    use yas_core::libraries::tick_math::{TickMath::MIN_TICK, TickMath::MAX_TICK};
    use yas_core::numbers::fixed_point::implementations::impl_64x96::{
        FP64x96Impl, FixedType, FixedTrait
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


    fn setup() -> (
        IYASPoolDispatcher, IERC20Dispatcher, IERC20Dispatcher, IYASRouterDispatcher, i32, i32
    ) {
        let yas_router = deploy_yas_router(); // 0x1
        let yas_factory = deploy_factory(OWNER(), POOL_CLASS_HASH()); // 0x2

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
