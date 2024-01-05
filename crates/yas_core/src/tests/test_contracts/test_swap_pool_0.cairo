mod PoolCase0 {
    use yas_core::tests::utils::swap_helper::SwapTestHelper::{
        test_pool, get_decimal_significant_figures
    };
    use yas_core::tests::utils::pool_0::{SWAP_CASES_POOL_0, SWAP_EXPECTED_RESULTS_POOL_0};
    use yas_core::tests::utils::swap_cases::SwapTestHelper::POOL_CASES;
    use debug::PrintTrait;
    use yas_core::utils::math_utils::pow;

    const PRECISION: u256 = 17;

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

        // 
        // 
        let a = get_decimal_significant_figures(41297079574049379320055831, 4);
        let b = get_decimal_significant_figures(41296095147310000683882913, 4);
        'b'.print();
        b.print();

        assert(a == b, 'error');
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
