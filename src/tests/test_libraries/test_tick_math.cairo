mod TickMathTest {
    mod GetSqrtRatioAtTick {
        use yas::libraries::tick_math::TickMath::{
            MIN_TICK, MAX_TICK, MAX_SQRT_RATIO, MIN_SQRT_RATIO, get_sqrt_ratio_at_tick,
        };
        use yas::numbers::fixed_point::implementations::impl_64x96::{
            ONE, MAX, FP64x96Impl, FP64x96Div, FP64x96Sub, FP64x96Mul, FP64x96PartialOrd,
            FP64x96PartialEq
        };
        use yas::numbers::fixed_point::core::{FixedTrait, FixedType};
        use yas::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};

        #[test]
        #[available_gas(200000000)]
        #[should_panic(expected: ('T',))]
        fn test_get_sqrt_ratio_at_tick_reverts_minus1() {
            let value = MIN_TICK() - IntegerTrait::<i32>::new(1, false);
            get_sqrt_ratio_at_tick(value);
        }

        #[test]
        #[available_gas(200000000)]
        #[should_panic(expected: ('T',))]
        fn test_get_sqrt_ratio_at_tick_reverts_plus1() {
            let value = MAX_TICK() + IntegerTrait::<i32>::new(1, false);
            get_sqrt_ratio_at_tick(value);
        }

        #[test]
        #[available_gas(200000000)]
        fn test_get_sqrt_ratio_at_tick_min_tick() {
            assert(
                get_sqrt_ratio_at_tick(MIN_TICK()) == FP64x96Impl::from_felt(4295128739),
                'result should be 4295128739_X96'
            );
        }

        #[test]
        #[available_gas(200000000)]
        fn test_get_sqrt_ratio_at_tick_min_plus_one() {
            let value = MIN_TICK() + IntegerTrait::<i32>::new(1, false);
            assert(
                get_sqrt_ratio_at_tick(value) == FP64x96Impl::from_felt(4295343490),
                'result should be 4295343490_X96'
            );
        }

        #[test]
        #[available_gas(200000000)]
        fn test_get_sqrt_ratio_at_tick_max_minus_1() {
            let value = MAX_TICK() - IntegerTrait::<i32>::new(1, false);
            assert(
                get_sqrt_ratio_at_tick(
                    value
                ) == FixedTrait::from_felt(1461373636630004318706518188784493106690254656249),
                'wrong ratio at tick MAX_TICK-1'
            );
        }

        #[test]
        #[available_gas(200000000)]
        fn test_get_sqrt_ratio_at_tick_max_tick() {
            assert(
                get_sqrt_ratio_at_tick(
                    MAX_TICK()
                ) == FixedTrait::from_felt(1461446703485210103287273052203988822378723970342),
                'wrong ratio at tick MAX_TICK'
            );
        }

        #[test]
        #[available_gas(200000000)]
        fn test_get_sqrt_ratio_at_tick_min_sqrt_ratio() {
            assert(
                get_sqrt_ratio_at_tick(MIN_TICK()) == FixedTrait::new(MIN_SQRT_RATIO, false),
                'wrong ratio tick MIN_SQRT_RATIO'
            );
        }

        #[test]
        #[available_gas(200000000)]
        fn test_get_sqrt_ratio_at_tick_max_sqrt_ratio() {
            assert(
                get_sqrt_ratio_at_tick(MAX_TICK()) == FixedTrait::new(MAX_SQRT_RATIO, false),
                'wrong ratio tick MAX_SQRT_RATIO'
            );
        }

        fn _check_within_ranges_get_sqrt_ratio_at_tick(
            tick: i32, expected: FixedType, err_msg: felt252
        ) {
            let res = get_sqrt_ratio_at_tick(tick);
            let diff = (res - expected).abs();
            assert(
                (diff / expected)
                    * FixedTrait::new((10 ^ 6) * ONE, false) < FixedTrait::new(ONE, false),
                err_msg
            );
        }

        // RETURN VALUES WHERE CALCULATED IN PYTHON USING:
        // format(math.sqrt((1.0001 ** tick)) * (2**96), '.96f')
        #[test]
        #[available_gas(2000000000)]
        fn test_check_within_ranges_get_sqrt_ratio_at_tick() {
            _check_within_ranges_get_sqrt_ratio_at_tick(
                IntegerTrait::<i32>::new(50, false),
                FixedTrait::from_felt(79426470787362564183332749312),
                '50'
            );
            _check_within_ranges_get_sqrt_ratio_at_tick(
                IntegerTrait::<i32>::new(100, false),
                FixedTrait::from_felt(79625275426524698543654961152),
                '100'
            );
            _check_within_ranges_get_sqrt_ratio_at_tick(
                IntegerTrait::<i32>::new(250, false),
                FixedTrait::from_felt(80224679980005204522633789440),
                '250'
            );
            _check_within_ranges_get_sqrt_ratio_at_tick(
                IntegerTrait::<i32>::new(500, false),
                FixedTrait::from_felt(81233731461782943452224290816),
                '500'
            );
            _check_within_ranges_get_sqrt_ratio_at_tick(
                IntegerTrait::<i32>::new(1000, false),
                FixedTrait::from_felt(83290069058675764276559347712),
                '1000'
            );
            _check_within_ranges_get_sqrt_ratio_at_tick(
                IntegerTrait::<i32>::new(2500, false),
                FixedTrait::from_felt(89776708723585931833226821632),
                '2500'
            );
            _check_within_ranges_get_sqrt_ratio_at_tick(
                IntegerTrait::<i32>::new(3000, false),
                FixedTrait::from_felt(92049301871180761616552558592),
                '3000'
            );
            _check_within_ranges_get_sqrt_ratio_at_tick(
                IntegerTrait::<i32>::new(4000, false),
                FixedTrait::from_felt(96768528593266295136749355008),
                '4000'
            );
            _check_within_ranges_get_sqrt_ratio_at_tick(
                IntegerTrait::<i32>::new(5000, false),
                FixedTrait::from_felt(101729702841315830865122557952),
                '5000'
            );
            _check_within_ranges_get_sqrt_ratio_at_tick(
                IntegerTrait::<i32>::new(50000, false),
                FixedTrait::from_felt(965075977352955512569221611520),
                '50000'
            );
            _check_within_ranges_get_sqrt_ratio_at_tick(
                IntegerTrait::<i32>::new(150000, false),
                FixedTrait::from_felt(143194173941191013896776541274112),
                '150000'
            );
            _check_within_ranges_get_sqrt_ratio_at_tick(
                IntegerTrait::<i32>::new(250000, false),
                FixedTrait::from_felt(21246587762904151822324099702587392),
                '250000'
            );
            _check_within_ranges_get_sqrt_ratio_at_tick(
                IntegerTrait::<i32>::new(500000, false),
                FixedTrait::from_felt(5697689776479602583788423076217614237696),
                '500000'
            );
            _check_within_ranges_get_sqrt_ratio_at_tick(
                IntegerTrait::<i32>::new(738203, false),
                FixedTrait::from_felt(847134979249810736670455374604595862878289920),
                '738203'
            );
        }
    }

    mod GetTickAtSqrtRatio {
        use yas::libraries::tick_math::TickMath::{
            MIN_TICK, MAX_TICK, MAX_SQRT_RATIO, MIN_SQRT_RATIO, get_tick_at_sqrt_ratio,
            get_sqrt_ratio_at_tick,
        };
        use yas::numbers::fixed_point::implementations::impl_64x96::{
            FP64x96Impl, FP64x96PartialOrd
        };
        use yas::numbers::fixed_point::core::{FixedTrait, FixedType};
        use yas::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};

        #[test]
        #[available_gas(2000000000)]
        #[should_panic(expected: ('R',))]
        fn test_panics_too_low() {
            let input = FixedTrait::new(MIN_SQRT_RATIO - 1, false);
            get_tick_at_sqrt_ratio(input);
        }

        #[test]
        #[available_gas(2000000000)]
        #[should_panic(expected: ('R',))]
        fn test_panics_too_high() {
            let input = FixedTrait::new(MAX_SQRT_RATIO + 1, false);
            get_tick_at_sqrt_ratio(input);
        }

        #[test]
        #[available_gas(2000000000)]
        fn test_ratio_min_tick() {
            let input = FixedTrait::new(MIN_SQRT_RATIO, false);
            let res = get_tick_at_sqrt_ratio(input);
            assert(res == MIN_TICK(), 'wrong tick at MIN_TICK');
        }

        #[test]
        #[available_gas(2000000000)]
        fn test_min_plus_one() {
            let input = FixedTrait::new(4295343490, false);
            let res = get_tick_at_sqrt_ratio(input);
            assert(
                res == (MIN_TICK() + IntegerTrait::<i32>::new(1, false)), 'wrong tick at MIN_TICK+1'
            );
        }

        #[test]
        #[available_gas(2000000000)]
        fn test_max_minus_one() {
            let input = FixedTrait::new(1461373636630004318706518188784493106690254656249, false);
            let res = get_tick_at_sqrt_ratio(input);
            assert(
                res == MAX_TICK() - IntegerTrait::<i32>::new(1, false), 'wrong tick at MIN_TICK-1'
            );
        }

        #[test]
        #[available_gas(2000000000)]
        fn test_ratio_closest_to_max_tick() {
            let input = FixedTrait::new(MAX_SQRT_RATIO - 1, false);
            let res = get_tick_at_sqrt_ratio(input);
            assert(
                res == MAX_TICK() - IntegerTrait::<i32>::new(1, false),
                'wrong tick at closest to max'
            );
        }

        fn _test_check_within_ranges_get_tick_at_sqrt_ratio(
            ratio: FixedType,
            expected: i32,
            err_msg_1: felt252,
            err_msg_2: felt252,
            err_msg_3: felt252
        ) {
            let res = get_tick_at_sqrt_ratio(ratio);
            let diff = (res - expected).abs();

            // is at most off by 1.
            assert(diff <= IntegerTrait::<i32>::new(1, false), err_msg_1);
            // ratio is between the tick and tick+1
            let ratio_of_tick = get_sqrt_ratio_at_tick(res);

            let ratio_of_tick_plus_one = get_sqrt_ratio_at_tick(
                res + IntegerTrait::<i32>::new(1, false)
            );
            assert(ratio >= ratio_of_tick, err_msg_2);
            assert(ratio < ratio_of_tick_plus_one, err_msg_3);
        }

        #[test]
        #[available_gas(200000000000)]
        fn test_check_within_ranges_get_tick_at_sqrt_ratio() {
            _test_check_within_ranges_get_tick_at_sqrt_ratio(
                FixedTrait::new(MIN_SQRT_RATIO, false),
                IntegerTrait::<i32>::new(887272, true),
                'diff 1',
                'ratio >= ratio_of_tick 1',
                'ratio < r(tick + 1) 1'
            );
            _test_check_within_ranges_get_tick_at_sqrt_ratio(
                FixedTrait::new(79228162514264337593543950340000000, false),
                IntegerTrait::<i32>::new(276324, false),
                'diff 2',
                'ratio >= ratio_of_tick 2',
                'ratio < r(tick + 1) 2'
            );

            _test_check_within_ranges_get_tick_at_sqrt_ratio(
                FixedTrait::new(79228162514264337593543950340000, false),
                IntegerTrait::<i32>::new(138162, false),
                'diff 3',
                'ratio >= ratio_of_tick 3',
                'ratio < r(tick + 1) 3'
            );

            _test_check_within_ranges_get_tick_at_sqrt_ratio(
                FixedTrait::new(9903520314283042199192993792, false),
                IntegerTrait::<i32>::new(41591, true),
                'diff 4',
                'ratio >= ratio_of_tick 4',
                'ratio < r(tick + 1) 4'
            );

            _test_check_within_ranges_get_tick_at_sqrt_ratio(
                FixedTrait::new(28011385487393069959365969113, false),
                IntegerTrait::<i32>::new(20796, true),
                'diff 5',
                'ratio >= ratio_of_tick 5',
                'ratio < r(tick + 1) 5'
            );

            _test_check_within_ranges_get_tick_at_sqrt_ratio(
                FixedTrait::new(56022770974786139918731938230, false),
                IntegerTrait::<i32>::new(6932, true),
                'diff 6',
                'ratio >= ratio_of_tick 6',
                'ratio < r(tick + 1) 6'
            );

            _test_check_within_ranges_get_tick_at_sqrt_ratio(
                FixedTrait::new(79228162514264337593543950340, false),
                IntegerTrait::<i32>::new(0, false),
                'diff 7',
                'ratio >= ratio_of_tick 7',
                'ratio < r(tick + 1) 7'
            );

            _test_check_within_ranges_get_tick_at_sqrt_ratio(
                FixedTrait::new(112045541949572279837463876400, false),
                IntegerTrait::<i32>::new(6931, false),
                'diff 8',
                'ratio >= ratio_of_tick 8',
                'ratio < r(tick + 1) 8'
            );

            _test_check_within_ranges_get_tick_at_sqrt_ratio(
                FixedTrait::new(224091083899144559674927752900, false),
                IntegerTrait::<i32>::new(20795, false),
                'diff 9',
                'ratio >= ratio_of_tick 9',
                'ratio < r(tick + 1) 9'
            );

            _test_check_within_ranges_get_tick_at_sqrt_ratio(
                FixedTrait::new(633825300114114700748351602700, false),
                IntegerTrait::<i32>::new(41590, false),
                'diff 10',
                'ratio >= ratio_of_tick 10',
                'ratio < r(tick + 1) 10'
            );

            _test_check_within_ranges_get_tick_at_sqrt_ratio(
                FixedTrait::new(79228162514264337593543950, false),
                IntegerTrait::<i32>::new(138163, true),
                'diff 11',
                'ratio >= ratio_of_tick 11',
                'ratio < r(tick + 1) 11'
            );

            _test_check_within_ranges_get_tick_at_sqrt_ratio(
                FixedTrait::new(79228162514264337593543, false),
                IntegerTrait::<i32>::new(276325, true),
                'diff 12',
                'ratio >= ratio_of_tick 12',
                'ratio < r(tick + 1) 12'
            );

            _test_check_within_ranges_get_tick_at_sqrt_ratio(
                FixedTrait::new(MAX_SQRT_RATIO - 1, false),
                IntegerTrait::<i32>::new(887272, false),
                'diff 13',
                'ratio >= ratio_of_tick 13',
                'ratio < r(tick + 1) 13'
            );
        }
    }

    mod BitWise {
        use yas::numbers::signed_integer::{i256::{i256, bitwise_or}, integer_trait::IntegerTrait};

        #[test]
        #[available_gas(2000000000)]
        fn test_bitwise_or() {
            let a: u32 = 123123;
            let b = 432432;
            let res = 522739;
            assert((a | b) == res, 'result should be 522739');

            let a = IntegerTrait::<i256>::new(123456789, true);
            let b = IntegerTrait::<i256>::new(987654321, true);
            let res = 39471121;

            assert(bitwise_or(a, b).mag == res, 'result should be 39471121');
            let a = IntegerTrait::<i256>::new(123456789, false);
            let b = IntegerTrait::<i256>::new(987654321, false);
            let res = 1071639989;

            assert(bitwise_or(a, b).mag == res, 'result should be 1071639989');

            let a = IntegerTrait::<i256>::new(123456789, true);
            let b = IntegerTrait::<i256>::new(987654321, false);
            let res = 83985669;

            assert(bitwise_or(a, b).mag == res, 'result should be 83985669');

            let a = IntegerTrait::<i256>::new(123456789, false);
            let b = IntegerTrait::<i256>::new(987654321, true);
            let res = 948183201;

            assert(bitwise_or(a, b).mag == res, 'result should be 948183201');
        }
    }

    mod AsI24 {
        use yas::libraries::tick_math::TickMath::as_i24;
        use yas::numbers::signed_integer::{i32::i32, i256::i256, integer_trait::IntegerTrait};
        use yas::utils::math_utils::BitShift::BitShiftTrait;

        #[test]
        #[available_gas(200000000)]
        fn test_as_i24_within_range() {
            let a_i32 = IntegerTrait::<i32>::new(0, false);
            let a_i256 = IntegerTrait::<i256>::new(0, false);
            assert(a_i32 == as_i24(a_i256), '0 == as_i24(0)');

            let a_i32 = IntegerTrait::<i32>::new(1, false);
            let a_i256 = IntegerTrait::<i256>::new(1, false);
            assert(a_i32 == as_i24(a_i256), '1 == as_i24(1)');

            let a_i32 = IntegerTrait::<i32>::new(1, true);
            let a_i256 = IntegerTrait::<i256>::new(1, true);
            assert(a_i32 == as_i24(a_i256), '-1 == as_i24(-1)');

            let a_i32 = IntegerTrait::<i32>::new(123321, false);
            let a_i256 = IntegerTrait::<i256>::new(123321, false);
            assert(a_i32 == as_i24(a_i256), '123321 == as_i24(123321)');

            let a_i32 = IntegerTrait::<i32>::new(123321, true);
            let a_i256 = IntegerTrait::<i256>::new(123321, true);
            assert(a_i32 == as_i24(a_i256), '-123321 == as_i24(-123321)');

            // MAX
            let a_i32 = IntegerTrait::<i32>::new(8388607, false);
            let a_i256 = IntegerTrait::<i256>::new(8388607, false);
            assert(a_i32 == as_i24(a_i256), '8388607 == as_i24(8388607)');

            // MIN
            let a_i32 = IntegerTrait::<i32>::new(8388607, true);
            let a_i256 = IntegerTrait::<i256>::new(8388607, true);
            assert(a_i32 == as_i24(a_i256), '-8388607 == as_i24(-8388607)');
        }

        #[test]
        #[available_gas(200000000)]
        fn test_as_i24_out_of_range() {
            let max_u32: u32 = ((1_u256.shl(23)) - 1).try_into().unwrap();
            let max: i32 = IntegerTrait::<i32>::new(max_u32, false);
            let min: i32 = IntegerTrait::<i32>::new(max_u32, true);

            // MAX + 1
            let a_i256 = IntegerTrait::<i256>::new(8388607 + 1, false);
            assert(min <= as_i24(a_i256) && as_i24(a_i256) <= max, 'min <= i24(max+1) <= max');

            // MIN - 1
            let a_i256 = IntegerTrait::<i256>::new(8388607 + 1, true);
            assert(min <= as_i24(a_i256) && as_i24(a_i256) <= max, 'min <= i24(min-1) <= max');

            let a_i256 = IntegerTrait::<i256>::new(1073741824, true);
            assert(min <= as_i24(a_i256) && as_i24(a_i256) <= max, 'min <= i24(-large) <= max');

            let a_i256 = IntegerTrait::<i256>::new(1073741824, false);
            assert(min <= as_i24(a_i256) && as_i24(a_i256) <= max, 'min <= i24(large) <= max');
        }
    }

    mod IsGtAsInt {
        use yas::libraries::tick_math::TickMath::is_gt_as_int;

        #[test]
        fn test_a_gt_b() {
            assert(is_gt_as_int(10, 2) == 1, 'a > b result should be 1');
        }

        #[test]
        fn test_a_lt_b() {
            assert(is_gt_as_int(5, 10) == 0, 'a < b result should be 0');
        }

        #[test]
        fn test_a_eq_b() {
            assert(is_gt_as_int(5, 5) == 0, 'a == b result should be 0');
        }
    }
}
