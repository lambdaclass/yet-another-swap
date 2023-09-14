use yas::numbers::signed_integer::{i32::i32, i64::i64, i128::i128, integer_trait::IntegerTrait};

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
trait ITick<TContractState> {
    fn tick_spacing_to_max_liquidity_per_tick(self: @TContractState, tick_spacing: i32) -> u128;
    fn clear(ref self: TContractState, tick: i32);
    fn cross(
        ref self: TContractState,
        tick: i32,
        fee_growth_global_0X128: u256,
        fee_growth_global_1X128: u256,
        seconds_per_liquidity_cumulative_X128: u256,
        tick_cumulative: i64,
        time: u32
    ) -> i128;
    fn get_fee_growth_inside(
        self: @TContractState,
        tick_lower: i32,
        tick_upper: i32,
        tick_current: i32,
        fee_growth_global_0X128: u256,
        fee_growth_global_1X128: u256
    ) -> (u256, u256);
    fn update(
        ref self: TContractState,
        tick: i32,
        tick_current: i32,
        liquidity_delta: i128,
        fee_growth_global_0X128: u256,
        fee_growth_global_1X128: u256,
        seconds_per_liquidity_cumulative_X128: u256,
        tick_cumulative: i64,
        time: u32,
        upper: bool,
        max_liquidity: u128
    ) -> bool;
}

#[starknet::contract]
mod Tick {
    use super::{ITick, Info};

    use integer::BoundedInt;
    use hash::{HashStateTrait, HashStateExTrait};
    use poseidon::PoseidonTrait;

    use yas::libraries::liquidity_math::LiquidityMath;
    use yas::numbers::signed_integer::{
        i32::{i32, i32TryIntou128, i32_div_no_round}, i64::i64, i128::i128,
        integer_trait::IntegerTrait
    };
    use yas::utils::math_utils::mod_subtraction;

    #[storage]
    struct Storage {
        ticks: LegacyMap::<felt252, Info>
    }

    #[external(v0)]
    impl TickImpl of ITick<ContractState> {
        /// @notice Derives max liquidity per tick from given tick spacing
        /// @dev Executed within the pool constructor
        /// @param tick_spacing The amount of required tick separation, realized in multiples of `tick_spacing`
        ///     e.g., a tick_spacing of 3 requires ticks to be initialized every 3rd tick i.e., ..., -6, -3, 0, 3, 6, ...
        /// @return The max liquidity per tick
        fn tick_spacing_to_max_liquidity_per_tick(self: @ContractState, tick_spacing: i32) -> u128 {
            let MIN_TICK = IntegerTrait::<i32>::new(887272, true);
            let MAX_TICK = IntegerTrait::<i32>::new(887272, false);

            let min_tick = i32_div_no_round(MIN_TICK, tick_spacing) * tick_spacing;
            let max_tick = i32_div_no_round(MAX_TICK, tick_spacing) * tick_spacing;
            let num_ticks = i32_div_no_round((max_tick - min_tick), tick_spacing)
                + IntegerTrait::<i32>::new(1, false);

            let max_u128: u128 = BoundedInt::max();
            max_u128 / num_ticks.try_into().expect('num ticks cannot be negative!')
        }

        /// @notice Clears tick data
        /// @param self The mapping containing all initialized tick information for initialized ticks
        /// @param tick The tick that will be cleared
        fn clear(ref self: ContractState, tick: i32) {
            let hashed_tick = PoseidonTrait::new().update_with(tick).finalize();
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
            let hashed_tick = PoseidonTrait::new().update_with(tick).finalize();
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
            self: @ContractState,
            tick_lower: i32,
            tick_upper: i32,
            tick_current: i32,
            fee_growth_global_0X128: u256,
            fee_growth_global_1X128: u256
        ) -> (u256, u256) {
            let lower: Info = self
                .ticks
                .read(PoseidonTrait::new().update_with(tick_lower).finalize());
            let upper: Info = self
                .ticks
                .read(PoseidonTrait::new().update_with(tick_upper).finalize());

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

        /// @notice Updates a tick and returns true if the tick was flipped from initialized to uninitialized, or vice versa
        /// @param self The mapping containing all tick information for initialized ticks
        /// @param tick The tick that will be updated
        /// @param tick_current The current tick
        /// @param liquidity_delta A new amount of liquidity to be added (subtracted) when tick is crossed from left to right (right to left)
        /// @param fee_growth_global_0X128 The all-time global fee growth, per unit of liquidity, in token0
        /// @param fee_growth_global_1X128 The all-time global fee growth, per unit of liquidity, in token1
        /// @param seconds_per_liquidity_cumulative_X128 The all-time seconds per max(1, liquidity) of the pool
        /// @param tick_cumulative The tick * time elapsed since the pool was first initialized
        /// @param time The current block timestamp cast to a uint32
        /// @param upper true for updating a position's upper tick, or false for updating a position's lower tick
        /// @param max_liquidity The maximum liquidity allocation for a single tick
        /// @return flipped Whether the tick was flipped from initialized to uninitialized, or vice versa
        fn update(
            ref self: ContractState,
            tick: i32,
            tick_current: i32,
            liquidity_delta: i128,
            fee_growth_global_0X128: u256,
            fee_growth_global_1X128: u256,
            seconds_per_liquidity_cumulative_X128: u256,
            tick_cumulative: i64,
            time: u32,
            upper: bool,
            max_liquidity: u128
        ) -> bool {
            let hashed_tick = PoseidonTrait::new().update_with(tick).finalize();
            let mut info: Info = self.ticks.read(hashed_tick);

            let liquidity_gross_before: u128 = info.liquidity_gross;
            let liquidity_gross_after: u128 = LiquidityMath::add_delta(
                liquidity_gross_before, liquidity_delta
            );

            assert(liquidity_gross_after <= max_liquidity, 'LO');

            let flipped = (liquidity_gross_after == 0) != (liquidity_gross_before == 0);

            if (liquidity_gross_before == 0) {
                // by convention, we assume that all growth before a tick was initialized happened _below_ the tick
                if (tick <= tick_current) {
                    info.fee_growth_outside_0X128 = fee_growth_global_0X128;
                    info.fee_growth_outside_1X128 = fee_growth_global_1X128;
                    info.seconds_per_liquidity_outside_X128 = seconds_per_liquidity_cumulative_X128;
                    info.tick_cumulative_outside = tick_cumulative;
                    info.seconds_outside = time;
                }
                info.initialized = true;
            }

            info.liquidity_gross = liquidity_gross_after;

            // when the lower (upper) tick is crossed left to right (right to left), liquidity must be added (removed)
            info
                .liquidity_net =
                    if upper {
                        info.liquidity_net - liquidity_delta
                    } else {
                        info.liquidity_net + liquidity_delta
                    };

            self.ticks.write(hashed_tick, info);
            flipped
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn set_tick(ref self: ContractState, tick: i32, info: Info) {
            let hashed_tick = PoseidonTrait::new().update_with(tick).finalize();
            self.ticks.write(hashed_tick, info);
        }

        fn get_tick(self: @ContractState, tick: i32) -> Info {
            let hashed_tick = PoseidonTrait::new().update_with(tick).finalize();
            self.ticks.read(hashed_tick)
        }
    }
}
