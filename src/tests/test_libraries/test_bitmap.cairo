use array::ArrayTrait;
use core::result::ResultTrait;
use core::traits::Into;
use option::OptionTrait;
use starknet::syscalls::deploy_syscall;
use traits::TryInto;

use orion::numbers::signed_integer::i32::i32;
use orion::numbers::signed_integer::i16::i16;
use orion::numbers::signed_integer::integer_trait::IntegerTrait;

use fractal_swap::libraries::tick_bitmap::{
    TickBitmap, ITickBitmap, ITickBitmapDispatcher, ITickBitmapDispatcherTrait
};
use fractal_swap::libraries::tick_bitmap::TickBitmap::InternalFunctions;

fn deploy() -> ITickBitmapDispatcher {
    let calldata: Array<felt252> = ArrayTrait::new();
    let (address, _) = deploy_syscall(
        TickBitmap::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), true
    )
        .expect('DEPLOY_FAILED');
    return (ITickBitmapDispatcher { contract_address: address });
}

fn init_ticks(tick_bitmap: ITickBitmapDispatcher) {
    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(200, true), IntegerTrait::<i32>::new(1, false));
    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(55, true), IntegerTrait::<i32>::new(1, false));
    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(4, true), IntegerTrait::<i32>::new(1, false));
    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(70, false), IntegerTrait::<i32>::new(1, false));
    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(78, false), IntegerTrait::<i32>::new(1, false));
    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(84, false), IntegerTrait::<i32>::new(1, false));
    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(139, false), IntegerTrait::<i32>::new(1, false));
    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(240, false), IntegerTrait::<i32>::new(1, false));
    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(535, false), IntegerTrait::<i32>::new(1, false));
}

// #isInitialized
#[test]
#[available_gas(30000000)]
fn test_is_false_at_first() {
    let tick_bitmap = deploy();

    assert(tick_bitmap.is_initialized(IntegerTrait::<i32>::new(1, false)) == false, '');
}

#[test]
#[available_gas(30000000)]
fn test_is_flipped_by_flip_tick() {
    let tick_bitmap = deploy();

    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(1, false), IntegerTrait::<i32>::new(1, false));

    assert(tick_bitmap.is_initialized(IntegerTrait::<i32>::new(1, false)) == true, '');
}

#[test]
#[available_gas(30000000)]
fn test_is_flipped_back_by_flip_tick() {
    let tick_bitmap = deploy();

    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(1, false), IntegerTrait::<i32>::new(1, false));
    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(1, false), IntegerTrait::<i32>::new(1, false));

    assert(tick_bitmap.is_initialized(IntegerTrait::<i32>::new(1, false)) == false, '');
}

#[test]
#[available_gas(30000000)]
fn test_is_not_changed_by_another_flip_to_a_different_tick() {
    let tick_bitmap = deploy();

    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(2, false), IntegerTrait::<i32>::new(1, false));

    assert(tick_bitmap.is_initialized(IntegerTrait::<i32>::new(1, false)) == false, '');
}

#[test]
#[available_gas(30000000)]
fn test_is_not_changed_by_another_flip_to_a_different_tick_on_another_word() {
    let tick_bitmap = deploy();

    tick_bitmap
        .flip_tick(IntegerTrait::<i32>::new(1 + 256, false), IntegerTrait::<i32>::new(1, false));

    assert(tick_bitmap.is_initialized(IntegerTrait::<i32>::new(257, false)) == true, '');
    assert(tick_bitmap.is_initialized(IntegerTrait::<i32>::new(1, false)) == false, '');
}

