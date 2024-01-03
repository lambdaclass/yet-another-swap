mod PoolCase0 {
    use yas_core::tests::utils::swap_helper::SwapTestHelper::test_pool;
    use yas_core::tests::utils::pool_0::{SWAP_CASES_POOL_0, SWAP_EXPECTED_RESULTS_POOL_0};
    use yas_core::tests::utils::swap_cases::SwapTestHelper::POOL_CASES;

    use yas_core::numbers::fixed_point::implementations::impl_64x96::{
        FixedType, FixedTrait, FP64x96PartialOrd, FP64x96PartialEq, FP64x96Impl, FP64x96Zeroable,
        FP64x96Div, FP64x96Mul, FP64x96SubEq, FP64x96Sub, FP64x96Add, ONE
    };

    use debug::PrintTrait;

    const PRECISION: u256 = 17;

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
