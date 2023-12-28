use yas_core::numbers::signed_integer::{
    i32::i32, i32::i32_div_no_round, i256::i256, integer_trait::IntegerTrait
};
use yas_core::tests::utils::swap_cases::SwapTestHelper::{
    SwapExpectedResults, SwapTestCase, PoolTestCase, obtain_swap_cases, POOL_CASES
};

fn SWAP_CASES_POOL_14() -> (Array<SwapTestCase>, Array<SwapTestCase>) {
    obtain_swap_cases(array![0, 2, 4, 6, 8, 10, 13, 14])
}

fn SWAP_EXPECTED_RESULTS_POOL_14() -> Array<SwapExpectedResults> {
    array![
        SwapExpectedResults {
            amount_0_before: 36796311322104302062438284732106019258,
            amount_0_delta: IntegerTrait::<i256>::new(36796311322104302058426248623781044040, true),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            execution_price: 2153155022,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 510423550381413820277666488039994629,
            pool_price_after: 39495239013360769732380381856,
            pool_price_before: 4295128739,
            tick_after: IntegerTrait::<i32>::new(13924, true),
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
            amount_0_delta: IntegerTrait::<i256>::new(36796311322104302058426248623781044040, true),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            execution_price: 2153155022,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 510423550381413820277666488039994629,
            pool_price_after: 39495239013360769732380381856,
            pool_price_before: 4295128739,
            tick_after: IntegerTrait::<i32>::new(13924, true),
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
            amount_0_delta: IntegerTrait::<i256>::new(36792226666449146913445651103694411508, true),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(1000, false),
            execution_price: 0,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 2381976568446569244235,
            pool_price_after: 38793068108090,
            pool_price_before: 4295128739,
            tick_after: IntegerTrait::<i32>::new(705093, true),
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
        },
        SwapExpectedResults {
            amount_0_before: 36796311322104302062438284732106019258,
            amount_0_delta: IntegerTrait::<i256>::new(36796311322104302061173373668038667492, true),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(3171793039286238112, false),
            execution_price: 6829362111,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 1618957864187523634078592530170978294,
            pool_price_after: 125270724187523965593206900784,
            pool_price_before: 4295128739,
            tick_after: IntegerTrait::<i32>::new(9163, false),
            tick_before: IntegerTrait::<i32>::new(887272, true),
        },
        SwapExpectedResults {
            amount_0_before: 36796311322104302062438284732106019258,
            amount_0_delta: IntegerTrait::<i256>::new(36796311322104302059276007071937639893, true),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(1268717215714495283, false),
            execution_price: 2731744844,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 647583145675012958539816297734564973,
            pool_price_after: 50108289675009586237282760313,
            pool_price_before: 4295128739,
            tick_after: IntegerTrait::<i32>::new(9164, true),
            tick_before: IntegerTrait::<i32>::new(887272, true),
        }
    ]
}
