use starknet::ContractAddress;
use yas::numbers::signed_integer::{i32::i32, i256::i256};
use yas::numbers::fixed_point::implementations::impl_64x96::FixedType;

#[starknet::interface]
trait IYASPool<TContractState> {
    fn initialize(ref self: TContractState, sqrt_price_X96: FixedType);
    fn swap(
        ref self: TContractState,
        recipient: ContractAddress,
        zero_for_one: bool,
        amount_specified: i256,
        sqrt_price_limit_X96: FixedType,
        data: Array<felt252>
    ) -> (i256, i256);
    fn mint(
        ref self: TContractState,
        recipient: ContractAddress,
        tick_lower: i32,
        tick_upper: i32,
        amount: u128,
        data: Array<felt252>
    ) -> (u256, u256);
}

#[starknet::contract]
mod YASPool {
    use super::IYASPool;
    use yas::interfaces::interface_ERC20::{IERC20DispatcherTrait, IERC20Dispatcher};
    use yas::interfaces::interface_yas_mint_callback::{
        IYASMintCallbackDispatcherTrait, IYASMintCallbackDispatcher
    };
    use yas::interfaces::interface_yas_swap_callback::{
        IYASSwapCallbackDispatcherTrait, IYASSwapCallbackDispatcher
    };

    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};

    use yas::libraries::liquidity_math::LiquidityMath;
    use yas::libraries::position::{Info, PositionKey};
    use yas::libraries::swap_math::SwapMath;
    use yas::libraries::tick::{Tick, Tick::TickImpl};
    use yas::libraries::tick_bitmap::{TickBitmap, TickBitmap::TickBitmapImpl};
    use yas::libraries::tick_math::TickMath::{
        get_tick_at_sqrt_ratio, get_sqrt_ratio_at_tick, MIN_SQRT_RATIO, MAX_SQRT_RATIO, MIN_TICK,
        MAX_TICK
    };
    use yas::numbers::fixed_point::implementations::impl_64x96::{
        FixedType, FP64x96PartialOrd, FP64x96PartialEq, FP64x96Impl, FP64x96Zeroable
    };
    use yas::numbers::signed_integer::{
        i32::i32, i64::i64, i128::{i128, u128Intoi128}, i256::{i256, i256TryIntou256}, integer_trait::IntegerTrait
    };
    use yas::utils::math_utils::Constants::Q128;
    use yas::utils::math_utils::FullMath;
    use yas::utils::math_utils::BitShift::BitShiftTrait;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Initialize: Initialize,
        SwapExecuted: SwapExecuted,
        Mint: Mint,
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

    #[derive(Drop, starknet::Event)]
    struct Mint {
        sender: ContractAddress,
        recipient: ContractAddress,
        tick_lower: i32,
        tick_upper: i32,
        amount: u128,
        amount_0: u256,
        amount_1: u256
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
    }

    #[derive(Copy, Drop)]
    struct SwapCache {
        // the protocol fee for the input token
        fee_protocol: u8,
        // liquidity at the beginning of the swap
        liquidity_start: u128,
        // the timestamp of the current block
        block_timestamp: u64,
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

    #[derive(Copy, Drop, Serde, starknet::Store)]
    // accumulated protocol fees in token_0/token_1 units
    struct ProtocolFees {
        token_0: u128,
        token_1: u128
    }

    #[derive(Serde, Copy, Drop)]
    struct ModifyPositionParams {
        position_key: PositionKey,
        // any change in liquidity
        liquidity_delta: i128
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
            .write(TickImpl::tick_spacing_to_max_liquidity_per_tick(@state_tick, tick_spacing));
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
            slot_0.tick = get_tick_at_sqrt_ratio(sqrt_price_X96);
            slot_0.fee_protocol = 0;
            self.slot_0.write(slot_0);

            self.unlocked.write(true);

            self.emit(Initialize { sqrt_price_X96, tick: slot_0.tick });
        }

        fn swap(
            ref self: ContractState,
            recipient: ContractAddress,
            zero_for_one: bool,
            amount_specified: i256,
            sqrt_price_limit_X96: FixedType,
            data: Array<felt252>
        ) -> (i256, i256) {
            assert(amount_specified.is_non_zero(), 'AS');

            let slot_0_start = self.slot_0.read();

            assert(
                if zero_for_one {
                    sqrt_price_limit_X96 < slot_0_start.sqrt_price_X96
                        && sqrt_price_limit_X96 > get_sqrt_ratio_at_tick(MIN_TICK())
                } else {
                    sqrt_price_limit_X96 > slot_0_start.sqrt_price_X96
                        && sqrt_price_limit_X96 < get_sqrt_ratio_at_tick(MAX_TICK())
                },
                'SPL'
            );
            self.check_and_lock();

            let cache = SwapCache {
                liquidity_start: self.liquidity.read(),
                block_timestamp: get_block_timestamp(),
                fee_protocol: if zero_for_one {
                    // calculate feeProtocol0
                    slot_0_start.fee_protocol % 16
                } else {
                    // calculate feeProtocol1
                    slot_0_start.fee_protocol.shr(4)
                }
            };

            let exact_input = amount_specified > Zeroable::zero();

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
                    TickBitmapImpl::next_initialized_tick_within_one_word(
                    @state_tick_bitmap, state.tick, self.tick_spacing.read(), zero_for_one
                );

                // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
                if step_tick_next < MIN_TICK() {
                    step_tick_next = MIN_TICK();
                } else if step_tick_next > MAX_TICK() {
                    step_tick_next = MAX_TICK();
                };

                // get the price for the next tick
                let step_sqrt_price_next_X96 = get_sqrt_ratio_at_tick(step_tick_next);

                // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
                let (ret_sqrt_price_X96, step_amount_in, step_amount_out, mut step_fee_amount) =
                    SwapMath::compute_swap_step(
                    state.sqrt_price_X96,
                    if (zero_for_one && step_sqrt_price_next_X96 < sqrt_price_limit_X96)
                        || (!zero_for_one && step_sqrt_price_next_X96 > sqrt_price_limit_X96) {
                        sqrt_price_limit_X96
                    } else {
                        step_sqrt_price_next_X96
                    },
                    state.liquidity,
                    state.amount_specified_remaining,
                    self.fee.read()
                );

                state.sqrt_price_X96 = ret_sqrt_price_X96;

                if exact_input {
                    state
                        .amount_specified_remaining -=
                            IntegerTrait::<i256>::new(step_amount_in + step_fee_amount, false);
                    state.amount_calculated -= step_amount_out.into();
                } else {
                    state.amount_specified_remaining += step_amount_out.into();
                    state.amount_calculated = state.amount_calculated
                        + IntegerTrait::<i256>::new(step_amount_in + step_fee_amount, false);
                };

                // if the protocol fee is on, calculate how much is owed, decrement feeAmount, and increment protocolFee
                if cache.fee_protocol > 0 {
                    let delta = step_fee_amount / cache.fee_protocol.into();
                    step_fee_amount -= delta;
                    state.protocol_fee += delta.try_into().unwrap();
                };

                // update global fee tracker
                if state.liquidity > 0 {
                    state
                        .fee_growth_global_X128 +=
                            FullMath::mul_div(step_fee_amount, Q128, state.liquidity.into());
                };

                // shift tick if we reached the next price
                if state.sqrt_price_X96 == step_sqrt_price_next_X96 {
                    // if the tick is initialized, run the tick transition
                    if step_initialized {
                        // crosses an initialized tick
                        let mut liquidity_net = TickImpl::cross(
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
                            0, // TODO: Remove in the future
                            IntegerTrait::<i64>::new(0, false),
                            0
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
                    state.tick = get_tick_at_sqrt_ratio(state.sqrt_price_X96);
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
                    protocol_fees.token_0 += state.protocol_fee;
                    self.protocol_fees.write(protocol_fees);
                }
            } else {
                self.fee_growth_global_1X128.write(state.fee_growth_global_X128);
                if state.protocol_fee > 0 {
                    let mut protocol_fees = self.protocol_fees.read();
                    protocol_fees.token_1 += state.protocol_fee;
                    self.protocol_fees.write(protocol_fees);
                }
            }

            let (amount_0, amount_1) = if zero_for_one == exact_input {
                (amount_specified - state.amount_specified_remaining, state.amount_calculated)
            } else {
                (state.amount_calculated, amount_specified - state.amount_specified_remaining)
            };

            // do the transfers and collect payment
            if zero_for_one {
                if amount_1 < Zeroable::zero() {
                    IERC20Dispatcher { contract_address: self.token_1.read() }
                        .transfer(recipient, amount_1.mag); // TODO: uint256(-amount1)
                };

                let balance_0_before: u256 = self.balance_0();

                let callback_contract = get_caller_address();
                assert(is_valid_callback_contract(callback_contract), 'invalid callback_contract');
                let dispatcher = IYASSwapCallbackDispatcher { contract_address: callback_contract };
                dispatcher.yas_swap_callback(amount_0, amount_1, data);

                assert(balance_0_before + amount_0.mag <= self.balance_0(), 'IIA');
            } else {
                if amount_0 < Zeroable::zero() {
                    IERC20Dispatcher { contract_address: self.token_0.read() }
                        .transfer(recipient, amount_0.mag); // TODO: uint256(-amount0)
                }

                let balance_1_before: u256 = self.balance_1();

                let callback_contract = get_caller_address();
                assert(is_valid_callback_contract(callback_contract), 'invalid callback_contract');
                let dispatcher = IYASSwapCallbackDispatcher { contract_address: callback_contract };
                dispatcher.yas_swap_callback(amount_0, amount_1, data);

                assert(balance_1_before + amount_1.mag <= self.balance_1(), 'IIA');
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
            self.unlock();
            (amount_0, amount_1)
        }

        fn mint(
            ref self: ContractState,
            recipient: ContractAddress,
            tick_lower: i32,
            tick_upper: i32,
            amount: u128,
            data: Array<felt252>
        ) -> (u256, u256) {
            self.check_and_lock();

            assert(amount > 0, 'amount must be greater than 0');
            let (_, amount_0, amount_1) = modify_position(
                    ModifyPositionParams {
                        position_key: PositionKey { owner: recipient, tick_lower, tick_upper },
                        liquidity_delta: amount.into()
                    }
                );

            let amount_0: u256 = amount_0.try_into().unwrap();
            let amount_1: u256 = amount_1.try_into().unwrap();

            let mut balance_0_before = 0;
            if amount_0 > 0 {
                balance_0_before = self.balance_0();
            }

            let mut balance_1_before = 0;
            if amount_1 > 0 {
                balance_1_before = self.balance_1();
            }

            let callback_contract = get_caller_address();
            assert(is_valid_callback_contract(callback_contract), 'invalid callback_contract');
            let dispatcher = IYASMintCallbackDispatcher { contract_address: callback_contract };
            dispatcher.yas_mint_callback(amount_0, amount_1, data);

            if amount_0 > 0 {
                assert(balance_0_before + amount_0 <= self.balance_0(), 'M0');
            }

            if amount_1 > 0 {
                assert(balance_1_before + amount_1 <= self.balance_1(), 'M1');
            }

            self
                .emit(
                    Mint {
                        sender: get_caller_address(),
                        recipient,
                        tick_lower,
                        tick_upper,
                        amount,
                        amount_0,
                        amount_1
                    }
                );
            self.unlock();
            (amount_0, amount_1)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn get_slot_0(self: @ContractState) -> Slot0 {
            self.slot_0.read()
        }

        fn check_and_lock(ref self: ContractState) {
            let unlocked = self.unlocked.read();
            assert(unlocked, 'LOK');
            self.unlocked.write(false);
        }

        fn unlock(ref self: ContractState) {
            let locked = self.unlocked.read();
            self.unlocked.write(true);
        }

        fn balance_0(self: @ContractState) -> u256 {
            IERC20Dispatcher { contract_address: self.token_0.read() }
                .balanceOf(get_contract_address())
        }

        fn balance_1(self: @ContractState) -> u256 {
            IERC20Dispatcher { contract_address: self.token_1.read() }
                .balanceOf(get_contract_address())
        }
    }

    fn is_valid_callback_contract(callback_contract: ContractAddress) -> bool {
        callback_contract.is_non_zero()
    }

    // TODO: mock
    fn modify_position(params: ModifyPositionParams) -> (Info, i256, i256) {
        let info = Info {
            liquidity: 100,
            fee_growth_inside_0_last_X128: 20,
            fee_growth_inside_1_last_X128: 20,
            tokens_owed_0: 10,
            tokens_owed_1: 10,
        };
        let zero: i256 = Zeroable::zero();
        (info, zero, zero)
    }
}
