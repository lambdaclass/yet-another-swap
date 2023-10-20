use yas::contracts::yas_erc20::{ERC20, IERC20Dispatcher, IERC20DispatcherTrait};
use yas::contracts::yas_factory::{YASFactory, IYASFactoryDispatcher, IYASFactoryDispatcherTrait};
use yas::contracts::yas_pool::{YASPool, IYASPoolDispatcher, IYASPoolDispatcherTrait};
use yas::contracts::yas_router::{YASRouter, IYASRouterDispatcher, IYASRouterDispatcherTrait};

use yas::numbers::signed_integer::{i32::i32, i256::i256, integer_trait::IntegerTrait};
use yas::numbers::fixed_point::implementations::impl_64x96::{
    FP64x96Impl, FP64x96Sub, FP64x96PartialEq, FixedType, FixedTrait
};

use starknet::{ContractAddress, contract_address_const};

struct SwapBuilder {
    user: ContractAddress,
    yas_pool: IYASPoolDispatcher,
    yas_router: IYASRouterDispatcher,
    token_0: IERC20Dispatcher,
    token_1: IERC20Dispatcher,
    initial_price: u256,
    mint_tick_lower: i32,
    mint_tick_upper: i32,
    mint_amount: u128,
    swap_amount: u256,
    zero_for_one: bool,
    price_limit: u256,
}

trait SwapBuilderTrait {
    fn new(
        yas_pool: IYASPoolDispatcher,
        yas_router: IYASRouterDispatcher,
        token_0: IERC20Dispatcher,
        token_1: IERC20Dispatcher
    ) -> SwapBuilder;
    fn initial_price(ref self: SwapBuilder, sqrt_price_X96: u256) -> SwapBuilder;
    fn user(ref self: SwapBuilder, user: ContractAddress) -> SwapBuilder;
    fn mint(
        ref self: SwapBuilder, lower_tick: i32, upper_tick: i32, liquidity: u128
    ) -> SwapBuilder;
    fn swap(ref self: SwapBuilder, amount: u256, zero_for_one: bool) -> SwapBuilder;
// fn price_limit(ref self: SwapBuilder, sqrt_price_limit_X96: u256) -> SwapBuilder;
// fn execute();
}

impl SwapBuilderImpl of SwapBuilderTrait {
    fn new(
        yas_pool: IYASPoolDispatcher,
        yas_router: IYASRouterDispatcher,
        token_0: IERC20Dispatcher,
        token_1: IERC20Dispatcher
    ) -> SwapBuilder {
        SwapBuilder {
            user: contract_address_const::<0>(),
            yas_pool,
            yas_router,
            token_0,
            token_1,
            initial_price: Zeroable::zero(),
            mint_tick_lower: Zeroable::zero(),
            mint_tick_upper: Zeroable::zero(),
            mint_amount: Zeroable::zero(),
            swap_amount: Zeroable::zero(),
            zero_for_one: false,
            price_limit: Zeroable::zero()
        }
    }

    fn initial_price(ref self: SwapBuilder, sqrt_price_X96: u256) -> SwapBuilder {
        SwapBuilder {
            user: self.user,
            yas_pool: self.yas_pool,
            yas_router: self.yas_router,
            token_0: self.token_0,
            token_1: self.token_1,
            initial_price: sqrt_price_X96,
            mint_tick_lower: self.mint_tick_lower,
            mint_tick_upper: self.mint_tick_upper,
            mint_amount: self.mint_amount,
            swap_amount: self.swap_amount,
            zero_for_one: self.zero_for_one,
            price_limit: self.price_limit
        }
    }

    fn user(ref self: SwapBuilder, user: ContractAddress) -> SwapBuilder {
        SwapBuilder {
            user,
            yas_pool: self.yas_pool,
            yas_router: self.yas_router,
            token_0: self.token_0,
            token_1: self.token_1,
            initial_price: self.initial_price,
            mint_tick_lower: self.mint_tick_lower,
            mint_tick_upper: self.mint_tick_upper,
            mint_amount: self.mint_amount,
            swap_amount: self.swap_amount,
            zero_for_one: self.zero_for_one,
            price_limit: self.price_limit
        }
    }

    fn mint(
        ref self: SwapBuilder, lower_tick: i32, upper_tick: i32, liquidity: u128
    ) -> SwapBuilder {
        // self.yas_router.mint(self.yas_pool.contract_address, self.user, lower_tick, upper_tick, liquidity)

        SwapBuilder {
            user: self.user,
            yas_pool: self.yas_pool,
            yas_router: self.yas_router,
            token_0: self.token_0,
            token_1: self.token_1,
            initial_price: self.initial_price,
            mint_tick_lower: lower_tick,
            mint_tick_upper: upper_tick,
            mint_amount: liquidity,
            swap_amount: self.swap_amount,
            zero_for_one: self.zero_for_one,
            price_limit: self.price_limit
        }
    }

    fn swap(ref self: SwapBuilder, amount: u256, zero_for_one: bool) -> SwapBuilder {
        let price_limit = if self.price_limit.is_zero() {
            if zero_for_one {
                self.initial_price / 1000
            } else {
                self.initial_price * 1000
            }
        } else {
            self.price_limit
        };

        // self.yas_router.swap(self.yas_pool.contract_address, self.user, zero_for_one, amount_specified: IntegerTrait::<i256>::new(amount, false), sqrt_price_limit_X96: FP64x96Impl::new(price_limit, false));
        SwapBuilder {
            user: self.user,
            yas_pool: self.yas_pool,
            yas_router: self.yas_router,
            token_0: self.token_0,
            token_1: self.token_1,
            initial_price: self.initial_price,
            mint_tick_lower: self.mint_tick_lower,
            mint_tick_upper: self.mint_tick_upper,
            mint_amount: self.mint_amount,
            swap_amount: amount,
            zero_for_one: self.zero_for_one,
            price_limit: self.price_limit
        }
    }
}
