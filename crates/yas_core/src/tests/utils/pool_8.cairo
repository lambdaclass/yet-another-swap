use yas_core::numbers::signed_integer::{
    i32::i32, i32::i32_div_no_round, i256::i256, integer_trait::IntegerTrait
};
use yas_core::tests::utils::swap_cases::SwapTestHelper::{
    SwapExpectedResults, SwapTestCase, PoolTestCase, obtain_swap_cases, POOL_CASES
};

fn SWAP_CASES_POOL_8() -> (Array<SwapTestCase>, Array<SwapTestCase>) {
    obtain_swap_cases(array![14, 15])
}

fn SWAP_EXPECTED_RESULTS_POOL_8() -> Array<SwapExpectedResults> {
    array![
        SwapExpectedResults { //ok
            amount_0_before: 1995041008271423675,
            amount_0_delta: IntegerTrait::<i256>::new(0, false),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(0, false),
            execution_price: 0,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 4295128740,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(887272, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults { //ok
            amount_0_before: 1995041008271423675,
            amount_0_delta: IntegerTrait::<i256>::new(665331998665331998, true),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            execution_price: 119080643457999107324893066056,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 510423550381407695195061911147652317,
            pool_price_after: 118723401527625109883925609578,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(8089, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults { //bugged
            amount_0_before: 1995041008271423675,
            amount_0_delta: IntegerTrait::<i256>::new(0, false),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(0, false),
            execution_price: 0,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 4295128740,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(887272, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults { //ok
            amount_0_before: 1995041008271423675,
            amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, true),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(2006018054162487463, false),
            execution_price: 158933124401733876866094591743,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 1023918857334819954209013958517557896,
            pool_price_after: 158456325028528675187087900672,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(13863, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults { //ok
            amount_0_before: 1995041008271423675,
            amount_0_delta: IntegerTrait::<i256>::new(0, false),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(0, false),
            execution_price: 0,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 56022770974786139918731938227,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(6932, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults { //ok
            amount_0_before: 1995041008271423675,
            amount_0_delta: IntegerTrait::<i256>::new(585786437626904951, true),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(830919884399388263, false),
            execution_price: 112382690019631173477261704572,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 424121077477644648929101317621422688,
            pool_price_after: 112045541949572279837463876454,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(6931, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults { //bugged
            amount_0_before: 1995041008271423675,
            amount_0_delta: IntegerTrait::<i256>::new(0, false),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(0, false),
            execution_price: 0,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 56022770974786139918731938227,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(6932, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults { //ok
            amount_0_before: 1995041008271423675,
            amount_0_delta: IntegerTrait::<i256>::new(585786437626904951, true),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(830919884399388263, false),
            execution_price: 112382690019631173477261704572,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 424121077477644648929101317621422688,
            pool_price_after: 112045541949572279837463876454,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(6931, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults { //ok
            amount_0_before: 1995041008271423675,
            amount_0_delta: IntegerTrait::<i256>::new(0, false),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(0, false),
            execution_price: 0,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 4295128740,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(887272, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults { //ok
            amount_0_before: 1995041008271423675,
            amount_0_delta: IntegerTrait::<i256>::new(996, true),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(1000, false),
            execution_price: 79546347905887889146199029593,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 510423550381407695195,
            pool_price_after: 79228162514264377088782963696,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(0, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults { //bugged
            amount_0_before: 1995041008271423675,
            amount_0_delta: IntegerTrait::<i256>::new(0, false),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(0, false),
            execution_price: 0,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 4295128740,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(887272, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults { //ok
            amount_0_before: 1995041008271423675,
            amount_0_delta: IntegerTrait::<i256>::new(1000, true),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(1005, false),
            execution_price: 79624303326835659281511670087,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 680564733841876926926,
            pool_price_after: 79228162514264377207625207469,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(0, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults { //ok
            amount_0_before: 1995041008271423675,
            amount_0_delta: IntegerTrait::<i256>::new(735088935932648267, true),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(1165774985123750584, false),
            execution_price: 125647667189091239369083622079,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 595039006852697554786973994761078087,
            pool_price_after: 125270724187523965593206900784,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(9163, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults { //ok
            amount_0_before: 1995041008271423675,
            amount_0_delta: IntegerTrait::<i256>::new(0, false),
            amount_1_before: 0,
            amount_1_delta: IntegerTrait::<i256>::new(0, false),
            execution_price: 0,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 50108289675009586237282760313,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(9164, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
    //panic case

    //panic case
    ]
}
