use starknet::ContractAddress;
use yas::numbers::signed_integer::{i32::i32, i64::i64, i128::i128, integer_trait::IntegerTrait};
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
    /// @notice Returns the Info struct of a position, given an owner and position boundaries
    /// @param self The mapping containing all user positions
    /// @param owner The ContractAddress of the position owner
    /// @param position_key conformed by the owner and the tick boundaries
    fn get(self: @TContractState, position_key: PositionKey) -> Info;


    fn update(
        ref self: TContractState,
        position_key: PositionKey,
        liquidity_delta: i128,
        fee_growth_inside_0_X128: u256,
        fee_growth_inside_1_X128: u256
    );
}

fn generate_hashed_position_key(key: @PositionKey) -> felt252 {
    let mut serialized: Array<felt252> = ArrayTrait::new();
    Serde::<PositionKey>::serialize(key, ref serialized);
    poseidon_hash_span(serialized.span())
}

#[starknet::contract]
mod Position {
    use core::traits::Into;
    use core::traits::TryInto;

    use super::{PositionKey, IPosition, Info, generate_hashed_position_key};

    use yas::numbers::signed_integer::{i32::i32, i64::i64, i128::i128, integer_trait::IntegerTrait};
    use yas::utils::math_utils::FullMath::{mul_div};

    use hash::{HashStateTrait, HashStateExTrait};
    use poseidon::PoseidonTrait;
    use serde::Serde;
    use array::ArrayTrait;
    use yas::libraries::liquidity_math::LiquidityMath::{add_delta};
    use integer::BoundedInt;

    #[storage]
    struct Storage {
        positions: LegacyMap::<felt252, Info>,
    }

    #[external(v0)]
    impl PositionImpl of IPosition<ContractState> {
        fn get(self: @ContractState, position_key: PositionKey) -> Info {
            let hashed_key = generate_hashed_position_key(@position_key);
            self.positions.read(hashed_key)
        }

        fn update(
            ref self: ContractState,
            position_key: PositionKey,
            liquidity_delta: i128,
            fee_growth_inside_0_X128: u256,
            fee_growth_inside_1_X128: u256
        ) {
            // get the position info
            let hashed_key = generate_hashed_position_key(@position_key);
            let mut position = self.positions.read(hashed_key);

            let liquidity_next: u128 = if liquidity_delta == IntegerTrait::<i128>::new(0, false) {
                // disallows pokes for 0 liquidity positions
                assert(position.liquidity > 0, 'NP');
                position.liquidity
            } else {
                add_delta(position.liquidity, liquidity_delta)
            };

            // calculate accumulated fees
            let max_u128_plus_one: u128 = BoundedInt::max() + 1;
            let tokens_owed_0: u128 = mul_div(
                fee_growth_inside_0_X128 - position.fee_growth_inside_0_last_X128,
                position.liquidity.into(),
                max_u128_plus_one.into()
            )
                .try_into()
                .unwrap();
            let tokens_owed_1: u128 = mul_div(
                fee_growth_inside_1_X128 - position.fee_growth_inside_1_last_X128,
                position.liquidity.into(),
                max_u128_plus_one.into()
            )
                .try_into()
                .unwrap();

            // update the position
            if (liquidity_delta != IntegerTrait::<i128>::new(0, false)) {
                position.liquidity = liquidity_next;
            }

            position.fee_growth_inside_0_last_X128 = fee_growth_inside_0_X128;
            position.fee_growth_inside_1_last_X128 = fee_growth_inside_1_X128;

            if (tokens_owed_0 > 0 || tokens_owed_1 > 0) {
                // overflow is acceptable, have to withdraw before you hit type(uint128).max fees
                position.tokens_owed_0 += tokens_owed_0;
                position.tokens_owed_1 += tokens_owed_1;
            }
        }
    }
}

