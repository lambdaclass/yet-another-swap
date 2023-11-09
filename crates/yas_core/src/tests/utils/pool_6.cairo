use yas_core::numbers::signed_integer::{
    i32::i32, i32::i32_div_no_round, i256::i256, integer_trait::IntegerTrait
};
use yas_core::tests::utils::swap_cases::SwapTestHelper::{
    SwapExpectedResults, SwapTestCase, PoolTestCase, obtain_swap_cases, POOL_CASES
};

fn SWAP_CASES_POOL_6() -> (Array<SwapTestCase>, Array<SwapTestCase>) {
    obtain_swap_cases(array![]) //list succes cases indexes
}

fn SWAP_EXPECTED_RESULTS_POOL_6() -> Array<SwapExpectedResults> { //get pool-0 expected
    array![
    
    ]
}
