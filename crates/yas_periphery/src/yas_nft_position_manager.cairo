use starknet::ContractAddress;

use yas_core::numbers::fixed_point::implementations::impl_64x96::FixedType;
use yas_core::numbers::signed_integer::{i32::i32};

// details about the uniswap position
#[derive(Copy, Drop, Serde, starknet::Store)]
struct Position {
    // the nonce for permits
    nonce: u128,
    // the address that is approved for spending this token
    operator: ContractAddress,
    // the ID of the pool with which this token is connected
    pool_id: u128,
    // the tick range of the position
    tick_lower: i32,
    tick_upper: i32,
    // the liquidity of the position
    liquidity: u128,
    // the fee growth of the aggregate position as of the last action on the individual position
    fee_growth_inside_0_last_X128: u256,
    fee_growth_inside_1_last_X128: u256,
    // how many uncollected tokens are owed to the position, as of the last computation
    tokens_owed_0: u128,
    tokens_owed_1: u128
}

#[derive(Copy, Drop, Serde, starknet::Store)]
struct PoolKey {
    token_0: ContractAddress,
    token_1: ContractAddress,
    fee: u32
}

#[derive(Drop, Serde)]
struct MintParams {
    token_0: ContractAddress,
    token_1: ContractAddress,
    fee: u32,
    tick_lower: i32,
    tick_upper: i32,
    amount_0_desired: u256,
    amount_1_desired: u256,
    amount_0_min: u256,
    amount_1_min: u256,
    recipient: ContractAddress,
    deadline: u256
}

#[derive(Drop, Serde)]
struct IncreaseLiquidityParams {
    token_id: u256,
    amount_0_desired: u256,
    amount_1_desired: u256,
    amount_0_min: u256,
    amount_1_min: u256,
    deadline: u256
}

#[derive(Drop, Serde)]
struct DecreaseLiquidityParams {
    token_id: u256,
    liquidity: u128,
    amount_0_min: u256,
    amount_1_min: u256,
    deadline: u256
}

#[derive(Drop, Serde)]
struct AddLiquidityParams {
    token_0: ContractAddress,
    token_1: ContractAddress,
    fee: u32,
    recipient: ContractAddress,
    tick_lower: i32,
    tick_upper: i32,
    amount_0_desired: u256,
    amount_1_desired: u256,
    amount_0_min: u256,
    amount_1_min: u256
}

#[starknet::interface]
trait IYASNFTPositionManager<TContractState> {
    fn create_and_initialize_pool_if_necessary(
        ref self: TContractState,
        token_0: ContractAddress,
        token_1: ContractAddress,
        fee: u32,
        sqrt_price_X96: FixedType
    ) -> ContractAddress;
    fn positions(self: @TContractState, token_id: u256) -> (Position, PoolKey);
    fn mint(ref self: TContractState, params: MintParams) -> (u256, u128, u256, u256);
    fn increase_liquidity(
        ref self: TContractState, params: IncreaseLiquidityParams
    ) -> (u128, u256, u256);
    // fn decrease_liquidity(
    //     ref self: TContractState, params: DecreaseLiquidityParams
    // ) -> (u256, u256);
    fn factory(self: @TContractState) -> ContractAddress;
    fn yas_mint_callback(
        ref self: TContractState, amount_0_owed: u256, amount_1_owed: u256, data: Array<felt252>
    );
    // ERC721
    fn supports_interface(self: @TContractState, interface_id: felt252) -> bool;
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn token_uri(self: @TContractState, token_id: u256) -> felt252;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;
    fn transfer_from(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, token_id: u256
    );
    fn safe_transfer_from(
        ref self: TContractState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    );
    fn approve(ref self: TContractState, to: ContractAddress, token_id: u256);
    fn set_approval_for_all(ref self: TContractState, operator: ContractAddress, approved: bool);
    fn get_approved(self: @TContractState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TContractState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
}

#[starknet::contract]
mod YASNFTPositionManager {
    use super::{
        IYASNFTPositionManager, AddLiquidityParams, IncreaseLiquidityParams,
        DecreaseLiquidityParams, MintParams, Position, PoolKey
    };
    use starknet::{
        ContractAddress, get_contract_address, contract_address_const, get_caller_address
    };
    use openzeppelin::token::erc721::ERC721;

