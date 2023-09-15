use starknet::ContractAddress;
use yas::numbers::signed_integer::i256::i256;

#[starknet::interface]
trait IYASPool<TContractState> {
    fn initialize(ref self: TContractState);
    fn swap(
        ref self: TContractState,
        recipient: ContractAddress,
        zero_for_one: bool,
        amount_specified: i256,
        sqrt_price_limit_X96: u256,
    // bytes calldata data
    ) -> (i256, i256);
}

#[starknet::contract]
mod YASPool {
    use super::IYASPool;
    use starknet::ContractAddress;

    use yas::libraries::swap_math::SwapMath;
    use yas::libraries::tick::Tick;
    use yas::libraries::tick_math::TickMath;
    use yas::numbers::signed_integer::{i32::i32, i64::i64, i256::i256, integer_trait::IntegerTrait};
    use yas::utils::math_utils::BitShift::BitShiftTrait;

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct Slot0 {
        // the current price
        sqrt_price_X96: u256,
        // the current tick
        tick: i32,
        // the most-recently updated index of the observations array
        observation_index: u16,
        // the current maximum number of observations that are being stored
        observation_cardinality: u16,
        // the next maximum number of observations to store, triggered in observations.write
        observation_cardinality_next: u16,
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)%
        fee_protocol: u8,
        // whether the pool is locked
        unlocked: bool,
    }

    #[derive(Copy, Drop)]
    struct SwapCache {
        // the protocol fee for the input token
        fee_protocol: u8,
        // liquidity at the beginning of the swap
        liquidity_start: u128,
        // the timestamp of the current block
        block_timestamp: u32,
        // the current value of the tick accumulator, computed only if we cross an initialized tick
        tick_cumulative: i64,
        // the current value of seconds per liquidity accumulator, computed only if we cross an initialized tick
        seconds_per_liquidity_cumulative_X128: u256,
        // whether we've computed and cached the above two accumulators
        computed_latest_observation: bool
    }

    // the top level state of the swap, the results of which are recorded in storage at the end
    #[derive(Copy, Drop)]
    struct SwapState {
        // the amount remaining to be swapped in/out of the input/output asset
        amount_specified_remaining: i256,
        // the amount already swapped out/in of the output/input asset
        amount_calculated: i256,
        // current sqrt(price)
        sqrt_price_X96: u256,
        // the tick associated with the current price
        tick: i32,
        // the global fee growth of the input token
        fee_growth_global_X128: u256,
        // amount of input token paid as protocol fee
        protocol_fee: u128,
        // the current liquidity in range
        liquidity: u128
    }

    struct StepComputations {
        // the price at the beginning of the step
        sqrt_price_start_X96: u256,
        // the next tick to swap to from the current tick in the swap direction
        tick_next: i32,
        // whether tickNext is initialized or not
        initialized: bool,
        // sqrt(price) for the next tick (1/0)
        sqrt_price_next_X96: u256,
        // how much is being swapped in in this step
        amount_in: u256,
        // how much is being swapped out
        amount_out: u256,
        // how much fee is being paid in
        fee_amount: u256
    }

    #[storage]
    struct Storage {
        factory: ContractAddress,
        token_0: ContractAddress,
        token_1: ContractAddress,
        fee: u32,
        liquidity_per_tick: u128,
        slot_0: Slot0,
        liquidity: u128,
        fee_growth_global_0X128: u256,
        fee_growth_global_1X128: u256,
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
        fn initialize(ref self: ContractState) { // TODO: implement
        }

        /// @inheritdoc IUniswapV3PoolActions
        fn swap(
            ref self: ContractState,
            recipient: ContractAddress,
            zero_for_one: bool,
            amount_specified: i256,
            sqrt_price_limit_X96: u256,
        // TODO:  bytes calldata data
        ) -> (i256, i256) {
            assert(amount_specified != IntegerTrait::<i256>::new(0, false), 'AS');

            let slot_0_start: Slot0 = self.slot_0.read();

            assert(slot_0_start.unlocked, 'LOK');
            assert(
                if zero_for_one {
                    sqrt_price_limit_X96 < slot_0_start.sqrt_price_X96
                        && sqrt_price_limit_X96 > TickMath::MIN_SQRT_RATIO
                } else {
                    sqrt_price_limit_X96 > slot_0_start.sqrt_price_X96
                        && sqrt_price_limit_X96 < TickMath::MAX_SQRT_RATIO
                },
                'SPL'
            );

            // TODO: slot_0.unlocked = false;

            let cache = SwapCache {
                liquidity_start: self.liquidity.read(),
                block_timestamp: 0, // TODO: _block_timestamp()
                fee_protocol: if zero_for_one {
                    slot_0_start.fee_protocol % 16
                } else {
                    slot_0_start.fee_protocol.shr(4)
                },
                seconds_per_liquidity_cumulative_X128: 0,
                tick_cumulative: IntegerTrait::<i64>::new(0, false),
                computed_latest_observation: false
            };

            let exactInput: bool = amount_specified > IntegerTrait::<i256>::new(0, false);

            let mut state = SwapState {
                amount_specified_remaining: amount_specified,
                amount_calculated: IntegerTrait::<i256>::new(0, false),
                sqrt_price_X96: slot_0_start.sqrt_price_X96,
                tick: slot_0_start.tick,
                fee_growth_global_X128: if zero_for_one {
                    self.fee_growth_global_0X128.read()
                } else {
                    self.fee_growth_global_1X128.read()
                },
                protocol_fee: 0,
                liquidity: cache.liquidity_start
            };

            (IntegerTrait::<i256>::new(1, false), IntegerTrait::<i256>::new(1, false))
        }
    }
}
