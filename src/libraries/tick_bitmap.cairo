use orion::numbers::signed_integer::i32::i32;
use orion::numbers::signed_integer::i16::i16;

#[starknet::interface]
trait ITickBitmap<TStorage> {
    fn flip_tick(ref self: TStorage, tick: i32, tick_spacing: i32);
    fn next_initialized_tick_within_one_word(
        self: @TStorage, tick: i32, tick_spacing: i32, lte: bool
    ) -> (i32, bool);
    fn is_initialized(self: @TStorage, tick: i32) -> bool;
    fn position(self: @TStorage, tick: i32) -> (i16, u8);
}

#[starknet::contract]
mod TickBitmap {
    use super::ITickBitmap;

    use array::ArrayTrait;
    use integer::BoundedInt;
    use option::{OptionTrait};
    use poseidon::poseidon_hash_span;
    use serde::Serde;
    use traits::{Into, TryInto};

    use orion::numbers::signed_integer::i32::i32;
    use orion::numbers::signed_integer::i16::i16;
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;

    use fractal_swap::libraries::bit_math::BitMath;
    use fractal_swap::utils::math_utils::MathUtils::{BitShiftTrait, pow};

    use fractal_swap::utils::orion_utils::OrionUtils::{
        u8Intoi32, i32TryIntoi16, i32TryIntou8, mod_i32
    };

    #[storage]
    struct Storage {
        bitmap: LegacyMap<felt252, u256>,
    }

    #[external(v0)]
    impl TickBitmap of ITickBitmap<ContractState> {
        fn flip_tick(ref self: ContractState, tick: i32, tick_spacing: i32) {
            self._flip_tick(tick, tick_spacing);
        }

        fn next_initialized_tick_within_one_word(
            self: @ContractState, tick: i32, tick_spacing: i32, lte: bool
        ) -> (i32, bool) {
            self._next_initialized_tick_within_one_word(tick, tick_spacing, lte)
        }

        fn is_initialized(self: @ContractState, tick: i32) -> bool {
            self._is_initialized(tick)
        }