    use yas_core::contracts::yas_pool::{IYASPoolDispatcher, IYASPoolDispatcherTrait};
    use yas_core::contracts::yas_factory::{IYASFactoryDispatcher, IYASFactoryDispatcherTrait};
    use yas_core::interfaces::interface_ERC20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use yas_core::libraries::position::{PositionKey, Info};
    use yas_core::libraries::tick_math::TickMath::{
        get_tick_at_sqrt_ratio, get_sqrt_ratio_at_tick, MIN_TICK, MAX_TICK
    };
    use yas_core::numbers::fixed_point::implementations::impl_64x96::{
        FixedType, FixedTrait, FP64x96PartialOrd, FP64x96PartialEq, FP64x96Impl, FP64x96Zeroable,
        FP64x96Sub, ONE
    };
    use yas_core::numbers::signed_integer::{i32::i32};
    use yas_core::utils::math_utils::Constants::Q128;
    use yas_core::utils::math_utils::FullMath;
    use yas_core::utils::utils::ContractAddressPartialOrd;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        IncreaseLiquidity: IncreaseLiquidity,
        DecreaseLiquidity: DecreaseLiquidity,
        Collect: Collect,
        Approval: Approval,
        MintCallback: MintCallback
    }

    #[derive(Drop, starknet::Event)]
    struct IncreaseLiquidity {
        token_id: u256,
        liquidity: u128,
        amount_0: u256,
        amount_1: u256
    }

