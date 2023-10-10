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
    use yas::numbers::fixed_point::implementations::impl_64x96::{
        FP64x96Impl, FixedType, FixedTrait
    };

    fn OWNER() -> ContractAddress {
        contract_address_const::<'OWNER'>()
    }

    fn WALLET() -> ContractAddress {
        contract_address_const::<'WALLET'>()
    }

    fn POOL_ADDRESS() -> ContractAddress {
        contract_address_const::<'POOL_ADDRESS'>()
    }

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

    // Due to issues with the calculations, the implementation of encode_sqrt_price(a, b)
    // was removed in favor of using constant values. What we are interested in testing are the 
    // methods of the SqrtPriceMath library.

    // returns result of encode_price_sqrt(1, 1) on v3-core typescript impl. 
    fn encode_price_sqrt_1_1() -> FixedType {
        FP64x96Impl::new(79228162514264337593543950336, false)
    }

    // sqrt_price_X96 is the result of encode_price_sqrt(1, 2) on v3-core typescript impl. 
    fn encode_price_sqrt_1_2() -> FixedType {
        FP64x96Impl::new(56022770974786139918731938227, false)
    }
}
