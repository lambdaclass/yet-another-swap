use fractal_swap::utils::math_utils::MathUtils::{BitShiftTrait};
use integer::BoundedInt;

#[test]
#[available_gas(2000000)]
fn test_shift_left_u256_1() {
    let input: u256 = 1;
    let result = input.shl(1);
    assert(result == 2, 'test_shift_left_1');
}

#[test]
#[available_gas(2000000)]
fn test_shift_left_u256_zero() {
    let input: u256 = 0;
    let result = input.shl(5);
    assert(result == 0, 'test_shift_left_zero');
}

#[test]
#[available_gas(2000000)]
fn test_shift_right_u256_1() {
    let input: u256 = 4;
    let result = input.shr(1);
    assert(result == 2, 'test_shift_left_zero');
}

#[test]
#[available_gas(2000000)]
fn test_shift_right_u256_max() {
    let input: u256 = BoundedInt::max();
    let result = input.shr(1);
    assert(result == BoundedInt::max() / 2, 'test_shift_left_zero');
}

#[test]
#[available_gas(2000000)]
fn test_shift_right_u256_zero() {
    let input: u256 = 0;
    let result = input.shr(5);
    assert(result == 0, 'test_shift_left_zero');
}

// TODO: The current implementation does not support left shift overflow
// input: 1111 (let's assume it's the max)
// call: shift_left(BoundedInt::max(), 1);
// output: should be 1110
// #[test]
// #[available_gas(2000000)]
// fn test_shift_left_max() {
//     let result = shift_left(BoundedInt::max(), 1);
//     assert(result == BoundedInt::max() - 1, 'test_shift_left_max');
// }

#[test]
#[available_gas(2000000)]
fn test_shift_left_u32_1() {
    let input: u32 = 1;
    let result = input.shl(1);
    assert(result == 2, 'test_shift_left_1');
}

#[test]
#[available_gas(2000000)]
fn test_shift_left_u32_zero() {
    let input: u256 = 0;
    let result = input.shl(5);
    assert(result == 0, 'test_shift_left_zero');
}

#[test]
#[available_gas(2000000)]
fn test_shift_right_u32_1() {
    let input: u32 = 4;
    let result = input.shr(1);
    assert(result == 2, 'test_shift_left_zero');
}

#[test]
#[available_gas(2000000)]
fn test_shift_right_u32_max() {
    let input: u32 = BoundedInt::max();
    let result = input.shr(1);
    assert(result == BoundedInt::max() / 2, 'test_shift_left_zero');
}

#[test]
#[available_gas(2000000)]
fn test_shift_right_u32_zero() {
    let input: u32 = 0;
    let result = input.shr(5);
    assert(result == 0, 'test_shift_left_zero');
}
