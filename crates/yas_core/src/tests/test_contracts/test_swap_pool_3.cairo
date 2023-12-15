mod PoolCase3 {
    use yas_core::tests::utils::swap_helper::SwapTestHelper::test_pool;
    use yas_core::tests::utils::pool_3::{SWAP_CASES_POOL_3, SWAP_EXPECTED_RESULTS_POOL_3};
    use yas_core::tests::utils::swap_cases::SwapTestHelper::POOL_CASES;

    const PRESICION: u256 = 5;

    #[test]
    #[available_gas(200000000000)]
    fn test_pool_3_success_cases() {
        let pool_case = POOL_CASES()[3];
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_3();
        let (success_swap_cases, _) = SWAP_CASES_POOL_3();

        test_pool(pool_case, expected_cases, success_swap_cases, PRESICION);
    }

    #[test]
    #[available_gas(200000000000)]
    #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
    fn test_pool_3_panics_0() {
        let PANIC_CASE = 0;
        let pool_case = POOL_CASES()[3];
        let (_, panic_swap_cases) = SWAP_CASES_POOL_3();
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_3();

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
    fn test_pool_3_panics_1() {
        let PANIC_CASE = 1;
        let pool_case = POOL_CASES()[3];
        let (_, panic_swap_cases) = SWAP_CASES_POOL_3();
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_3();
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
    fn test_pool_3_panics_2() {
        let PANIC_CASE = 2;
        let pool_case = POOL_CASES()[3];
        let (_, panic_swap_cases) = SWAP_CASES_POOL_3();
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_3();
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
    fn test_pool_3_panics_3() {
        let PANIC_CASE = 3;
        let pool_case = POOL_CASES()[3];
        let (_, panic_swap_cases) = SWAP_CASES_POOL_3();
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_3();
        test_pool(
            pool_case,
            array![*expected_cases[PANIC_CASE]],
            array![*panic_swap_cases[PANIC_CASE]],
            Zeroable::zero()
        );
    }
}
