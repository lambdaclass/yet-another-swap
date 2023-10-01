use yas::numbers::signed_integer::i256::i256;

// In order to do a swap the contract trying to perform this action will have to implement this function in their code.
#[starknet::interface]
trait IYASFlashCallback<TContractState> {
    fn yas_flash_callback(
        self: @TContractState, amount_0_delta: u256, amount_1_delta: u256, data: Array<felt252>
    );
}