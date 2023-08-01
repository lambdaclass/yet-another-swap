#[starknet::interface]
trait TContract<TContractState> {
    fn get_token_x_quantity(self: @TContractState) -> felt252;
    fn get_token_y_quantity(self: @TContractState) -> felt252;
    fn increase_token_x_quantity(ref self: TContractState, amount: felt252) -> felt252;
    fn increase_token_y_quantity(ref self: TContractState, amount: felt252) -> felt252;
}

#[starknet::contract]
mod Contract {
    #[storage]
    struct Storage {
        token_x_quantity: felt252,
        token_y_quantity: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState, token_x_quantity: felt252, token_y_quantity: felt252) {
        self.token_x_quantity.write(token_x_quantity);
        self.token_y_quantity.write(token_y_quantity);
    }

    #[external(v0)]
    impl Contract of super::TContract<ContractState> {
        fn get_token_x_quantity(self: @ContractState) -> felt252 {
            self.token_x_quantity.read()
        }
        fn get_token_y_quantity(self: @ContractState) -> felt252 {
            self.token_y_quantity.read()
        }
        fn increase_token_x_quantity(ref self: ContractState, amount: felt252) -> felt252 {
            let current_amount = self.token_x_quantity.read();
            let new_amount = current_amount + amount;
            self.token_x_quantity.write(new_amount);
            new_amount
        }
        fn increase_token_y_quantity(ref self: ContractState, amount: felt252) -> felt252 {
            let current_amount = self.token_y_quantity.read();
            let new_amount = current_amount + amount;
            self.token_y_quantity.write(new_amount);
            new_amount
        }
    }
}
