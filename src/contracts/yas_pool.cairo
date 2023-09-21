use yas::numbers::signed_integer::i32::i32;
use yas::numbers::fixed_point::implementations::impl_64x96::FixedType;

#[starknet::interface]
trait IYASPool<TContractState> {
    fn initialize(ref self: TContractState, sqrt_price_X96: FixedType);
}

#[starknet::contract]
mod YASPool {
    use super::IYASPool;

    use starknet::ContractAddress;
    use yas::libraries::{
        tick::{Tick, Tick::TickImpl}, tick_bitmap::{TickBitmap, TickBitmap::TickBitmapImpl},
        tick_math::TickMath, position::{Info, Position, Position::PositionImpl, PositionKey}
    };
    use yas::numbers::fixed_point::implementations::impl_64x96::{
        FP64x96Impl, FP64x96Zeroable, FixedType
    };
    use yas::numbers::signed_integer::{i32::i32, i64::i64, i128::i128, integer_trait::IntegerTrait};


    #[derive(Serde, Copy, Drop, starknet::Store)]
    struct Slot0 {
        // the current price
        sqrt_price_X96: FixedType,
        // the current tick
        tick: i32,
        // represented as an integer denominator (1/x)%
        fee_protocol: u8,
        // whether the pool is locked
        unlocked: bool
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Initialize: Initialize
    }

    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrt_price_X96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    #[derive(Drop, starknet::Event)]
    struct Initialize {
        sqrt_price_X96: FixedType,
        tick: i32
    }

    #[storage]
    struct Storage {
        factory: ContractAddress,
        token_0: ContractAddress,
        token_1: ContractAddress,
        fee: u32,
        max_liquidity_per_tick: u128,
        tick_spacing: i32,
        slot_0: Slot0,
        fee_growth_global_0_X_128: u256,
        fee_growth_global_1_X_128: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        factory: ContractAddress,
        token_0: ContractAddress,
        token_1: ContractAddress,
        fee: u32,
        tick_spacing: i32,
    ) {
        self.factory.write(factory);
        self.token_0.write(token_0);
        self.token_1.write(token_1);
        self.fee.write(fee);
        self.tick_spacing.write(tick_spacing);

        //TODO: temporary component syntax
        let state = Tick::unsafe_new_contract_state();
        self
            .max_liquidity_per_tick
            .write(TickImpl::tick_spacing_to_max_liquidity_per_tick(@state, tick_spacing));
    }

    #[external(v0)]
    impl YASPoolImpl of IYASPool<ContractState> {
        /// @notice Sets the initial price for the pool
        /// @dev price is represented as a sqrt(amount_token_1/amount_token_0) Q64.96 value
        /// @param sqrt_price_X96 the initial sqrt price of the pool as a Q64.96
        fn initialize(ref self: ContractState, sqrt_price_X96: FixedType) {
            // The initialize function should only be called once. To ensure this, 
            // we verify that the price is not initialized.
            let mut slot_0 = self.slot_0.read();
            assert(slot_0.sqrt_price_X96.is_zero(), 'AI');

            slot_0.sqrt_price_X96 = sqrt_price_X96;
            slot_0.tick = TickMath::get_tick_at_sqrt_ratio(sqrt_price_X96);
            slot_0.fee_protocol = 0;
            slot_0.unlocked = true;
            self.slot_0.write(slot_0);

            self.emit(Initialize { sqrt_price_X96, tick: slot_0.tick });
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn get_slot_0(self: @ContractState) -> Slot0 {
            self.slot_0.read()
        }

        /// @dev Gets and updates a position with the given liquidity delta
        /// @param owner the owner of the position
        /// @param tick_lower the lower tick of the position's tick range
        /// @param tick_upper the upper tick of the position's tick range
        /// @param tick the current tick, passed to avoid sloads
        fn update_position(
            self: @ContractState, position_key: PositionKey, liquidity_delta: i128, tick: i32
        ) -> Info {
            let mut tick_bitmap_state = TickBitmap::unsafe_new_contract_state();
            let mut tick_state = Tick::unsafe_new_contract_state();
            let mut position_state = Position::unsafe_new_contract_state();

            // SLOAD for gas optimization
            let _fee_growth_global_0_X_128 = self.fee_growth_global_0_X_128.read();

            let _fee_growth_global_1_X_128 = self.fee_growth_global_1_X_128.read();

            let _max_liquidity_per_tick = self.max_liquidity_per_tick.read();

            // if we need to update the ticks, do it
            let mut flipped_lower = false;
            let mut flipped_upper = false;

            if liquidity_delta.is_non_zero() {
                // block time in .sol is type u32, but in starknet its u64
                let time = starknet::get_block_timestamp().try_into().unwrap();

                flipped_lower =
                    TickImpl::update(
                        ref tick_state,
                        position_key.tick_lower,
                        tick,
                        liquidity_delta,
                        _fee_growth_global_0_X_128,
                        _fee_growth_global_1_X_128,
                        Zeroable::zero(), // secondsPerLiquidityCumulativeX128
                        IntegerTrait::<i64>::new(0, false), // tickCumulative
                        time,
                        false,
                        _max_liquidity_per_tick
                    );

                flipped_upper =
                    TickImpl::update(
                        ref tick_state,
                        position_key.tick_upper,
                        tick,
                        liquidity_delta,
                        _fee_growth_global_0_X_128,
                        _fee_growth_global_1_X_128,
                        Zeroable::zero(), // secondsPerLiquidityCumulativeX128
                        IntegerTrait::<i64>::new(0, false), // tickCumulative
                        time,
                        true,
                        _max_liquidity_per_tick
                    );
            }

            if flipped_lower {
                TickBitmapImpl::flip_tick(
                    ref tick_bitmap_state, position_key.tick_lower, self.tick_spacing.read()
                );
            }

            if flipped_upper {
                TickBitmapImpl::flip_tick(
                    ref tick_bitmap_state, position_key.tick_upper, self.tick_spacing.read()
                );
            }

            let (fee_growth_inside_0_X128, fee_growth_inside_1_X128) =
                TickImpl::get_fee_growth_inside(
                @tick_state,
                position_key.tick_lower,
                position_key.tick_upper,
                tick,
                _fee_growth_global_0_X_128,
                _fee_growth_global_1_X_128
            );

            PositionImpl::update(
                ref position_state,
                position_key,
                liquidity_delta,
                fee_growth_inside_0_X128,
                fee_growth_inside_1_X128
            );

            // clear any tick data that is no longer needed
            if liquidity_delta < Zeroable::zero() {
                if flipped_lower {
                    TickImpl::clear(ref tick_state, position_key.tick_lower);
                }

                if flipped_upper {
                    TickImpl::clear(ref tick_state, position_key.tick_upper);
                }
            }

            // read again to obtain Info with changes in the update step 
            PositionImpl::get(@position_state, position_key)
        }
    }
}
