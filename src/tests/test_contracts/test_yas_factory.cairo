mod YASFactoryTests {
    use core::starknet::SyscallResultTrait;
    use core::result::ResultTrait;
    use starknet::syscalls::deploy_syscall;
    use starknet::testing::pop_log;
    use starknet::{ContractAddress, ClassHash, contract_address_const, class_hash_const};
    use yas::contracts::yas_factory::{
        YASFactory, YASFactory::OwnerChanged, YASFactory::FeeAmountEnabled, IYASFactory,
        IYASFactoryDispatcher, IYASFactoryDispatcherTrait
    };
    use yas::numbers::signed_integer::i32::i32;
    use yas::contracts::yas_pool::YASPool;

    fn OWNER() -> ContractAddress {
        contract_address_const::<'OWNER'>()
    }

    fn OTHER() -> ContractAddress {
        contract_address_const::<'CALLER'>()
    }

    fn ZERO() -> ContractAddress {
        Zeroable::zero()
    }

    fn ONE_CLASS_HASH() -> ClassHash {
        class_hash_const::<1>()
    }

    enum FeeAmount {
        LOW: (),
        MEDIUM: (),
        HIGH: ()
    }

    fn fee_amount(fee_type: FeeAmount) -> u32 {
        match fee_type {
            FeeAmount::LOW => 500,
            FeeAmount::MEDIUM => 3000,
            FeeAmount::HIGH => 10000,
        }
    }

    fn tick_spacing(fee_type: FeeAmount) -> u32 {
        match fee_type {
            FeeAmount::LOW => 10,
            FeeAmount::MEDIUM => 60,
            FeeAmount::HIGH => 200,
        }
    }

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
            if i == 4 {
                break;
            }
            pop_log::<OwnerChanged>(address);
            i += 1;
        }
    }

    mod Constructor {
        use super::{
            OTHER, OWNER, ZERO, ONE_CLASS_HASH, FeeAmount, deploy, fee_amount, tick_spacing,
            clean_events
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
            let yas_factory = deploy(OWNER(), ONE_CLASS_HASH());
            assert(yas_factory.owner() == OWNER(), 'Owner doesnt match')
        }

        #[test]
        #[available_gas(20000000)]
        fn test_initial_enabled_fee_amounts() {
            let yas_factory = deploy(OWNER(), ONE_CLASS_HASH());

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
            let yas_factory = deploy(OWNER(), ONE_CLASS_HASH());

            let event = pop_log::<OwnerChanged>(yas_factory.contract_address).unwrap();
            assert(event.old_owner == ZERO(), 'event old owner should be ZERO');
            assert(event.new_owner == OWNER(), 'event new owner should be OWNER');

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

    mod SetOwner {
        use super::{OTHER, OWNER, ONE_CLASS_HASH, deploy, clean_events};
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
            let yas_factory = deploy(OWNER(), ONE_CLASS_HASH());
            set_contract_address(OTHER());
            yas_factory.set_owner(OTHER());
        }

        #[test]
        #[available_gas(20000000)]
        fn test_success_when_caller_is_owner() {
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER(), ONE_CLASS_HASH());

            // Set and read new owner
            yas_factory.set_owner(OTHER());
            assert(yas_factory.owner() == OTHER(), 'new owner should be OTHER');
        }

        #[test]
        #[available_gas(20000000)]
        fn test_emits_events() {
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER(), ONE_CLASS_HASH());

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
        use super::{OTHER, OWNER, ONE_CLASS_HASH, deploy, clean_events};
        use yas::contracts::yas_factory::{
            YASFactory, YASFactory::FeeAmountEnabled, IYASFactory, IYASFactoryDispatcher,
            IYASFactoryDispatcherTrait
        };
        use starknet::testing::{pop_log, set_contract_address};
        use yas::numbers::signed_integer::{integer_trait::IntegerTrait, i32::i32};

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('only owner can do this action!', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_caller_is_not_owner() {
            let yas_factory = deploy(OWNER(), ONE_CLASS_HASH());
            set_contract_address(OTHER());
            yas_factory.enable_fee_amount(100, IntegerTrait::<i32>::new(2, false));
        }

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('fee cannot be gt 1000000', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_fee_is_too_large() {
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER(), ONE_CLASS_HASH());

            yas_factory.enable_fee_amount(1000000, IntegerTrait::<i32>::new(20, false));
        }

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('wrong tick_spacing (0<ts<16384)', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_tick_spacing_is_too_large() {
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER(), ONE_CLASS_HASH());

            yas_factory.enable_fee_amount(500, IntegerTrait::<i32>::new(16834, false));
        }

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('wrong tick_spacing (0<ts<16384)', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_tick_spacing_is_too_small() {
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER(), ONE_CLASS_HASH());

            yas_factory.enable_fee_amount(500, IntegerTrait::<i32>::new(0, false));
        }

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('fee amount already initialized', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_already_initialized() {
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER(), ONE_CLASS_HASH());

            yas_factory.enable_fee_amount(100, IntegerTrait::<i32>::new(5, false));
            yas_factory.enable_fee_amount(100, IntegerTrait::<i32>::new(10, false));
        }

        #[test]
        #[available_gas(20000000)]
        fn test_set_fee_amount_in_the_mapping() {
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER(), ONE_CLASS_HASH());
            yas_factory.enable_fee_amount(100, IntegerTrait::<i32>::new(5, false));

            assert(
                yas_factory.fee_amount_tick_spacing(100) == IntegerTrait::<i32>::new(5, false),
                'wrong tick spacing for amount'
            );
        }

        #[test]
        #[available_gas(20000000)]
        fn test_emits_event() {
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER(), ONE_CLASS_HASH());

            // Clean up the 4 events emitted by the deploy
            clean_events(yas_factory.contract_address);

            yas_factory.enable_fee_amount(100, IntegerTrait::<i32>::new(5, false));

            // Verify FeeAmountEnabled event emitted
            let event = pop_log::<FeeAmountEnabled>(yas_factory.contract_address).unwrap();
            assert(event.fee == 100, 'fee event should be 100');
            assert(
                event.tick_spacing == IntegerTrait::<i32>::new(5, false),
                'tick_spacing event should be 5'
            );
        }
    // TODO: add this test when create_pool is implemented
    // it('enables pool creation', async () => {
    //       await factory.enableFeeAmount(250, 15)
    //       await createAndCheckPool([TEST_ADDRESSES[0], TEST_ADDRESSES[1]], 250, 15)
    //     })
    }
}
