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
    fn tick_spacing_to_max_liquidity_per_tick(ref self: TStorage, tick_spacing: i32) -> u128;
    // TODO: Function used for testing. To be removed in the future
    fn set_tick(ref self: TStorage, tick: i32, info: Info);
    // TODO: Function used for testing. To be removed in the future
    fn get_tick(self: @TStorage, tick: i32) -> Info;
}

#[starknet::contract]
mod Tick {
    use super::{ITick, Info};
    use orion::numbers::signed_integer::i32::i32;
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;
    use fractal_swap::utils::orion_utils::OrionUtils::i32TryIntou32;
    use poseidon::poseidon_hash_span;

    use integer::BoundedInt;
    use traits::Into;

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
        fn tick_spacing_to_max_liquidity_per_tick(
            ref self: ContractState, tick_spacing: i32
        ) -> u128 {
            // TODO: remove MIN_TICK and MAX_TICK when TickMath its done 
            let MIN_TICK = IntegerTrait::<i32>::new(887272, true);
            let MAX_TICK = IntegerTrait::<i32>::new(887272, false);

            let min_tick = (MIN_TICK / tick_spacing) * tick_spacing;
            let max_tick = (MAX_TICK / tick_spacing) * tick_spacing;
            let num_ticks: u32 = (((max_tick - min_tick) / tick_spacing)
                + IntegerTrait::<i32>::new(1, false))
                .try_into()
                .unwrap();

            let max_u128: u128 = BoundedInt::max();
            max_u128 / num_ticks.into()
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
