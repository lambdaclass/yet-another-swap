#[starknet::interface]
trait IYASPool<TContractState> {
    fn initialize(ref self: TContractState);
}

#[starknet::contract]
mod YASPool {
    use super::IYASPool;
    use starknet::ContractAddress;

    use yas::libraries::tick::Tick;
    use yas::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};

    #[storage]
    struct Storage {
        factory: ContractAddress,
        token_0: ContractAddress,
        token_1: ContractAddress,
        fee: u32,
        liquidity_per_tick: u128,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        factory: ContractAddress,
        token_0: ContractAddress,
        token_1: ContractAddress,
        fee: u32,
        tick_spacing: i32,
    ) {
        self.factory.write(factory);
        self.token_0.write(token_0);
        self.token_1.write(token_1);
        self.fee.write(fee);

        //TODO: temporary component syntax
        let state = Tick::unsafe_new_contract_state();
        self
            .liquidity_per_tick
            .write(Tick::TickImpl::tick_spacing_to_max_liquidity_per_tick(@state, tick_spacing));
    }

    #[external(v0)]
    impl YASPoolImpl of IYASPool<ContractState> {
        fn initialize(ref self: ContractState) { // TODO: implement
        }
    }
}
