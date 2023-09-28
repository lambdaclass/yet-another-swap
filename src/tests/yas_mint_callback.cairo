#[starknet::interface]
trait IYASMintCallback<TContractState> {
    fn yas_mint_callback(
        self: @TContractState, amount_0_owed: u256, amount_1_owed: u256, data: Array<felt252>
    );
}

#[starknet::contract]
mod YASMintCallback {
    use super::IYASMintCallback;

    use starknet::{get_caller_address, get_contract_address};

    use yas::interfaces::interface_ERC20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use yas::contracts::yas_pool::{IYASPoolDispatcher, IYASPoolDispatcherTrait};

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        MintCallback: MintCallback,
    }

    #[derive(Drop, starknet::Event)]
    struct MintCallback {
        amount_0_owed: u256,
        amount_1_owed: u256
    }

    #[storage]
    struct Storage {}

    #[external(v0)]
    impl YASMintCallbackImpl of IYASMintCallback<ContractState> {
        fn yas_mint_callback(
            self: @ContractState, amount_0_owed: u256, amount_1_owed: u256, data: Array<felt252>
        ) {
            let sender = get_caller_address();
            let sender_contract_address = get_contract_address();

            // self.emit(MintCallback { amount_0_owed, amount_1_owed });

            if amount_0_owed > 0 {
                let token_0 = IYASPoolDispatcher { contract_address: sender }.token_0();
                IERC20Dispatcher { contract_address: token_0 }
                    .transferFrom(sender_contract_address, sender, amount_0_owed);
            }
            if amount_1_owed > 0 {
                let token_1 = IYASPoolDispatcher { contract_address: sender }.token_1();
                IERC20Dispatcher { contract_address: token_1 }
                    .transferFrom(sender_contract_address, sender, amount_1_owed);
            }
        }
    }
}

