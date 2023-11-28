use yas_core::numbers::signed_integer::{
    i32::i32, i32::i32_div_no_round, i256::i256, integer_trait::IntegerTrait
};
use yas_core::tests::utils::swap_cases::SwapTestHelper::{
    SwapExpectedResults, SwapTestCase, PoolTestCase, obtain_swap_cases, POOL_CASES
};

fn SWAP_CASES_POOL_14() -> (Array<SwapTestCase>, Array<SwapTestCase>) {
    obtain_swap_cases(array![0, 1, 3, 4, 6, 7, 9, 10])
}

fn SWAP_EXPECTED_RESULTS_POOL_14() -> Array<SwapExpectedResults> {
    array![
        SwapExpectedResults {
            amount_0_before: 36796311322104302062438284732106019258,
            amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, true),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(2, false),
            execution_price: 158456325028,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 170141183460469231731,
            pool_price_after: 4306310045,
            pool_price_before: 4295128739,
            tick_after: IntegerTrait::<i32>::new(887220, true),
            tick_before: IntegerTrait::<i32>::new(887272, true),
        },
        SwapExpectedResults {
            amount_0_before: 36796311322104302062438284732106019258,
            amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, true),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(2, false),
            execution_price: 158456325028,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 170141183460469231731,
            pool_price_after: 4306310045,
            pool_price_before: 4295128739,
            tick_after: IntegerTrait::<i32>::new(887220, true),
            tick_before: IntegerTrait::<i32>::new(887272, true),
        },
        SwapExpectedResults {
            amount_0_before: 36796311322104302062438284732106019258,
            amount_0_delta: IntegerTrait::<i256>::new(1000, true),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(2, false),
            execution_price: 158456325028528675187087900,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 170141183460469231731,
            pool_price_after: 4306310045,
            pool_price_before: 4295128739,
            tick_after: IntegerTrait::<i32>::new(887220, true),
            tick_before: IntegerTrait::<i32>::new(887272, true),
        }
    ]
}