        fn position(self: @ContractState, tick: i32) -> (i16, u8) {
            self._position(tick)
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _generate_hashed_word_pos(self: @ContractState, word_pos: @i16) -> felt252 {
            let mut serialized: Array<felt252> = ArrayTrait::new();
            Serde::<i16>::serialize(word_pos, ref serialized);
            poseidon_hash_span(serialized.span())
        }

        /// Calculates the word value based on a tick input.
        /// - For ticks between 0 and 255 inclusive, it returns 0.
        /// - For ticks greater than 255, it divides the tick by 256.
        /// - For ticks less than 0 but greater than or equal to -256, it returns -1.
        /// - For other negative ticks, it divides the tick by 256 and subtracts 1.
        ///
        /// Parameters:
        /// - `tick`: An i32 input representing the tick value.
        ///
        /// Returns: An i16 value representing the calculated word.
        fn _calculate_word(self: @ContractState, tick: i32) -> i16 {
            let zero = IntegerTrait::<i32>::new(0, false);
            let one_negative = IntegerTrait::<i32>::new(1, true);
            let upper_bound = IntegerTrait::<i32>::new(255, false);
            let divisor = IntegerTrait::<i32>::new(256, false);
            let negative_lower_bound = IntegerTrait::<i32>::new(256, true);

            let result = if tick >= zero && tick <= upper_bound {
                zero
            } else if tick > upper_bound {
                tick / divisor
            } else if tick >= negative_lower_bound {
                one_negative
            } else {
                tick / divisor + one_negative
            };
            result.try_into().expect('calculate_word')
        }

        /// Calculates the bit value based on a given tick input.
        ///
        /// Parameters:
        /// - `tick`: An i32 input representing the tick value.
        /// Returns: A u8 value representing the calculated bit.
        fn _calculate_bit(self: @ContractState, tick: i32) -> u8 {
            // Using this util function because Orion returns negative reminder numbers
            let bit = mod_i32(tick, IntegerTrait::<i32>::new(256, false));
            bit.try_into().expect('calculate_bit')
        }

        /// @notice Computes the position in the mapping where the initialized bit for a tick lives
        /// @param tick The tick for which to compute the position
        /// @return word_pos The key in the mapping containing the word in which the bit is stored
        /// @return bit_pos The bit position in the word where the flag is stored
        fn _position(self: @ContractState, tick: i32) -> (i16, u8) {
            let word_pos: i16 = self._calculate_word(tick);
            let bit_pos: u8 = self._calculate_bit(tick);
            (word_pos, bit_pos)
        }

        /// @notice Flips the initialized state for a given tick from false to true, or vice versa
        /// @param self The ContractState
        /// @param tick The tick to flip
        /// @param tick_spacing The spacing between usable ticks
        fn _flip_tick(ref self: ContractState, tick: i32, tick_spacing: i32) {
            assert(
                tick % tick_spacing == IntegerTrait::<i32>::new(0, false),
                'ensure that the tick is spaced'
            );

            let (word_pos, bit_pos) = self._position(tick / tick_spacing);
            let mask: u256 = 1_u256.shl(bit_pos.into());
            let hashed_word_pos = self._generate_hashed_word_pos(@word_pos);
            let word = self.bitmap.read(hashed_word_pos);
            self.bitmap.write(hashed_word_pos, word ^ mask);
        }

        /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
        /// to the left (less than or equal to) or right (greater than) of the given tick
        /// @param self The @ContractState
        /// @param tick The starting tick
        /// @param tickSpacing The spacing between usable ticks
        /// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
        /// @return next The next initialized or uninitialized tick up to 256 ticks away from the current tick
        /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
        fn _next_initialized_tick_within_one_word(
            self: @ContractState, tick: i32, tick_spacing: i32, lte: bool
        ) -> (i32, bool) {
            let mut compressed: i32 = tick / tick_spacing;
            if (tick < IntegerTrait::<i32>::new(0, false)
                && tick % tick_spacing != IntegerTrait::<i32>::new(0, false)) {
                compressed -= IntegerTrait::<i32>::new(1, false); // round towards negative infinity
            };

            if lte {
                let (word_pos, bit_pos) = self._position(compressed);
                let word: u256 = self.bitmap.read(self._generate_hashed_word_pos(@word_pos));
                // all the 1s at or to the right of the current bitPos
                let mask: u256 = 1_u256.shl(bit_pos.into()) - 1 + 1_u256.shl(bit_pos.into());
                let masked: u256 = word & mask;

                // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
                let initialized = masked != 0;
                // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
                let next = if initialized {
                    // (compressed - int24(bit_pos - BitMath.most_significant_bit(masked))) * tick_spacing
                    (compressed - (bit_pos - BitMath::most_significant_bit(masked)).into())
                        * tick_spacing
                } else {
                    // (compressed - int24(bit_pos)) * tick_spacing
                    (compressed - bit_pos.into()) * tick_spacing
                };
                (next, initialized)
            } else {
                // start from the word of the next tick, since the current tick state doesn't matter
                let (word_pos, bit_pos) = self
                    ._position(compressed + IntegerTrait::<i32>::new(1, false));
                let word = self.bitmap.read(self._generate_hashed_word_pos(@word_pos));
                // all the 1s at or to the left of the bitPos
                let mask: u256 = ~(1_u256.shl(bit_pos.into()) - 1);
                let masked: u256 = word & mask;

                // if there are no initialized ticks to the left of the current tick, return leftmost in the word
                let initialized = masked != 0;
                // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
                let next = if initialized {
                    // (compressed + 1 + int24(BitMath::least_significant_bit(masked) - bit_pos)) * tick_spacing
                    (compressed
                        + IntegerTrait::<i32>::new(1, false)
                        + (BitMath::least_significant_bit(masked) - bit_pos).into())
                        * tick_spacing
                } else {
                    // (compressed + 1 + int24(type(uint8).max - bit_pos)) * tick_spacing
                    let max_u8: u8 = BoundedInt::max();
                    (compressed + IntegerTrait::<i32>::new(1, false) + (max_u8 - bit_pos).into())
                        * tick_spacing
                };
                (next, initialized)
            }
        }

        // returns whether the given tick is initialized
        fn _is_initialized(self: @ContractState, tick: i32) -> bool {
            let (next, initialized) = self
                ._next_initialized_tick_within_one_word(
                    tick, IntegerTrait::<i32>::new(1, false), true
                );
            if next == tick {
                initialized
            } else {
                false
            }
        }
    }
}