    #[derive(Drop, starknet::Event)]
    struct DecreaseLiquidity {
        token_id: u256,
        liquidity: u128,
        amount_0: u256,
        amount_1: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Collect {
        token_id: u256,
        recipient: ContractAddress,
        amount_0_collect: u256,
        amount_1_collect: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        to: ContractAddress,
        token_id: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct MintCallback {
        amount_0_owed: u256,
        amount_1_owed: u256
    }

    #[storage]
    struct Storage {
        factory: ContractAddress,
        pool_ids: LegacyMap<ContractAddress, u128>,
        pool_id_to_pool_key: LegacyMap<u128, PoolKey>,
        positions: LegacyMap<u256, Position>,
        next_id: u256,
        next_pool_id: u128
    }

    #[constructor]
    fn constructor(ref self: ContractState, factory: ContractAddress) {
        // TODO: ERC721Permit.sol
        let mut state = ERC721::unsafe_new_contract_state();
        ERC721::InternalImpl::initializer(ref state, 'YAS Positions NFT-V1', 'YAS-V3-POS');

        self.factory.write(factory);
        self.next_id.write(1);
        self.next_pool_id.write(1);
    }

    #[external(v0)]
    impl YASNFTPositionManagerImpl of IYASNFTPositionManager<ContractState> {
        fn factory(self: @ContractState) -> ContractAddress {
            self.factory.read()
        }

        fn positions(self: @ContractState, token_id: u256) -> (Position, PoolKey) {
            let position = self.positions.read(token_id);
            assert(position.pool_id != 0, 'Invalid token ID');
            let pool_key = self.pool_id_to_pool_key.read(position.pool_id);
            (position, pool_key)
        }

        fn mint(ref self: ContractState, params: MintParams) -> (u256, u128, u256, u256) {
            let (liquidity, amount_0, amount_1, pool_dispatcher) = self
                .add_liquidity(
                    AddLiquidityParams {
                        token_0: params.token_0,
                        token_1: params.token_1,
                        fee: params.fee,
                        recipient: get_contract_address(),
                        tick_lower: params.tick_lower,
                        tick_upper: params.tick_upper,
                        amount_0_desired: params.amount_0_desired,
                        amount_1_desired: params.amount_1_desired,
                        amount_0_min: params.amount_0_min,
                        amount_1_min: params.amount_1_min
                    }
                );

            let token_id = self.next_id.read();
            self.next_id.write(token_id + 1);
            let mut state = ERC721::unsafe_new_contract_state();
            ERC721::InternalImpl::_mint(ref state, params.recipient, token_id);

            let info = pool_dispatcher
                .positions(
                    PositionKey {
                        owner: get_contract_address(),
                        tick_lower: params.tick_lower,
                        tick_upper: params.tick_upper
                    }
                );

            // idempotent set
            let pool_id = self
                .cache_pool_key(
                    pool_dispatcher.contract_address,
                    PoolKey { token_0: params.token_0, token_1: params.token_1, fee: params.fee }
                );

            self
                .positions
                .write(
                    token_id,
                    Position {
                        nonce: 0,
                        operator: contract_address_const::<0>(),
                        pool_id: pool_id,
                        tick_lower: params.tick_lower,
                        tick_upper: params.tick_upper,
                        liquidity: liquidity,
                        fee_growth_inside_0_last_X128: info.fee_growth_inside_0_last_X128,
                        fee_growth_inside_1_last_X128: info.fee_growth_inside_1_last_X128,
                        tokens_owed_0: 0,
                        tokens_owed_1: 0
                    }
                );

            self.emit(IncreaseLiquidity { token_id, liquidity, amount_0, amount_1 });
            (token_id, liquidity, amount_0, amount_1)
        }

        fn increase_liquidity(
            ref self: ContractState, params: IncreaseLiquidityParams
        ) -> (u128, u256, u256) {
            let mut position = self.positions.read(params.token_id);
            let pool_key = self.pool_id_to_pool_key.read(position.pool_id);

            let (liquidity, amount_0, amount_1, pool_dispatcher) = self
                .add_liquidity(
                    AddLiquidityParams {
                        token_0: pool_key.token_0,
                        token_1: pool_key.token_1,
                        fee: pool_key.fee,
                        tick_lower: position.tick_lower,
                        tick_upper: position.tick_upper,
                        amount_0_desired: params.amount_0_desired,
                        amount_1_desired: params.amount_1_desired,
                        amount_0_min: params.amount_0_min,
                        amount_1_min: params.amount_1_min,
                        recipient: get_contract_address()
                    }
                );

            // this is now updated to the current transaction
            let info = pool_dispatcher
                .positions(
                    PositionKey {
                        owner: get_contract_address(),
                        tick_lower: position.tick_lower,
                        tick_upper: position.tick_upper
                    }
                );

            position
                .tokens_owed_0 +=
                    FullMath::mul_div(
                        info.fee_growth_inside_0_last_X128 - position.fee_growth_inside_0_last_X128,
                        position.liquidity.into(),
                        Q128
                    )
                .try_into()
                .unwrap();

            position
                .tokens_owed_1 +=
                    FullMath::mul_div(
                        info.fee_growth_inside_1_last_X128 - position.fee_growth_inside_1_last_X128,
                        position.liquidity.into(),
                        Q128
                    )
                .try_into()
                .unwrap();

            position.fee_growth_inside_0_last_X128 = info.fee_growth_inside_0_last_X128;
            position.fee_growth_inside_1_last_X128 = info.fee_growth_inside_1_last_X128;
            position.liquidity += liquidity;

            self.positions.write(params.token_id, position);

            self
                .emit(
                    IncreaseLiquidity { token_id: params.token_id, liquidity, amount_0, amount_1 }
                );
            (liquidity, amount_0, amount_1)
        }

        // /// @inheritdoc INonfungiblePositionManager
        // fn decrease_liquidity(
        //     ref self: ContractState, params: DecreaseLiquidityParams
        // ) -> (u256, u256) {
        //     assert(params.liquidity > 0, '');
        //     let mut position = self.positions.read(params.token_id);

        //     let position_liquidity = position.liquidity;
        //     assert(position_liquidity >= params.liquidity, '');

        //     let pool_key = self.pool_id_to_pool_key.read(position.pool_id);
        //     // // IUniswapV3Pool pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));
        //     // let (amount_0, amount_1) = pool.burn(position.tick_lower, position.tick_upper, params.liquidity);
        //     let (amount_0, amount_1) = (0, 0);

        //     assert(
        //         amount_0 >= params.amount_0_min && amount_1 >= params.amount_1_min,
        //         'Price slippage check'
        //     );

        //     // this is now updated to the current transaction
        //     // let (_, fee_growth_inside_0_last_X128, fee_growth_inside_1_last_X128, _, _) = pool
        //     let info = pool.positions(
        //             PositionKey {
        //                 owner: get_contract_address(),
        //                 tick_lower: position.tick_lower,
        //                 tick_upper: position.tick_upper
        //             }
        //         );

        //     position
        //         .tokens_owed_0 +=
        //             (amount_0
        //                 + FullMath::mul_div(
        //                     info.fee_growth_inside_0_last_X128 - position.fee_growth_inside_0_last_X128,
        //                     position_liquidity.into(),
        //                     Q128
        //                 ))
        //         .try_into()
        //         .unwrap();

        //     position
        //         .tokens_owed_1 +=
        //             (amount_1
        //                 + FullMath::mul_div(
        //                     info.fee_growth_inside_1_lastX128 - position.fee_growth_inside_1_last_X128,
        //                     position_liquidity,
        //                     Q128
        //                 ))
        //         .try_into()
        //         .unwrap();

        //     position.fee_growth_inside_0_last_X128 = info.fee_growth_inside_0_last_X128;
        //     position.fee_growth_inside_1_last_X128 = info.fee_growth_inside_1_last_X128;
        //     // subtraction is safe because we checked positionLiquidity is gte params.liquidity
        //     position.liquidity = position_liquidity - params.liquidity;

        //     self.positions.write(params.token_id, position);

        //     self
        //         .emit(
        //             DecreaseLiquidity {
        //                 token_id: params.token_id, liquidity: params.liquidity, amount_0, amount_1
        //             }
        //         );
        //     (amount_0, amount_1)
        // }

        fn create_and_initialize_pool_if_necessary(
            ref self: ContractState,
            token_0: ContractAddress,
            token_1: ContractAddress,
            fee: u32,
            sqrt_price_X96: FixedType
        ) -> ContractAddress {
            assert(token_0 < token_1, '');
            let factory_dispatcher = IYASFactoryDispatcher {
                contract_address: self.factory.read()
            };
            let mut pool = factory_dispatcher.pool(token_0, token_1, fee);

            if pool.is_zero() {
                pool = factory_dispatcher.create_pool(token_0, token_1, fee);
                IYASPoolDispatcher { contract_address: pool }.initialize(sqrt_price_X96);
            } else {
                let (sqrt_price_X96_existing, _, _, _) = IYASPoolDispatcher {
                    contract_address: pool
                }
                    .slot_0();
                if sqrt_price_X96_existing.is_zero() {
                    IYASPoolDispatcher { contract_address: pool }.initialize(sqrt_price_X96);
                }
            }
            pool
        }

        fn yas_mint_callback(
            ref self: ContractState, amount_0_owed: u256, amount_1_owed: u256, data: Array<felt252>
        ) {
            let msg_sender = get_caller_address();

            // TODO: we need verify if data has a valid ContractAddress
            let mut sender: ContractAddress = Zeroable::zero();
            if !data.is_empty() {
                sender = (*data[0]).try_into().unwrap();
            }

            self.emit(MintCallback { amount_0_owed, amount_1_owed });

            if amount_0_owed > 0 {
                let token_0 = IYASPoolDispatcher { contract_address: msg_sender }.token_0();
                IERC20Dispatcher { contract_address: token_0 }
                    .transferFrom(sender, msg_sender, amount_0_owed);
            }
            if amount_1_owed > 0 {
                let token_1 = IYASPoolDispatcher { contract_address: msg_sender }.token_1();
                IERC20Dispatcher { contract_address: token_1 }
                    .transferFrom(sender, msg_sender, amount_1_owed);
            }
        }

        // ERC721
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            let state = ERC721::unsafe_new_contract_state();
            ERC721::SRC5Impl::supports_interface(@state, interface_id)
        }

        fn name(self: @ContractState) -> felt252 {
            let state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721MetadataImpl::name(@state)
        }

        fn symbol(self: @ContractState) -> felt252 {
            let state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721MetadataImpl::symbol(@state)
        }

        fn token_uri(self: @ContractState, token_id: u256) -> felt252 {
            let state = ERC721::unsafe_new_contract_state();
            assert(ERC721::InternalImpl::_exists(@state, token_id), 'ERC721: invalid token ID');
            // TODO: url
            1
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            let state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::balance_of(@state, account)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::owner_of(@state, token_id)
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            let mut state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::transfer_from(ref state, from, to, token_id);
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            let mut state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::safe_transfer_from(ref state, from, to, token_id, data);
        }

        // TODO: replace _approve
        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let state = ERC721::unsafe_new_contract_state();
            let owner = ERC721::InternalImpl::_owner_of(@state, token_id);

            let caller = get_caller_address();
            assert(
                owner == caller || ERC721::ERC721Impl::is_approved_for_all(@state, owner, caller),
                ERC721::Errors::UNAUTHORIZED
            );

            let mut position = self.positions.read(token_id);
            position.operator = to;
            self.positions.write(token_id, position);

            self.emit(Approval { owner, to, token_id });
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            let mut state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::set_approval_for_all(ref state, operator, approved);
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            let state = ERC721::unsafe_new_contract_state();
            assert(ERC721::InternalImpl::_exists(@state, token_id), 'ERC721: invalid token ID');
            self.positions.read(token_id).operator
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            let state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::is_approved_for_all(@state, owner, operator)
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        // @dev Caches a pool key
        fn cache_pool_key(
            ref self: ContractState, pool: ContractAddress, pool_key: PoolKey
        ) -> u128 {
            let mut pool_id = self.pool_ids.read(pool);
            if pool_id == 0 {
                pool_id = self.next_pool_id.read();
                self.next_pool_id.write(pool_id + 1);
                self.pool_ids.write(pool, pool_id);
                self.pool_id_to_pool_key.write(pool_id, pool_key);
            }
            pool_id
        }

        fn add_liquidity(
            self: @ContractState, params: AddLiquidityParams
        ) -> (u128, u256, u256, IYASPoolDispatcher) {
            let pool_key = PoolKey {
                token_0: params.token_0, token_1: params.token_1, fee: params.fee
            };

            let pool_address = IYASFactoryDispatcher { contract_address: self.factory.read() }
                .pool(params.token_0, params.token_1, params.fee);

            let pool_dispatcher = IYASPoolDispatcher { contract_address: pool_address };

            // compute the liquidity amount
            let (sqrt_price_X96, _, _, _) = pool_dispatcher.slot_0();
            let sqrt_ratio_AX96 = get_sqrt_ratio_at_tick(params.tick_lower);
            let sqrt_ratio_BX96 = get_sqrt_ratio_at_tick(params.tick_upper);

            // TODO:
            let liquidity = get_liquidity_for_amounts(
                sqrt_price_X96,
                sqrt_ratio_AX96,
                sqrt_ratio_BX96,
                params.amount_0_desired,
                params.amount_1_desired
            );

            let (amount_0, amount_1) = pool_dispatcher
                .mint(
                    params.recipient,
                    params.tick_lower,
                    params.tick_upper,
                    liquidity,
                    array![get_caller_address().into()]
                );

            assert(
                amount_0 >= params.amount_0_min && amount_1 >= params.amount_1_min,
                'Price slippage check'
            );
            (liquidity, amount_0, amount_1, pool_dispatcher)
        }
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    fn get_liquidity_for_amount_0(
        sqrt_ratio_AX96: FixedType, sqrt_ratio_BX96: FixedType, amount_0: u256
    ) -> u128 {
        let (sqrt_ratio_AX96, sqrt_ratio_BX96) = if sqrt_ratio_AX96 > sqrt_ratio_BX96 {
            (sqrt_ratio_BX96, sqrt_ratio_AX96)
        } else {
            (sqrt_ratio_AX96, sqrt_ratio_BX96)
        };
        // TODO: .mag
        let intermediate = FullMath::mul_div(sqrt_ratio_AX96.mag, sqrt_ratio_BX96.mag, ONE);
        FullMath::mul_div(amount_0, intermediate, (sqrt_ratio_BX96 - sqrt_ratio_AX96).mag)
            .try_into()
            .unwrap()
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    fn get_liquidity_for_amount_1(
        sqrt_ratio_AX96: FixedType, sqrt_ratio_BX96: FixedType, amount_1: u256
    ) -> u128 {
        let (sqrt_ratio_AX96, sqrt_ratio_BX96) = if sqrt_ratio_AX96 > sqrt_ratio_BX96 {
            (sqrt_ratio_BX96, sqrt_ratio_AX96)
        } else {
            (sqrt_ratio_AX96, sqrt_ratio_BX96)
        };
        // TODO: .mag
        FullMath::mul_div(amount_1, ONE, (sqrt_ratio_BX96 - sqrt_ratio_AX96).mag)
            .try_into()
            .unwrap()
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    fn get_liquidity_for_amounts(
        sqrt_ratio_X96: FixedType,
        sqrt_ratio_AX96: FixedType,
        sqrt_ratio_BX96: FixedType,
        amount_0: u256,
        amount_1: u256
    ) -> u128 {
        let (sqrt_ratio_AX96, sqrt_ratio_BX96) = if sqrt_ratio_AX96 > sqrt_ratio_BX96 {
            (sqrt_ratio_BX96, sqrt_ratio_AX96)
        } else {
            (sqrt_ratio_AX96, sqrt_ratio_BX96)
        };

        if sqrt_ratio_X96 <= sqrt_ratio_AX96 {
            get_liquidity_for_amount_0(sqrt_ratio_AX96, sqrt_ratio_BX96, amount_0)
        } else if sqrt_ratio_X96 < sqrt_ratio_BX96 {
            let liquidity_0 = get_liquidity_for_amount_0(sqrt_ratio_X96, sqrt_ratio_BX96, amount_0);
            let liquidity_1 = get_liquidity_for_amount_1(sqrt_ratio_AX96, sqrt_ratio_X96, amount_1);
            if liquidity_0 < liquidity_1 {
                liquidity_0
            } else {
                liquidity_1
            }
        } else {
            get_liquidity_for_amount_1(sqrt_ratio_AX96, sqrt_ratio_BX96, amount_1)
        }
    }
}
