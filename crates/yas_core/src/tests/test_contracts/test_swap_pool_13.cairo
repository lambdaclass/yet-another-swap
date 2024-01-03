mod PoolCase13 {
    use yas_core::tests::utils::swap_helper::SwapTestHelper::test_pool;
    use yas_core::tests::utils::pool_13::{SWAP_CASES_POOL_13, SWAP_EXPECTED_RESULTS_POOL_13};
    use yas_core::tests::utils::swap_cases::SwapTestHelper::{POOL_CASES};

    const PRECISION: u256 = 18;

    #[test]
    #[available_gas(200000000000)]
    fn test_pool_13_success_cases() {
        let pool_case = POOL_CASES()[13];
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_13();
        let (success_swap_cases, _) = SWAP_CASES_POOL_13();
        test_pool(pool_case, expected_cases, success_swap_cases, PRECISION,);
    }

    #[test]
    #[available_gas(200000000000)]
    #[should_panic(expected: ('SPL', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
    fn test_pool_13_panics_0() {
        let PANIC_CASE = 0;
        let pool_case = POOL_CASES()[13];
        let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_13();
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_13();
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
    fn test_pool_13_panics_1() {
        let PANIC_CASE = 1;
        let pool_case = POOL_CASES()[13];
        let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_13();
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_13();
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
    fn test_pool_13_panics_2() {
        let PANIC_CASE = 2;
        let pool_case = POOL_CASES()[13];
        let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_13();
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_13();
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
    fn test_pool_13_panics_3() {
        let PANIC_CASE = 3;
        let pool_case = POOL_CASES()[13];
        let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_13();
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_13();
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
    fn test_pool_13_panics_4() {
        let PANIC_CASE = 4;
        let pool_case = POOL_CASES()[13];
        let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_13();
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_13();
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
    fn test_pool_13_panics_5() {
        let PANIC_CASE = 5;
        let pool_case = POOL_CASES()[13];
        let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_13();
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_13();
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
    fn test_pool_13_panics_6() {
        let PANIC_CASE = 6;
        let pool_case = POOL_CASES()[13];
        let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_13();
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_13();
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
    fn test_pool_13_panics_7() {
        let PANIC_CASE = 7;
        let pool_case = POOL_CASES()[13];
        let (success_swap_cases, panic_swap_cases) = SWAP_CASES_POOL_13();
        let expected_cases = SWAP_EXPECTED_RESULTS_POOL_13();
        test_pool(
            pool_case,
            array![*expected_cases[PANIC_CASE]],
            array![*panic_swap_cases[PANIC_CASE]],
            Zeroable::zero()
        );
    }
}
