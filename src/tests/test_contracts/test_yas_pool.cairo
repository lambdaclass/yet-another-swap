mod YASPoolTests {
    use starknet::ContractAddress;
    use starknet::syscalls::deploy_syscall;

    use yas::contracts::yas_pool::{YASPool, IYASPool, IYASPoolDispatcher, IYASPoolDispatcherTrait};
    use yas::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};

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

        use yas::contracts::yas_pool::{
            YASPool, IYASPool, IYASPoolDispatcher, IYASPoolDispatcherTrait
        };
        use yas::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};

        #[test]
        #[available_gas(2000000000000)]
        fn test_deployer() {
            let factory = contract_address_const::<'FACTORY'>();
            let token_0 = contract_address_const::<'TOKEN0'>();
            let token_1 = contract_address_const::<'TOKEN1'>();
            let fee = 5;
            let tick_spacing = IntegerTrait::<i32>::new(1, false);
            let yas_pool = deploy(factory, token_0, token_1, fee, tick_spacing);
        }
    }
}
