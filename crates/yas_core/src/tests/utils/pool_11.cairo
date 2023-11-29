use yas_core::numbers::signed_integer::{
    i32::i32, i32::i32_div_no_round, i256::i256, integer_trait::IntegerTrait
};
use yas_core::tests::utils::swap_cases::SwapTestHelper::{
    SwapExpectedResults, SwapTestCase, PoolTestCase, obtain_swap_cases, POOL_CASES
};

fn SWAP_CASES_POOL_11() -> (Array<SwapTestCase>, Array<SwapTestCase>) {
    obtain_swap_cases(array![4, 6, 13, 14])
}

fn SWAP_EXPECTED_RESULTS_POOL_11() -> Array<SwapExpectedResults> {
    array![
		// SwapExpectedResults { //ok
		// 	amount_0_before: 26037782196502120275425782622539039026,
		// 	amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
		// 	amount_1_before: 1,
		// 	amount_1_delta: IntegerTrait::<i256>::new(0, false),
		// 	execution_price: 0,
		// 	fee_growth_global_0_X128_delta: 170141183460469231731687303715884105728,
		// 	fee_growth_global_1_X128_delta: 0,
		// 	pool_price_after: 6085630636,
		// 	pool_price_before: 6085630636,
		// 	tick_after: IntegerTrait::<i32>::new(880303, true),
		// 	tick_before: IntegerTrait::<i32>::new(880303, true),
		// },
		// SwapExpectedResults { //ok
		// 	amount_0_before: 26037782196502120275425782622539039026,
		// 	amount_0_delta: IntegerTrait::<i256>::new(26037782196502120271413746514214063808, true),
		// 	amount_1_before: 1,
		// 	amount_1_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
		// 	execution_price: 3042815318,
		// 	fee_growth_global_0_X128_delta: 0,
		// 	fee_growth_global_1_X128_delta: 510423550381413820277666488039994629,
		// 	pool_price_after: 39495239013360769732380381856,
		// 	pool_price_before: 6085630636,
		// 	tick_after: IntegerTrait::<i32>::new(13924, true),
		// 	tick_before: IntegerTrait::<i32>::new(880303, true),
		// },
		// SwapExpectedResults { //bugged
		// 	amount_0_before: 26037782196502120275425782622539039026,
		// 	amount_0_delta: IntegerTrait::<i256>::new(10790901831095468191587263901270792610, false),
		// 	amount_1_before: 1,
		// 	amount_1_delta: IntegerTrait::<i256>::new(0, false),
		// 	execution_price: 0,
		// 	fee_growth_global_0_X128_delta: 5507930424444982259736347157352787128931407551935325049,
		// 	fee_growth_global_1_X128_delta: 0,
		// 	pool_price_after: 4295128740,
		// 	pool_price_before: 6085630636,
		// 	tick_after: IntegerTrait::<i32>::new(887272, true),
		// 	tick_before: IntegerTrait::<i32>::new(880303, true),
		// },
		// SwapExpectedResults { //bugged
		// 	amount_0_before: 26037782196502120275425782622539039026,
		// 	amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, true),
		// 	amount_1_before: 1,
		// 	amount_1_delta: IntegerTrait::<i256>::new(2, false),
		// 	execution_price: 158456325028,
		// 	fee_growth_global_0_X128_delta: 0,
		// 	fee_growth_global_1_X128_delta: 170141183460469231731,
		// 	pool_price_after: 6085630637,
		// 	pool_price_before: 6085630636,
		// 	tick_after: IntegerTrait::<i32>::new(880303, true),
		// 	tick_before: IntegerTrait::<i32>::new(880303, true),
		// },

		// // panic here

		// SwapExpectedResults {  //ok
		// 	amount_0_before: 26037782196502120275425782622539039026,
		// 	amount_0_delta: IntegerTrait::<i256>::new(26037782196502120271413746514214063808, true),
		// 	amount_1_before: 1,
		// 	amount_1_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
		// 	execution_price: 3042815318,
		// 	fee_growth_global_0_X128_delta: 0,
		// 	fee_growth_global_1_X128_delta: 510423550381413820277666488039994629,
		// 	pool_price_after: 39495239013360769732380381856,
		// 	pool_price_before: 6085630636,
		// 	tick_after: IntegerTrait::<i32>::new(13924, true),
		// 	tick_before: IntegerTrait::<i32>::new(880303, true),
		// },

		// // panic here

		// SwapExpectedResults { //bugged
		// 	amount_0_before: 26037782196502120275425782622539039026,
		// 	amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, true),
		// 	amount_1_before: 1,
		// 	amount_1_delta: IntegerTrait::<i256>::new(2, false),
		// 	execution_price: 158456325028,
		// 	fee_growth_global_0_X128_delta: 0,
		// 	fee_growth_global_1_X128_delta: 170141183460469231731,
		// 	pool_price_after: 6085630637,
		// 	pool_price_before: 6085630636,
		// 	tick_after: IntegerTrait::<i32>::new(880303, true),
		// 	tick_before: IntegerTrait::<i32>::new(880303, true),
		// },
		// SwapExpectedResults { //ok
		// 	amount_0_before: 26037782196502120275425782622539039026,
		// 	amount_0_delta: IntegerTrait::<i256>::new(1000, false),
		// 	amount_1_before: 1,
		// 	amount_1_delta: IntegerTrait::<i256>::new(0, false),
		// 	execution_price: 0,
		// 	fee_growth_global_0_X128_delta: 170141183460469231731687,
		// 	fee_growth_global_1_X128_delta: 0,
		// 	pool_price_after: 6085630636,
		// 	pool_price_before: 6085630636,
		// 	tick_after: IntegerTrait::<i32>::new(880303, true),
		// 	tick_before: IntegerTrait::<i32>::new(880303, true),
		// },
		// SwapExpectedResults {//ok
		// 	amount_0_before: 26037782196502120275425782622539039026,
		// 	amount_0_delta: IntegerTrait::<i256>::new(26033697540846965126433148994127431276, true),
		// 	amount_1_before: 1,
		// 	amount_1_delta: IntegerTrait::<i256>::new(1000, false),
		// 	execution_price: 0,
		// 	fee_growth_global_0_X128_delta: 0,
		// 	fee_growth_global_1_X128_delta: 2381976568446569244235,
		// 	pool_price_after: 38793068108090,
		// 	pool_price_before: 6085630636,
		// 	tick_after: IntegerTrait::<i32>::new(705093, true),
		// 	tick_before: IntegerTrait::<i32>::new(880303, true),
		// },

		// SwapExpectedResults { //bugged
		// 	amount_0_before: 26037782196502120275425782622539039026,
		// 	amount_0_delta: IntegerTrait::<i256>::new(10790901831095468191587263901270792610, false),
		// 	amount_1_before: 1,
		// 	amount_1_delta: IntegerTrait::<i256>::new(0, false),
		// 	execution_price: 0,
		// 	fee_growth_global_0_X128_delta: 5507930424444982259736347157352787128931407551935325049,
		// 	fee_growth_global_1_X128_delta: 0,
		// 	pool_price_after: 4295128740,
		// 	pool_price_before: 6085630636,
		// 	tick_after: IntegerTrait::<i32>::new(887272, true),
		// 	tick_before: IntegerTrait::<i32>::new(880303, true),
		// },
		// SwapExpectedResults { //bugged
		// 	amount_0_before: 26037782196502120275425782622539039026,
		// 	amount_0_delta: IntegerTrait::<i256>::new(1000, true),
		// 	amount_1_before: 1,
		// 	amount_1_delta: IntegerTrait::<i256>::new(2, false),
		// 	execution_price: 158456325028528675187087900,
		// 	fee_growth_global_0_X128_delta: 0,
		// 	fee_growth_global_1_X128_delta: 170141183460469231731,
		// 	pool_price_after: 6085630637,
		// 	pool_price_before: 6085630636,
		// 	tick_after: IntegerTrait::<i32>::new(880303, true),
		// 	tick_before: IntegerTrait::<i32>::new(880303, true),
		// },

		// SwapExpectedResults { //ok
		// 	amount_0_before: 26037782196502120275425782622539039026,
		// 	amount_0_delta: IntegerTrait::<i256>::new(26037782196502120274160871558471687260, true),
		// 	amount_1_before: 1,
		// 	amount_1_delta: IntegerTrait::<i256>::new(3171793039286238112, false),
		// 	execution_price: 9651180445,
		// 	fee_growth_global_0_X128_delta: 0,
		// 	fee_growth_global_1_X128_delta: 1618957864187523634078592530170978294,
		// 	pool_price_after: 125270724187523965593206900784,
		// 	pool_price_before: 6085630636,
		// 	tick_after: IntegerTrait::<i32>::new(9163, false),
		// 	tick_before: IntegerTrait::<i32>::new(880303, true),
		// },

		// panic case here

		// panic case here

		// SwapExpectedResults { //ok
		// 	amount_0_before: 26037782196502120275425782622539039026,
		// 	amount_0_delta: IntegerTrait::<i256>::new(26037782196502120272263504962370659661, true),
		// 	amount_1_before: 1,
		// 	amount_1_delta: IntegerTrait::<i256>::new(1268717215714495283, false),
		// 	execution_price: 3860472178,
		// 	fee_growth_global_0_X128_delta: 0,
		// 	fee_growth_global_1_X128_delta: 647583145675012958539816297734564973,
		// 	pool_price_after: 50108289675009586237282760313,
		// 	pool_price_before: 6085630636,
		// 	tick_after: IntegerTrait::<i32>::new(9164, true),
		// 	tick_before: IntegerTrait::<i32>::new(880303, true),
		// },
    ]
}