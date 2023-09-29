use starknet::ContractAddress;

use yas::numbers::signed_integer::{i32::i32, i256::i256};
use yas::numbers::fixed_point::implementations::impl_64x96::FixedType;

#[starknet::interface]
trait IYASRouter<TContractState> {
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
    fn swap(
        self: @TContractState,
        pool: ContractAddress,
        recipient: ContractAddress,
        zero_for_one: bool,
        amount_specified: i256,
        sqrt_price_limit_X96: FixedType
    ) -> (i256, i256);
    fn yas_swap_callback(
        ref self: TContractState, amount_0_delta: i256, amount_1_delta: i256, data: Array<felt252>
    );
}

#[starknet::contract]
mod YASRouter {
    use super::IYASRouter;

    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    use yas::contracts::yas_pool::{IYASPoolDispatcher, IYASPoolDispatcherTrait};
    use yas::interfaces::interface_ERC20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use yas::numbers::signed_integer::{i32::i32, i256::i256};
    use yas::numbers::fixed_point::implementations::impl_64x96::FixedType;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        MintCallback: MintCallback,
        SwapCallback: SwapCallback
    }

    #[derive(Drop, starknet::Event)]
    struct MintCallback {
        amount_0_owed: u256,
        amount_1_owed: u256
    }

    #[derive(Drop, starknet::Event)]
    struct SwapCallback {
        amount_0_delta: i256,
        amount_1_delta: i256
    }

    #[storage]
    struct Storage {}

    #[external(v0)]
    impl YASRouterCallbackImpl of IYASRouter<ContractState> {
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

        fn swap(
            self: @ContractState,
            pool: ContractAddress,
            recipient: ContractAddress,
            zero_for_one: bool,
            amount_specified: i256,
            sqrt_price_limit_X96: FixedType
        ) -> (i256, i256) {
            IYASPoolDispatcher { contract_address: pool }
                .swap(
                    recipient,
                    zero_for_one,
                    amount_specified,
                    sqrt_price_limit_X96,
                    array![get_caller_address().into()]
                )
        }

        fn yas_swap_callback(
            ref self: ContractState,
            amount_0_delta: i256,
            amount_1_delta: i256,
            data: Array<felt252>
        ) {
            let msg_sender = get_caller_address();

            // TODO: we need verify if data has a valid ContractAddress
            let mut sender: ContractAddress = Zeroable::zero();
            if !data.is_empty() {
                sender = (*data[0]).try_into().unwrap();
            }

            self.emit(SwapCallback { amount_0_delta, amount_1_delta });

            if amount_0_delta > Zeroable::zero() {
                let token_0 = IYASPoolDispatcher { contract_address: msg_sender }.token_0();
                IERC20Dispatcher { contract_address: token_0 }
                    .transferFrom(sender, msg_sender, amount_0_delta.try_into().unwrap());
            } else if amount_1_delta > Zeroable::zero() {
                let token_1 = IYASPoolDispatcher { contract_address: msg_sender }.token_1();
                IERC20Dispatcher { contract_address: token_1 }
                    .transferFrom(sender, msg_sender, amount_1_delta.try_into().unwrap());
            } else {
                // if both are not gt 0, both must be 0.
                assert(
                    amount_0_delta == Zeroable::zero() && amount_1_delta == Zeroable::zero(),
                    'both amount deltas are negative'
                );
            }
        }
    }
}
