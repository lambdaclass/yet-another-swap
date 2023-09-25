#[starknet::interface]
trait IYASMintCallback<TContractState> {
    fn yas_mint_callback(
        self: @TContractState, amount_0_owed: u256, amount_1_owed: u256, data: Array<felt252>
    );
}
