mod SwapTestHelper {
    use integer::BoundedInt;
    use yas_core::contracts::yas_factory::{
        YASFactory, IYASFactoryDispatcher, IYASFactoryDispatcherTrait
    };
    use yas_core::contracts::yas_pool::{YASPool, IYASPoolDispatcher, IYASPoolDispatcherTrait};
    use yas_core::contracts::yas_router::{
        YASRouter, IYASRouterDispatcher, IYASRouterDispatcherTrait
    };
    use yas_core::contracts::yas_erc20::{ERC20, IERC20Dispatcher, IERC20DispatcherTrait};
    use yas_core::libraries::tick_math::TickMath::{MAX_SQRT_RATIO, MIN_SQRT_RATIO};
    use yas_core::numbers::fixed_point::implementations::impl_64x96::{
        FixedType, FixedTrait, FP64x96Impl, FP64x96Zeroable
    };
    use yas_core::numbers::signed_integer::i256::{IntegerTrait, i256};
    use yas_core::tests::utils::constants::FactoryConstants::{POOL_CLASS_HASH};
    use yas_core::tests::utils::constants::PoolConstants::{WALLET, OWNER, POOL_ADDRESS};
    use yas_core::tests::utils::swap_cases::{
        SwapTestHelper, SwapTestHelper::PoolTestCase, SwapTestHelper::SwapTestCase,
        SwapTestHelper::SwapExpectedResults, SwapTestHelper::{POOL_CASES, SWAP_CASES}
    };
    use yas_core::tests::utils::swap_helper::ContractDeployerHelper::{
        deploy_yas_erc20, deploy_yas_factory, deploy_yas_router
    };
    use yas_core::utils::math_utils::{FullMath::mul_div, pow};

    use starknet::{ContractAddress, ClassHash, SyscallResultTrait};
    use starknet::testing::{set_contract_address, set_caller_address};

    fn test_pool(
        pool_case: @PoolTestCase,
        expected_cases: Array<SwapExpectedResults>,
        swap_cases: Array<SwapTestCase>,
        precision_required: u256,
    ) {
        let mut i = 0;
        assert(expected_cases.len() == swap_cases.len(), 'wrong amount of expected cases');
        loop {
            if i == expected_cases.len() {
                break;
            }

            // Restart pool
            let (yas_pool, yas_router, token_0, token_1) = setup_pool_for_swap_test(
                initial_price: *pool_case.starting_price,
                fee_amount: *pool_case.fee_amount,
                mint_positions: pool_case.mint_positions,
            );
            let swap_case = swap_cases[i];
            let expected = expected_cases[i];

            // Save values before swap for compare
            let user_token_0_balance_bf = token_0.balanceOf(WALLET());
            let user_token_1_balance_bf = token_1.balanceOf(WALLET());
            let (fee_growth_global_0_X128_bf, fee_growth_global_1_X128_bf) = yas_pool
                .get_fee_growth_globals();

            let pool_balance_0_bf = token_0.balanceOf(yas_pool.contract_address);
            let pool_balance_1_bf = token_1.balanceOf(yas_pool.contract_address);
            let slot0_bf = yas_pool.get_slot_0();

            let mut amount_to_swap = Zeroable::zero();
            if *swap_case.has_exact_out {
                if *swap_case.exact_out { //exact OUT
                    amount_to_swap =
                        IntegerTrait::<i256>::new(
                            *swap_case.amount_specified.mag, true
                        ); //swap(-x) when amount=amount_out
                } else { //exact IN, normal swap.
                    amount_to_swap = *swap_case.amount_specified; //swap(x) when amount=amount_in
                }
            } else {
                amount_to_swap = IntegerTrait::<i256>::new((BoundedInt::max() / 2) - 1, false);
            }

            // Execute swap
            let (token_0_swapped_amount, token_1_swapped_amount) = swap_test_case(
                yas_router,
                yas_pool,
                token_0,
                token_1,
                *swap_case.zero_for_one,
                amount_to_swap,
                *swap_case.sqrt_price_limit
            );

            // Save values after swap to get deltas
            let (fee_growth_global_0_X128_af, fee_growth_global_1_X128_af) = yas_pool
                .get_fee_growth_globals();

            let user_token_0_balance_af = token_0.balanceOf(WALLET());
            let user_token_1_balance_af = token_1.balanceOf(WALLET());
            let (fee_growth_global_0_X128_af, fee_growth_global_1_X128_af) = yas_pool
                .get_fee_growth_globals();
            let (fee_growth_global_0_X128_delta, fee_growth_global_1_X128_delta) = (
                fee_growth_global_0_X128_af - fee_growth_global_0_X128_bf,
                fee_growth_global_1_X128_af - fee_growth_global_1_X128_bf
            );
            let slot0_af = yas_pool.get_slot_0();

            // Generate swap result values to compare with expected values
            let (fee_growth_global_0_X128_delta, fee_growth_global_1_X128_delta) = (
                fee_growth_global_0_X128_af - fee_growth_global_0_X128_bf,
                fee_growth_global_1_X128_af - fee_growth_global_1_X128_bf
            );
            let execution_price = calculate_execution_price(
                token_0_swapped_amount, token_1_swapped_amount
            );

            let pool_balance_0_af = token_0.balanceOf(yas_pool.contract_address);
            let pool_balance_1_af = token_1.balanceOf(yas_pool.contract_address);

            let pool_price_bf = slot0_bf.sqrt_price_X96.mag;
            let pool_price_af = slot0_af.sqrt_price_X96.mag;

            let tick_bf = slot0_bf.tick;
            let tick_af = slot0_af.tick;

            let actual = SwapExpectedResults {
                amount_0_before: pool_balance_0_bf,
                amount_0_delta: IntegerTrait::<i256>::new(pool_balance_0_af, false)
                    - IntegerTrait::<i256>::new(pool_balance_0_bf, false),
                amount_1_before: pool_balance_1_bf,
                amount_1_delta: IntegerTrait::<i256>::new(pool_balance_1_af, false)
                    - IntegerTrait::<i256>::new(pool_balance_1_bf, false),
                execution_price: execution_price,
                fee_growth_global_0_X128_delta: fee_growth_global_0_X128_delta,
                fee_growth_global_1_X128_delta: fee_growth_global_1_X128_delta,
                pool_price_after: pool_price_af,
                pool_price_before: pool_price_bf,
                tick_after: tick_af,
                tick_before: tick_bf,
            };

            assert_swap_result_equals(actual, expected, precision_required);
            i += 1;
        };
    }

