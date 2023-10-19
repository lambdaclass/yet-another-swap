mod YASNFTPositionManagerTests {
    use starknet::{ClassHash, ContractAddress, SyscallResultTrait};
    use starknet::syscalls::deploy_syscall;
    use starknet::testing::{set_contract_address};
    use integer::BoundedInt;

    use yas_core::contracts::yas_erc20::{
        ERC20, ERC20::ERC20Impl, IERC20Dispatcher, IERC20DispatcherTrait
    };
    use yas_core::contracts::yas_factory::{
        YASFactory, IYASFactory, IYASFactoryDispatcher, IYASFactoryDispatcherTrait
    };
    use yas_core::libraries::tick_math::{TickMath::MIN_TICK, TickMath::MAX_TICK};
    use yas_core::numbers::fixed_point::implementations::impl_64x96::{
        FP64x96Impl, FixedType, FixedTrait
    };
    use yas_core::numbers::signed_integer::{
        i32::i32, i32::i32_div_no_round, integer_trait::IntegerTrait
    };
    use yas_core::tests::utils::constants::FactoryConstants::{
        POOL_CLASS_HASH, FeeAmount, fee_amount, tick_spacing, OWNER
    };
    use yas_core::tests::utils::constants::PoolConstants::{
        TOKEN_A, TOKEN_B, POOL_ADDRESS, WALLET, encode_price_sqrt_1_1
    };

    use yas_periphery::yas_nft_position_manager::{
        YASNFTPositionManager, IYASNFTPositionManager, IYASNFTPositionManagerDispatcher,
        IYASNFTPositionManagerDispatcherTrait, MintParams
    };

    fn setup() -> (IYASNFTPositionManagerDispatcher, IERC20Dispatcher, IERC20Dispatcher) {
        let yas_factory = deploy_factory(OWNER(), POOL_CLASS_HASH()); // 0x1
        let nft_position_manager = deploy_nft_position_manager(yas_factory.contract_address); // 0x2

        // Deploy ERC20 tokens with factory address
        let token_0 = deploy_erc20('YAS0', '$YAS0', 4000000000000000000, OWNER()); // 0x3
        let token_1 = deploy_erc20('YAS1', '$YAS1', 4000000000000000000, OWNER()); // 0x4

        set_contract_address(OWNER());
        token_0.transfer(WALLET(), 4000000000000000000);
        token_1.transfer(WALLET(), 4000000000000000000);

        // Give permissions to expend WALLET() tokens
        set_contract_address(WALLET());
        token_1.approve(nft_position_manager.contract_address, BoundedInt::max());
        token_0.approve(nft_position_manager.contract_address, BoundedInt::max());

        (nft_position_manager, token_0, token_1)
    }

    fn deploy_factory(
        deployer: ContractAddress, pool_class_hash: ClassHash
    ) -> IYASFactoryDispatcher {
        let (address, _) = deploy_syscall(
            YASFactory::TEST_CLASS_HASH.try_into().unwrap(),
            0,
            array![deployer.into(), pool_class_hash.into()].span(),
            true
        )
            .unwrap_syscall();

        return IYASFactoryDispatcher { contract_address: address };
    }

    fn deploy_erc20(
        name: felt252, symbol: felt252, initial_supply: u256, recipent: ContractAddress
    ) -> IERC20Dispatcher {
        let mut calldata = array![name, symbol];
        Serde::serialize(@initial_supply, ref calldata);
        calldata.append(recipent.into());

        let (address, _) = deploy_syscall(
            ERC20::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), true
        )
            .unwrap_syscall();

        return IERC20Dispatcher { contract_address: address };
    }

    fn deploy_nft_position_manager(factory: ContractAddress) -> IYASNFTPositionManagerDispatcher {
        let (address, _) = deploy_syscall(
            YASNFTPositionManager::TEST_CLASS_HASH.try_into().unwrap(),
            0,
            array![factory.into()].span(),
            true
        )
            .unwrap_syscall();

        return IYASNFTPositionManagerDispatcher { contract_address: address };
    }

    fn get_min_tick_and_max_tick() -> (i32, i32) {
        let tick_spacing = IntegerTrait::<i32>::new(tick_spacing(FeeAmount::MEDIUM), false);
        let min_tick = i32_div_no_round(MIN_TICK(), tick_spacing) * tick_spacing;
        let max_tick = i32_div_no_round(MAX_TICK(), tick_spacing) * tick_spacing;
        (min_tick, max_tick)
    }

    mod mint {
        use super::{setup, get_min_tick_and_max_tick};
        use starknet::testing::{set_contract_address};

        use yas_core::contracts::yas_erc20::{
            ERC20, ERC20::ERC20Impl, IERC20Dispatcher, IERC20DispatcherTrait
        };
        use yas_core::numbers::fixed_point::implementations::impl_64x96::{
            FP64x96Impl, FixedType, FixedTrait
        };
        use yas_core::tests::utils::constants::FactoryConstants::{
            POOL_CLASS_HASH, FeeAmount, fee_amount, tick_spacing
        };
        use yas_core::tests::utils::constants::PoolConstants::{TOKEN_A, TOKEN_B, WALLET, OTHER, encode_price_sqrt_1_1};

        use yas_periphery::yas_nft_position_manager::{
            YASNFTPositionManager, IYASNFTPositionManager, IYASNFTPositionManagerDispatcher,
            IYASNFTPositionManagerDispatcherTrait, MintParams, Position, PoolKey
        };

        #[test]
        #[available_gas(200000000)]
        #[should_panic(expected: ('CONTRACT_NOT_DEPLOYED', 'ENTRYPOINT_FAILED'))]
        fn test_fails_if_pool_does_not_exist() {
            let (yas_nft_position_manager, token_0, token_1) = setup();

            let (min_tick, max_tick) = get_min_tick_and_max_tick();

            yas_nft_position_manager
                .mint(
                    MintParams {
                        token_0: token_0.contract_address,
                        token_1: token_1.contract_address,
                        fee: fee_amount(FeeAmount::MEDIUM),
                        recipient: WALLET(),
                        tick_lower: min_tick,
                        tick_upper: max_tick,
                        amount_0_desired: 100,
                        amount_1_desired: 100,
                        amount_0_min: 0,
                        amount_1_min: 0,
                        deadline: 1
                    }
                );
        }

        #[test]
        #[available_gas(200000000)]
        #[should_panic(
            expected: (
                'u256_sub Overflow',
                'ENTRYPOINT_FAILED',
                'ENTRYPOINT_FAILED',
                'ENTRYPOINT_FAILED',
                'ENTRYPOINT_FAILED'
            )
        )]
        fn test_fails_if_cannot_transfer() {
            let (yas_nft_position_manager, token_0, token_1) = setup();

            let sqrt_price_X96 = encode_price_sqrt_1_1();

            yas_nft_position_manager
                .create_and_initialize_pool_if_necessary(
                    token_0.contract_address,
                    token_1.contract_address,
                    fee_amount(FeeAmount::MEDIUM),
                    sqrt_price_X96
                );

            set_contract_address(WALLET());
            token_0.approve(yas_nft_position_manager.contract_address, 0);

            let (min_tick, max_tick) = get_min_tick_and_max_tick();
            yas_nft_position_manager
                .mint(
                    MintParams {
                        token_0: token_0.contract_address,
                        token_1: token_1.contract_address,
                        fee: fee_amount(FeeAmount::MEDIUM),
                        recipient: WALLET(),
                        tick_lower: min_tick,
                        tick_upper: max_tick,
                        amount_0_desired: 100,
                        amount_1_desired: 100,
                        amount_0_min: 0,
                        amount_1_min: 0,
                        deadline: 1
                    }
                );
        }

        #[test]
        #[available_gas(200000000)]
        fn test_creates_a_token() {
            let (yas_nft_position_manager, token_0, token_1) = setup();

            let sqrt_price_X96 = encode_price_sqrt_1_1();

            yas_nft_position_manager
                .create_and_initialize_pool_if_necessary(
                    token_0.contract_address,
                    token_1.contract_address,
                    fee_amount(FeeAmount::MEDIUM),
                    sqrt_price_X96
                );

            let (min_tick, max_tick) = get_min_tick_and_max_tick();
            yas_nft_position_manager
                .mint(
                    MintParams {
                        token_0: token_0.contract_address,
                        token_1: token_1.contract_address,
                        fee: fee_amount(FeeAmount::MEDIUM),
                        recipient: OTHER(),
                        tick_lower: min_tick,
                        tick_upper: max_tick,
                        amount_0_desired: 15,
                        amount_1_desired: 15,
                        amount_0_min: 0,
                        amount_1_min: 0,
                        deadline: 10
                    }
                );

            assert(yas_nft_position_manager.balance_of(OTHER()) == 1, 'wrong balance_of OTHER');
            // assert(yas_nft_position_manager.token_of_owner_by_index(other.address, 0) == 1, ''); // TODO: ERC721Enumerable

            let (position, pool_key) = yas_nft_position_manager.positions(1);
            assert(pool_key.token_0 == token_0.contract_address, 'wrong token_0');
            assert(pool_key.token_1 == token_1.contract_address, 'wrong token_1');
            assert(pool_key.fee == fee_amount(FeeAmount::MEDIUM), 'wrong fee');
            assert(position.tick_lower == min_tick, 'wrong tick_lower');
            assert(position.tick_upper == max_tick, 'wrong tick_upper');
            assert(position.liquidity == 15, 'wrong liquidity');
            assert(position.tokens_owed_0 == 0, 'wrong tokens_owed_0');
            assert(position.tokens_owed_1 == 0, 'wrong tokens_owed_1');
            assert(position.fee_growth_inside_0_last_X128 == 0, 'wrong fee_growth_inside_0');
            assert(position.fee_growth_inside_1_last_X128 == 0, 'wrong fee_growth_inside_1');
        }
    }
}
