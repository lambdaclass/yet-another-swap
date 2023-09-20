use starknet::ContractAddress;
use yas::numbers::signed_integer::i256::i256;
use yas::numbers::fixed_point::implementations::impl_64x96::FixedType;

#[starknet::interface]
trait IYASPool<TContractState> {
    fn swap(
        ref self: TContractState,
        recipient: ContractAddress,
        zero_for_one: bool,
        amount_specified: i256,
        sqrt_price_limit_X96: FixedType,
    // bytes calldata data
    ) -> (i256, i256);
}

#[starknet::contract]
mod YASPool {
    use super::IYASPool;
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};

    use yas::libraries::liquidity_math::LiquidityMath;
    use yas::libraries::swap_math::SwapMath;
    use yas::libraries::tick::Tick;
    use yas::libraries::tick_bitmap::TickBitmap;
    use yas::libraries::tick_math::TickMath;
    use yas::numbers::fixed_point::implementations::impl_64x96::{
        FixedType, FP64x96PartialOrd, FP64x96PartialEq
    };
    use yas::numbers::signed_integer::{
        i32::i32, i64::i64, i128::i128, i256::i256, integer_trait::IntegerTrait
    };
    use yas::utils::math_utils::FullMath;
    use yas::utils::math_utils::BitShift::BitShiftTrait;

    const Q128: u256 = 0x100000000000000000000000000000000;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        SwapExecuted: SwapExecuted
    }

    #[derive(Drop, starknet::Event)]
    struct SwapExecuted {
        sender: ContractAddress,
        recipient: ContractAddress,
        amount_0: i256,
        amount_1: i256,
        sqrt_price_X96: FixedType,
        liquidity: u128,
        tick: i32
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct Slot0 {
        // the current price
        sqrt_price_X96: FixedType,
        // the current tick
        tick: i32,
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)%
        fee_protocol: u8,
        // whether the pool is locked
        unlocked: bool
    }

    #[derive(Copy, Drop)]
    struct SwapCache {
        // the protocol fee for the input token
        fee_protocol: u8,
        // liquidity at the beginning of the swap
        liquidity_start: u128,
        // the timestamp of the current block
        block_timestamp: u64,
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
        sqrt_price_X96: FixedType,
        // the tick associated with the current price
        tick: i32,
        // the global fee growth of the input token
        fee_growth_global_X128: u256,
        // amount of input token paid as protocol fee
        protocol_fee: u128,
        // the current liquidity in range
        liquidity: u128
    }

    // TODO: remove
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

    #[derive(Copy, Drop, Serde, starknet::Store)]
    // accumulated protocol fees in token0/token1 units
    struct ProtocolFees {
        token0: u128,
        token1: u128
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
        protocol_fees: ProtocolFees,
        tick_spacing: i32,
        unlocked: bool
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
        let state_tick = Tick::unsafe_new_contract_state();
        self
            .liquidity_per_tick
            .write(
                Tick::TickImpl::tick_spacing_to_max_liquidity_per_tick(@state_tick, tick_spacing)
            );
    }

    #[external(v0)]
    impl YASPoolImpl of IYASPool<ContractState> {
        /// @inheritdoc IUniswapV3PoolActions
        fn swap(
            ref self: ContractState,
            recipient: ContractAddress,
            zero_for_one: bool,
            amount_specified: i256,
            sqrt_price_limit_X96: FixedType,
        // TODO:  bytes calldata data
        ) -> (i256, i256) {
            assert(amount_specified.is_non_zero(), 'AS');

            let slot_0_start: Slot0 = self.slot_0.read();

            assert(slot_0_start.unlocked, 'LOK');
            assert(
                if zero_for_one {
                    sqrt_price_limit_X96 < slot_0_start.sqrt_price_X96
                        && sqrt_price_limit_X96 > TickMath::MIN_SQRT_RATIO()
                } else {
                    sqrt_price_limit_X96 > slot_0_start.sqrt_price_X96
                        && sqrt_price_limit_X96 < TickMath::MAX_SQRT_RATIO()
                },
                'SPL'
            );

            self.unlocked.write(false);

            let cache = SwapCache {
                liquidity_start: self.liquidity.read(),
                block_timestamp: get_block_timestamp(),
                fee_protocol: if zero_for_one {
                    slot_0_start.fee_protocol % 16
                } else {
                    slot_0_start.fee_protocol.shr(4)
                },
                seconds_per_liquidity_cumulative_X128: 0,
                tick_cumulative: Zeroable::zero(),
                computed_latest_observation: false
            };

            let exact_input: bool = amount_specified > Zeroable::zero();

            let mut state = SwapState {
                amount_specified_remaining: amount_specified,
                amount_calculated: Zeroable::zero(),
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

            //TODO: temporary component syntax
            let state_tick_bitmap = TickBitmap::unsafe_new_contract_state();

            //TODO: temporary component syntax
            let mut state_tick = Tick::unsafe_new_contract_state();

            // continue swapping as long as we haven't used the entire input/output and haven't reached the price limit
            loop {
                if state.amount_specified_remaining.is_non_zero()
                    && state.sqrt_price_X96 != sqrt_price_limit_X96 {
                    break;
                }

                let step_sqrt_price_start_X96 = state.sqrt_price_X96;

                // TODO: test mut
                let (mut step_tick_next, step_initialized) =
                    TickBitmap::TickBitmapImpl::next_initialized_tick_within_one_word(
                    @state_tick_bitmap, state.tick, self.tick_spacing.read(), zero_for_one
                );

                // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
                if step_tick_next < TickMath::MIN_TICK() {
                    step_tick_next = TickMath::MIN_TICK();
                } else if step_tick_next > TickMath::MAX_TICK() {
                    step_tick_next = TickMath::MAX_TICK();
                };

                // get the price for the next tick
                let step_sqrt_price_next_X96 = TickMath::get_sqrt_ratio_at_tick(step_tick_next);

                // TODO: refactor
                let bandera = if zero_for_one {
                    step_sqrt_price_next_X96 < sqrt_price_limit_X96
                } else {
                    step_sqrt_price_next_X96 > sqrt_price_limit_X96
                };

                let bandera = if bandera {
                    sqrt_price_limit_X96
                } else {
                    step_sqrt_price_next_X96
                };

                // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
                let (ret_sqrt_price_X96, step_amount_in, step_amount_out, mut step_fee_amount) =
                    SwapMath::compute_swap_step(
                    state.sqrt_price_X96,
                    bandera,
                    state.liquidity,
                    state.amount_specified_remaining,
                    self.fee.read()
                );

                state.sqrt_price_X96 = ret_sqrt_price_X96;

                if exact_input {
                    state
                        .amount_specified_remaining -=
                            IntegerTrait::<i256>::new(step_amount_in + step_fee_amount, false);
                    state.amount_calculated = state.amount_calculated
                        - IntegerTrait::<i256>::new(step_amount_out, false);
                } else {
                    state
                        .amount_specified_remaining +=
                            IntegerTrait::<i256>::new(step_amount_out, false);
                    state.amount_calculated = state.amount_calculated
                        + IntegerTrait::<i256>::new(step_amount_in + step_fee_amount, false);
                };

                // if the protocol fee is on, calculate how much is owed, decrement feeAmount, and increment protocolFee
                if cache.fee_protocol > 0 {
                    let delta: u256 = step_fee_amount / cache.fee_protocol.into();
                    step_fee_amount -= delta;
                    state.protocol_fee += delta.try_into().unwrap();
                };

                // update global fee tracker
                if state.liquidity > 0 {
                    state
                        .fee_growth_global_X128 +=
                            FullMath::mul_div(step_fee_amount, Q128, step_fee_amount);
                };

                // shift tick if we reached the next price
                if state.sqrt_price_X96 == step_sqrt_price_next_X96 {
                    // if the tick is initialized, run the tick transition
                    if step_initialized {
                        // crosses an initialized tick
                        let mut liquidity_net: i128 = Tick::TickImpl::cross(
                            ref state_tick,
                            step_tick_next,
                            if zero_for_one {
                                state.fee_growth_global_X128
                            } else {
                                self.fee_growth_global_0X128.read()
                            },
                            if zero_for_one {
                                self.fee_growth_global_1X128.read()
                            } else {
                                state.fee_growth_global_X128
                            },
                            cache.seconds_per_liquidity_cumulative_X128, // TODO: 
                            cache.tick_cumulative,
                            cache.block_timestamp
                        );

                        // if we're moving leftward, we interpret liquidityNet as the opposite sign
                        // safe because liquidityNet cannot be type(int128).min
                        if zero_for_one {
                            liquidity_net = -liquidity_net;
                        };

                        state.liquidity = LiquidityMath::add_delta(state.liquidity, liquidity_net);
                    };

                    state
                        .tick =
                            if zero_for_one {
                                step_tick_next - IntegerTrait::<i32>::new(1, false)
                            } else {
                                step_tick_next
                            };
                } else if state.sqrt_price_X96 != step_sqrt_price_start_X96 {
                    // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
                    state.tick = TickMath::get_tick_at_sqrt_ratio(state.sqrt_price_X96);
                };
            };

            // update tick and write an oracle entry if the tick change
            let mut slot_0 = self.slot_0.read();
            if state.tick != slot_0_start.tick {
                slot_0.tick = state.tick;
            }
            slot_0.sqrt_price_X96 = state.sqrt_price_X96;
            self.slot_0.write(slot_0);

            // update liquidity if it changed
            if cache.liquidity_start != state.liquidity {
                self.liquidity.write(state.liquidity);
            }

            // update fee growth global and, if necessary, protocol fees
            // overflow is acceptable, protocol has to withdraw before it hits type(uint128).max fees
            if zero_for_one {
                self.fee_growth_global_0X128.write(state.fee_growth_global_X128);
                if state.protocol_fee > 0 {
                    let mut protocol_fees = self.protocol_fees.read();
                    protocol_fees.token0 += state.protocol_fee;
                    self.protocol_fees.write(protocol_fees);
                }
            } else {
                self.fee_growth_global_1X128.write(state.fee_growth_global_X128);
                if state.protocol_fee > 0 {
                    let mut protocol_fees = self.protocol_fees.read();
                    protocol_fees.token1 += state.protocol_fee;
                    self.protocol_fees.write(protocol_fees);
                }
            }

            let (amount_0, amount_1) = if zero_for_one == exact_input {
                (amount_specified - state.amount_specified_remaining, state.amount_calculated)
            } else {
                (state.amount_calculated, amount_specified - state.amount_specified_remaining)
            };

            // do the transfers and collect payment
            if zero_for_one { // if (amount_1 < 0) TransferHelper.safeTransfer(token1, recipient, uint256(-amount1));
            // uint256 balance0Before = balance0();
            // IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(amount0, amount1, data);
            // require(balance0Before.add(uint256(amount0)) <= balance0(), 'IIA');
            } else { // if (amount_0 < 0) TransferHelper.safeTransfer(token0, recipient, uint256(-amount0));
            // uint256 balance1Before = balance1();
            // IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(amount0, amount1, data);
            // require(balance1Before.add(uint256(amount1)) <= balance1(), 'IIA');
            }

            self
                .emit(
                    SwapExecuted {
                        sender: get_caller_address(),
                        recipient,
                        amount_0,
                        amount_1,
                        sqrt_price_X96: state.sqrt_price_X96,
                        liquidity: state.liquidity,
                        tick: state.tick
                    }
                );
            self.unlocked.write(true);

            (amount_0, amount_0)
        }
    }
}
