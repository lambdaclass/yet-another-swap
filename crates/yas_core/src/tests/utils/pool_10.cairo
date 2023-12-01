use yas_core::numbers::signed_integer::{
    i32::i32, i32::i32_div_no_round, i256::i256, integer_trait::IntegerTrait
};
use yas_core::tests::utils::swap_cases::SwapTestHelper::{
    SwapExpectedResults, SwapTestCase, PoolTestCase, obtain_swap_cases, POOL_CASES
};

fn SWAP_CASES_POOL_10() -> (Array<SwapTestCase>, Array<SwapTestCase>) {
    obtain_swap_cases(array![5, 7, 12, 15])
}

fn SWAP_EXPECTED_RESULTS_POOL_10() -> Array<SwapExpectedResults> {
    array![
        
    ]
}