    fn assert_swap_result_equals(
        actual: SwapExpectedResults, expected: @SwapExpectedResults, precision: u256
    ) {
        assert(actual.amount_0_before == *expected.amount_0_before, 'wrong amount_0_before');
        assert(actual.amount_0_delta == *expected.amount_0_delta, 'wrong amount_0_delta');
        assert(actual.amount_1_before == *expected.amount_1_before, 'wrong amount_1_before');
        assert(actual.amount_1_delta == *expected.amount_1_delta, 'wrong amount_1_delta');

        // 10 significant_figures in x96 is way more accurate than uniswap precision
        let SIGNIFICANT_FIGURES = 10;
        assert(
            get_significant_figures(
                actual.execution_price, SIGNIFICANT_FIGURES
            ) == get_significant_figures(*expected.execution_price, SIGNIFICANT_FIGURES),
            'wrong execution_price'
        );

        assert(
            actual.fee_growth_global_0_X128_delta == *expected.fee_growth_global_0_X128_delta,
            'wrong fee_growth_global_0_X128'
        );
        assert(
            actual.fee_growth_global_1_X128_delta == *expected.fee_growth_global_1_X128_delta,
            'wrong fee_growth_global_1_X128'
        );
        assert(actual.pool_price_before == *expected.pool_price_before, 'wrong pool_price_before');
        // Significant figures comparison here to accept same degree of error as uniswap
        assert(
            get_significant_figures(
                actual.pool_price_after, precision
            ) == get_significant_figures(*expected.pool_price_after, precision),
            'wrong pool_price_after'
        );

        assert(actual.tick_after == *expected.tick_after, 'wrong tick_after');
        assert(actual.tick_before == *expected.tick_before, 'wrong tick_before');
    }

    fn calculate_execution_price(
        token_0_swapped_amount: u256, token_1_swapped_amount: u256
    ) -> u256 {
        if token_0_swapped_amount == 0
            && token_1_swapped_amount == 0 { //this avoids 0/0 , if no tokens swapped: exec_price = 0
            'NaN'.into()
        } else if token_0_swapped_amount == 0 { //this avoids x/0 , case that makes price tend to Infinity
            // Since uniswap divides deltas to calculate exec_price, all prices are multiplied by -1 so that all prices are > 0.
            // Therefore, this value ends up as -Infinity
            '-Infinity'.into()
        } else { //this is every other case, price = 0/x = 0, or price = x/y = z
            (token_1_swapped_amount * pow(2, 96)) / token_0_swapped_amount
        }
    }

    fn get_significant_figures(number: u256, sig_figures: u256) -> u256 {
        let order = get_order_of_magnitude(number);
        let mut my_number = number;
        if sig_figures >= order {
            number
        } else {
            let rounder = pow(10, order - sig_figures);
            let mid_point = (rounder / 2) - 1;
            let round_decider = number % rounder;
            if round_decider > mid_point {
                number + (rounder - round_decider)
            } else {
                number - round_decider
            }
        }
    }

    fn get_order_of_magnitude(number: u256) -> u256 {
        let mut order = 0;
        let mut my_number = number;
        loop {
            if my_number >= 1 {
                my_number = my_number / 10;
                order = order + 1;
            } else {
                break;
            };
        };
        order
    }

