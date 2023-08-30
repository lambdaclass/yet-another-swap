use array::ArrayTrait;
use serde::Serde;

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
    // true iff the tick is initialized, i.e. the value is exactly equivalent to the expression liquidityGross != 0
    // these 8 bits are set to prevent fresh sstores when crossing newly initialized ticks
    initialized: bool
}

#[starknet::interface]
trait ITick<TStorage> {
    fn set_tick(ref self: TStorage);
    fn get_tick(self: @TStorage, tick: felt252) -> Info;
}

#[starknet::contract]
mod Tick {
    use super::{ITick, Info};

    use array::ArrayTrait;
    use option::{OptionTrait};
    use poseidon::poseidon_hash_span;
    use serde::Serde;
    use traits::{Into, TryInto};

    use orion::numbers::signed_integer::i64::i64;
    use orion::numbers::signed_integer::i128::i128;
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;

    #[storage]
    struct Storage {
        ticks: LegacyMap::<felt252, Info>
    }

    #[external(v0)]
    impl Tick of ITick<ContractState> {
        fn set_tick(ref self: ContractState) {
            self
                .ticks
                .write(
                    1,
                    Info {
                        liquidity_gross: 1,
                        liquidity_net: IntegerTrait::<i128>::new(2, false),
                        fee_growth_outside_0X128: 3,
                        fee_growth_outside_1X128: 4,
                        tick_cumulative_outside: IntegerTrait::<i64>::new(5, false),
                        seconds_per_liquidity_outside_X128: 6,
                        seconds_outside: 7,
                        initialized: true
                    }
                );
        }

        fn get_tick(self: @ContractState, tick: felt252) -> Info {
            self.ticks.read(tick)
        }
    }
}
