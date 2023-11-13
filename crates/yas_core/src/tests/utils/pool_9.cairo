use yas_core::numbers::signed_integer::{
    i32::i32, i32::i32_div_no_round, i256::i256, integer_trait::IntegerTrait
};
use yas_core::tests::utils::swap_cases::SwapTestHelper::{
    SwapExpectedResults, SwapTestCase, PoolTestCase, obtain_swap_cases, POOL_CASES
};

fn SWAP_CASES_POOL_9() -> (Array<SwapTestCase>, Array<SwapTestCase>) {
    obtain_swap_cases(array![])
}

fn SWAP_EXPECTED_RESULTS_POOL_9() -> Array<SwapExpectedResults> {
    array![
        // SwapExpectedResults { //OK
        //     amount_0_before: 0,
        //     amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
        //     amount_1_before: 1995041008271423675,
        //     amount_1_delta: IntegerTrait::<i256>::new(665331998665331998, true),
        //     execution_price: 66533,
        //     fee_growth_global_0_X128_delta: 510423550381407695195061911147652317,
        //     fee_growth_global_1_X128_delta: 0,
        //     pool_price_after: 44533,
        //     pool_price_before: 100000,
        //     tick_after: IntegerTrait::<i32>::new(8090, true),
        //     tick_before: IntegerTrait::<i32>::new(0, false),
        // },
		SwapExpectedResults {
			amount_0_before: 0,
			amount_0_delta: IntegerTrait::<i256>::new(0, false),
			amount_1_before: 1995041008271423675,
			amount_1_delta: IntegerTrait::<i256>::new(0, false),
			execution_price: 0,
			fee_growth_global_0_X128_delta: 0,
			fee_growth_global_1_X128_delta: 0,
			pool_price_after: 34026000000000000946377896149546450548686848,
			pool_price_before: 100000,
			tick_after: IntegerTrait::<i32>::new(887271, false),
			tick_before: IntegerTrait::<i32>::new(0, false),
		},
    ]
}
