use yas_core::numbers::signed_integer::{
    i32::i32, i32::i32_div_no_round, i256::i256, integer_trait::IntegerTrait
};
use yas_core::tests::utils::swap_cases::SwapTestHelper::{
    SwapExpectedResults, SwapTestCase, PoolTestCase, obtain_swap_cases, POOL_CASES
};

fn SWAP_CASES_POOL_10() -> (Array<SwapTestCase>, Array<SwapTestCase>) {
    obtain_swap_cases(array![5, 7, 12, 15])
}

fn SWAP_EXPECTED_RESULTS_POOL_10() -> Array<SwapExpectedResults> {
    array![
        SwapExpectedResults {
            amount_0_before: 1,
            amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            amount_1_before: 26087635650665564424699143612505016738,
            amount_1_delta: IntegerTrait::<i256>::new(26087635650665564420687107504180041533, true),
            execution_price: 2066875436943847413039672616718658691043432595456,
            fee_growth_global_0_X128_delta: 510423550381413479995299567101531162,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 158933124401733886835376621103,
            pool_price_before: 1033437718471923706666374484006904511252097097914,
            tick_after: IntegerTrait::<i32>::new(13923, false),
            tick_before: IntegerTrait::<i32>::new(880340, false),
        },
        SwapExpectedResults {
            amount_0_before: 1,
            amount_0_delta: IntegerTrait::<i256>::new(0, false),
            amount_1_before: 26087635650665564424699143612505016738,
            amount_1_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            execution_price: '-Infinity'.into(),
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 510423550381407695195061911147652317,
            pool_price_after: 1033437718471923706705869723020265283542478757156,
            pool_price_before: 1033437718471923706666374484006904511252097097914,
            tick_after: IntegerTrait::<i32>::new(880340, false),
            tick_before: IntegerTrait::<i32>::new(880340, false),
        },
        SwapExpectedResults {
            amount_0_before: 1,
            amount_0_delta: IntegerTrait::<i256>::new(2, false),
            amount_1_before: 26087635650665564424699143612505016738,
            // TODO: Original amount_1_delta 1000000000000000000
            amount_1_delta: IntegerTrait::<i256>::new(5587595338773672892908939151299000550, true),
            // TODO: execution_price 39614081257132168796771975168000000000000000000,
            execution_price: 221347455782153226464807387954346659361332566398722661167818342400,
            fee_growth_global_0_X128_delta: 170141183460469231731,
            fee_growth_global_1_X128_delta: 0,
            // TODO: Original pool_price_after 1033437718471923706626760402749772342455325122746
            pool_price_after: 812090262689770480201567096052557851872885475574,
            pool_price_before: 1033437718471923706666374484006904511252097097914,
            // TODO: Original tick_after 880340
            tick_after: IntegerTrait::<i32>::new(875519, false),
            tick_before: IntegerTrait::<i32>::new(880340, false),
        },
        SwapExpectedResults {
            amount_0_before: 1,
            amount_0_delta: IntegerTrait::<i256>::new(0, false),
            amount_1_before: 26087635650665564424699143612505016738,
            amount_1_delta: IntegerTrait::<i256>::new(
                10740898373457544742072477595619363803, false
            ),
            execution_price: '-Infinity'.into(),
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 5482407482066087054477299856254072312542046383926535301,
            // TODO: Original pool_price_after 1461446703485210103287273052203988822378723970341
            pool_price_after: 1457652066949847389969617340386294118487833376468,
            pool_price_before: 1033437718471923706666374484006904511252097097914,
            // TODO: Original tick_after 887271
            tick_after: IntegerTrait::<i32>::new(887220, false),
            tick_before: IntegerTrait::<i32>::new(880340, false),
        },
        SwapExpectedResults {
            amount_0_before: 1,
            amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            amount_1_before: 26087635650665564424699143612505016738,
            amount_1_delta: IntegerTrait::<i256>::new(26087635650665564420687107504180041533, true),
            execution_price: 2066875436943847413039672616718658691043432595456,
            fee_growth_global_0_X128_delta: 510423550381413479995299567101531162,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 158933124401733886835376621103,
            pool_price_before: 1033437718471923706666374484006904511252097097914,
            tick_after: IntegerTrait::<i32>::new(13923, false),
            tick_before: IntegerTrait::<i32>::new(880340, false),
        },
        SwapExpectedResults {
            amount_0_before: 1,
            amount_0_delta: IntegerTrait::<i256>::new(2, false),
            amount_1_before: 26087635650665564424699143612505016738,
            // TODO: Original amount_1_delta -1000000000000000000
            amount_1_delta: IntegerTrait::<i256>::new(5587595338773672892908939151299000550, true),
            // TODO: Original execution_price 39614081257132168796771975168000000000000000000
            execution_price: 221347455782153226464807387954346659361332566398722661167818342400,
            fee_growth_global_0_X128_delta: 170141183460469231731,
            fee_growth_global_1_X128_delta: 0,
            // TODO: Original pool_price_after 1033437718471923706626760402749772342455325122746
            pool_price_after: 812090262689770480201567096052557851872885475574,
            pool_price_before: 1033437718471923706666374484006904511252097097914,
            // TODO: Original tick_after 880340
            tick_after: IntegerTrait::<i32>::new(875519, false),
            tick_before: IntegerTrait::<i32>::new(880340, false),
        },
        SwapExpectedResults {
            amount_0_before: 1,
            amount_0_delta: IntegerTrait::<i256>::new(1000, false),
            amount_1_before: 26087635650665564424699143612505016738,
            amount_1_delta: IntegerTrait::<i256>::new(26083549850867114346332688477747755628, true),
            execution_price: 2066551726533415062021770703518529325917857120256000000000000000,
            fee_growth_global_0_X128_delta: 2381976568446569244235,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 161855205216175642309983856828649147738467364,
            pool_price_before: 1033437718471923706666374484006904511252097097914,
            tick_after: IntegerTrait::<i32>::new(705098, false),
            tick_before: IntegerTrait::<i32>::new(880340, false),
        },
        SwapExpectedResults {
            amount_0_before: 1,
            amount_0_delta: IntegerTrait::<i256>::new(0, false),
            amount_1_before: 26087635650665564424699143612505016738,
            amount_1_delta: IntegerTrait::<i256>::new(1000, false),
            execution_price: '-Infinity'.into(),
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 510423550381407695195,
            pool_price_after: 1033437718471923706666374484006904550747336111274,
            pool_price_before: 1033437718471923706666374484006904511252097097914,
            tick_after: IntegerTrait::<i32>::new(880340, false),
            tick_before: IntegerTrait::<i32>::new(880340, false),
        },
        SwapExpectedResults {
            amount_0_before: 1,
            amount_0_delta: IntegerTrait::<i256>::new(2, false),
            amount_1_before: 26087635650665564424699143612505016738,
            // TODO: Original amount_1_delta -1000
            amount_1_delta: IntegerTrait::<i256>::new(5587595338773672892908939151299000550, true),
            // TODO: Original execution_price 39614081257132168796771975168000
            execution_price: 221347455782153226464807387954346659361332566398722661167818342400,
            fee_growth_global_0_X128_delta: 170141183460469231731,
            fee_growth_global_1_X128_delta: 0,
            // TODO: Original pool_price_after 1033437718471923706666374484006904471638015840781
            pool_price_after: 812090262689770480201567096052557851872885475574,
            pool_price_before: 1033437718471923706666374484006904511252097097914,
            // TODO: Original tick_after 880340
            tick_after: IntegerTrait::<i32>::new(875519, false),
            tick_before: IntegerTrait::<i32>::new(880340, false),
        },
        SwapExpectedResults {
            amount_0_before: 1,
            amount_0_delta: IntegerTrait::<i256>::new(0, false),
            amount_1_before: 26087635650665564424699143612505016738,
            amount_1_delta: IntegerTrait::<i256>::new(
                10740898373457544742072477595619363803, false
            ),
            execution_price: '-Infinity'.into(),
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 5482407482066087054477299856254072312542046383926535301,
            // TODO: Original pool_price_after 1461446703485210103287273052203988822378723970341
            pool_price_after: 1457652066949847389969617340386294118487833376468,
            pool_price_before: 1033437718471923706666374484006904511252097097914,
            // TODO: Original tick_after 887271
            tick_after: IntegerTrait::<i32>::new(887220, false),
            tick_before: IntegerTrait::<i32>::new(880340, false),
        },
        SwapExpectedResults {
            amount_0_before: 1,
            amount_0_delta: IntegerTrait::<i256>::new(3171793039286238109, false),
            amount_1_before: 26087635650665564424699143612505016738,
            amount_1_delta: IntegerTrait::<i256>::new(26087635650665564423434232548437664977, true),
            execution_price: 651642591853649146618245502796380447701949480960,
            fee_growth_global_0_X128_delta: 1618957864187523123655042148763283097,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 50108289675009586237282760313,
            pool_price_before: 1033437718471923706666374484006904511252097097914,
            tick_after: IntegerTrait::<i32>::new(9164, true),
            tick_before: IntegerTrait::<i32>::new(880340, false),
        },
        SwapExpectedResults {
            amount_0_before: 1,
            amount_0_delta: IntegerTrait::<i256>::new(1268717215714495281, false),
            amount_1_before: 26087635650665564424699143612505016738,
            amount_1_delta: IntegerTrait::<i256>::new(26087635650665564421536865952336637378, true),
            execution_price: 1629106479634122818414505029575366031176923873280,
            fee_growth_global_0_X128_delta: 647583145675012618257449376796101507,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 125270724187523965593206900784,
            pool_price_before: 1033437718471923706666374484006904511252097097914,
            tick_after: IntegerTrait::<i32>::new(9163, false),
            tick_before: IntegerTrait::<i32>::new(880340, false),
        },
    ]
}
