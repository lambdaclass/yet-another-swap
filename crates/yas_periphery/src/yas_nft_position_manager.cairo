use starknet::ContractAddress;
use yas::numbers::signed_integer::i32::i32;

#[starknet::interface]
trait IYASNFTPositionManager<TContractState> {
    fn positions(self: @TContractState, token_id: u256) -> i32;
}

#[starknet::contract]
mod YASNFTPositionManager {
    use super::IYASNFTPositionManager;

    use yas::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};

    #[storage]
    struct Storage {}

    #[external(v0)]
    impl YASNFTPositionManagerImpl of IYASNFTPositionManager<ContractState> {
        fn positions(self: @ContractState, token_id: u256) -> i32 {
            IntegerTrait::<i32>::new(0, false)
        }
    }
}