// #flipTick
#[test]
#[available_gas(30000000)]
fn test_flips_only_the_specified_tick() {
    let tick_bitmap = deploy();

    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(230, true), IntegerTrait::<i32>::new(1, false));
    assert(tick_bitmap.is_initialized(IntegerTrait::<i32>::new(230, true)) == true, '');
    assert(tick_bitmap.is_initialized(IntegerTrait::<i32>::new(231, true)) == false, '');
    assert(tick_bitmap.is_initialized(IntegerTrait::<i32>::new(229, true)) == false, '');
    assert(tick_bitmap.is_initialized(IntegerTrait::<i32>::new(256 - 230, false)) == false, '');
    assert(tick_bitmap.is_initialized(IntegerTrait::<i32>::new(230 + 256, true)) == false, '');

    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(230, true), IntegerTrait::<i32>::new(1, false));
    assert(tick_bitmap.is_initialized(IntegerTrait::<i32>::new(230, true)) == false, '');
    assert(tick_bitmap.is_initialized(IntegerTrait::<i32>::new(231, true)) == false, '');
    assert(tick_bitmap.is_initialized(IntegerTrait::<i32>::new(229, true)) == false, '');
    assert(tick_bitmap.is_initialized(IntegerTrait::<i32>::new(256 - 230, false)) == false, '');
    assert(tick_bitmap.is_initialized(IntegerTrait::<i32>::new(230 + 256, true)) == false, '');
}

#[test]
#[available_gas(30000000)]
fn test_reverts_only_itself() {
    let tick_bitmap = deploy();

    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(230, true), IntegerTrait::<i32>::new(1, false));
    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(259, true), IntegerTrait::<i32>::new(1, false));
    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(229, true), IntegerTrait::<i32>::new(1, false));
    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(500, false), IntegerTrait::<i32>::new(1, false));
    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(259, true), IntegerTrait::<i32>::new(1, false));
    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(229, true), IntegerTrait::<i32>::new(1, false));
    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(259, true), IntegerTrait::<i32>::new(1, false));

    assert(tick_bitmap.is_initialized(IntegerTrait::<i32>::new(259, true)) == true, '');
    assert(tick_bitmap.is_initialized(IntegerTrait::<i32>::new(229, true)) == false, '');
}

// #nextInitializedTickWithinOneWord

// lte = false
#[test]
#[available_gas(300000000)]
fn test_returns_tick_to_right_if_at_initialized_tick() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);

    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(78, false), IntegerTrait::<i32>::new(1, false), false
        );

    assert(next == IntegerTrait::<i32>::new(84, false), '');
    assert(initialized == true, '');
}

#[test]
#[available_gas(300000000)]
fn test_returns_tick_to_right_if_at_initialized_tick_2() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);
    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(55, true), IntegerTrait::<i32>::new(1, false), false
        );

    assert(next == IntegerTrait::<i32>::new(4, true), '');
    assert(initialized == true, '');
}

#[test]
#[available_gas(300000000)]
fn test_returns_the_tick_directly_to_the_right() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);
    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(77, false), IntegerTrait::<i32>::new(1, false), false
        );

    assert(next == IntegerTrait::<i32>::new(78, false), '');
    assert(initialized == true, '');
}

#[test]
#[available_gas(3000000000)]
fn test_returns_the_tick_directly_to_the_right_2() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);
    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(56, true), IntegerTrait::<i32>::new(1, false), false
        );

    assert(next == IntegerTrait::<i32>::new(55, true), '');
    assert(initialized == true, '');
}

#[test]
#[available_gas(3000000000)]
fn test_returns_the_next_words_initialized_tick_if_on_the_right_boundary() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);
    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(255, false), IntegerTrait::<i32>::new(1, false), false
        );

    assert(next == IntegerTrait::<i32>::new(511, false), '');
    assert(initialized == false, '');
}

#[test]
#[available_gas(300000000)]
fn test_returns_the_next_words_initialized_tick_if_on_the_right_boundary_2() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);
    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(257, true), IntegerTrait::<i32>::new(1, false), false
        );

    assert(next == IntegerTrait::<i32>::new(200, true), '');
    assert(initialized == true, '');
}

