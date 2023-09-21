use yas::numbers::signed_integer::i256::i256;

#[starknet::interface]
trait IYASSwapCallback<TContractState> {
    fn yas_swap_callback(
        self: @TContractState, amount_0_delta: i256, amount_1_delta: i256, data: Array<felt252>
    );
}
