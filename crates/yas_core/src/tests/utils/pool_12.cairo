use yas_core::numbers::signed_integer::{
    i32::i32, i32::i32_div_no_round, i256::i256, integer_trait::IntegerTrait
};
use yas_core::tests::utils::swap_cases::SwapTestHelper::{
    SwapExpectedResults, SwapTestCase, PoolTestCase, obtain_swap_cases, POOL_CASES
};

fn SWAP_CASES_POOL_12() -> (Array<SwapTestCase>, Array<SwapTestCase>) {
    obtain_swap_cases(array![14, 15])
}

fn SWAP_EXPECTED_RESULTS_POOL_12() -> Array<SwapExpectedResults> {
    array![
        SwapExpectedResults {
            amount_0_before: 11505743598341114571255423385623647,
            amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            amount_1_before: 11505743598341114571255423385506404,
            amount_1_delta: IntegerTrait::<i256>::new(996999999999999318, true),
            execution_price: 78990478026721490547156483756,
            fee_growth_global_0_X128_delta: 88725000000017597125,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 79228162514264330728235563131,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(1, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 11505743598341114571255423385623647,
            amount_0_delta: IntegerTrait::<i256>::new(996999999999999232, true),
            amount_1_before: 11505743598341114571255423385506404,
            amount_1_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            execution_price: 79466562200866999620957205638,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 88725000000020140575,
            pool_price_after: 79228162514264344458852337541,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(0, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 11505743598341114571255423385623647,
            amount_0_delta: IntegerTrait::<i256>::new(1003009027081361181, false),
            amount_1_before: 11505743598341114571255423385506404,
            amount_1_delta: IntegerTrait::<
                i256
            >::new(1000000000000117009, true), // TODO: 1000000000000000000
            execution_price: 78990478026712294997025922178,
            fee_growth_global_0_X128_delta: 88991975927793784300,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 79228162514264330707577664272,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(1, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 11505743598341114571255423385623647,
            amount_0_delta: IntegerTrait::<
                i256
            >::new(1000000000000116922, true), // TODO: 1000000000000000000
            amount_1_before: 11505743598341114571255423385506404,
            amount_1_delta: IntegerTrait::<i256>::new(1003009027081361094, false),
            execution_price: 79466562200876236848270376220,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 88991975927793784300,
            pool_price_after: 79228162514264344479510236400,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(0, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 11505743598341114571255423385623647,
            amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            amount_1_before: 11505743598341114571255423385506404,
            amount_1_delta: IntegerTrait::<i256>::new(996999999999999318, true),
            execution_price: 78990478026721490547156483756,
            fee_growth_global_0_X128_delta: 88725000000017597125,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 79228162514264330728235563131,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(1, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 11505743598341114571255423385623647,
            amount_0_delta: IntegerTrait::<i256>::new(996999999999999232, true),
            amount_1_before: 11505743598341114571255423385506404,
            amount_1_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            execution_price: 79466562200866999620957205638,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 88725000000020140575,
            pool_price_after: 79228162514264344458852337541,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(0, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 11505743598341114571255423385623647,
            amount_0_delta: IntegerTrait::<i256>::new(1003009027081361181, false),
            amount_1_before: 11505743598341114571255423385506404,
            amount_1_delta: IntegerTrait::<
                i256
            >::new(1000000000000117009, true), // TODO: 1000000000000000000
            execution_price: 78990478026712294997025922178,
            fee_growth_global_0_X128_delta: 88991975927793784300,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 79228162514264330707577664272,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(1, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 11505743598341114571255423385623647,
            amount_0_delta: IntegerTrait::<
                i256
            >::new(1000000000000116922, true), // TODO: 1000000000000000000
            amount_1_before: 11505743598341114571255423385506404,
            amount_1_delta: IntegerTrait::<i256>::new(1003009027081361094, false),
            execution_price: 79466562200876236848270376220,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 88991975927793784300,
            pool_price_after: 79228162514264344479510236400,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(0, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 11505743598341114571255423385623647,
            amount_0_delta: IntegerTrait::<i256>::new(1000, false),
            amount_1_before: 11505743598341114571255423385506404,
            amount_1_delta: IntegerTrait::<i256>::new(0, false),
            execution_price: 0,
            fee_growth_global_0_X128_delta: 29575000,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 79228162514264337593543950336,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(1, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        // TODO: replace case -Infinity
        SwapExpectedResults {
            amount_0_before: 11505743598341114571255423385623647,
            amount_0_delta: IntegerTrait::<i256>::new(1000, false),
            amount_1_before: 11505743598341114571255423385506404,
            amount_1_delta: IntegerTrait::<i256>::new(0, false),
            execution_price: 0,
            fee_growth_global_0_X128_delta: 29575000,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 79228162514264337593543950336,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(1, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 11505743598341114571255423385623647,
            amount_0_delta: IntegerTrait::<i256>::new(145660, false),
            amount_1_before: 11505743598341114571255423385506404,
            amount_1_delta: IntegerTrait::<i256>::new(1000, true),
            execution_price: 543925322767158709279772289,
            fee_growth_global_0_X128_delta: 12924275,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 79228162514264337593543950335,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(1, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 11505743598341114571255423385623647,
            amount_0_delta: IntegerTrait::<i256>::new(1000, true),
            amount_1_before: 11505743598341114571255423385506404,
            amount_1_delta: IntegerTrait::<i256>::new(145660, false),
            execution_price: 11540374151827743413875611805941,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 12924275,
            pool_price_after: 79228162514264337593543950337,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(0, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 11505743598341114571255423385623647,
            amount_0_delta: IntegerTrait::<i256>::new(4228872409409224753601131224936259, true),
            amount_1_before: 11505743598341114571255423385506404,
            amount_1_delta: IntegerTrait::<i256>::new(6706554036096900675845906992220230, false),
            execution_price: 125647667189091239313623908319,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 595039006852697512464428097884749099,
            pool_price_after: 125270724187523965593206900784,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(9163, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 11505743598341114571255423385623647,
            amount_0_delta: IntegerTrait::<i256>::new(6706554036096900675845906992672697, false),
            amount_1_before: 11505743598341114571255423385506404,
            amount_1_delta: IntegerTrait::<i256>::new(4228872409409224753601131225116702, true),
            execution_price: 49957964805984557478525009393,
            fee_growth_global_0_X128_delta: 595039006852697512464428097924911949,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 50108289675009586237282760313,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(9164, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
    ]
}
