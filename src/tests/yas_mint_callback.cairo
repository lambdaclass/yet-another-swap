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
        ref self: TContractState, amount_0_owed: u256, amount_1_owed: u256, data: Array<felt252>
    );
}

#[starknet::contract]
mod YASMintCallback {
    use core::array::ArrayTrait;
    use super::IYASMintCallback;

    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    use yas::contracts::yas_pool::{IYASPoolDispatcher, IYASPoolDispatcherTrait};
    use yas::interfaces::interface_ERC20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use yas::numbers::signed_integer::{integer_trait::IntegerTrait, i32::i32};

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
                .mint(
                    recipient, tick_lower, tick_upper, amount, array![get_caller_address().into()]
                );
        }


        fn yas_mint_callback(
            ref self: ContractState, amount_0_owed: u256, amount_1_owed: u256, data: Array<felt252>
        ) {
            let msg_sender = get_caller_address();

            // TODO: we need verify if data has a valid ContractAddress
            let mut sender: ContractAddress = Zeroable::zero();
            if !data.is_empty() {
                sender = (*data[0]).try_into().unwrap();
            }

            self.emit(MintCallback { amount_0_owed, amount_1_owed });

            if amount_0_owed > 0 {
                let token_0 = IYASPoolDispatcher { contract_address: msg_sender }.token_0();
                IERC20Dispatcher { contract_address: token_0 }
                    .transferFrom(sender, msg_sender, amount_0_owed);
            }
            if amount_1_owed > 0 {
                let token_1 = IYASPoolDispatcher { contract_address: msg_sender }.token_1();
                IERC20Dispatcher { contract_address: token_1 }
                    .transferFrom(sender, msg_sender, amount_1_owed);
            }
        }
    }
}

