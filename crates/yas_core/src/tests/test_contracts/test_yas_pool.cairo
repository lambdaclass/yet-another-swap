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
        use yas_core::tests::utils::constants::PoolConstants::{TOKEN_A, TOKEN_B, WALLET};
        use yas_core::tests::utils::constants::FactoryConstants::{
            FeeAmount, fee_amount, tick_spacing
        };
        use yas_core::contracts::yas_erc20::{ERC20, ERC20::ERC20Impl, IERC20Dispatcher};
        use yas_core::numbers::signed_integer::{
            i32::i32, i32::i32_div_no_round, integer_trait::IntegerTrait
        };

        // TODO: 'fails if not initialized'
        // TODO: 'initialize the pool at price of 10:1'

        mod FailureCases {
            // TODO: 'fails if tickLower greater than tickUpper'
            #[test]
            #[available_gas(2000000)]
            fn test_fails_tick_lower_greater_than_tick_upper() {}
        // TODO: 'fails if tickLower less than min tick'
        // TODO: 'fails if tickUpper greater than max tick'
        // TODO: 'fails if amount exceeds the max'
        // TODO: 'fails if total amount at tick exceeds the max'
        // TODO: 'fails if amount is 0'
        }

        mod SuccessCases {
            // TODO: 'initial balances'
            // TODO: 'initial tick'
            mod AboveCurrentPrice {
                use super::super::super::setup;

                use yas_core::contracts::yas_pool::{
                    YASPool, YASPool::ContractState, YASPool::InternalImpl, IYASPool,
                    IYASPoolDispatcher, IYASPoolDispatcherTrait
                };
                use yas_core::contracts::yas_erc20::IERC20DispatcherTrait;

                #[test]
                #[available_gas(200000000)]
                fn test_transfers_token_0_only() {
                    let (yas_pool, token_0, token_1) = setup();

                    let balance_token_0 = token_0.balanceOf(yas_pool.contract_address);
                    let balance_token_1 = token_1.balanceOf(yas_pool.contract_address);

                    assert(balance_token_0 == 2000000000000000000, 'wrong balance token 0');
                    assert(balance_token_1 == 2000000000000000000, 'wrong balance token 1');
                }
            // TODO: 'max tick with max leverage'
            // TODO: 'works for max tick'
            // TODO: 'removing works'
            // TODO: 'adds liquidity to liquidityGross'
            // TODO: 'removes liquidity from liquidityGross'
            // TODO: 'clears tick lower if last position is removed'
            // TODO: 'clears tick upper if last position is removed'
            // TODO: 'only clears the tick that is not used at all'
            }

            mod IncludingCurrentPrice { // TODO: 'price within range: transfers current price of both tokens'
            // TODO: 'initializes lower tick'
            // TODO: 'initializes upper tick'
            // TODO: 'works for min/max tick'
            // TODO: 'removing works'
            }

            mod BelowCurrentPrice { // TODO: 'transfers token1 only'
            // TODO: 'min tick with max leverage'
            // TODO: 'works for min tick'
            // TODO: 'removing works'
            }
        }
    // TODO: 'protocol fees accumulate as expected during swap'
    // TODO: 'positions are protected before protocol fee is turned on'
    // TODO: 'poke is not allowed on uninitialized position'
    }

    mod Swap {
        use super::{setup_with, setup_pool_for_swap_test, mint_positions, swap_test_case};

        use yas_core::numbers::fixed_point::implementations::impl_64x96::{
            FP64x96Impl, FP64x96Sub, FP64x96PartialEq, FixedType, FixedTrait
        };
        use yas_core::numbers::signed_integer::{i256::i256, integer_trait::IntegerTrait};
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
            TOKEN_A, TOKEN_B, POOL_ADDRESS, WALLET, encode_price_sqrt_1_1, encode_price_sqrt_1_2
        };

        use yas_core::tests::utils::constants::FactoryConstants::{
            fee_amount, FeeAmount
        };

        use yas_core::libraries::tick_math::TickMath::{
            MIN_TICK, MAX_TICK, get_sqrt_ratio_at_tick, MIN_SQRT_RATIO, MAX_SQRT_RATIO
        };


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

        #[test]
        #[available_gas(200000000000)]
        fn test_swap_first_pool_first_case() {
            // swap test case:
                //{
                //    zeroForOne: true,
                //    exactOut: false,
                //    amount0: expandTo18Decimals(1),
                //},

            // pool test case:
                //{
                //    description: 'low fee, 1:1 price, 2e18 max range liquidity',
                //    feeAmount: FeeAmount.LOW,
                //    tickSpacing: TICK_SPACINGS[FeeAmount.LOW],
                //    startingPrice: encodePriceSqrt(1, 1),
                //    positions: [
                //    {
                //        tickLower: getMinTick(TICK_SPACINGS[FeeAmount.LOW]),
                //        tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.LOW]),
                //        liquidity: expandTo18Decimals(2),
                //    },
                //    ],
                //},
            
            // case to description:
                //low fee, 1:1 price, 2e18 max range liquidity

                //const priceClause = testCase?.sqrtPriceLimit ? ` to price ${formatPrice(testCase.sqrtPriceLimit)}` : ''
                //return `swap exactly 1.0000 token0 for token1${priceClause}`

            // expected:
                //exports[`UniswapV3Pool swap tests low fee, 1:1 price, 2e18 max range liquidity swap exactly 1.0000 token0 for token1 1`] = `
                //    Object {
                //    "amount0Before": "2000000000000000000",
                //    "amount0Delta": "1000000000000000000",
                //    "amount1Before": "2000000000000000000",
                //    "amount1Delta": "-666444407401233536",
                //    "executionPrice": "0.66644",
                //    "feeGrowthGlobal0X128Delta": "85070591730234956148210572796405514",
                //    "feeGrowthGlobal1X128Delta": "0",
                //    "poolPriceAfter": "0.44459",
                //    "poolPriceBefore": "1.0000",
                //    "tickAfter": -8107,
                //    "tickBefore": 0,
                //}

            // con esto: se crea la pool y se inicializa. se mintean las positions de la pool. 
            // se ejecuta un swap(pool, testcase, poolfunction(?))
            // se comparan los balances after swap
            // 

            // TODO: find real numbers expected
            let token_0_swapped_expected = 1000000000000000000;
            let token_1_swapped_expected = 666444407401233536;


            // setup POOL test case:

            let INITIAL_PRICE = encode_price_sqrt_1_1();

            let NEGATIVE = true;
            let POSITIVE = false;

            let (yas_pool, yas_router, token_0, token_1, min_tick, max_tick) = setup_pool_for_swap_test(
                initial_price: INITIAL_PRICE,
                fee_amount: fee_amount(FeeAmount::LOW),
                liquidity: 2000000000000000000
            );

            //mint_positions(
            //    yas_router,
            //    yas_pool.contract_address,
            //    min_tick,
            //    max_tick,
            //    2000000000000000000
            //);

            // setup SWAP test case

            let token_0_amount = IntegerTrait::<i256>::new(1000000000000000000, POSITIVE); 
            let zero_for_one = true; 
            let has_sqrt_price_limit = false;
            let sqrt_price_limit = false;
            let sqrt_price_limit_u256 = 123;

            // When selling token 0 (zeroForOne is true) sqrtPriceLimitX96 must be
            // between the current price and the minimal sqrt(P) since selling token 0
            // moves the price down. Likewise, when selling token 1, sqrtPriceLimitX96
            // must be between the current price and the maximal sqrt(P) ​because price moves up.

            // In the while loop, we want to satisfy two conditions: full swap amount has not been
            // filled and current price isn’t equal to sqrtPriceLimitX96:
            //let price_limit = FP64x96Impl::new(INITIAL_PRICE_u256 / 1000, NEGATIVE);
            let price_limit =
                if has_sqrt_price_limit {
                    FP64x96Impl::new(sqrt_price_limit_u256, POSITIVE)
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
                .swap(yas_pool.contract_address, WALLET(), zero_for_one, token_0_amount, price_limit);
            
            let user_token_0_balance_af = token_0.balanceOf(WALLET());
            let user_token_1_balance_af = token_1.balanceOf(WALLET());

            let swapped_token_0 = user_token_0_balance_bf - user_token_0_balance_af;
            let swapped_token_1 = user_token_1_balance_af - user_token_1_balance_bf;

            //'swapped token_0:'.print();
            //swapped_token_0.print();
            //'swapped token_1:'.print();
            //swapped_token_1.print();

            assert(
                token_0_swapped_expected == swapped_token_0,
                'swapped wrong USDC amount'
            );
            assert(
                token_1_swapped_expected == swapped_token_1,
                'swapped wrong ETH amount'
            );
        }

        #[test]
        #[available_gas(200000000000)]
        fn test_swap_first_pool_second_case() {
            // swap test case:
                //{
                //    zeroForOne: false,
                //    exactOut: false,
                //    amount1: expandTo18Decimals(1),
                //},

            // pool test case:
                //{
                //    description: 'low fee, 1:1 price, 2e18 max range liquidity',
                //    feeAmount: FeeAmount.LOW,
                //    tickSpacing: TICK_SPACINGS[FeeAmount.LOW],
                //    startingPrice: encodePriceSqrt(1, 1),
                //    positions: [
                //    {
                //        tickLower: getMinTick(TICK_SPACINGS[FeeAmount.LOW]),
                //        tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.LOW]),
                //        liquidity: expandTo18Decimals(2),
                //    },
                //    ],
                //},
            
            // case to description:
                //low fee, 1:1 price, 2e18 max range liquidity
                //const priceClause = testCase?.sqrtPriceLimit ? ` to price ${formatPrice(testCase.sqrtPriceLimit)}` : ''
                //return `swap exactly 1.0000 token1 for token0'${priceClause}`
            // expected:
                //exports[`UniswapV3Pool swap tests low fee, 1:1 price, 2e18 max range liquidity swap exactly 1.0000 token1 for token0 1`] = `
                //Object {
                    //"amount0Before": "2000000000000000000",
                    //"amount0Delta": "-666444407401233536",
                    //"amount1Before": "2000000000000000000",
                    //"amount1Delta": "1000000000000000000",
                    //"executionPrice": "1.5005",
                    //"feeGrowthGlobal0X128Delta": "0",
                    //"feeGrowthGlobal1X128Delta": "85070591730234956148210572796405515",
                    //"poolPriceAfter": "2.2493",
                    //"poolPriceBefore": "1.0000",
                    //"tickAfter": 8106,
                    //"tickBefore": 0,
                //}


            // setup POOL test case:
            let liquidity = 2000000000000000000; //variable por test
            let INITIAL_PRICE = encode_price_sqrt_1_1(); //variable por test

            let (yas_pool, yas_router, token_0, token_1, min_tick, max_tick) = setup_pool_for_swap_test(
                initial_price: INITIAL_PRICE, 
                fee_amount: fee_amount(FeeAmount::LOW), //variable por test
                liquidity: liquidity
            );

            //a hardcodear los test cases!!!! de arriba a abajo: son 16
            // https://github.com/Uniswap/v3-core/blob/main/test/UniswapV3Pool.swaps.spec.ts#L135
            //zero_for_one_array = [true, false, true, false, true, false, true, false, true, false, true, false, false, true, true, false]
            //exact_out_array = [false, false, true, true, false, false, true, true, false, false, true, true, NULL, NULL, NULL, NULL]
            //amount_specified_array = [1000000000000000000, 1000000000000000000, 1000000000000000000, 1000000000000000000, 1000000000000000000, 1000000000000000000, 1000000000000000000, 1000000000000000000, 1000, 1000, 1000, 1000, NULL, NULL, NULL, NULL]
            //sqrt_price_limit_array = [NULL, NULL, NULL, NULL, encodePriceSqrt(50, 100), encodePriceSqrt(200, 100), encodePriceSqrt(50, 100), encodePriceSqrt(200, 100), NULL, NULL, NULL, NULL, encodePriceSqrt(5, 2), encodePriceSqrt(2, 5), encodePriceSqrt(5, 2), encodePriceSqrt(2, 5)]

            // setup SWAP test case
            // TODO get values from array to loop
            let zero_for_one = false; //variable por test
            let amount_specified = IntegerTrait::<i256>::new(1000000000000000000, false); //variable por test
            let has_sqrt_price_limit = false; //variable por test
            let sqrt_price_limit_u256 = 123; //variable por test

            let token_0_swapped_expected = 666444407401233536; //variable por test
            let token_1_swapped_expected = 1000000000000000000; //variable por test

            let user_token_0_balance_bf = token_0.balanceOf(WALLET());
            let user_token_1_balance_bf = token_1.balanceOf(WALLET());
            //let (fee_growth_global_0_X128_bf, fee_growth_global_1_X128_bf) = yas_pool.get_fee_growth_globals();

            let pool_token_0_balance_bf = token_0.balanceOf(yas_pool.contract_address);
            let pool_token_1_balance_bf = token_1.balanceOf(yas_pool.contract_address);

            //SWAP
            let (token_0_swapped_amount, token_1_swapped_amount) = swap_test_case(yas_router, yas_pool, token_0, token_1, zero_for_one, amount_specified, has_sqrt_price_limit, sqrt_price_limit_u256);
            
            let user_token_0_balance_af = token_0.balanceOf(WALLET());
            let user_token_1_balance_af = token_1.balanceOf(WALLET());
            //let (fee_growth_global_0_X128_af, fee_growth_global_1_X128_af) = yas_pool.get_fee_growth_globals();

            //let(fee_growth_global_0_X128_delta, fee_growth_global_1_X128_delta) = (fee_growth_global_0_X128_bf - fee_growth_global_0_X128_af, fee_growth_global_1_X128_bf - fee_growth_global_1_X128_af);



            // assert:
                    //"amount0Before": "2000000000000000000",
                    //"amount0Delta": "-666444407401233536",
                    //"amount1Before": "2000000000000000000",
                    //"amount1Delta": "1000000000000000000",
                    //"executionPrice": "1.5005",
                    //"feeGrowthGlobal0X128Delta": "0",
                    //"feeGrowthGlobal1X128Delta": "85070591730234956148210572796405515",
                    //"poolPriceAfter": "2.2493",
                    //"poolPriceBefore": "1.0000",
                    //"tickAfter": 8106,
                    //"tickBefore": 0,
            assert(pool_token_0_balance_bf == 2000000000000000000, 'wrong token0 before');
            assert(token_0_swapped_amount == token_0_swapped_expected, 'wrong token0 swapped amount'); //done
            assert(pool_token_1_balance_bf == 2000000000000000000, 'wrong token1 before');
            assert(token_1_swapped_amount == token_1_swapped_expected, 'wrong token1 swapped amount'); //done

            //let execution_price = token_0_swapped_amount / token_1_swapped_amount ;
            //assert(execution_price == 1.5005, 'wrong execution price'); //how to decimals ?
            
            //assert(fee_growth_global_0_X128_delta == 0, 'wrong feeGrowthGlobal0X128Delta'); 
            //assert(fee_growthGlobal1X128Delta == 85070591730234956148210572796405515, 'wrong feeGrowthGlobal1X128Delta');

            //assert(pool_priceAfter == 2.2493, 'wrong poolPriceAfter');
            //assert(pool_priceBefore == 1.0000, 'wrong poolPriceBefore');
            //assert(tick_after == 8106, 'wrong tickAfter');
            //assert(tick_before == 0, 'wrong tickBefore');
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
        FP64x96Impl, FixedType, FixedTrait
    };

    use yas_core::contracts::yas_router::{
        YASRouter, IYASRouterDispatcher, IYASRouterDispatcherTrait
    };
    use yas_core::tests::utils::constants::PoolConstants::{TOKEN_A, TOKEN_B, POOL_ADDRESS, WALLET};
    use yas_core::tests::utils::constants::FactoryConstants::{
        POOL_CLASS_HASH, FeeAmount, fee_amount, tick_spacing
    };
    use yas_core::contracts::yas_erc20::{
        ERC20, ERC20::ERC20Impl, IERC20Dispatcher, IERC20DispatcherTrait
    };

    use yas_core::numbers::signed_integer::{i256::i256};

    use yas_core::libraries::tick_math::TickMath::{MAX_SQRT_RATIO, MIN_SQRT_RATIO};

    use debug::PrintTrait;


    fn setup() -> (IYASPoolDispatcher, IERC20Dispatcher, IERC20Dispatcher) {
        let mint_callback = deploy_mint_callback(); // 0x1
        let yas_factory = deploy_factory(OWNER(), POOL_CLASS_HASH()); // 0x2

        // Deploy ERC20 tokens with factory address
        let token_0 = deploy_erc20('YAS0', '$YAS0', 4000000000000000000, OWNER()); // 0x3
        let token_1 = deploy_erc20('YAS1', '$YAS1', 4000000000000000000, OWNER()); // 0x4

        set_contract_address(OWNER());
        token_0.transfer(WALLET(), 4000000000000000000);
        token_1.transfer(WALLET(), 4000000000000000000);

        // Give permissions to expend WALLET() tokens
        set_contract_address(WALLET());
        token_1.approve(mint_callback.contract_address, BoundedInt::max());
        token_0.approve(mint_callback.contract_address, BoundedInt::max());

        let encode_price_sqrt_1_1 = FP64x96Impl::new(79228162514264337593543950336, false);

        let yas_pool_address = yas_factory // 0x5
            .create_pool(
                token_0.contract_address, token_1.contract_address, fee_amount(FeeAmount::LOW)
            );
        let yas_pool = IYASPoolDispatcher { contract_address: yas_pool_address };

        set_contract_address(OWNER());
        yas_pool.initialize(encode_price_sqrt_1_1);

        let (min_tick, max_tick) = get_min_tick_and_max_tick();
        set_contract_address(WALLET());
        mint_callback.mint(yas_pool_address, WALLET(), min_tick, max_tick, 2000000000000000000);

        (yas_pool, token_0, token_1)
    }

    fn setup_with(
        initial_price: FixedType, usdc_amount: u256, eth_amount: u256, mint_amount: u128
    ) -> (IYASPoolDispatcher, IYASRouterDispatcher, IERC20Dispatcher, IERC20Dispatcher) {
        let yas_router = deploy_mint_callback(); // 0x1
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
                token_0.contract_address, token_1.contract_address, fee_amount(FeeAmount::LOW) // why LOW ?
            );
        let yas_pool = IYASPoolDispatcher { contract_address: yas_pool_address };

        set_contract_address(OWNER());
        yas_pool.initialize(initial_price);

        let (min_tick, max_tick) = get_min_tick_and_max_tick();

        set_contract_address(WALLET());
        yas_router.mint(yas_pool_address, WALLET(), min_tick, max_tick, mint_amount);

        (yas_pool, yas_router, token_0, token_1)
    }

    fn swap_test_case(
        yas_router: IYASRouterDispatcher, yas_pool: IYASPoolDispatcher, token_0: IERC20Dispatcher, token_1: IERC20Dispatcher, zero_for_one: bool, amount_specified: i256, has_sqrt_price_limit: bool, sqrt_price_limit_u256: u256    
    ) -> (u256, u256) {
            let NEGATIVE = true;
            let POSITIVE = false;
        let sqrt_price_limit =
            if has_sqrt_price_limit {
                FP64x96Impl::new(sqrt_price_limit_u256, POSITIVE)
            } else {
                if zero_for_one {
                    FP64x96Impl::new(MIN_SQRT_RATIO + 1, POSITIVE)
                } else {
                    FP64x96Impl::new(MAX_SQRT_RATIO - 1, POSITIVE)
                }
            };

        let user_token_0_balance_bf = token_0.balanceOf(WALLET());
        let user_token_1_balance_bf = token_1.balanceOf(WALLET());


        //TODO: make yas_pool.swap()
        yas_router
            .swap(yas_pool.contract_address, WALLET(), zero_for_one, amount_specified, sqrt_price_limit);
        
        let user_token_0_balance_af = token_0.balanceOf(WALLET());
        let user_token_1_balance_af = token_1.balanceOf(WALLET());

        //TODO make them integers with sign
        let (token_0_swapped_amount, token_1_swapped_amount) = 
            if zero_for_one {
                (user_token_0_balance_bf - user_token_0_balance_af, user_token_1_balance_af - user_token_1_balance_bf)
            } else {
                (user_token_0_balance_af - user_token_0_balance_bf, user_token_1_balance_bf - user_token_1_balance_af)
            };
        
        //'swapped token_0:'.print();
        //swapped_token_0.print();
        //'swapped token_1:'.print();
        //swapped_token_1.print();
        (token_0_swapped_amount, token_1_swapped_amount)
    }

    fn setup_pool_for_swap_test(
        initial_price: FixedType, fee_amount: u32, liquidity: u128
    ) -> (IYASPoolDispatcher, IYASRouterDispatcher, IERC20Dispatcher, IERC20Dispatcher, i32, i32) {
        let yas_router = deploy_mint_callback(); // 0x1
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
            .create_pool(
                token_0.contract_address, token_1.contract_address, fee_amount
            );
        let yas_pool = IYASPoolDispatcher { contract_address: yas_pool_address };

        set_contract_address(OWNER());
        yas_pool.initialize(initial_price);

        set_contract_address(WALLET());

        let (min_tick, max_tick) = get_min_tick_and_max_tick_with_fee(fee_amount);

        mint_positions(
            yas_router,
            yas_pool.contract_address,
            min_tick,
            max_tick,
            liquidity //variable por test
        );

        (yas_pool, yas_router, token_0, token_1, min_tick, max_tick)
    }

    fn mint_positions(
        yas_router: IYASRouterDispatcher, yas_pool_address: ContractAddress, lower_tick: i32, upper_tick: i32, liquidity: u128
    ) {
        yas_router.mint(yas_pool_address, WALLET(), lower_tick, upper_tick, liquidity)
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

    fn deploy_mint_callback() -> IYASRouterDispatcher {
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
