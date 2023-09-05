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
    fn clear(ref self: TStorage, tick: i32);
    // TODO: Function used for testing. To be removed in the future
    fn set_tick(ref self: TStorage, tick: i32, info: Info);
    // TODO: Function used for testing. To be removed in the future
    fn get_tick(self: @TStorage, tick: i32) -> Info;
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
        /// @notice Clears tick data
        /// @param self The mapping containing all initialized tick information for initialized ticks
        /// @param tick The tick that will be cleared
        fn clear(ref self: ContractState, tick: i32) {
            let hashed_tick = self._generate_hashed_tick(@tick);
            self
                .ticks
                .write(
                    hashed_tick,
                    Info {
                        liquidity_gross: 0,
                        liquidity_net: IntegerTrait::<i128>::new(0, false),
                        fee_growth_outside_0X128: 0,
                        fee_growth_outside_1X128: 0,
                        tick_cumulative_outside: IntegerTrait::<i64>::new(0, false),
                        seconds_per_liquidity_outside_X128: 0,
                        seconds_outside: 0,
                        initialized: false
                    }
                );
        }

        fn set_tick(ref self: ContractState, tick: i32, info: Info) {
            let hashed_tick = self._generate_hashed_tick(@tick);
            self.ticks.write(hashed_tick, info);
        }

        fn get_tick(self: @ContractState, tick: i32) -> Info {
            let hashed_tick = self._generate_hashed_tick(@tick);
            self.ticks.read(hashed_tick)
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
