mod YASFactoryTests {
    use starknet::syscalls::deploy_syscall;
    use starknet::testing::pop_log;
    use starknet::{contract_address_const, ContractAddress};
    use yas::contracts::yas_factory::{
        YASFactory, YASFactory::OwnerChanged, YASFactory::FeeAmountEnabled, IYASFactory,
        IYASFactoryDispatcher, IYASFactoryDispatcherTrait
    };
    use orion::numbers::signed_integer::i32::i32;

    use debug::PrintTrait;

    fn OWNER() -> ContractAddress {
        contract_address_const::<'OWNER'>()
    }

    fn OTHER() -> ContractAddress {
        contract_address_const::<'CALLER'>()
    }

    fn ZERO() -> ContractAddress {
        Zeroable::zero()
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

    fn deploy(deployer: ContractAddress) -> IYASFactoryDispatcher {
        let (address, _) = deploy_syscall(
            YASFactory::TEST_CLASS_HASH.try_into().unwrap(), 0, array![deployer.into()].span(), true
        )
            .expect('DEPLOY FAILED');

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
        use super::{OTHER, OWNER, ZERO, FeeAmount, deploy, fee_amount, tick_spacing, clean_events};
        use yas::contracts::yas_factory::{
            YASFactory, YASFactory::OwnerChanged, YASFactory::FeeAmountEnabled, IYASFactory,
            IYASFactoryDispatcher, IYASFactoryDispatcherTrait
        };
        use starknet::{
            contract_address_const, testing::{set_caller_address, set_contract_address, pop_log}
        };
        use orion::numbers::signed_integer::i32::i32;
        use debug::PrintTrait;

        #[test]
        #[available_gas(20000000)]
        fn test_deployer_should_be_contract_owner() {
            let yas_factory = deploy(OWNER());
            assert(yas_factory.owner() == OWNER(), 'Owner doesnt match')
        }

        #[test]
        #[available_gas(20000000)]
        fn test_initial_enabled_fee_amounts() {
            let yas_factory = deploy(OWNER());

            let fee_amount_low = yas_factory.fee_amount_tick_spacing(fee_amount(FeeAmount::LOW));
            assert(
                fee_amount_low == i32 { mag: tick_spacing(FeeAmount::LOW), sign: false },
                'fee low doesnt set correctly'
            );

            let fee_amount_med = yas_factory.fee_amount_tick_spacing(fee_amount(FeeAmount::MEDIUM));
            assert(
                fee_amount_med == i32 { mag: tick_spacing(FeeAmount::MEDIUM), sign: false },
                'fee med doesnt set correctly'
            );

            let fee_amount_high = yas_factory.fee_amount_tick_spacing(fee_amount(FeeAmount::HIGH));
            assert(
                fee_amount_high == i32 { mag: tick_spacing(FeeAmount::HIGH), sign: false },
                'fee high doesnt set correctly'
            );
        }

        #[test]
        #[available_gas(20000000)]
        fn test_emits_events() {
            // TODO: Why we should use set_contract_address instead of set_caller_address, doesnt make sense
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER());

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
        use super::{OTHER, OWNER, ZERO, deploy, clean_events};
        use yas::contracts::yas_factory::{
            YASFactory, YASFactory::OwnerChanged, IYASFactory, IYASFactoryDispatcher,
            IYASFactoryDispatcherTrait
        };
        use starknet::{
            contract_address_const, testing::{pop_log, set_caller_address, set_contract_address}
        };
        use orion::numbers::signed_integer::i32::i32;

        use debug::PrintTrait;

        #[test]
        #[available_gas(20000000)]
        #[should_panic(expected: ('Only owner can do this action!', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_caller_is_not_owner() {
            let yas_factory = deploy(OWNER());
            set_contract_address(OTHER());
            yas_factory.set_owner(OTHER());
        }

        #[test]
        #[available_gas(20000000)]
        fn test_success_when_caller_is_owner() {
            // TODO: Why we should use set_contract_address instead of set_caller_address, doesnt make sense
            set_contract_address(OWNER());
            let yas_factory = deploy(OWNER());

            // Clean up the 4 events emitted by the deploy
            clean_events(yas_factory.contract_address);

            // Set and read new owner
            yas_factory.set_owner(OTHER());
            let new_owner = yas_factory.owner();

            assert(new_owner == OTHER(), 'new owner should be OTHER');

            // Verify OwnerChanged event emitted
            let event = pop_log::<OwnerChanged>(yas_factory.contract_address).unwrap();
            assert(event.old_owner == OWNER(), 'event old owner should be OWNER');
            assert(event.new_owner == OTHER(), 'event new owner should be OTHER');
        }
    }
}