#[test]
#[available_gas(300000000)]
fn test_returns_the_next_initialized_tick_from_the_next_word() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);
    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(340, false), IntegerTrait::<i32>::new(1, false));
    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(328, false), IntegerTrait::<i32>::new(1, false), false
        );

    assert(next == IntegerTrait::<i32>::new(340, false), '');
    assert(initialized == true, '');
}

#[test]
#[available_gas(300000000)]
fn test_does_not_exceed_boundary() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);
    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(508, false), IntegerTrait::<i32>::new(1, false), false
        );

    assert(next == IntegerTrait::<i32>::new(511, false), '');
    assert(initialized == false, '');
}

#[test]
#[available_gas(300000000)]
fn test_skips_entire_word() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);
    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(255, false), IntegerTrait::<i32>::new(1, false), false
        );

    assert(next == IntegerTrait::<i32>::new(511, false), '');
    assert(initialized == false, '');
}

#[test]
#[available_gas(300000000)]
fn test_skips_half_word() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);
    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(383, false), IntegerTrait::<i32>::new(1, false), false
        );

    assert(next == IntegerTrait::<i32>::new(511, false), '');
    assert(initialized == false, '');
}

// // lte = true
#[test]
#[available_gas(300000000)]
fn test_returns_same_tick_if_initialized() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);
    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(78, false), IntegerTrait::<i32>::new(1, false), true
        );

    assert(next == IntegerTrait::<i32>::new(78, false), '');
    assert(initialized == true, '');
}

#[test]
#[available_gas(300000000)]
fn test_returns_tick_directly_to_the_left_of_input_tick_if_not_initialized() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);
    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(79, false), IntegerTrait::<i32>::new(1, false), true
        );

    assert(next == IntegerTrait::<i32>::new(78, false), '');
    assert(initialized == true, '');
}

#[test]
#[available_gas(300000000)]
fn test_will_not_exceed_the_word_boundary() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);
    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(258, false), IntegerTrait::<i32>::new(1, false), true
        );

    assert(next == IntegerTrait::<i32>::new(256, false), '');
    assert(initialized == false, '');
}

#[test]
#[available_gas(300000000)]
fn test_at_the_word_boundary() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);
    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(256, false), IntegerTrait::<i32>::new(1, false), true
        );

    assert(next == IntegerTrait::<i32>::new(256, false), '');
    assert(initialized == false, '');
}

#[test]
#[available_gas(300000000)]
fn test_word_boundary_less_1() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);
    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(72, false), IntegerTrait::<i32>::new(1, false), true
        );

    assert(next == IntegerTrait::<i32>::new(70, false), '');
    assert(initialized == true, '');
}

#[test]
#[available_gas(300000000)]
fn test_word_boundary() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);
    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(257, true), IntegerTrait::<i32>::new(1, false), true
        );

    assert(next == IntegerTrait::<i32>::new(512, true), '');
    assert(initialized == false, '');
}

#[test]
#[available_gas(300000000)]
fn test_entire_empty_word() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);
    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(1023, false), IntegerTrait::<i32>::new(1, false), true
        );

    assert(next == IntegerTrait::<i32>::new(768, false), '');
    assert(initialized == false, '');
}

#[test]
#[available_gas(300000000)]
fn test_halfway_through_empty_word() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);
    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(900, false), IntegerTrait::<i32>::new(1, false), true
        );

    assert(next == IntegerTrait::<i32>::new(768, false), '');
    assert(initialized == false, '');
}

#[test]
#[available_gas(300000000)]
fn test_boundary_is_initialized() {
    let tick_bitmap = deploy();

    init_ticks(tick_bitmap);
    tick_bitmap.flip_tick(IntegerTrait::<i32>::new(329, false), IntegerTrait::<i32>::new(1, false));
    let (next, initialized) = tick_bitmap
        .next_initialized_tick_within_one_word(
            IntegerTrait::<i32>::new(456, false), IntegerTrait::<i32>::new(1, false), true
        );

    assert(next == IntegerTrait::<i32>::new(329, false), '');
    assert(initialized == true, '');
}
