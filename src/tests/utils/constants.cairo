mod FactoryConstants {
    use starknet::{ContractAddress, ClassHash, contract_address_const, class_hash_const};
    use yas::contracts::yas_pool::{YASPool, IYASPool, IYASPoolDispatcher, IYASPoolDispatcherTrait};

    fn OWNER() -> ContractAddress {
        contract_address_const::<'OWNER'>()
    }

    fn OTHER() -> ContractAddress {
        contract_address_const::<'CALLER'>()
    }

    fn ZERO() -> ContractAddress {
        Zeroable::zero()
    }

    fn POOL_CLASS_HASH() -> ClassHash {
        YASPool::TEST_CLASS_HASH.try_into().unwrap()
    }

    fn TOKEN_A() -> ContractAddress {
        contract_address_const::<'A'>()
    }

    fn TOKEN_B() -> ContractAddress {
        contract_address_const::<'B'>()
    }

    enum FeeAmount {
        CUSTOM: (),
        LOW: (),
        MEDIUM: (),
        HIGH: ()
    }

    fn fee_amount(fee_type: FeeAmount) -> u32 {
        match fee_type {
            FeeAmount::CUSTOM => 100,
            FeeAmount::LOW => 500,
            FeeAmount::MEDIUM => 3000,
            FeeAmount::HIGH => 10000,
        }
    }

    fn tick_spacing(fee_type: FeeAmount) -> u32 {
        match fee_type {
            FeeAmount::CUSTOM => 2,
            FeeAmount::LOW => 10,
            FeeAmount::MEDIUM => 60,
            FeeAmount::HIGH => 200,
        }
    }
}

mod PoolConstants {
    use starknet::{ContractAddress, contract_address_const};

    use yas::contracts::yas_pool::{YASPool, IYASPool, IYASPoolDispatcher, IYASPoolDispatcherTrait};
    use yas::numbers::signed_integer::{
        i32::i32, i32::i32_div_no_round, integer_trait::IntegerTrait
    };

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
}
