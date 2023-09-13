mod TickBitmapTests {
    use yas::libraries::tick_bitmap::TickBitmap;
    use yas::libraries::tick_bitmap::TickBitmap::TickBitmapImpl;
    use yas::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};

    fn STATE() -> TickBitmap::ContractState {
        TickBitmap::contract_state_for_testing()
    }

    fn init_ticks(ref state: TickBitmap::ContractState) {
        TickBitmapImpl::flip_tick(
            ref state, IntegerTrait::<i32>::new(200, true), IntegerTrait::<i32>::new(1, false)
        );
        TickBitmapImpl::flip_tick(
            ref state, IntegerTrait::<i32>::new(55, true), IntegerTrait::<i32>::new(1, false)
        );
        TickBitmapImpl::flip_tick(
            ref state, IntegerTrait::<i32>::new(4, true), IntegerTrait::<i32>::new(1, false)
        );
        TickBitmapImpl::flip_tick(
            ref state, IntegerTrait::<i32>::new(70, false), IntegerTrait::<i32>::new(1, false)
        );
        TickBitmapImpl::flip_tick(
            ref state, IntegerTrait::<i32>::new(78, false), IntegerTrait::<i32>::new(1, false)
        );
        TickBitmapImpl::flip_tick(
            ref state, IntegerTrait::<i32>::new(84, false), IntegerTrait::<i32>::new(1, false)
        );
        TickBitmapImpl::flip_tick(
            ref state, IntegerTrait::<i32>::new(139, false), IntegerTrait::<i32>::new(1, false)
        );
        TickBitmapImpl::flip_tick(
            ref state, IntegerTrait::<i32>::new(240, false), IntegerTrait::<i32>::new(1, false)
        );
        TickBitmapImpl::flip_tick(
            ref state, IntegerTrait::<i32>::new(535, false), IntegerTrait::<i32>::new(1, false)
        );
    }

    mod IsInitialized {
        use super::{init_ticks, STATE};

        use yas::libraries::tick_bitmap::TickBitmap::{TickBitmapImpl, InternalImpl};
        use yas::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};

        #[test]
        #[available_gas(30000000)]
        fn test_is_false_at_first() {
            let state = STATE();

            assert(
                InternalImpl::is_initialized(@state, IntegerTrait::<i32>::new(1, false)) == false,
                'is_initialized should be true'
            );
        }

        #[test]
        #[available_gas(30000000)]
        fn test_is_flipped_by_flip_tick() {
            let mut state = STATE();

            TickBitmapImpl::flip_tick(
                ref state, IntegerTrait::<i32>::new(1, false), IntegerTrait::<i32>::new(1, false)
            );

            assert(
                InternalImpl::is_initialized(@state, IntegerTrait::<i32>::new(1, false)) == true,
                'is_initialized should be true'
            );
        }

        #[test]
        #[available_gas(30000000)]
        fn test_is_flipped_back_by_flip_tick() {
            let mut state = STATE();

            TickBitmapImpl::flip_tick(
                ref state, IntegerTrait::<i32>::new(1, false), IntegerTrait::<i32>::new(1, false)
            );
            TickBitmapImpl::flip_tick(
                ref state, IntegerTrait::<i32>::new(1, false), IntegerTrait::<i32>::new(1, false)
            );

            assert(
                InternalImpl::is_initialized(@state, IntegerTrait::<i32>::new(1, false)) == false,
                'is_initialized should be false'
            );
        }

        #[test]
        #[available_gas(30000000)]
        fn test_is_not_changed_by_another_flip_to_a_different_tick() {
            let mut state = STATE();

            TickBitmapImpl::flip_tick(
                ref state, IntegerTrait::<i32>::new(2, false), IntegerTrait::<i32>::new(1, false)
            );

            assert(
                InternalImpl::is_initialized(@state, IntegerTrait::<i32>::new(1, false)) == false,
                'is_initialized should be false'
            );
        }

        #[test]
        #[available_gas(30000000)]
        fn test_is_not_changed_by_another_flip_to_a_different_tick_on_another_word() {
            let mut state = STATE();

            TickBitmapImpl::flip_tick(
                ref state,
                IntegerTrait::<i32>::new(1 + 256, false),
                IntegerTrait::<i32>::new(1, false)
            );

            assert(
                InternalImpl::is_initialized(@state, IntegerTrait::<i32>::new(257, false)) == true,
                'is_initialized should be true'
            );
            assert(
                InternalImpl::is_initialized(@state, IntegerTrait::<i32>::new(1, false)) == false,
                'is_initialized should be false'
            );
        }
    }

    mod FlipTick {
        use super::STATE;

        use yas::libraries::tick_bitmap::TickBitmap::{TickBitmapImpl, InternalImpl};
        use yas::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};

        #[test]
        #[available_gas(300000000)]
        fn test_flips_only_the_specified_tick() {
            let mut state = STATE();

            TickBitmapImpl::flip_tick(
                ref state, IntegerTrait::<i32>::new(230, true), IntegerTrait::<i32>::new(1, false)
            );
            assert(
                InternalImpl::is_initialized(@state, IntegerTrait::<i32>::new(230, true)) == true,
                'is_initialized should be true'
            );
            assert(
                InternalImpl::is_initialized(@state, IntegerTrait::<i32>::new(231, true)) == false,
                'is_initialized should be false'
            );
            assert(
                InternalImpl::is_initialized(@state, IntegerTrait::<i32>::new(229, true)) == false,
                'is_initialized should be false'
            );
            assert(
                InternalImpl::is_initialized(
                    @state, IntegerTrait::<i32>::new(256 - 230, false)
                ) == false,
                'is_initialized should be false'
            );
            assert(
                InternalImpl::is_initialized(
                    @state, IntegerTrait::<i32>::new(230 + 256, true)
                ) == false,
                'is_initialized should be false'
            );

            TickBitmapImpl::flip_tick(
                ref state, IntegerTrait::<i32>::new(230, true), IntegerTrait::<i32>::new(1, false)
            );
            assert(
                InternalImpl::is_initialized(@state, IntegerTrait::<i32>::new(230, true)) == false,
                'is_initialized should be false'
            );
            assert(
                InternalImpl::is_initialized(@state, IntegerTrait::<i32>::new(231, true)) == false,
                'is_initialized should be false'
            );
            assert(
                InternalImpl::is_initialized(@state, IntegerTrait::<i32>::new(229, true)) == false,
                'is_initialized should be false'
            );
            assert(
                InternalImpl::is_initialized(
                    @state, IntegerTrait::<i32>::new(256 - 230, false)
                ) == false,
                'is_initialized should be false'
            );
            assert(
                InternalImpl::is_initialized(
                    @state, IntegerTrait::<i32>::new(230 + 256, true)
                ) == false,
                'is_initialized should be false'
            );
        }

        #[test]
        #[available_gas(300000000)]
        fn test_reverts_only_itself() {
            let mut state = STATE();

            TickBitmapImpl::flip_tick(
                ref state, IntegerTrait::<i32>::new(230, true), IntegerTrait::<i32>::new(1, false)
            );
            TickBitmapImpl::flip_tick(
                ref state, IntegerTrait::<i32>::new(259, true), IntegerTrait::<i32>::new(1, false)
            );
            TickBitmapImpl::flip_tick(
                ref state, IntegerTrait::<i32>::new(229, true), IntegerTrait::<i32>::new(1, false)
            );
            TickBitmapImpl::flip_tick(
                ref state, IntegerTrait::<i32>::new(500, false), IntegerTrait::<i32>::new(1, false)
            );
            TickBitmapImpl::flip_tick(
                ref state, IntegerTrait::<i32>::new(259, true), IntegerTrait::<i32>::new(1, false)
            );
            TickBitmapImpl::flip_tick(
                ref state, IntegerTrait::<i32>::new(229, true), IntegerTrait::<i32>::new(1, false)
            );
            TickBitmapImpl::flip_tick(
                ref state, IntegerTrait::<i32>::new(259, true), IntegerTrait::<i32>::new(1, false)
            );

            assert(
                InternalImpl::is_initialized(@state, IntegerTrait::<i32>::new(259, true)) == true,
                'is_initialized should be '
            );
            assert(
                InternalImpl::is_initialized(@state, IntegerTrait::<i32>::new(229, true)) == false,
                'is_initialized should be '
            );
        }

        #[test]
        #[available_gas(3000000)]
        #[should_panic]
        fn test_tick_is_spaced() {
            let mut state = STATE();

            let n = IntegerTrait::<i32>::new(3, true);
            let m = IntegerTrait::<i32>::new(2, false);

            TickBitmapImpl::flip_tick(ref state, n, m);
        }
    }

    // lte = false
    mod NextInitializedTickWithinOneWordToTheRight {
        use super::{init_ticks, STATE};

        use yas::libraries::tick_bitmap::TickBitmap::{TickBitmapImpl, InternalImpl};
        use yas::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};

        #[test]
        #[available_gas(300000000)]
        fn test_returns_tick_to_right_if_at_initialized_tick() {
            let mut state = STATE();

            init_ticks(ref state);

            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(78, false),
                IntegerTrait::<i32>::new(1, false),
                false
            );

            assert(next == IntegerTrait::<i32>::new(84, false), 'next should be 84');
            assert(initialized == true, 'initialized should be true');
        }

        #[test]
        #[available_gas(300000000)]
        fn test_returns_tick_to_right_if_at_initialized_tick_2() {
            let mut state = STATE();

            init_ticks(ref state);
            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(55, true),
                IntegerTrait::<i32>::new(1, false),
                false
            );
            assert(next == IntegerTrait::<i32>::new(4, true), 'next should be -4');
            assert(initialized == true, 'initialized should be true');
        }

        #[test]
        #[available_gas(300000000)]
        fn test_returns_the_tick_directly_to_the_right() {
            let mut state = STATE();

            init_ticks(ref state);
            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(77, false),
                IntegerTrait::<i32>::new(1, false),
                false
            );

            assert(next == IntegerTrait::<i32>::new(78, false), 'next should be 78');
            assert(initialized == true, 'initialized should be true');
        }

        #[test]
        #[available_gas(3000000000)]
        fn test_returns_the_tick_directly_to_the_right_2() {
            let mut state = STATE();

            init_ticks(ref state);
            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(56, true),
                IntegerTrait::<i32>::new(1, false),
                false
            );

            assert(next == IntegerTrait::<i32>::new(55, true), 'next should be -55');
            assert(initialized == true, 'initialized should be true');
        }

        #[test]
        #[available_gas(3000000000)]
        fn test_returns_the_next_words_initialized_tick_if_on_the_right_boundary() {
            let mut state = STATE();

            init_ticks(ref state);
            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(255, false),
                IntegerTrait::<i32>::new(1, false),
                false
            );

            assert(next == IntegerTrait::<i32>::new(511, false), 'next should be 511');
            assert(initialized == false, 'initialized should be false');
        }

        #[test]
        #[available_gas(300000000)]
        fn test_returns_the_next_words_initialized_tick_if_on_the_right_boundary_2() {
            let mut state = STATE();

            init_ticks(ref state);
            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(257, true),
                IntegerTrait::<i32>::new(1, false),
                false
            );

            assert(next == IntegerTrait::<i32>::new(200, true), 'next should be -200');
            assert(initialized == true, 'initialized should be true');
        }

        #[test]
        #[available_gas(300000000)]
        fn test_returns_the_next_initialized_tick_from_the_next_word() {
            let mut state = STATE();

            init_ticks(ref state);
            TickBitmapImpl::flip_tick(
                ref state, IntegerTrait::<i32>::new(340, false), IntegerTrait::<i32>::new(1, false)
            );
            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(328, false),
                IntegerTrait::<i32>::new(1, false),
                false
            );

            assert(next == IntegerTrait::<i32>::new(340, false), 'next should be 340');
            assert(initialized == true, 'initialized should be true');
        }

        #[test]
        #[available_gas(300000000)]
        fn test_does_not_exceed_boundary() {
            let mut state = STATE();

            init_ticks(ref state);
            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(508, false),
                IntegerTrait::<i32>::new(1, false),
                false
            );

            assert(next == IntegerTrait::<i32>::new(511, false), 'next should be 511');
            assert(initialized == false, 'initialized should be false');
        }

        #[test]
        #[available_gas(300000000)]
        fn test_skips_entire_word() {
            let mut state = STATE();

            init_ticks(ref state);
            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(255, false),
                IntegerTrait::<i32>::new(1, false),
                false
            );

            assert(next == IntegerTrait::<i32>::new(511, false), 'next should be 511');
            assert(initialized == false, 'initialized should be false');
        }

        #[test]
        #[available_gas(300000000)]
        fn test_skips_half_word() {
            let mut state = STATE();

            init_ticks(ref state);
            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(383, false),
                IntegerTrait::<i32>::new(1, false),
                false
            );

            assert(next == IntegerTrait::<i32>::new(511, false), 'next should be 511');
            assert(initialized == false, 'initialized should be false');
        }
    }

    // lte = true
    mod NextInitializedTickWithinOneWordToTheLeft {
        use super::{init_ticks, STATE};

        use yas::libraries::tick_bitmap::TickBitmap::{TickBitmapImpl, InternalImpl};
        use yas::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};

        #[test]
        #[available_gas(300000000)]
        fn test_returns_same_tick_if_initialized() {
            let mut state = STATE();

            init_ticks(ref state);
            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(78, false),
                IntegerTrait::<i32>::new(1, false),
                true
            );

            assert(next == IntegerTrait::<i32>::new(78, false), 'next should be 78');
            assert(initialized == true, 'initialized should be true');
        }

        #[test]
        #[available_gas(300000000)]
        fn test_returns_tick_directly_to_the_left_of_input_tick_if_not_initialized() {
            let mut state = STATE();

            init_ticks(ref state);
            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(79, false),
                IntegerTrait::<i32>::new(1, false),
                true
            );

            assert(next == IntegerTrait::<i32>::new(78, false), 'next should be 78');
            assert(initialized == true, 'initialized should be true');
        }

        #[test]
        #[available_gas(300000000)]
        fn test_will_not_exceed_the_word_boundary() {
            let mut state = STATE();

            init_ticks(ref state);
            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(258, false),
                IntegerTrait::<i32>::new(1, false),
                true
            );

            assert(next == IntegerTrait::<i32>::new(256, false), 'next should be 256');
            assert(initialized == false, 'initialized should be false');
        }

        #[test]
        #[available_gas(300000000)]
        fn test_at_the_word_boundary() {
            let mut state = STATE();

            init_ticks(ref state);
            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(256, false),
                IntegerTrait::<i32>::new(1, false),
                true
            );

            assert(next == IntegerTrait::<i32>::new(256, false), 'next should be 256');
            assert(initialized == false, 'initialized should be false');
        }

        #[test]
        #[available_gas(300000000)]
        fn test_word_boundary_less_1() {
            let mut state = STATE();

            init_ticks(ref state);
            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(72, false),
                IntegerTrait::<i32>::new(1, false),
                true
            );

            assert(next == IntegerTrait::<i32>::new(70, false), 'next should be 70');
            assert(initialized == true, 'initialized should be true');
        }

        #[test]
        #[available_gas(300000000)]
        fn test_word_boundary() {
            let mut state = STATE();

            init_ticks(ref state);
            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(257, true),
                IntegerTrait::<i32>::new(1, false),
                true
            );

            assert(next == IntegerTrait::<i32>::new(512, true), 'next should be -512');
            assert(initialized == false, 'initialized should be false');
        }

        #[test]
        #[available_gas(300000000)]
        fn test_entire_empty_word() {
            let mut state = STATE();

            init_ticks(ref state);
            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(1023, false),
                IntegerTrait::<i32>::new(1, false),
                true
            );

            assert(next == IntegerTrait::<i32>::new(768, false), 'next should be 768');
            assert(initialized == false, 'initialized should be false');
        }

        #[test]
        #[available_gas(300000000)]
        fn test_halfway_through_empty_word() {
            let mut state = STATE();

            init_ticks(ref state);
            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(900, false),
                IntegerTrait::<i32>::new(1, false),
                true
            );

            assert(next == IntegerTrait::<i32>::new(768, false), 'next should be 768');
            assert(initialized == false, 'initialized should be false');
        }

        #[test]
        #[available_gas(300000000)]
        fn test_boundary_is_initialized() {
            let mut state = STATE();

            init_ticks(ref state);
            TickBitmapImpl::flip_tick(
                ref state, IntegerTrait::<i32>::new(329, false), IntegerTrait::<i32>::new(1, false)
            );
            let (next, initialized) = TickBitmapImpl::next_initialized_tick_within_one_word(
                @state,
                IntegerTrait::<i32>::new(456, false),
                IntegerTrait::<i32>::new(1, false),
                true
            );

            assert(next == IntegerTrait::<i32>::new(329, false), 'next should be 329');
            assert(initialized == true, 'initialized should be true');
        }
    }

    mod Position {
        use yas::libraries::tick_bitmap::TickBitmap;
        use yas::numbers::signed_integer::{i16::i16, i32::i32, integer_trait::IntegerTrait};

        #[test]
        #[available_gas(30000000)]
        fn test_positive_position_at_one() {
            let (word, bit) = TickBitmap::position(IntegerTrait::<i32>::new(1, false));
            assert(word == IntegerTrait::<i16>::new(0, false), 'word should be 0');
            assert(bit == 1, 'bit should be 1');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_zero_position() {
            let (word, bit) = TickBitmap::position(IntegerTrait::<i32>::new(0, false));
            assert(word == IntegerTrait::<i16>::new(0, false), 'word should be 0');
            assert(bit == 0, 'bit should be 0');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_positive_position_at_255_boundary() {
            let (word, bit) = TickBitmap::position(IntegerTrait::<i32>::new(255, false));
            assert(word == IntegerTrait::<i16>::new(0, false), 'word should be 0');
            assert(bit == 255, 'bit should be 255');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_positive_position_beyond_255_boundary() {
            let (word, bit) = TickBitmap::position(IntegerTrait::<i32>::new(256, false));
            assert(word == IntegerTrait::<i16>::new(1, false), 'word should be 1');
            assert(bit == 0, 'bit should be 0');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_negative_position_at_minus_one() {
            let (word, bit) = TickBitmap::position(IntegerTrait::<i32>::new(1, true));
            assert(word == IntegerTrait::<i16>::new(1, true), 'word should be 1');
            assert(bit == 255, 'bit should be 255');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_negative_position_at_minus_100() {
            let (word, bit) = TickBitmap::position(IntegerTrait::<i32>::new(100, true));
            assert(word == IntegerTrait::<i16>::new(1, true), 'word should be 1');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_negative_position_at_minus_200() {
            let (word, bit) = TickBitmap::position(IntegerTrait::<i32>::new(200, true));
            assert(word == IntegerTrait::<i16>::new(1, true), 'word should be 1');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_negative_position_at_minus_256_boundary() {
            let (word, bit) = TickBitmap::position(IntegerTrait::<i32>::new(256, true));
            assert(word == IntegerTrait::<i16>::new(1, true), 'word should be 1');
            assert(bit == 0, 'bit should be 0');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_negative_position_beyond_minus_256_boundary() {
            let (word, bit) = TickBitmap::position(IntegerTrait::<i32>::new(257, true));
            assert(word == IntegerTrait::<i16>::new(2, true), 'word should be 2');
            assert(bit == 255, 'bit should be 255');
        }
    }
}
