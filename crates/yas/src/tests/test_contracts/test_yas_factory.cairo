mod YASFactoryTests {
    use starknet::SyscallResultTrait;
    use starknet::syscalls::deploy_syscall;
    use starknet::testing::pop_log;
    use starknet::{ContractAddress, ClassHash, contract_address_const, class_hash_const};

    use yas::contracts::yas_factory::{
        YASFactory, YASFactory::OwnerChanged, YASFactory::FeeAmountEnabled, IYASFactory,
        IYASFactoryDispatcher, IYASFactoryDispatcherTrait
    };
    use yas::numbers::signed_integer::i32::i32;

    fn deploy(deployer: ContractAddress, pool_class_hash: ClassHash) -> IYASFactoryDispatcher {
        let (address, _) = deploy_syscall(
            YASFactory::TEST_CLASS_HASH.try_into().unwrap(),
            0,
            array![deployer.into(), pool_class_hash.into()].span(),
            true
        )
            .unwrap_syscall();

        return IYASFactoryDispatcher { contract_address: address };
    }

    // The events emitted by Starknet are queued. In our default constructor, 
    // we have 4 events (1 OwnerChanged and 3 FeeAmountEnabled). To make this simple, 
    // it is necessary to 'clean up' these events
    fn clean_events(address: ContractAddress) {
        let mut i = 0;
        loop {
            if i == 5 {
                break;
            }
            pop_log::<OwnerChanged>(address);
            i += 1;
        }
    }

    mod Constructor {
        use super::{clean_events, deploy};
        use yas::tests::utils::constants::FactoryConstants::{
            OTHER, OWNER, ZERO, POOL_CLASS_HASH, FeeAmount, fee_amount, tick_spacing
        };
        use yas::contracts::yas_factory::{
            YASFactory, YASFactory::OwnerChanged, YASFactory::FeeAmountEnabled, IYASFactory,
            IYASFactoryDispatcher, IYASFactoryDispatcherTrait
        };
        use starknet::{
            contract_address_const, class_hash_const, testing::{set_contract_address, pop_log}
        };
        use yas::numbers::signed_integer::{integer_trait::IntegerTrait, i32::i32};

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('pool class hash can not be zero', 'CONSTRUCTOR_FAILED'))]
        fn test_fails_when_pool_class_hash_is_zero() {
            let yas_factory = deploy(OWNER(), class_hash_const::<0>());
        }

        #[test]
        #[available_gas(20000000)]
        fn test_deployer_should_be_contract_owner() {
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());
            assert(yas_factory.owner() == OWNER(), 'Owner doesnt match')
        }

        #[test]
        #[available_gas(20000000)]
        fn test_initial_enabled_fee_amounts() {
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());

            let fee_amount_custom = yas_factory
                .fee_amount_tick_spacing(fee_amount(FeeAmount::CUSTOM));
            assert(
                fee_amount_custom == IntegerTrait::<i32>::new(
                    tick_spacing(FeeAmount::CUSTOM), false
                ),
                'fee custom doesnt set correctly'
            );

            let fee_amount_low = yas_factory.fee_amount_tick_spacing(fee_amount(FeeAmount::LOW));
            assert(
                fee_amount_low == IntegerTrait::<i32>::new(tick_spacing(FeeAmount::LOW), false),
                'fee low doesnt set correctly'
            );

            let fee_amount_med = yas_factory.fee_amount_tick_spacing(fee_amount(FeeAmount::MEDIUM));
            assert(
                fee_amount_med == IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false),
                'fee med doesnt set correctly'
            );

            let fee_amount_high = yas_factory.fee_amount_tick_spacing(fee_amount(FeeAmount::HIGH));
            assert(
                fee_amount_high == IntegerTrait::<i32>::new(tick_spacing(FeeAmount::HIGH), false),
                'fee high doesnt set correctly'
            );
        }

        #[test]
        #[available_gas(20000000)]
        fn test_emits_all_events() {
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());

            let event = pop_log::<OwnerChanged>(yas_factory.contract_address).unwrap();
            assert(event.old_owner == ZERO(), 'event old owner should be ZERO');
            assert(event.new_owner == OWNER(), 'event new owner should be OWNER');

            let event = pop_log::<FeeAmountEnabled>(yas_factory.contract_address).unwrap();
            assert(event.fee == fee_amount(FeeAmount::CUSTOM), 'wrong custom fee event');
            assert(
                event.tick_spacing.mag == tick_spacing(FeeAmount::CUSTOM),
                'wrong custom tick_spacing event'
            );

            let event = pop_log::<FeeAmountEnabled>(yas_factory.contract_address).unwrap();
            assert(event.fee == fee_amount(FeeAmount::LOW), 'wrong low fee event');
            assert(
                event.tick_spacing.mag == tick_spacing(FeeAmount::LOW),
                'wrong low tick_spacing event'
            );

            let event = pop_log::<FeeAmountEnabled>(yas_factory.contract_address).unwrap();
            assert(event.fee == fee_amount(FeeAmount::MEDIUM), 'wrong med fee event');
            assert(
                event.tick_spacing.mag == tick_spacing(FeeAmount::MEDIUM),
                'wrong med tick_spacing event'
            );

            let event = pop_log::<FeeAmountEnabled>(yas_factory.contract_address).unwrap();
            assert(event.fee == fee_amount(FeeAmount::HIGH), 'wrong high fee event');
            assert(
                event.tick_spacing.mag == tick_spacing(FeeAmount::HIGH),
                'wrong high tick_spacing event'
            );
        }
    }

    mod CreatePool {
        use super::{clean_events, deploy};
        use yas::tests::utils::constants::FactoryConstants::{
            OTHER, OWNER, TOKEN_A, TOKEN_B, ZERO, POOL_CLASS_HASH, FeeAmount, fee_amount,
            tick_spacing
        };
        use yas::contracts::yas_factory::{
            YASFactory, YASFactory::PoolCreated, IYASFactory, IYASFactoryDispatcher,
            IYASFactoryDispatcherTrait
        };
        use starknet::testing::{pop_log, set_contract_address};
        use starknet::call_contract_syscall;

        use yas::numbers::signed_integer::i32::i32;

        #[test]
        #[available_gas(20000000)]
        fn test_success_for_low_pool() {
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());
            clean_events(yas_factory.contract_address);
            set_contract_address(OTHER());

            let pool_deployed = yas_factory
                .create_pool(TOKEN_A(), TOKEN_B(), fee_amount(FeeAmount::LOW));

            let pool_token_a_token_b = yas_factory
                .pool(TOKEN_A(), TOKEN_B(), fee_amount(FeeAmount::LOW));
            let pool_token_b_token_a = yas_factory
                .pool(TOKEN_B(), TOKEN_A(), fee_amount(FeeAmount::LOW));

            assert(pool_token_a_token_b == pool_deployed, 'wrong pool in order result');
            assert(pool_token_b_token_a == pool_deployed, 'wrong pool in reverse result');

            // Verify PoolCreated event emitted
            let event = pop_log::<PoolCreated>(yas_factory.contract_address).unwrap();
            assert(event.token_0 == TOKEN_A(), 'event token_0 should be TOKEN_A');
            assert(event.token_1 == TOKEN_B(), 'event token_1 should be TOKEN_B');
            assert(event.fee == fee_amount(FeeAmount::LOW), 'event fee should be LOW');
            assert(event.tick_spacing.mag == tick_spacing(FeeAmount::LOW), 'wrong tick_spacing');
            assert(event.tick_spacing.sign == false, 'tick_spacing should be false');
            assert(event.pool == pool_deployed, 'wrong event pool address');
        }

        #[test]
        #[available_gas(20000000)]
        fn test_success_for_medium_pool() {
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());
            clean_events(yas_factory.contract_address);
            set_contract_address(OTHER());

            let pool_deployed = yas_factory
                .create_pool(TOKEN_A(), TOKEN_B(), fee_amount(FeeAmount::MEDIUM));

            let pool_token_a_token_b = yas_factory
                .pool(TOKEN_A(), TOKEN_B(), fee_amount(FeeAmount::MEDIUM));
            let pool_token_b_token_a = yas_factory
                .pool(TOKEN_B(), TOKEN_A(), fee_amount(FeeAmount::MEDIUM));

            assert(pool_token_a_token_b == pool_deployed, 'wrong pool in order result');
            assert(pool_token_b_token_a == pool_deployed, 'wrong pool in reverse result');

            // Verify PoolCreated event emitted
            let event = pop_log::<PoolCreated>(yas_factory.contract_address).unwrap();
            assert(event.token_0 == TOKEN_A(), 'event token_0 should be TOKEN_A');
            assert(event.token_1 == TOKEN_B(), 'event token_1 should be TOKEN_B');
            assert(event.fee == fee_amount(FeeAmount::MEDIUM), 'event fee should be MEDIUM');
            assert(event.tick_spacing.mag == tick_spacing(FeeAmount::MEDIUM), 'wrong tick_spacing');
            assert(event.tick_spacing.sign == false, 'tick_spacing should be false');
            assert(event.pool == pool_deployed, 'wrong event pool address');
        }

        #[test]
        #[available_gas(20000000)]
        fn test_success_for_high_pool() {
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());
            clean_events(yas_factory.contract_address);
            set_contract_address(OTHER());

            let pool_deployed = yas_factory
                .create_pool(TOKEN_A(), TOKEN_B(), fee_amount(FeeAmount::HIGH));

            let pool_token_a_token_b = yas_factory
                .pool(TOKEN_A(), TOKEN_B(), fee_amount(FeeAmount::HIGH));
            let pool_token_b_token_a = yas_factory
                .pool(TOKEN_B(), TOKEN_A(), fee_amount(FeeAmount::HIGH));

            assert(pool_token_a_token_b == pool_deployed, 'wrong pool in order result');
            assert(pool_token_b_token_a == pool_deployed, 'wrong pool in reverse result');

            // Verify PoolCreated event emitted
            let event = pop_log::<PoolCreated>(yas_factory.contract_address).unwrap();
            assert(event.token_0 == TOKEN_A(), 'event token_0 should be TOKEN_A');
            assert(event.token_1 == TOKEN_B(), 'event token_1 should be TOKEN_B');
            assert(event.fee == fee_amount(FeeAmount::HIGH), 'event fee should be HIGH');
            assert(event.tick_spacing.mag == tick_spacing(FeeAmount::HIGH), 'wrong tick_spacing');
            assert(event.tick_spacing.sign == false, 'tick_spacing should be false');
            assert(event.pool == pool_deployed, 'wrong event pool address');
        }

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('tokens must be different', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_tokens_are_the_same() {
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());
            set_contract_address(OTHER());
            yas_factory.create_pool(TOKEN_A(), TOKEN_A(), fee_amount(FeeAmount::LOW));
        }

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('tokens addresses cannot be zero', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_token_A_is_zero() {
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());
            set_contract_address(OTHER());
            yas_factory.create_pool(ZERO(), TOKEN_A(), fee_amount(FeeAmount::LOW));
        }

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('tokens addresses cannot be zero', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_token_B_is_zero() {
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());
            set_contract_address(OTHER());
            yas_factory.create_pool(TOKEN_A(), ZERO(), fee_amount(FeeAmount::LOW));
        }

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('tick spacing not initialized', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_fee_amount_is_not_enabled() {
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());
            set_contract_address(OTHER());
            // select a value different from those initialized by default (500, 3000, 10000).
            yas_factory.create_pool(TOKEN_A(), TOKEN_B(), 1);
        }

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('token pair already created', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_token_pair_is_already_created() {
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());
            set_contract_address(OTHER());
            // create pool with pair (token_A, token_B)
            yas_factory.create_pool(TOKEN_A(), TOKEN_B(), fee_amount(FeeAmount::LOW));

            // try create again, this should fail
            yas_factory.create_pool(TOKEN_A(), TOKEN_B(), fee_amount(FeeAmount::LOW));
        }

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('token pair already created', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_token_pair_is_already_created_invert_order() {
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());
            set_contract_address(OTHER());
            // create pool with pair (token_A, token_B)
            yas_factory.create_pool(TOKEN_A(), TOKEN_B(), fee_amount(FeeAmount::LOW));

            // try create again in other order, this should fail
            yas_factory.create_pool(TOKEN_B(), TOKEN_A(), fee_amount(FeeAmount::LOW));
        }
    }

    mod SetOwner {
        use super::{clean_events, deploy};
        use yas::tests::utils::constants::FactoryConstants::{OTHER, OWNER, POOL_CLASS_HASH};
        use yas::contracts::yas_factory::{
            YASFactory, YASFactory::OwnerChanged, IYASFactory, IYASFactoryDispatcher,
            IYASFactoryDispatcherTrait
        };
        use starknet::testing::{pop_log, set_contract_address};
        use yas::numbers::signed_integer::i32::i32;

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('only owner can do this action!', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_caller_is_not_owner() {
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());
            set_contract_address(OTHER());
            yas_factory.set_owner(OTHER());
        }

        #[test]
        #[available_gas(20000000)]
        fn test_success_when_caller_is_owner() {
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());

            // Set and read new owner
            yas_factory.set_owner(OTHER());
            assert(yas_factory.owner() == OTHER(), 'new owner should be OTHER');
        }

        #[test]
        #[available_gas(20000000)]
        fn test_emits_events() {
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());

            // Clean up the 4 events emitted by the deploy
            clean_events(yas_factory.contract_address);

            yas_factory.set_owner(OTHER());

            // Verify OwnerChanged event emitted
            let event = pop_log::<OwnerChanged>(yas_factory.contract_address).unwrap();
            assert(event.old_owner == OWNER(), 'event old owner should be OWNER');
            assert(event.new_owner == OTHER(), 'event new owner should be OTHER');
        }
    }

    mod SetEnableFeeAmount {
        use super::{clean_events, deploy};
        use yas::tests::utils::constants::FactoryConstants::{
            OTHER, OWNER, POOL_CLASS_HASH, TOKEN_A, TOKEN_B, FeeAmount, fee_amount
        };
        use yas::contracts::yas_factory::{
            YASFactory, YASFactory::FeeAmountEnabled, YASFactory::PoolCreated, IYASFactory,
            IYASFactoryDispatcher, IYASFactoryDispatcherTrait
        };
        use starknet::testing::{pop_log, set_contract_address};
        use yas::numbers::signed_integer::{integer_trait::IntegerTrait, i32::i32};

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('only owner can do this action!', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_caller_is_not_owner() {
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());
            set_contract_address(OTHER());
            yas_factory.enable_fee_amount(100, IntegerTrait::<i32>::new(2, false));
        }

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('fee cannot be gt 1000000', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_fee_is_too_large() {
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());

            yas_factory.enable_fee_amount(1000000, IntegerTrait::<i32>::new(20, false));
        }

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('wrong tick_spacing (0<ts<16384)', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_tick_spacing_is_too_large() {
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());

            yas_factory.enable_fee_amount(500, IntegerTrait::<i32>::new(16834, false));
        }

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('wrong tick_spacing (0<ts<16384)', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_tick_spacing_is_too_small() {
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());

            yas_factory.enable_fee_amount(500, IntegerTrait::<i32>::new(0, false));
        }

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('fee amount already initialized', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_already_initialized() {
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());

            yas_factory.enable_fee_amount(50, IntegerTrait::<i32>::new(1, false));
            yas_factory.enable_fee_amount(50, IntegerTrait::<i32>::new(10, false));
        }

        #[test]
        #[available_gas(20000000)]
        fn test_set_fee_amount_in_the_mapping() {
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());
            yas_factory.enable_fee_amount(50, IntegerTrait::<i32>::new(1, false));

            assert(
                yas_factory.fee_amount_tick_spacing(50) == IntegerTrait::<i32>::new(1, false),
                'wrong tick spacing for amount'
            );
        }

        #[test]
        #[available_gas(20000000)]
        fn test_emits_event() {
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());

            // Clean up the 4 events emitted by the deploy
            clean_events(yas_factory.contract_address);

            yas_factory.enable_fee_amount(50, IntegerTrait::<i32>::new(1, false));

            // Verify FeeAmountEnabled event emitted
            let event = pop_log::<FeeAmountEnabled>(yas_factory.contract_address).unwrap();
            assert(event.fee == 50, 'fee event should be 50');
            assert(
                event.tick_spacing == IntegerTrait::<i32>::new(1, false),
                'tick_spacing event should be 1'
            );
        }

        #[test]
        #[available_gas(20000000)]
        fn test_enables_pool_creation() {
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER(), POOL_CLASS_HASH());
            let yas_factory_contract_address = yas_factory.contract_address;
            // Clean up the 4 events emitted by the deploy
            clean_events(yas_factory.contract_address);

            yas_factory.enable_fee_amount(250, IntegerTrait::<i32>::new(15, false));
            let pool_deployed = yas_factory.create_pool(TOKEN_A(), TOKEN_B(), 250);

            let pool_token_a_token_b = yas_factory.pool(TOKEN_A(), TOKEN_B(), 250);
            let pool_token_b_token_a = yas_factory.pool(TOKEN_B(), TOKEN_A(), 250);

            assert(pool_token_a_token_b == pool_deployed, 'wrong pool in order result');
            assert(pool_token_b_token_a == pool_deployed, 'wrong pool in reverse result');

            // Skip FeeAmountEnabled event emitted
            pop_log::<FeeAmountEnabled>(yas_factory_contract_address);

            // Verify PoolCreated event emitted
            let event = pop_log::<PoolCreated>(yas_factory.contract_address).unwrap();
            assert(event.token_0 == TOKEN_A(), 'event token_0 should be TOKEN_A');
            assert(event.token_1 == TOKEN_B(), 'event token_1 should be TOKEN_B');
            assert(event.fee == 250, 'event fee should be 250');
            assert(
                event.tick_spacing == IntegerTrait::<i32>::new(15, false),
                'tick_spacing event should be 15'
            );
            assert(event.pool == pool_deployed, 'wrong event pool address');
        }
    }
}
