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
    fn tick_spacing_to_max_liquidity_per_tick(self: @TStorage, tick_spacing: i32) -> u128;
    fn clear(ref self: TStorage, tick: i32);
    fn cross(
        ref self: TStorage,
        tick: i32,
        fee_growth_global_0X128: u256,
        fee_growth_global_1X128: u256,
        seconds_per_liquidity_cumulative_X128: u256,
        tick_cumulative: i64,
        time: u32
    ) -> i128;
    fn get_fee_growth_inside(
        ref self: TStorage,
        tick_lower: i32,
        tick_upper: i32,
        tick_current: i32,
        fee_growth_global_0X128: u256,
        fee_growth_global_1X128: u256
    ) -> (u256, u256);
    // TODO: Function used for testing. To be removed in the future
    fn set_tick(ref self: TStorage, tick: i32, info: Info);
    // TODO: Function used for testing. To be removed in the future
    fn get_tick(self: @TStorage, tick: i32) -> Info;
}

#[starknet::contract]
mod Tick {
    use super::{ITick, Info};

    use poseidon::poseidon_hash_span;
    use serde::Serde;
    use integer::BoundedInt;

    use orion::numbers::signed_integer::{i32::i32, i64::i64, i128::i128};
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;

    use yas::utils::math_utils::MathUtils::{i32_div, mod_subtraction};
    use yas::utils::orion_utils::OrionUtils::i32TryIntou128;

    #[storage]
    struct Storage {
        ticks: LegacyMap::<felt252, Info>
    }

    #[external(v0)]
    impl Tick of ITick<ContractState> {
        /// @notice Derives max liquidity per tick from given tick spacing
        /// @dev Executed within the pool constructor
        /// @param tick_spacing The amount of required tick separation, realized in multiples of `tick_spacing`
        ///     e.g., a tick_spacing of 3 requires ticks to be initialized every 3rd tick i.e., ..., -6, -3, 0, 3, 6, ...
        /// @return The max liquidity per tick
        fn tick_spacing_to_max_liquidity_per_tick(self: @ContractState, tick_spacing: i32) -> u128 {
            let MIN_TICK = IntegerTrait::<i32>::new(887272, true);
            let MAX_TICK = IntegerTrait::<i32>::new(887272, false);

            let min_tick = i32_div(MIN_TICK, tick_spacing) * tick_spacing;
            let max_tick = i32_div(MAX_TICK, tick_spacing) * tick_spacing;
            let num_ticks = i32_div((max_tick - min_tick), tick_spacing)
                + IntegerTrait::<i32>::new(1, false);

            let max_u128: u128 = BoundedInt::max();
            max_u128 / num_ticks.try_into().expect('num ticks cannot be negative!')
        }

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

        /// @notice Transitions to next tick as needed by price movement
        /// @param self The mapping containing all tick information for initialized ticks
        /// @param tick The destination tick of the transition
        /// @param fee_growth_global_0X128 The all-time global fee growth, per unit of liquidity, in token0
        /// @param fee_growth_global_1X128 The all-time global fee growth, per unit of liquidity, in token1
        /// @param seconds_per_liquidity_cumulative_X128 The current seconds per liquidity
        /// @param tick_cumulative The tick * time elapsed since the pool was first initialized
        /// @param time The current block.timestamp
        /// @return liquidity_net The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left)
        fn cross(
            ref self: ContractState,
            tick: i32,
            fee_growth_global_0X128: u256,
            fee_growth_global_1X128: u256,
            seconds_per_liquidity_cumulative_X128: u256,
            tick_cumulative: i64,
            time: u32
        ) -> i128 {
            let hashed_tick = self._generate_hashed_tick(@tick);
            let mut info: Info = self.ticks.read(hashed_tick);
            info.fee_growth_outside_0X128 = fee_growth_global_0X128 - info.fee_growth_outside_0X128;
            info.fee_growth_outside_1X128 = fee_growth_global_1X128 - info.fee_growth_outside_1X128;
            info.seconds_per_liquidity_outside_X128 = seconds_per_liquidity_cumulative_X128
                - info.seconds_per_liquidity_outside_X128;
            info.tick_cumulative_outside = tick_cumulative - info.tick_cumulative_outside;
            info.seconds_outside = time - info.seconds_outside;
            self.ticks.write(hashed_tick, info);
            info.liquidity_net
        }

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

            // this function mimics the u256 overflow that occurs in Solidity
            (
                mod_subtraction(
                    mod_subtraction(fee_growth_global_0X128, fee_growth_below_0X128),
                    fee_growth_above_0X128
                ),
                mod_subtraction(
                    mod_subtraction(fee_growth_global_1X128, fee_growth_below_1X128),
                    fee_growth_above_1X128
                )
            )
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
