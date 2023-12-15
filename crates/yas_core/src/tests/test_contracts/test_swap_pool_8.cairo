mod PoolCase8 {
    use yas_core::tests::utils::swap_helper::SwapTestHelper::test_pool;
    use yas_core::tests::utils::pool_8::{SWAP_CASES_POOL_8, SWAP_EXPECTED_RESULTS_POOL_8};
    use yas_core::tests::utils::swap_cases::SwapTestHelper::POOL_CASES;
    use debug::PrintTrait;

    const PRECISION: u256 = 5;

    #[test]
    #[available_gas(200000000000)]
    fn test_pool_8_success_cases() {
        let pool_case = POOL_CASES()[8];
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_8();
        let (success_swap_cases, _) = SWAP_CASES_POOL_8();
        test_pool(pool_case, expected_cases, success_swap_cases, PRECISION);
    }

    #[test]
    #[available_gas(200000000000)]
    #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
    fn test_pool_8_panics_0() {
        let PANIC_CASE = 0;
        let pool_case = POOL_CASES()[8];
        let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_8();
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_8();
        test_pool(
            pool_case,
            array![*expected_cases[PANIC_CASE]],
            array![*panic_swap_cases[PANIC_CASE]],
            PRECISION
        );
    }
    #[test]
    #[available_gas(200000000000)]
    #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
    fn test_pool_8_panics_1() {
        let PANIC_CASE = 1;
        let pool_case = POOL_CASES()[8];
        let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_8();
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_8();
        test_pool(
            pool_case,
            array![*expected_cases[PANIC_CASE]],
            array![*panic_swap_cases[PANIC_CASE]],
            PRECISION
        );
    }
}