    fn swap_test_case(
        yas_router: IYASRouterDispatcher,
        yas_pool: IYASPoolDispatcher,
        token_0: IERC20Dispatcher,
        token_1: IERC20Dispatcher,
        zero_for_one: bool,
        amount_specified: i256,
        sqrt_price_limit: FixedType
    ) -> (u256, u256) {
        let NEGATIVE = true;
        let POSITIVE = false;
        let sqrt_price_limit_usable = if !sqrt_price_limit.is_zero() {
            sqrt_price_limit
        } else {
            if zero_for_one {
                FP64x96Impl::new(MIN_SQRT_RATIO + 1, POSITIVE)
            } else {
                FP64x96Impl::new(MAX_SQRT_RATIO - 1, POSITIVE)
            }
        };

        let user_token_0_balance_bf = token_0.balanceOf(WALLET());
        let user_token_1_balance_bf = token_1.balanceOf(WALLET());

        yas_router
            .swap(
                yas_pool.contract_address,
                WALLET(),
                zero_for_one,
                amount_specified,
                sqrt_price_limit_usable
            );

        let user_token_0_balance_af = token_0.balanceOf(WALLET());
        let user_token_1_balance_af = token_1.balanceOf(WALLET());

        let (token_0_swapped_amount, token_1_swapped_amount) = if zero_for_one {
            (
                user_token_0_balance_bf - user_token_0_balance_af,
                user_token_1_balance_af - user_token_1_balance_bf
            )
        } else {
            (
                user_token_0_balance_af - user_token_0_balance_bf,
                user_token_1_balance_bf - user_token_1_balance_af
            )
        };

        (token_0_swapped_amount, token_1_swapped_amount)
    }

    fn setup_pool_for_swap_test(
        initial_price: FixedType, fee_amount: u32, mint_positions: @Array<SwapTestHelper::Position>,
    ) -> (IYASPoolDispatcher, IYASRouterDispatcher, IERC20Dispatcher, IERC20Dispatcher) {
        let yas_router = deploy_yas_router(); // 0x1
        let yas_factory = deploy_yas_factory(OWNER(), POOL_CLASS_HASH()); // 0x2

        // Deploy ERC20 tokens with factory address
        // in testnet TOKEN0 is USDC and TOKEN1 is ETH
        let token_0 = deploy_yas_erc20('USDC', 'USDC', BoundedInt::max(), OWNER()); // 0x3
        let token_1 = deploy_yas_erc20('ETH', 'ETH', BoundedInt::max(), OWNER()); // 0x4

        set_contract_address(OWNER());
        token_0.transfer(WALLET(), BoundedInt::max());
        token_1.transfer(WALLET(), BoundedInt::max());

        // Give permissions to expend WALLET() tokens
        set_contract_address(WALLET());
        token_1.approve(yas_router.contract_address, BoundedInt::max());
        token_0.approve(yas_router.contract_address, BoundedInt::max());

        let yas_pool_address = yas_factory // 0x5
            .create_pool(token_0.contract_address, token_1.contract_address, fee_amount);
        let yas_pool = IYASPoolDispatcher { contract_address: yas_pool_address };

        set_contract_address(OWNER());
        yas_pool.initialize(initial_price);

        set_contract_address(WALLET());

        mint_positions(yas_router, yas_pool_address, mint_positions);

        (yas_pool, yas_router, token_0, token_1)
    }

    fn mint_positions(
        yas_router: IYASRouterDispatcher,
        yas_pool_address: ContractAddress,
        mint_positions: @Array<SwapTestHelper::Position>
    ) {
        let mut i = 0;
        loop {
            if i == mint_positions.len() {
                break;
            }
            let position = *mint_positions[i];
            yas_router
                .mint(
                    yas_pool_address,
                    WALLET(),
                    position.tick_lower,
                    position.tick_upper,
                    position.liquidity
                );
            i += 1;
        };
    }
}

mod ContractDeployerHelper {
    use yas_core::contracts::yas_erc20::{ERC20, IERC20Dispatcher, IERC20DispatcherTrait};
    use yas_core::contracts::yas_factory::{
        YASFactory, IYASFactoryDispatcher, IYASFactoryDispatcherTrait
    };
    use yas_core::contracts::yas_pool::{YASPool, IYASPoolDispatcher, IYASPoolDispatcherTrait};
    use yas_core::contracts::yas_router::{
        YASRouter, IYASRouterDispatcher, IYASRouterDispatcherTrait
    };

    use starknet::{ContractAddress, ClassHash, SyscallResultTrait};
    use starknet::syscalls::deploy_syscall;

    fn deploy_yas_erc20(
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

    fn deploy_yas_router() -> IYASRouterDispatcher {
        let (address, _) = deploy_syscall(
            YASRouter::TEST_CLASS_HASH.try_into().unwrap(), 0, array![].span(), true
        )
            .unwrap_syscall();

        return IYASRouterDispatcher { contract_address: address };
    }

    fn deploy_yas_factory(
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
}
