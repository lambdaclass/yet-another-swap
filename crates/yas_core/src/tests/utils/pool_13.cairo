use yas_core::numbers::signed_integer::{
    i32::i32, i32::i32_div_no_round, i256::i256, integer_trait::IntegerTrait
};
use yas_core::tests::utils::swap_cases::SwapTestHelper::{
    SwapExpectedResults, SwapTestCase, PoolTestCase, obtain_swap_cases, POOL_CASES
};

fn SWAP_CASES_POOL_13() -> (Array<SwapTestCase>, Array<SwapTestCase>) {
    obtain_swap_cases(array![1, 3, 4, 7, 9, 11, 12, 15])
}

fn SWAP_EXPECTED_RESULTS_POOL_13() -> Array<SwapExpectedResults> {
    array![
        SwapExpectedResults {
            amount_0_before: 0,
            amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            amount_1_before: 36796311329002736532545403775337522448,
            amount_1_delta: IntegerTrait::<i256>::new(36796311329002736528533367667012547243, true),
            execution_price: 2915304133899694779658338854281460679776869023744,
            fee_growth_global_0_X128_delta: 510423550381413479995299567101531162,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 158933124401733886835376621103,
            pool_price_before: 1461446703485210103287273052203988822378723970341,
            tick_after: IntegerTrait::<i32>::new(13923, false),
            tick_before: IntegerTrait::<i32>::new(887271, false),
        },
        SwapExpectedResults {
            amount_0_before: 0,
            amount_0_delta: IntegerTrait::<i256>::new(2, false),
            amount_1_before: 36796311329002736532545403775337522448,
            amount_1_delta: IntegerTrait::<i256>::new(1000000000000000000, true),
            execution_price: 39614081257132168796771975168000000000000000000,
            fee_growth_global_0_X128_delta: 170141183460469231731,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 1457652066949847389930003259129161949691061401300,
            pool_price_before: 1461446703485210103287273052203988822378723970341,
            tick_after: IntegerTrait::<i32>::new(887219, false),
            tick_before: IntegerTrait::<i32>::new(887271, false),
        },
        SwapExpectedResults {
            amount_0_before: 0,
            amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            amount_1_before: 36796311329002736532545403775337522448,
            amount_1_delta: IntegerTrait::<i256>::new(36796311329002736528533367667012547243, true),
            execution_price: 2915304133899694779658338854281460679776869023744,
            fee_growth_global_0_X128_delta: 510423550381413479995299567101531162,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 158933124401733886835376621103,
            pool_price_before: 1461446703485210103287273052203988822378723970341,
            tick_after: IntegerTrait::<i32>::new(13923, false),
            tick_before: IntegerTrait::<i32>::new(887271, false),
        },
        SwapExpectedResults {
            amount_0_before: 0,
            amount_0_delta: IntegerTrait::<i256>::new(2, false),
            amount_1_before: 36796311329002736532545403775337522448,
            amount_1_delta: IntegerTrait::<i256>::new(1000000000000000000, true),
            execution_price: 39614081257132168796771975168000000000000000000,
            fee_growth_global_0_X128_delta: 170141183460469231731,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 1457652066949847389930003259129161949691061401300,
            pool_price_before: 1461446703485210103287273052203988822378723970341,
            tick_after: IntegerTrait::<i32>::new(887219, false),
            tick_before: IntegerTrait::<i32>::new(887271, false),
        },
        SwapExpectedResults {
            amount_0_before: 0,
            amount_0_delta: IntegerTrait::<i256>::new(1000, false),
            amount_1_before: 36796311329002736532545403775337522448,
            amount_1_delta: IntegerTrait::<i256>::new(36792225529204286454178948640580261338, true),
            execution_price: 2914980423489262428640436941081331314651293548544000000000000000,
            fee_growth_global_0_X128_delta: 2381976568446569244235,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 161855205216175642309983856828649147738467364,
            pool_price_before: 1461446703485210103287273052203988822378723970341,
            tick_after: IntegerTrait::<i32>::new(705098, false),
            tick_before: IntegerTrait::<i32>::new(887271, false),
        },
        SwapExpectedResults {
            amount_0_before: 0,
            amount_0_delta: IntegerTrait::<i256>::new(2, false),
            amount_1_before: 36796311329002736532545403775337522448,
            amount_1_delta: IntegerTrait::<i256>::new(1000, true),
            execution_price: 39614081257132168796771975168000,
            fee_growth_global_0_X128_delta: 170141183460469231731,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 1457652066949847389969617340386294078873752119335,
            pool_price_before: 1461446703485210103287273052203988822378723970341,
            tick_after: IntegerTrait::<i32>::new(887219, false),
            tick_before: IntegerTrait::<i32>::new(887271, false),
        },
        SwapExpectedResults {
            amount_0_before: 0,
            amount_0_delta: IntegerTrait::<i256>::new(3171793039286238109, false),
            amount_1_before: 36796311329002736532545403775337522448,
            amount_1_delta: IntegerTrait::<i256>::new(36796311329002736531280492711270170687, true),
            execution_price: 919134413182184767242402077850106250594759999488,
            fee_growth_global_0_X128_delta: 1618957864187523123655042148763283097,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 50108289675009586237282760313,
            pool_price_before: 1461446703485210103287273052203988822378723970341,
            tick_after: IntegerTrait::<i32>::new(9164, true),
            tick_before: IntegerTrait::<i32>::new(887271, false),
        },
        SwapExpectedResults {
            amount_0_before: 0,
            amount_0_delta: IntegerTrait::<i256>::new(1268717215714495281, false),
            amount_1_before: 36796311329002736532545403775337522448,
            amount_1_delta: IntegerTrait::<i256>::new(36796311329002736529383126115169143088, true),
            execution_price: 2297836032955461850167855838643596140022962585600,
            fee_growth_global_0_X128_delta: 647583145675012618257449376796101507,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 125270724187523965593206900784,
            pool_price_before: 1461446703485210103287273052203988822378723970341,
            tick_after: IntegerTrait::<i32>::new(9163, false),
            tick_before: IntegerTrait::<i32>::new(887271, false),
        },
    ]
}
