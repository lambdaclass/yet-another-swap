use starknet::ContractAddress;
use orion::numbers::signed_integer::{i32::i32, i64::i64, i128::i128, integer_trait::IntegerTrait};
use hash::{HashStateTrait, HashStateExTrait};
use poseidon::PoseidonTrait;
use poseidon::poseidon_hash_span;


// info stored for each user's position
#[derive(Copy, Drop, Serde, starknet::Store)]
struct Info {
    // the amount of liquidity owned by this position
    liquidity: u128,
    // fee growth per unit of liquidity as of the last update to liquidity or fees owned
    fee_growth_inside_0_last_X128: u256,
    fee_growth_inside_1_last_X128: u256,
    // the fee owed to the position owner in token0/token1
    tokens_owed_0: u128,
    tokens_owed_1: u128,
}

#[derive(Copy, Drop, Serde, starknet::Store)]
struct PositionKey {
    owner: starknet::ContractAddress,
    tick_lower: i32,
    tick_upper: i32,
}

#[starknet::interface]
trait IPosition<TContractState> {
    fn get(
        self: @TContractState, owner: starknet::ContractAddress, tick_lower: i32, tick_upper: i32
    ) -> Info;
// fn update(self: ref TContractState, liquidity_delta: i128, fee_growth_inside_0_X128: u256, fee_growth_inside_1_X128: u256) -> Info;
}

fn generate_hashed_position_key(key: @PositionKey) -> felt252 {
    let mut serialized: Array<felt252> = ArrayTrait::new();
    Serde::<PositionKey>::serialize(key, ref serialized);
    poseidon_hash_span(serialized.span())
}

#[starknet::contract]
mod Position {
    use super::{PositionKey, IPosition, Info, generate_hashed_position_key};
    use orion::numbers::signed_integer::{
        i32::i32, i64::i64, i128::i128, integer_trait::IntegerTrait
    };
    use hash::{HashStateTrait, HashStateExTrait};
    use poseidon::PoseidonTrait;
    use serde::Serde;
    use array::ArrayTrait;

    #[storage]
    struct Storage {
        positions: LegacyMap::<felt252, Info>,
    }

    #[external(v0)]
    impl PositionImpl of IPosition<ContractState> {
        /// @notice Returns the Info struct of a position, given an owner and position boundaries
        /// @param self The mapping containing all user positions
        /// @param owner The ContractAddress of the position owner
        /// @param tickLower The lower tick boundary of the position
        /// @param tickUpper The upper tick boundary of the position
        /// @return position The position info struct of the given owners' position
        fn get(
            self: @ContractState, owner: starknet::ContractAddress, tick_lower: i32, tick_upper: i32
        ) -> Info {
            let key = PositionKey { owner: owner, tick_lower: tick_lower, tick_upper: tick_upper };
            let hashed_key = generate_hashed_position_key(@key);
            self.positions.read(hashed_key)
        }
    }
}

