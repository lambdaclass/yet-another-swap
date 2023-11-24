use yas_core::numbers::signed_integer::{
    i32::i32, i32::i32_div_no_round, i256::i256, integer_trait::IntegerTrait
};
use yas_core::tests::utils::swap_cases::SwapTestHelper::{
    SwapExpectedResults, SwapTestCase, PoolTestCase, obtain_swap_cases, POOL_CASES
};

fn SWAP_CASES_POOL_7() -> (Array<SwapTestCase>, Array<SwapTestCase>) {
    obtain_swap_cases(array![14,15]) //list should panic cases indexes
}

fn SWAP_EXPECTED_RESULTS_POOL_7() -> Array<SwapExpectedResults> {
    array![
		SwapExpectedResults {
			amount_0_before: 999700069986003,
			amount_0_delta: IntegerTrait::<i256>::new(1000700370186095, false),
			amount_1_before: 999700069986003,
			amount_1_delta: IntegerTrait::<i256>::new(999700069986002, true),
			execution_price: 79148966034301727736510650137,
			fee_growth_global_0_X128_delta: 85130172636557991529041720559172,
			fee_growth_global_1_X128_delta: 0,
			pool_price_after: 4295128740,
			pool_price_before: 79228162514264337593543950336,
			tick_after: IntegerTrait::<i32>::new(887272, true),
			tick_before: IntegerTrait::<i32>::new(0, false),
		},
		SwapExpectedResults {
			amount_0_before: 999700069986003,
			amount_0_delta: IntegerTrait::<i256>::new(999700069986002, true),
			amount_1_before: 999700069986003,
			amount_1_delta: IntegerTrait::<i256>::new(1000700370186095, false),
			execution_price: 79307438238249361462063265539,
			fee_growth_global_0_X128_delta: 0,
			fee_growth_global_1_X128_delta: 85130172636557991529041720559172,
			pool_price_after: 1461446703485210103287273052203988822378723970341,
			pool_price_before: 79228162514264337593543950336,
			tick_after: IntegerTrait::<i32>::new(887271, false),
			tick_before: IntegerTrait::<i32>::new(0, false),
		},
		SwapExpectedResults { //wrong pool_price_after. Not even close, gives: 79000000000000000000000000000
			amount_0_before: 999700069986003,
			amount_0_delta: IntegerTrait::<i256>::new(1000700370186095, false),
			amount_1_before: 999700069986003,
			amount_1_delta: IntegerTrait::<i256>::new(999700069986002, true),
			execution_price: 79148966034301727736510650137,
			fee_growth_global_0_X128_delta: 85130172636557991529041720559172,
			fee_growth_global_1_X128_delta: 0,
			pool_price_after: 4295128740,
			pool_price_before: 79228162514264337593543950336,
			tick_after: IntegerTrait::<i32>::new(887272, true),
			tick_before: IntegerTrait::<i32>::new(0, false),
		},
		SwapExpectedResults {
			amount_0_before: 999700069986003,
			amount_0_delta: IntegerTrait::<i256>::new(999700069986002, true),
			amount_1_before: 999700069986003,
			amount_1_delta: IntegerTrait::<i256>::new(1000700370186095, false),
			execution_price: 79307438238249361462063265539,
			fee_growth_global_0_X128_delta: 0,
			fee_growth_global_1_X128_delta: 85130172636557991529041720559172,
			pool_price_after: 1461446703485210103287273052203988822378723970341,
			pool_price_before: 79228162514264337593543950336,
			tick_after: IntegerTrait::<i32>::new(887271, false),
			tick_before: IntegerTrait::<i32>::new(0, false),
		},
		SwapExpectedResults {
			amount_0_before: 999700069986003,
			amount_0_delta: IntegerTrait::<i256>::new(1000700370186095, false),
			amount_1_before: 999700069986003,
			amount_1_delta: IntegerTrait::<i256>::new(999700069986002, true),
			execution_price: 79148966034301727736510650137,
			fee_growth_global_0_X128_delta: 85130172636557991529041720559172,
			fee_growth_global_1_X128_delta: 0,
			pool_price_after: 56022770974786139918731938227,
			pool_price_before: 79228162514264337593543950336,
			tick_after: IntegerTrait::<i32>::new(6932, true),
			tick_before: IntegerTrait::<i32>::new(0, false),
		},
		SwapExpectedResults {
			amount_0_before: 999700069986003,
			amount_0_delta: IntegerTrait::<i256>::new(999700069986002, true),
			amount_1_before: 999700069986003,
			amount_1_delta: IntegerTrait::<i256>::new(1000700370186095, false),
			execution_price: 79307438238249361462063265539,
			fee_growth_global_0_X128_delta: 0,
			fee_growth_global_1_X128_delta: 85130172636557991529041720559172,
			pool_price_after: 112045541949572279837463876454,
			pool_price_before: 79228162514264337593543950336,
			tick_after: IntegerTrait::<i32>::new(6931, false),
			tick_before: IntegerTrait::<i32>::new(0, false),
		},
		SwapExpectedResults {
			amount_0_before: 999700069986003,
			amount_0_delta: IntegerTrait::<i256>::new(1000700370186095, false),
			amount_1_before: 999700069986003,
			amount_1_delta: IntegerTrait::<i256>::new(999700069986002, true),
			execution_price: 79148966034301727736510650137,
			fee_growth_global_0_X128_delta: 85130172636557991529041720559172,
			fee_growth_global_1_X128_delta: 0,
			pool_price_after: 56022770974786139918731938227,
			pool_price_before: 79228162514264337593543950336,
			tick_after: IntegerTrait::<i32>::new(6932, true),
			tick_before: IntegerTrait::<i32>::new(0, false),
		},
		SwapExpectedResults {
			amount_0_before: 999700069986003,
			amount_0_delta: IntegerTrait::<i256>::new(999700069986002, true),
			amount_1_before: 999700069986003,
			amount_1_delta: IntegerTrait::<i256>::new(1000700370186095, false),
			execution_price: 79307438238249361462063265539,
			fee_growth_global_0_X128_delta: 0,
			fee_growth_global_1_X128_delta: 85130172636557991529041720559172,
			pool_price_after: 112045541949572279837463876454,
			pool_price_before: 79228162514264337593543950336,
			tick_after: IntegerTrait::<i32>::new(6931, false),
			tick_before: IntegerTrait::<i32>::new(0, false),
		},
		SwapExpectedResults {
			amount_0_before: 999700069986003,
			amount_0_delta: IntegerTrait::<i256>::new(1000, false),
			amount_1_before: 999700069986003,
			amount_1_delta: IntegerTrait::<i256>::new(998, true),
			execution_price: 79069706189235808918356862435,
			fee_growth_global_0_X128_delta: 170141183460469231731,
			fee_growth_global_1_X128_delta: 0,
			pool_price_after: 79228162514264298019076774461,
			pool_price_before: 79228162514264337593543950336,
			tick_after: IntegerTrait::<i32>::new(1, true),
			tick_before: IntegerTrait::<i32>::new(0, false),
		},
		SwapExpectedResults {
			amount_0_before: 999700069986003,
			amount_0_delta: IntegerTrait::<i256>::new(998, true),
			amount_1_before: 999700069986003,
			amount_1_delta: IntegerTrait::<i256>::new(1000, false),
			execution_price: 79386936387038414420150016185,
			fee_growth_global_0_X128_delta: 0,
			fee_growth_global_1_X128_delta: 170141183460469231731,
			pool_price_after: 79228162514264377168011126211,
			pool_price_before: 79228162514264337593543950336,
			tick_after: IntegerTrait::<i32>::new(0, false),
			tick_before: IntegerTrait::<i32>::new(0, false),
		},
		SwapExpectedResults {
			amount_0_before: 999700069986003,
			amount_0_delta: IntegerTrait::<i256>::new(1002, false),
			amount_1_before: 999700069986003,
			amount_1_delta: IntegerTrait::<i256>::new(1000, true),
			execution_price: 79070022469325686220923048591,
			fee_growth_global_0_X128_delta: 170141183460469231731,
			fee_growth_global_1_X128_delta: 0,
			pool_price_after: 79228162514264297979462693203,
			pool_price_before: 79228162514264337593543950336,
			tick_after: IntegerTrait::<i32>::new(1, true),
			tick_before: IntegerTrait::<i32>::new(0, false),
		},
		SwapExpectedResults {
			amount_0_before: 999700069986003,
			amount_0_delta: IntegerTrait::<i256>::new(1000, true),
			amount_1_before: 999700069986003,
			amount_1_delta: IntegerTrait::<i256>::new(1002, false),
			execution_price: 79386618839292866268731038236,
			fee_growth_global_0_X128_delta: 0,
			fee_growth_global_1_X128_delta: 170141183460469231731,
			pool_price_after: 79228162514264377207625207469,
			pool_price_before: 79228162514264337593543950336,
			tick_after: IntegerTrait::<i32>::new(0, false),
			tick_before: IntegerTrait::<i32>::new(0, false),
		},
		SwapExpectedResults {
			amount_0_before: 999700069986003,
			amount_0_delta: IntegerTrait::<i256>::new(999700069986002, true),
			amount_1_before: 999700069986003,
			amount_1_delta: IntegerTrait::<i256>::new(1000700370186095, false),
			execution_price: 79307438238249361462063265539,
			fee_growth_global_0_X128_delta: 0,
			fee_growth_global_1_X128_delta: 85130172636557991529041720559172,
			pool_price_after: 125270724187523965593206900784,
			pool_price_before: 79228162514264337593543950336,
			tick_after: IntegerTrait::<i32>::new(9163, false),
			tick_before: IntegerTrait::<i32>::new(0, false),
		},
		SwapExpectedResults {
			amount_0_before: 999700069986003,
			amount_0_delta: IntegerTrait::<i256>::new(1000700370186095, false),
			amount_1_before: 999700069986003,
			amount_1_delta: IntegerTrait::<i256>::new(999700069986002, true),
			execution_price: 79148966034301727736510650137,
			fee_growth_global_0_X128_delta: 85130172636557991529041720559172,
			fee_growth_global_1_X128_delta: 0,
			pool_price_after: 50108289675009586237282760313,
			pool_price_before: 79228162514264337593543950336,
			tick_after: IntegerTrait::<i32>::new(9164, true),
			tick_before: IntegerTrait::<i32>::new(0, false),
		},
        // SwapExpectedResults { //OK
		// 	amount_0_before: 999700069986003,
		// 	amount_0_delta: IntegerTrait::<i256>::new(1000700370186095, false),
		// 	amount_1_before: 999700069986003,
		// 	amount_1_delta: IntegerTrait::<i256>::new(999700069986002, true),
		// 	execution_price: 99900,
		// 	fee_growth_global_0_X128_delta: 85130172636557991529041720559172,
		// 	fee_growth_global_1_X128_delta: 0,
		// 	pool_price_after: 0,
		// 	pool_price_before: 100000,
		// 	tick_after: IntegerTrait::<i32>::new(887272, true),
		// 	tick_before: IntegerTrait::<i32>::new(0, false),
		// },
        // SwapExpectedResults { //u256 mul overflow
		// 	amount_0_before: 999700069986003,
		// 	amount_0_delta: IntegerTrait::<i256>::new(999700069986002, true),
		// 	amount_1_before: 999700069986003,
		// 	amount_1_delta: IntegerTrait::<i256>::new(1000700370186095, false),
		// 	execution_price: 100100,
		// 	fee_growth_global_0_X128_delta: 0,
		// 	fee_growth_global_1_X128_delta: 85130172636557991529041720559172,
		// 	pool_price_after: 34026000000000000946377896149546450548686848,
		// 	pool_price_before: 100000,
		// 	tick_after: IntegerTrait::<i32>::new(887271, false),
		// 	tick_before: IntegerTrait::<i32>::new(0, false),
		// },
		// SwapExpectedResults { //wrong pool_price after, should be 0.0000000000000000000000000000000000000029390
		// 	amount_0_before: 999700069986003,
		// 	amount_0_delta: IntegerTrait::<i256>::new(1000700370186095, false),
		// 	amount_1_before: 999700069986003,
		// 	amount_1_delta: IntegerTrait::<i256>::new(999700069986002, true),
		// 	execution_price: 99900,
		// 	fee_growth_global_0_X128_delta: 85130172636557991529041720559172,
		// 	fee_growth_global_1_X128_delta: 0,
		// 	pool_price_after: 0,
		// 	pool_price_before: 100000,
		// 	tick_after: IntegerTrait::<i32>::new(887272, true),
		// 	tick_before: IntegerTrait::<i32>::new(0, false),
		// },
		// SwapExpectedResults { //wrong tick_after and pool_price_after. Not even close
		// 	amount_0_before: 999700069986003,
		// 	amount_0_delta: IntegerTrait::<i256>::new(999700069986002, true),
		// 	amount_1_before: 999700069986003,
		// 	amount_1_delta: IntegerTrait::<i256>::new(1000700370186095, false),
		// 	execution_price: 100100,
		// 	fee_growth_global_0_X128_delta: 0,
		// 	fee_growth_global_1_X128_delta: 85130172636557991529041720559172,
		// 	pool_price_after: 34026000000000000946377896149546450548686848,
		// 	pool_price_before: 100000,
		// 	tick_after: IntegerTrait::<i32>::new(887271, false),
		// 	tick_before: IntegerTrait::<i32>::new(0, false),
		// },
		// SwapExpectedResults { //OK
		// 	amount_0_before: 999700069986003,
		// 	amount_0_delta: IntegerTrait::<i256>::new(1000700370186095, false),
		// 	amount_1_before: 999700069986003,
		// 	amount_1_delta: IntegerTrait::<i256>::new(999700069986002, true),
		// 	execution_price: 99900,
		// 	fee_growth_global_0_X128_delta: 85130172636557991529041720559172,
		// 	fee_growth_global_1_X128_delta: 0,
		// 	pool_price_after: 50000,
		// 	pool_price_before: 100000,
		// 	tick_after: IntegerTrait::<i32>::new(6932, true),
		// 	tick_before: IntegerTrait::<i32>::new(0, false),
		// },
		// SwapExpectedResults { //OK
		// 	amount_0_before: 999700069986003,
		// 	amount_0_delta: IntegerTrait::<i256>::new(999700069986002, true),
		// 	amount_1_before: 999700069986003,
		// 	amount_1_delta: IntegerTrait::<i256>::new(1000700370186095, false),
		// 	execution_price: 100100,
		// 	fee_growth_global_0_X128_delta: 0,
		// 	fee_growth_global_1_X128_delta: 85130172636557991529041720559172,
		// 	pool_price_after: 200000,
		// 	pool_price_before: 100000,
		// 	tick_after: IntegerTrait::<i32>::new(6931, false),
		// 	tick_before: IntegerTrait::<i32>::new(0, false),
		// },
		// SwapExpectedResults { //wrong tick_after and pool_price_after. Not even close
		// 	amount_0_before: 999700069986003,
		// 	amount_0_delta: IntegerTrait::<i256>::new(1000700370186095, false),
		// 	amount_1_before: 999700069986003,
		// 	amount_1_delta: IntegerTrait::<i256>::new(999700069986002, true),
		// 	execution_price: 99900,
		// 	fee_growth_global_0_X128_delta: 85130172636557991529041720559172,
		// 	fee_growth_global_1_X128_delta: 0,
		// 	pool_price_after: 50000,
		// 	pool_price_before: 100000,
		// 	tick_after: IntegerTrait::<i32>::new(6932, true),
		// 	tick_before: IntegerTrait::<i32>::new(0, false),
		// },
		// SwapExpectedResults { //wrong tick_after and pool_price_after. Not even close
		// 	amount_0_before: 999700069986003,
		// 	amount_0_delta: IntegerTrait::<i256>::new(999700069986002, true),
		// 	amount_1_before: 999700069986003,
		// 	amount_1_delta: IntegerTrait::<i256>::new(1000700370186095, false),
		// 	execution_price: 100100,
		// 	fee_growth_global_0_X128_delta: 0,
		// 	fee_growth_global_1_X128_delta: 85130172636557991529041720559172,
		// 	pool_price_after: 200000,
		// 	pool_price_before: 100000,
		// 	tick_after: IntegerTrait::<i32>::new(6931, false),
		// 	tick_before: IntegerTrait::<i32>::new(0, false),
		// },
		// SwapExpectedResults { //OK
		// 	amount_0_before: 999700069986003,
		// 	amount_0_delta: IntegerTrait::<i256>::new(1000, false),
		// 	amount_1_before: 999700069986003,
		// 	amount_1_delta: IntegerTrait::<i256>::new(998, true),
		// 	execution_price: 99800,
		// 	fee_growth_global_0_X128_delta: 170141183460469231731,
		// 	fee_growth_global_1_X128_delta: 0,
		// 	pool_price_after: 100000,
		// 	pool_price_before: 100000,
		// 	tick_after: IntegerTrait::<i32>::new(1, true),
		// 	tick_before: IntegerTrait::<i32>::new(0, false),
		// },
		// SwapExpectedResults { //OK
		// 	amount_0_before: 999700069986003,
		// 	amount_0_delta: IntegerTrait::<i256>::new(998, true),
		// 	amount_1_before: 999700069986003,
		// 	amount_1_delta: IntegerTrait::<i256>::new(1000, false),
		// 	execution_price: 100200,
		// 	fee_growth_global_0_X128_delta: 0,
		// 	fee_growth_global_1_X128_delta: 170141183460469231731,
		// 	pool_price_after: 100000,
		// 	pool_price_before: 100000,
		// 	tick_after: IntegerTrait::<i32>::new(0, false),
		// 	tick_before: IntegerTrait::<i32>::new(0, false),
		// },
		// SwapExpectedResults { //OK
		// 	amount_0_before: 999700069986003,
		// 	amount_0_delta: IntegerTrait::<i256>::new(1002, false),
		// 	amount_1_before: 999700069986003,
		// 	amount_1_delta: IntegerTrait::<i256>::new(1000, true),
		// 	execution_price: 99800,
		// 	fee_growth_global_0_X128_delta: 170141183460469231731,
		// 	fee_growth_global_1_X128_delta: 0,
		// 	pool_price_after: 100000,
		// 	pool_price_before: 100000,
		// 	tick_after: IntegerTrait::<i32>::new(1, true),
		// 	tick_before: IntegerTrait::<i32>::new(0, false),
		// },
		// SwapExpectedResults {//OK
		// 	amount_0_before: 999700069986003,
		// 	amount_0_delta: IntegerTrait::<i256>::new(1000, true),
		// 	amount_1_before: 999700069986003,
		// 	amount_1_delta: IntegerTrait::<i256>::new(1002, false),
		// 	execution_price: 100200,
		// 	fee_growth_global_0_X128_delta: 0,
		// 	fee_growth_global_1_X128_delta: 170141183460469231731,
		// 	pool_price_after: 100000,
		// 	pool_price_before: 100000,
		// 	tick_after: IntegerTrait::<i32>::new(0, false),
		// 	tick_before: IntegerTrait::<i32>::new(0, false),
		// },
		// SwapExpectedResults {//OK
		// 	amount_0_before: 999700069986003,
		// 	amount_0_delta: IntegerTrait::<i256>::new(999700069986002, true),
		// 	amount_1_before: 999700069986003,
		// 	amount_1_delta: IntegerTrait::<i256>::new(1000700370186095, false),
		// 	execution_price: 100100,
		// 	fee_growth_global_0_X128_delta: 0,
		// 	fee_growth_global_1_X128_delta: 85130172636557991529041720559172,
		// 	pool_price_after: 250000,
		// 	pool_price_before: 100000,
		// 	tick_after: IntegerTrait::<i32>::new(9163, false),
		// 	tick_before: IntegerTrait::<i32>::new(0, false),
		// },
		// SwapExpectedResults {//OK
		// 	amount_0_before: 999700069986003,
		// 	amount_0_delta: IntegerTrait::<i256>::new(1000700370186095, false),
		// 	amount_1_before: 999700069986003,
		// 	amount_1_delta: IntegerTrait::<i256>::new(999700069986002, true),
		// 	execution_price: 99900,
		// 	fee_growth_global_0_X128_delta: 85130172636557991529041720559172,
		// 	fee_growth_global_1_X128_delta: 0,
		// 	pool_price_after: 40000,
		// 	pool_price_before: 100000,
		// 	tick_after: IntegerTrait::<i32>::new(9164, true),
		// 	tick_before: IntegerTrait::<i32>::new(0, false),
		// },
    ]
}
