mod PoolCase0 {
    use yas_core::tests::utils::swap_helper::SwapTestHelper::test_pool;
    use yas_core::tests::utils::pool_0::{SWAP_CASES_POOL_0, SWAP_EXPECTED_RESULTS_POOL_0};
    use yas_core::tests::utils::swap_cases::SwapTestHelper::POOL_CASES;

    use yas_core::numbers::fixed_point::implementations::impl_64x96::{
        FixedType, FixedTrait, FP64x96PartialOrd, FP64x96PartialEq, FP64x96Impl, FP64x96Zeroable, 
        FP64x96Div, FP64x96Mul, FP64x96SubEq, FP64x96Sub, FP64x96Add, ONE
    };

    use debug::PrintTrait;

    const PRECISION: u256 = 5;

    #[test]
    #[available_gas(200000000000)]
    fn test_precision() {
        // 17703951872335741665094590362
        // 0.223455288
        // 0.22344999999999999999

        // 98979262442818629108247360
        // 0.0012492939291
        // 0.00124
        // 0.00123999999999999999

        // 72302208423356786316246282502
        // 0.91259129529419292929292222
        // 0.91259
        // 0.91258912589125891258

        // 51666739921848742181150399198
        // 0.6521259395930910
        // 0.65212
        // 0.65211999999999999999

        // 79228093067356365710448173302
        // 0.999999123456789
        // 0.99999
        // 0.99998999999999999999

        let mut num: u256 = 72302208423356786316246282502;

        let FP0_1 = 7922816251426433759354395033;
        let FP0_01 = 792281625142643375935439503;
        let FP0_001 = 79228162514264337593543950;
        let FP0_0001 = 7922816251426433759354395;
        let FP0_00001 = 792281625142643375935439;

        let num_D1 = num / FP0_1;
        'num_D1'.print();
        num_D1.print();
        let FP_num_1 = num_D1 * FP0_1;
        num -= FP_num_1;

        let num_D2 = num / FP0_01;
        'num_D2'.print();
        num_D2.print();
        let FP_num_2 = num_D2 * FP0_01;
        num -= FP_num_2;

        let num_D3 = num / FP0_001;
        'num_D3'.print();
        num_D3.print();
        let FP_num_3 = num_D3 * FP0_001;
        num -= FP_num_3;

        let num_D4 = num / FP0_0001;
        'num_D4'.print();
        num_D4.print();
        let FP_num_4 = num_D4 * FP0_0001;
        num -= FP_num_4;

        let num_D5 = num / FP0_00001;
        'num_D5'.print();
        num_D5.print();
        let FP_num_5 = num_D5 * FP0_00001;
        num -= FP_num_5;

        let sum = FP_num_1 + FP_num_2 + FP_num_3 + FP_num_4 + FP_num_5;
        'sum'.print();
        sum.print();
    }

    #[test]
    #[available_gas(200000000000)]
    fn test_pool_0_success_cases() {
        let pool_case = POOL_CASES()[0];
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_0();
        let (success_swap_cases, _) = SWAP_CASES_POOL_0();
        test_pool(pool_case, expected_cases, success_swap_cases, PRECISION);
    }

    #[test]
    #[available_gas(200000000000)]
    #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
    fn test_pool_0_panics_0() {
        let PANIC_CASE = 0;
        let pool_case = POOL_CASES()[0];
        let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_0();
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_0();
        test_pool(
            pool_case,
            array![*expected_cases[PANIC_CASE]],
            array![*panic_swap_cases[PANIC_CASE]],
            Zeroable::zero()
        );
    }

    #[test]
    #[available_gas(200000000000)]
    #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
    fn test_pool_0_panics_1() {
        let PANIC_CASE = 1;
        let pool_case = POOL_CASES()[0];
        let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_0();
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_0();
        test_pool(
            pool_case,
            array![*expected_cases[PANIC_CASE]],
            array![*panic_swap_cases[PANIC_CASE]],
            Zeroable::zero()
        );
    }
}
