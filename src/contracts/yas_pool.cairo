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

    use yas::libraries::liquidity_math::LiquidityMath;
    use yas::libraries::position::Info;
    use yas::libraries::sqrt_price_math::SqrtPriceMath;
    use yas::libraries::{tick::Tick, tick_math::TickMath};
    use yas::numbers::fixed_point::implementations::impl_64x96::{
        FP64x96Impl, FP64x96Zeroable, FixedType
    };
    use yas::numbers::signed_integer::{
        i32::i32, i128::i128, i256::i256, integer_trait::IntegerTrait
    };

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

    #[derive(Serde, Copy, Drop)]
    struct ModifyPositionParams {
        // the address that owns the position
        owner: ContractAddress,
        // the lower and upper tick of the position
        tick_lower: i32,
        tick_upper: i32,
        // any change in liquidity
        liquidity_delta: i128
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
        liquidity_per_tick: u128,
        slot_0: Slot0,
        liquidity: u128
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

        //TODO: temporary component syntax
        let state = Tick::unsafe_new_contract_state();
        self
            .liquidity_per_tick
            .write(Tick::TickImpl::tick_spacing_to_max_liquidity_per_tick(@state, tick_spacing));
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

        /// @dev Effect some changes to a position
        /// @param params the position details and the change to the position's liquidity to effect
        /// @return position a storage pointer referencing the position with the given owner and tick range
        /// @return amount0 the amount of token0 owed to the pool, negative if the pool should pay the recipient
        /// @return amount1 the amount of token1 owed to the pool, negative if the pool should pay the recipient
        fn modify_position(
            ref self: ContractState, params: ModifyPositionParams
        ) -> (Info, i256, i256) // TODO: noDelegateCall
        {
            check_ticks(params.tick_lower, params.tick_upper);

            let slot_0 = self.slot_0.read();

            let position = update_position(
                params.owner,
                params.tick_lower,
                params.tick_upper,
                params.liquidity_delta,
                slot_0.tick
            );

            let mut amount_0 = Zeroable::zero();
            let mut amount_1 = Zeroable::zero();
            if params.liquidity_delta.is_non_zero() {
                if slot_0.tick < params.tick_lower {
                    // current tick is below the passed range; liquidity can only become in range by crossing from left to
                    // right, when we'll need _more_ token0 (it's becoming more valuable) so user must provide it
                    amount_0 =
                        SqrtPriceMath::get_amount_0_delta_signed_token(
                            TickMath::get_sqrt_ratio_at_tick(params.tick_lower),
                            TickMath::get_sqrt_ratio_at_tick(params.tick_upper),
                            params.liquidity_delta
                        );
                } else if (slot_0.tick < params.tick_upper) {
                    // current tick is inside the passed range

                    amount_0 =
                        SqrtPriceMath::get_amount_0_delta_signed_token(
                            slot_0.sqrt_price_X96,
                            TickMath::get_sqrt_ratio_at_tick(params.tick_upper),
                            params.liquidity_delta
                        );
                    amount_1 =
                        SqrtPriceMath::get_amount_1_delta_signed_token(
                            TickMath::get_sqrt_ratio_at_tick(params.tick_lower),
                            slot_0.sqrt_price_X96,
                            params.liquidity_delta
                        );

                    let mut liquidity = self.liquidity.read();
                    liquidity = LiquidityMath::add_delta(liquidity, params.liquidity_delta);
                    self.liquidity.write(liquidity);
                } else {
                    // current tick is above the passed range; liquidity can only become in range by crossing from right to
                    // left, when we'll need _more_ token1 (it's becoming more valuable) so user must provide it
                    amount_1 =
                        SqrtPriceMath::get_amount_1_delta_signed_token(
                            TickMath::get_sqrt_ratio_at_tick(params.tick_lower),
                            TickMath::get_sqrt_ratio_at_tick(params.tick_upper),
                            params.liquidity_delta
                        );
                }
            }
            (position, amount_0, amount_1)
        }
    }

    /// @dev Common checks for valid tick inputs.
    fn check_ticks(tick_lower: i32, tick_upper: i32) {
        assert(tick_lower < tick_upper, 'TLU');
        assert(tick_lower >= TickMath::MIN_TICK(), 'TLM');
        assert(tick_upper <= TickMath::MAX_TICK(), 'TUM');
    }

    // TODO: mock
    fn update_position(
        owner: ContractAddress, tick_lower: i32, tick_upper: i32, liquidity_delta: i128, tick: i32
    ) -> Info {
        Info {
            liquidity: 100,
            fee_growth_inside_0_last_X128: 20,
            fee_growth_inside_1_last_X128: 20,
            tokens_owed_0: 10,
            tokens_owed_1: 10,
        }
    }
}
