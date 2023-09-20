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

    use yas::libraries::{tick::Tick, tick_math::TickMath};
    use yas::numbers::fixed_point::implementations::impl_64x96::{
        FP64x96Impl, FP64x96Zeroable, FixedType
    };
    use yas::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};


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
        liquidity_per_tick: u128,
        slot_0: Slot0
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
    }
}
