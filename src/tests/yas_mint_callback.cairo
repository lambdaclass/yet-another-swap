use starknet::ContractAddress;

use yas::numbers::signed_integer::{integer_trait::IntegerTrait, i32::i32};

#[starknet::interface]
trait IYASMintCallback<TContractState> {
    fn mint(
        self: @TContractState,
        pool: ContractAddress,
        recipient: ContractAddress,
        tick_lower: i32,
        tick_upper: i32,
        amount: u128
    );
    fn yas_mint_callback(
        self: @TContractState, amount_0_owed: u256, amount_1_owed: u256, data: Array<felt252>
    );
}

#[starknet::contract]
mod YASMintCallback {
    use super::IYASMintCallback;

    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    use yas::contracts::yas_pool::{IYASPoolDispatcher, IYASPoolDispatcherTrait};
    use yas::interfaces::interface_ERC20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use yas::numbers::signed_integer::{integer_trait::IntegerTrait, i32::i32};

    use debug::PrintTrait;

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
        fn mint(
            self: @ContractState,
            pool: ContractAddress,
            recipient: ContractAddress,
            tick_lower: i32,
            tick_upper: i32,
            amount: u128
        ) {
            IYASPoolDispatcher { contract_address: pool }
                .mint(recipient, tick_lower, tick_upper, amount, array![]);
        }


        fn yas_mint_callback(
            self: @ContractState, amount_0_owed: u256, amount_1_owed: u256, data: Array<felt252>
        ) {
            let sender = get_caller_address();
            let sender_contract_address = get_contract_address();

            'sender'.print();
            sender.print();

            'sender_contract_address'.print();
            sender_contract_address.print();

            // self.emit(MintCallback { amount_0_owed, amount_1_owed });

            if amount_0_owed > 0 {
                let token_0 = IYASPoolDispatcher { contract_address: sender }.token_0();
                let balance_sender_contract = IERC20Dispatcher { contract_address: token_0 }
                    .balanceOf(sender_contract_address);
                'balance_sender_contract token 0'.print();
                balance_sender_contract.print();
                IERC20Dispatcher { contract_address: token_0 }
                    .transferFrom(sender_contract_address, sender, amount_0_owed);
            }
            if amount_1_owed > 0 {
                let token_1 = IYASPoolDispatcher { contract_address: sender }.token_1();

                let balance_sender_contract = IERC20Dispatcher { contract_address: token_1 }
                    .balanceOf(sender_contract_address);
                'balance_sender_contract token 1'.print();
                balance_sender_contract.print();

                IERC20Dispatcher { contract_address: token_1 }
                    .transferFrom(sender_contract_address, sender, amount_1_owed);
            }
        }
    }
}

