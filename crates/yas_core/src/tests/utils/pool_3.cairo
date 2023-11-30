use yas_core::numbers::signed_integer::{
    i32::i32, i32::i32_div_no_round, i256::i256, integer_trait::IntegerTrait
};
use yas_core::tests::utils::swap_cases::SwapTestHelper::{
    SwapExpectedResults, SwapTestCase, PoolTestCase, obtain_swap_cases, POOL_CASES
};

fn SWAP_CASES_POOL_3() -> (Array<SwapTestCase>, Array<SwapTestCase>) {
    obtain_swap_cases(array![5, 7, 12, 15])
}

fn SWAP_EXPECTED_RESULTS_POOL_3() -> Array<SwapExpectedResults> {
    array![
        SwapExpectedResults {
            amount_0_before: 632455532033675867,
            amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            amount_1_before: 6324555320336758664,
            amount_1_delta: IntegerTrait::<i256>::new(3869747612262812754, true),
            execution_price: 306592992713544507924111903276,
            fee_growth_global_0_X128_delta: 510423550381407865336245371616884048,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 97244952018275677188403231914,
            pool_price_before: 250541448375047931186413801569,
            tick_after: IntegerTrait::<i32>::new(4098, false),
            tick_before: IntegerTrait::<i32>::new(23027, false),
        },
        SwapExpectedResults {
            amount_0_before: 632455532033675867,
            amount_0_delta: IntegerTrait::<i256>::new(86123526743846551, true),
            amount_1_before: 6324555320336758664,
            amount_1_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            execution_price: 919936346196193353013622028779,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 510423550381407695195061911147652317,
            pool_price_after: 290036687388408703476795460811,
            pool_price_before: 250541448375047931186413801569,
            tick_after: IntegerTrait::<i32>::new(25954, false),
            tick_before: IntegerTrait::<i32>::new(23027, false),
        },
        SwapExpectedResults {
            amount_0_before: 632455532033675867,
            amount_0_delta: IntegerTrait::<i256>::new(119138326055954425, false),
            amount_1_before: 6324555320336758664,
            // TODO: original amount_1_delta value 1000000000000000000
            amount_1_delta: IntegerTrait::<i256>::new(1000000000000000002, true),
            execution_price: 665009868252254046240513819058,
            fee_growth_global_0_X128_delta: 60811007371978153949466126675899993,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 210927367117915762389641826401,
            pool_price_before: 250541448375047931186413801569,
            tick_after: IntegerTrait::<i32>::new(19584, false),
            tick_before: IntegerTrait::<i32>::new(23027, false),
        },
        SwapExpectedResults {
            amount_0_before: 632455532033675867,
            amount_0_delta: IntegerTrait::<i256>::new(632455532033675838, true),
            amount_1_before: 6324555320336758664,
            amount_1_delta: IntegerTrait::<i256>::new(
                36907032426281581270030941278837275671, false
            ),
            execution_price: 4623370679652723600004998355562925450542729658368,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 18838218525064384185660173270402201838945341643205005201,
            // TODO: original pool_price_after value 1461446703485210103287273052203988822378723970341
            pool_price_after: 1457652066949847389969617340386294118487833376468,
            pool_price_before: 250541448375047931186413801569,
            // TODO: original tick_after value 887271
            tick_after: IntegerTrait::<i32>::new(887220, false),
            tick_before: IntegerTrait::<i32>::new(23027, false),
        },
        SwapExpectedResults {
            amount_0_before: 632455532033675867,
            amount_0_delta: IntegerTrait::<i256>::new(1000000000000000000, false),
            amount_1_before: 6324555320336758664,
            amount_1_delta: IntegerTrait::<i256>::new(3869747612262812754, true),
            execution_price: 306592992713544507924111903276,
            fee_growth_global_0_X128_delta: 510423550381407865336245371616884048,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 97244952018275677188403231914,
            pool_price_before: 250541448375047931186413801569,
            tick_after: IntegerTrait::<i32>::new(4098, false),
            tick_before: IntegerTrait::<i32>::new(23027, false),
        },
        SwapExpectedResults {
            amount_0_before: 632455532033675867,
            amount_0_delta: IntegerTrait::<i256>::new(119138326055954425, false),
            amount_1_before: 6324555320336758664,
            // TODO: original amount_1_delta value 1000000000000000000
            amount_1_delta: IntegerTrait::<i256>::new(1000000000000000002, true),
            execution_price: 665009868252254046240513819058,
            fee_growth_global_0_X128_delta: 60811007371978153949466126675899993,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 210927367117915762389641826401,
            pool_price_before: 250541448375047931186413801569,
            tick_after: IntegerTrait::<i32>::new(19584, false),
            tick_before: IntegerTrait::<i32>::new(23027, false),
        },
        SwapExpectedResults {
            amount_0_before: 632455532033675867,
            amount_0_delta: IntegerTrait::<i256>::new(1000, false),
            amount_1_before: 6324555320336758664,
            amount_1_delta: IntegerTrait::<i256>::new(9969, true),
            execution_price: 789825552104701181470039640899,
            fee_growth_global_0_X128_delta: 510423550381407695195,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 250541448375047536234023667962,
            pool_price_before: 250541448375047931186413801569,
            tick_after: IntegerTrait::<i32>::new(23027, false),
            tick_before: IntegerTrait::<i32>::new(23027, false),
        },
        SwapExpectedResults {
            amount_0_before: 632455532033675867,
            amount_0_delta: IntegerTrait::<i256>::new(99, true),
            amount_1_before: 6324555320336758664,
            amount_1_delta: IntegerTrait::<i256>::new(1000, false),
            execution_price: 800284469841053915078299683948,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 510423550381407695195,
            pool_price_after: 250541448375047970681652814929,
            pool_price_before: 250541448375047931186413801569,
            tick_after: IntegerTrait::<i32>::new(23027, false),
            tick_before: IntegerTrait::<i32>::new(23027, false),
        },
        SwapExpectedResults {
            amount_0_before: 632455532033675867,
            amount_0_delta: IntegerTrait::<i256>::new(102, false),
            amount_1_before: 6324555320336758664,
            // TODO: original amount_1_delta value 1000
            amount_1_delta: IntegerTrait::<i256>::new(1009, true),
            // TODO: original execution_price value 776746691316317035231444439862
            execution_price: 783737411538163888547900449892,
            fee_growth_global_0_X128_delta: 170141183460469231731,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 250541448375047891572332544436,
            pool_price_before: 250541448375047931186413801569,
            tick_after: IntegerTrait::<i32>::new(23027, false),
            tick_before: IntegerTrait::<i32>::new(23027, false),
        },
        SwapExpectedResults {
            amount_0_before: 632455532033675867,
            amount_0_delta: IntegerTrait::<i256>::new(1000, true),
            amount_1_before: 6324555320336758664,
            amount_1_delta: IntegerTrait::<i256>::new(10032, false),
            execution_price: 794816926343099834738432909770,
            fee_growth_global_0_X128_delta: 0,
            fee_growth_global_1_X128_delta: 5274376687274546183682,
            pool_price_after: 250541448375048327327226372892,
            pool_price_before: 250541448375047931186413801569,
            tick_after: IntegerTrait::<i32>::new(23027, false),
            tick_before: IntegerTrait::<i32>::new(23027, false),
        },
        SwapExpectedResults {
            amount_0_before: 632455532033675867,
            amount_0_delta: IntegerTrait::<i256>::new(2537434431428990438, false),
            amount_1_before: 6324555320336758664,
            amount_1_delta: IntegerTrait::<i256>::new(5059644256269406930, true),
            execution_price: 157980956053443089058530025701,
            fee_growth_global_0_X128_delta: 1295166291350014007196790362622908786,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 50108289675009586237282760313,
            pool_price_before: 250541448375047931186413801569,
            tick_after: IntegerTrait::<i32>::new(9164, true),
            tick_before: IntegerTrait::<i32>::new(23027, false),
        },
        SwapExpectedResults {
            amount_0_before: 632455532033675867,
            amount_0_delta: IntegerTrait::<i256>::new(634358607857247610, false),
            amount_1_before: 6324555320336758664,
            amount_1_delta: IntegerTrait::<i256>::new(3162277660168379331, true),
            execution_price: 394952390133607722301682557316,
            fee_growth_global_0_X128_delta: 323791572837503501799197590655727196,
            fee_growth_global_1_X128_delta: 0,
            pool_price_after: 125270724187523965593206900784,
            pool_price_before: 250541448375047931186413801569,
            tick_after: IntegerTrait::<i32>::new(9163, false),
            tick_before: IntegerTrait::<i32>::new(23027, false),
        },
    ]
}
