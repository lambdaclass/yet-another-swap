use starknet::ContractAddress;
use orion::numbers::signed_integer::i32::i32;
use orion::numbers::signed_integer::integer_trait::IntegerTrait;

#[starknet::interface]
trait IPositions<TStorage> {
    fn get(owner: ContractAddress, tickLower: i32, tickUpper: i32) -> u8;
}

////////////////////////////////
// Positions represent an owner address' liquidity between a lower and upper tick boundary
////////////////////////////////
#[starknet::contract]
mod Position {
    use super::{IPositions};
    use starknet::collections::LegacyMap;
    use fractal_swap::libraries::position_utils::PositionUtils::_generate_id_position;
    use option::OptionTrait;

    // info stored for each user's position
    struct Info {
        // the amount of liquidity owned by this position
        liquidity: u256,
        // fee growth per unit of liquidity as of the last update to liquidity or fees owed
        feeGrowthInside0LastX128: u256,
        feeGrowthInside1LastX128: u256,
        // the fees owed to the position owner in token0/token1
        tokensOwed0: u256,
        tokensOwed1: u256,
    }

    #[storage]
    struct Storage {
        positions: LegacyMap<felt252, Info>
    }

    #[external(v0)]
    impl Positions of IPositions<ContractState> {
        fn get(
            self: @ContractState,
            owner: ContractAddress, // In the original version the following attributes have int24 data types
            tickLower: i32,
            tickUpper: i32
        ) -> Option<Info> {
            let id = _generate_id_position(owner, tickLower, tickUpper);
            let position = self.positions.read((id));

            if position.liquidity == 0
                && position.feeGrowthInside0LastX128 == 0
                && position.feeGrowthInside1LastX128 == 0
                && position.tokensOwed0 == 0
                && position.tokensOwed1 == 0 {
                return None;
            }

            return Some(position);
        }
    }
}

