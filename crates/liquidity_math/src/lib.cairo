use core::result::ResultTrait;
/// Math library for liquidity
mod LiquidityMath {
    use traits::Into;
    use traits::TryInto;
    use core::traits::PartialOrd;
    use option::OptionTrait;
    use result::Result;
    use result::ResultTrait;
    use core::integer::u128_overflowing_add;
    use orion::numbers::signed_integer::i128::i128;
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;

    /// Add a signed liquidity delta to liquidity and revert if it overflows or underflows.
    /// Parameters:
    /// - x: The liquidity before change.
    /// - y: The delta by which liquidity should be changed.
    fn addDelta(x: u128, y: i128) -> u128 {
        let zero = IntegerTrait::<i128>::new(0, true);
        if (y < zero) {
            // require((z = x - uint128(-y)) < x, 'LS');
            let y_abs_i128: i128 = y.abs();
            let y_felt252: felt252 = y_abs_i128.into();
            let y_u128: u128 = y_felt252.try_into().unwrap();
            assert(x >= y_u128, 'LS');
            x - y_u128
        } else {
            // require((z = x + uint128(y)) >= x, 'LA');
            let y_felt252: felt252 = y.into();
            let y_u128: u128 = y_felt252.try_into().unwrap();
            assert(u128_overflowing_add(x, y_u128).is_ok(), 'LA');
            x + y_u128
        }
    }
}

use LiquidityMath::addDelta;
use orion::numbers::signed_integer::i128::i128;
use orion::numbers::signed_integer::integer_trait::IntegerTrait;

#[test]
#[available_gas(2000000)]
fn test_addDelta_5_10() {
    let y = IntegerTrait::<i128>::new(10, false);
    let z = addDelta(5, y);
    assert(z == 15, 'z == 15');
}

#[test]
#[available_gas(2000000)]
fn test_addDelta_1_0() {
    let y = IntegerTrait::<i128>::new(0, false);
    let z = addDelta(1, y);
    assert(z == 1, 'z == 1');
}
#[test]
#[available_gas(2000000)]
fn test_addDelta_1_minus1() {
    let y = IntegerTrait::<i128>::new(1, true);
    let z = addDelta(1, y);
    assert(z == 0, 'z == 0');
}
#[test]
#[available_gas(2000000)]
fn test_addDelta_1_1() {
    let y = IntegerTrait::<i128>::new(1, false);
    let z = addDelta(1, y);
    assert(z == 2, 'z == 2');
}
#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('LA', ))]
// Should panic with 'LA'.
fn test_addDelta_overflows() {
    let x: u128 = 340282366920938463463374607431768211455; // 2 ** 128 - 1
    let x = x - 14;
    let y = IntegerTrait::<i128>::new(15, false);
    addDelta(x, y);
}
#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('LS', ))]
// Should panic with 'LS'.
fn test_addDelta_0_minus1_underflows() {
    let y = IntegerTrait::<i128>::new(1, true);
    addDelta(0, y);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('LS', ))]
// Should panic with 'LS'.
fn test_addDelta_3_minus4_underflows() {
    let y = IntegerTrait::<i128>::new(4, true);
    addDelta(3, y);
}
