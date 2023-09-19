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
