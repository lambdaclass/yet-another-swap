use orion::numbers::signed_integer::i32::i32;
use orion::numbers::signed_integer::i64::i64;
use orion::numbers::signed_integer::i128::i128;
use orion::numbers::signed_integer::integer_trait::IntegerTrait;

#[derive(Copy, Drop, Serde, starknet::Store)]
struct Info {
    // the total position liquidity that references this tick
    liquidity_gross: u128,
    // amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
    liquidity_net: i128,
    // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    fee_growth_outside_0X128: u256,
    fee_growth_outside_1X128: u256,
    // the cumulative tick value on the other side of the tick
    tick_cumulative_outside: i64,
    // the seconds per unit of liquidity on the _other_ side of this tick (relative to the current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    seconds_per_liquidity_outside_X128: u256,
    // the seconds spent on the other side of the tick (relative to the current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    seconds_outside: u32,
    // true if the tick is initialized, i.e. the value is exactly equivalent to the expression liquidityGross != 0
    // these 8 bits are set to prevent fresh sstores when crossing newly initialized ticks
    initialized: bool
}

#[starknet::interface]
trait ITick<TStorage> {
    fn get_fee_growth_inside(
        ref self: TStorage,
        tick_lower: i32,
        tick_upper: i32,
        tick_current: i32,
        fee_growth_global_0X128: u256,
        fee_growth_global_1X128: u256
    ) -> (u256, u256);
    fn set_tick(ref self: TStorage, tick: i32, info: Info);
}

#[starknet::contract]
mod Tick {
    use super::{ITick, Info};

    use array::ArrayTrait;
    use option::{OptionTrait};
    use poseidon::poseidon_hash_span;
    use serde::Serde;
    use traits::{Into, TryInto};

    use orion::numbers::signed_integer::i32::i32;
    use orion::numbers::signed_integer::i64::i64;
    use orion::numbers::signed_integer::i128::i128;
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;

    #[storage]
    struct Storage {
        ticks: LegacyMap::<felt252, Info>
    }

    #[external(v0)]
    impl Tick of ITick<ContractState> {
        /// @notice Retrieves fee growth data
        /// @param self The mapping containing all tick information for initialized ticks
        /// @param tick_lower The lower tick boundary of the position
        /// @param tick_upper The upper tick boundary of the position
        /// @param tick_current The current tick
        /// @param fee_growth_global_0X128 The all-time global fee growth, per unit of liquidity, in token0
        /// @param fee_growth_global_1X128 The all-time global fee growth, per unit of liquidity, in token1
        /// @return fee_growth_inside_0X128 The all-time fee growth in token0, per unit of liquidity, inside the position's tick boundaries
        /// @return fee_growth_inside_1X128 The all-time fee growth in token1, per unit of liquidity, inside the position's tick boundaries    
        fn get_fee_growth_inside(
            ref self: ContractState,
            tick_lower: i32,
            tick_upper: i32,
            tick_current: i32,
            fee_growth_global_0X128: u256,
            fee_growth_global_1X128: u256
        ) -> (u256, u256) {
            let lower: Info = self.ticks.read(self._generate_hashed_tick(@tick_lower));
            let upper: Info = self.ticks.read(self._generate_hashed_tick(@tick_upper));

            // calculate fee growth below
            let (fee_growth_below_0X128, fee_growth_below_1X128) = if tick_current >= tick_lower {
                (lower.fee_growth_outside_0X128, lower.fee_growth_outside_1X128)
            } else {
                (
                    fee_growth_global_0X128 - lower.fee_growth_outside_0X128,
                    fee_growth_global_1X128 - lower.fee_growth_outside_1X128
                )
            };

            // calculate fee growth above
            let (fee_growth_above_0X128, fee_growth_above_1X128) = if tick_current < tick_upper {
                (upper.fee_growth_outside_0X128, upper.fee_growth_outside_1X128)
            } else {
                (
                    fee_growth_global_0X128 - upper.fee_growth_outside_0X128,
                    fee_growth_global_1X128 - upper.fee_growth_outside_1X128
                )
            };

            (
                fee_growth_global_0X128 - fee_growth_below_0X128 - fee_growth_above_0X128,
                fee_growth_global_1X128 - fee_growth_below_1X128 - fee_growth_above_1X128
            )
        }

        fn set_tick(ref self: ContractState, tick: i32, info: Info) {
            let hashed_tick = self._generate_hashed_tick(@tick);
            self.ticks.write(hashed_tick, info);
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _generate_hashed_tick(self: @ContractState, tick: @i32) -> felt252 {
            let mut serialized: Array<felt252> = ArrayTrait::new();
            Serde::<i32>::serialize(tick, ref serialized);
            poseidon_hash_span(serialized.span())
        }
    }
}
