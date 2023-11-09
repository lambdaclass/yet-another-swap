use yas_core::numbers::signed_integer::{
    i32::i32, i32::i32_div_no_round, i256::i256, integer_trait::IntegerTrait
};
use yas_core::tests::utils::swap_cases::SwapTestHelper::{
    SwapExpectedResults, SwapTestCase, PoolTestCase, obtain_swap_cases, POOL_CASES
};

fn SWAP_CASES_POOL_4() -> (Array<SwapTestCase>, Array<SwapTestCase>) {
    obtain_swap_cases(array![4,6,13,14]) //list error cases indexes
}

fn SWAP_EXPECTED_RESULTS_POOL_4() -> Array<SwapExpectedResults> {
    array![
        SwapExpectedResults {//
            amount_0_before: 6324555320336758664,
            amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            amount_1_before: 632455532033675867,
            amount_1_delta: IntegerTrait::<i256>::new(86123526743846551, true),
            execution_price: 8612,
            fee_growth_global_0_X128_delta: 510423550381407695195061911147652317,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 7462,
            pool_price_before: 10000,
            tick_after: IntegerTrait::<i32>::new(25955, true),
            tick_before: IntegerTrait::<i32>::new(23028, true),
        },
        SwapExpectedResults {//
            amount_0_before: 6324555320336758664,
            amount_0_delta: IntegerTrait::<i256>::new(3869747612262812753, true),
            amount_1_before: 632455532033675867,
            amount_1_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            execution_price: 25841,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 510423550381407865336245371616884047,
            pool_price_after: 66378,
            pool_price_before: 10000,
            tick_after: IntegerTrait::<i32>::new(4099, true),
            tick_before: IntegerTrait::<i32>::new(23028, true),
        },
        SwapExpectedResults {//BUGGED
            amount_0_before: 6324555320336758664,
            amount_0_delta: IntegerTrait::<i256>::new(36907032419362389223785084665766560335, false),
            amount_1_before: 632455532033675867,
            amount_1_delta: IntegerTrait::<i256>::new(632455532033675838, true),
            execution_price: 0, //should 0.000000000000000000017136
            fee_growth_global_0_X128_delta: 18838218521532665615644565874197034349094564536667752274,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 0, //should 0.0000000000000000000000000000000000000029390,
            pool_price_before: 10000,
            tick_after: IntegerTrait::<i32>::new(887272, true), //gives 887220
            tick_before: IntegerTrait::<i32>::new(23028, true),
        },
        SwapExpectedResults {//bugged
            amount_0_before: 6324555320336758664,
            amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, true), //gives 1000000000000000002
            amount_1_before: 632455532033675867,
            amount_1_delta: IntegerTrait::<i256>::new(119138326055954425, false),
            execution_price: 11914,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 60811007371978153949466126675899993,
            pool_price_after: 14109,
            pool_price_before: 10000,
            tick_after: IntegerTrait::<i32>::new(19585, true),
            tick_before: IntegerTrait::<i32>::new(23028, true),
        },

        //panic case here

        SwapExpectedResults {
            amount_0_before: 6324555320336758664,
            amount_0_delta: IntegerTrait::<i256>::new(3869747612262812753, true),
            amount_1_before: 632455532033675867,
            amount_1_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            execution_price: 25841,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 510423550381407865336245371616884047,
            pool_price_after: 66378,
            pool_price_before: 10000,
            tick_after: IntegerTrait::<i32>::new(4099, true),
            tick_before: IntegerTrait::<i32>::new(23028, true),
        },

        //panic case here

        SwapExpectedResults { //bugged
            amount_0_before: 6324555320336758664,
            amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, true), //gives 1000000000000000002
            amount_1_before: 632455532033675867,
            amount_1_delta: IntegerTrait::<i256>::new(119138326055954425, false),
            execution_price: 11914,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 60811007371978153949466126675899993,
            pool_price_after: 14109,
            pool_price_before: 10000,
            tick_after: IntegerTrait::<i32>::new(19585, true),
            tick_before: IntegerTrait::<i32>::new(23028, true),
        },
        SwapExpectedResults {
            amount_0_before: 6324555320336758664,
            amount_0_delta: IntegerTrait::<i256>::new(1000, false),
            amount_1_before: 632455532033675867,
            amount_1_delta: IntegerTrait::<i256>::new(99, true),
            execution_price: 9900,
            fee_growth_global_0_X128_delta: 510423550381407695195,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 10000,
            pool_price_before: 10000,
            tick_after: IntegerTrait::<i32>::new(23028, true),
            tick_before: IntegerTrait::<i32>::new(23028, true),
        },
        SwapExpectedResults {
            amount_0_before: 6324555320336758664,
            amount_0_delta: IntegerTrait::<i256>::new(9969, true),
            amount_1_before: 632455532033675867,
            amount_1_delta: IntegerTrait::<i256>::new(1000, false),
            execution_price: 10031,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 510423550381407695195,
            pool_price_after: 10000,
            pool_price_before: 10000,
            tick_after: IntegerTrait::<i32>::new(23028, true),
            tick_before: IntegerTrait::<i32>::new(23028, true),
        },
        SwapExpectedResults {
            amount_0_before: 6324555320336758664,
            amount_0_delta: IntegerTrait::<i256>::new(10032, false),
            amount_1_before: 632455532033675867,
            amount_1_delta: IntegerTrait::<i256>::new(1000, true),
            execution_price: 9968,
            fee_growth_global_0_X128_delta: 5274376687274546183682,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 10000,
            pool_price_before: 10000,
            tick_after: IntegerTrait::<i32>::new(23028, true),
            tick_before: IntegerTrait::<i32>::new(23028, true),
        },
        SwapExpectedResults { //bugged
            amount_0_before: 6324555320336758664,
            amount_0_delta: IntegerTrait::<i256>::new(1000, true), //gives 1009
            amount_1_before: 632455532033675867,
            amount_1_delta: IntegerTrait::<i256>::new(102, false),
            execution_price: 10200,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 170141183460469231731,
            pool_price_after: 10000,
            pool_price_before: 10000,
            tick_after: IntegerTrait::<i32>::new(23028, true),
            tick_before: IntegerTrait::<i32>::new(23028, true),
        },
        SwapExpectedResults {
            amount_0_before: 6324555320336758664,
            amount_0_delta: IntegerTrait::<i256>::new(5059644256269406930, true),
            amount_1_before: 632455532033675867,
            amount_1_delta: IntegerTrait::<i256>::new(2537434431428990440, false),
            execution_price: 50150,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 1295166291350014177337973823092140516,
            pool_price_after: 250000,
            pool_price_before: 10000,
            tick_after: IntegerTrait::<i32>::new(9163, false),
            tick_before: IntegerTrait::<i32>::new(23028, true),
        },

        //panic case here

        //panic case here

        SwapExpectedResults {
            amount_0_before: 6324555320336758664,
            amount_0_delta: IntegerTrait::<i256>::new(3162277660168379331, true),
            amount_1_before: 632455532033675867,
            amount_1_delta: IntegerTrait::<i256>::new(634358607857247611, false),
            execution_price: 20060,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 323791572837503501799197590655727195,
            pool_price_after: 40000,
            pool_price_before: 10000,
            tick_after: IntegerTrait::<i32>::new(9164, true),
            tick_before: IntegerTrait::<i32>::new(23028, true),
        },
    ]
}
