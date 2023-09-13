use yas::libraries::liquidity_math::LiquidityMath::add_delta;
use yas::numbers::signed_integer::{i128::i128, integer_trait::IntegerTrait};

#[test]
#[available_gas(2000000)]
fn test_add_delta_5_10() {
    let y = IntegerTrait::<i128>::new(10, false);
    let z = add_delta(5, y);
    assert(z == 15, 'z == 15');
}

#[test]
#[available_gas(2000000)]
fn test_add_delta_1_0() {
    let y = IntegerTrait::<i128>::new(0, false);
    let z = add_delta(1, y);
    assert(z == 1, 'z == 1');
}
#[test]
#[available_gas(2000000)]
fn test_add_delta_1_minus1() {
    let y = IntegerTrait::<i128>::new(1, true);
    let z = add_delta(1, y);
    assert(z == 0, 'z == 0');
}
#[test]
#[available_gas(2000000)]
fn test_add_delta_1_1() {
    let y = IntegerTrait::<i128>::new(1, false);
    let z = add_delta(1, y);
    assert(z == 2, 'z == 2');
}
#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('LA',))]
// Should panic with 'LA'.
fn test_add_delta_overflows() {
    let x: u128 = 340282366920938463463374607431768211455; // 2 ** 128 - 1
    let x = x - 14;
    let y = IntegerTrait::<i128>::new(15, false);
    add_delta(x, y);
}
#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('LS',))]
// Should panic with 'LS'.
fn test_add_delta_0_minus1_underflows() {
    let y = IntegerTrait::<i128>::new(1, true);
    add_delta(0, y);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('LS',))]
// Should panic with 'LS'.
fn test_add_delta_3_minus4_underflows() {
    let y = IntegerTrait::<i128>::new(4, true);
    add_delta(3, y);
}
