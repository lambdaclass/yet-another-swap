use yas_core::numbers::signed_integer::{
    i32::i32, i32::i32_div_no_round, i256::i256, integer_trait::IntegerTrait
};
use yas_core::tests::utils::swap_cases::SwapTestHelper::{
    SwapExpectedResults, SwapTestCase, PoolTestCase, obtain_swap_cases, POOL_CASES
};

fn SWAP_CASES_POOL_2() -> (Array<SwapTestCase>, Array<SwapTestCase>) {
    obtain_swap_cases(array![14, 15])
}

fn SWAP_EXPECTED_RESULTS_POOL_2() -> Array<SwapExpectedResults> {
    array![
        SwapExpectedResults {
            amount_0_before: 2000000000000000000,
            amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            amount_1_before: 2000000000000000000,
            amount_1_delta: IntegerTrait::<i256>::new(662207357859531772, true),
            execution_price: 66221,
            fee_growth_global_0_X128_delta: 1701411834604692317316873037158841057,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 52995426430946045213072876479, // 52995426430946045095399391232
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(8043, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 2000000000000000000,
            amount_0_delta: IntegerTrait::<i256>::new(662207357859531772, true),
            amount_1_before: 2000000000000000000,
            amount_1_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            execution_price: 151010,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 1701411834604692317316873037158841057,
            pool_price_after: 118446102958825184702348205752, // 118446102958825193146597507072
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(8042, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 2000000000000000000,
            amount_0_delta: IntegerTrait::<i256>::new(2020202020202020203, false),
            amount_1_before: 2000000000000000000,
            amount_1_delta: IntegerTrait::<i256>::new(1000000000000000000, true),
            execution_price: 49500,
            fee_growth_global_0_X128_delta: 3437195625464025050172418213103875650,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 39614081257132168796771975168,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(13864, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 2000000000000000000,
            amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, true),
            amount_1_before: 2000000000000000000,
            amount_1_delta: IntegerTrait::<i256>::new(2020202020202020203, false),
            execution_price: 202020,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 3437195625464025050172418213103875650,
            pool_price_after: 158456325028528675187087900672,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(13863, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 2000000000000000000,
            amount_0_delta: IntegerTrait::<i256>::new(836795075501202120, false),
            amount_1_before: 2000000000000000000,
            amount_1_delta: IntegerTrait::<i256>::new(585786437626904951, true),
            execution_price: 70004,
            fee_growth_global_0_X128_delta: 1423733044596672457631004491657125052,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 56022770974786139918731938227, // 56022770974786143748341366784
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(6932, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 2000000000000000000,
            amount_0_delta: IntegerTrait::<i256>::new(585786437626904951, true),
            amount_1_before: 2000000000000000000,
            amount_1_delta: IntegerTrait::<i256>::new(836795075501202120, false),
            execution_price: 142850,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 1423733044596672457631004491657125052,
            pool_price_after: 112045541949572279837463876454, // 112045541949572287496682733568
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(6931, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 2000000000000000000,
            amount_0_delta: IntegerTrait::<i256>::new(836795075501202120, false),
            amount_1_before: 2000000000000000000,
            amount_1_delta: IntegerTrait::<i256>::new(585786437626904951, true),
            execution_price: 70004,
            fee_growth_global_0_X128_delta: 1423733044596672457631004491657125052,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 56022770974786139918731938227, // 56022770974786143748341366784
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(6932, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 2000000000000000000,
            amount_0_delta: IntegerTrait::<i256>::new(585786437626904951, true),
            amount_1_before: 2000000000000000000,
            amount_1_delta: IntegerTrait::<i256>::new(836795075501202120, false),
            execution_price: 142850,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 1423733044596672457631004491657125052,
            pool_price_after: 112045541949572279837463876454, // 112045541949572287496682733568
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(6931, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 2000000000000000000,
            amount_0_delta: IntegerTrait::<i256>::new(1000, false),
            amount_1_before: 2000000000000000000,
            amount_1_delta: IntegerTrait::<i256>::new(989, true),
            execution_price: 98900,
            fee_growth_global_0_X128_delta: 1701411834604692317316,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 79228162514264298375603505776, // 79228162514264302409171861504
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(1, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 2000000000000000000,
            amount_0_delta: IntegerTrait::<i256>::new(989, true),
            amount_1_before: 2000000000000000000,
            amount_1_delta: IntegerTrait::<i256>::new(1000, false),
            execution_price: 101110,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 1701411834604692317316,
            pool_price_after: 79228162514264376811484394896, // 79228162514264372777916039168
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(0, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 2000000000000000000,
            amount_0_delta: IntegerTrait::<i256>::new(1012, false),
            amount_1_before: 2000000000000000000,
            amount_1_delta: IntegerTrait::<i256>::new(1000, true),
            execution_price: 98814,
            fee_growth_global_0_X128_delta: 1871553018065161549048,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 79228162514264297939848611947, // 79228162514264293613078839296
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(1, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 2000000000000000000,
            amount_0_delta: IntegerTrait::<i256>::new(1000, true),
            amount_1_before: 2000000000000000000,
            amount_1_delta: IntegerTrait::<i256>::new(1012, false),
            execution_price: 101200,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 1871553018065161549048,
            pool_price_after: 79228162514264377247239288725, // 79228162514264372777916039168
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(0, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 2000000000000000000,
            amount_0_delta: IntegerTrait::<i256>::new(735088935932648267, true),
            amount_1_before: 2000000000000000000,
            amount_1_delta: IntegerTrait::<i256>::new(1174017838553918518, false),
            execution_price: 159710,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 1997487844552658120479227965844634309,
            pool_price_after: 125270724187523965593206900784, // 125270724187523973151104958464
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(9163, false),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
        SwapExpectedResults {
            amount_0_before: 2000000000000000000,
            amount_0_delta: IntegerTrait::<i256>::new(1174017838553918518, false),
            amount_1_before: 2000000000000000000,
            amount_1_delta: IntegerTrait::<i256>::new(735088935932648267, true),
            execution_price: 62613,
            fee_growth_global_0_X128_delta: 1997487844552658120479227965844634309,
            fee_growth_global_1_X128_delta: 0,
            // pool_price_after from Uniswap: 50108289675009587501223378944
            // Difference: ( sqrt_X96: 1263940618631 ) ( decimals: 0.00000000000000001595317344894170110578967034346526 )
            pool_price_after: 50108289675009586237282760313,
            pool_price_before: 79228162514264337593543950336,
            tick_after: IntegerTrait::<i32>::new(9164, true),
            tick_before: IntegerTrait::<i32>::new(0, false),
        },
    ]
}
