use fractal_swap::utils::math_utils::MathUtils::{shift_left, shift_right};
use integer::BoundedInt;

#[test]
#[available_gas(2000000)]
fn test_shift_left_1() {
    let result = shift_left(1, 1);
    assert(result == 2, 'test_shift_left_1');
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
fn test_shift_left_zero() {
    let result = shift_left(0, 5);
    assert(result == 0, 'test_shift_left_zero');
}

#[test]
#[available_gas(2000000)]
fn test_shift_right_1() {
    let result = shift_right(4, 1);
    assert(result == 2, 'test_shift_right_1');
}

#[test]
#[available_gas(2000000)]
fn test_shift_right_max() {
    let result = shift_right(BoundedInt::max(), 1);
    assert(result == BoundedInt::max() / 2, 'test_shift_right_max');
}

#[test]
#[available_gas(2000000)]
fn test_shift_right_zero() {
    let result = shift_right(0, 5);
    assert(result == 0, 'test_shift_right_zero');
}
