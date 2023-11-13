use yas_core::numbers::signed_integer::{
    i32::i32, i32::i32_div_no_round, i256::i256, integer_trait::IntegerTrait
};
use yas_core::tests::utils::swap_cases::SwapTestHelper::{
    SwapExpectedResults, SwapTestCase, PoolTestCase, obtain_swap_cases, POOL_CASES
};

fn SWAP_CASES_POOL_8() -> (Array<SwapTestCase>, Array<SwapTestCase>) {
    obtain_swap_cases(array![14,15]) //list should_panic cases indexes
}

fn SWAP_EXPECTED_RESULTS_POOL_8() -> Array<SwapExpectedResults> {
    array![
        // SwapExpectedResults { //OK. Wait, no swap but pool_price change?
		// 	amount_0_before: 1995041008271423675,
		// 	amount_0_delta: IntegerTrait::<i256>::new(0, false),
		// 	amount_1_before: 0,
		// 	amount_1_delta: IntegerTrait::<i256>::new(0, false),
		// 	execution_price: 0,
		// 	fee_growth_global_0_X128_delta: 0,
		// 	fee_growth_global_1_X128_delta: 0,
		// 	pool_price_after: 0,
		// 	pool_price_before: 100000,
		// 	tick_after: IntegerTrait::<i32>::new(887272, true),
		// 	tick_before: IntegerTrait::<i32>::new(0, false),
		// },
		// SwapExpectedResults { //OK
		// 	amount_0_before: 1995041008271423675,
		// 	amount_0_delta: IntegerTrait::<i256>::new(665331998665331998, true),
		// 	amount_1_before: 0,
		// 	amount_1_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
		// 	execution_price: 150300,
		// 	fee_growth_global_0_X128_delta: 0,
		// 	fee_growth_global_1_X128_delta: 510423550381407695195061911147652317,
		// 	pool_price_after: 224550,
		// 	pool_price_before: 100000,
		// 	tick_after: IntegerTrait::<i32>::new(8089, false),
		// 	tick_before: IntegerTrait::<i32>::new(0, false),
		// },
		SwapExpectedResults { //again no swap but pool price change.
			amount_0_before: 1995041008271423675,
			amount_0_delta: IntegerTrait::<i256>::new(0, false),
			amount_1_before: 0,
			amount_1_delta: IntegerTrait::<i256>::new(0, false),
			execution_price: 0,
			fee_growth_global_0_X128_delta: 0,
			fee_growth_global_1_X128_delta: 0,
			pool_price_after: 0,
			pool_price_before: 100000,
			tick_after: IntegerTrait::<i32>::new(887272, true),
			tick_before: IntegerTrait::<i32>::new(0, false),
		},
    ]
}
