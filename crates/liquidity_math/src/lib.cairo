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

    /// Add a signed liquidity delta to liquidity and revert if it overflows or underflows.
    /// Parameters:
    /// - x: The liquidity before change.
    /// - y: The delta by which liquidity should be changed.
    fn addDelta(x: u128, y: i128) -> u128 {
        if (y < 0) {
            // require((z = x - uint128(-y)) < x, 'LS');
            let y_neg_i128: i128 = 0 - y;
            let y_felt252: felt252 = y_neg_i128.into();
            let y_u128: u128 = y_felt252.try_into().unwrap();
            assert( x >= y_u128, 'LS');
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

#[test]
#[available_gas(2000000)]
fn test_addDelta_5_10() {
    let z = addDelta(5, 10);
    assert(z == 15, 'z == 15');
}

#[test]
#[available_gas(2000000)]
fn test_addDelta_1_0() {
    let z = addDelta(1, 0);
    assert(z == 1, 'z == 1');
}
#[test]
#[available_gas(2000000)]
fn test_addDelta_1_minus1() {
    let y = -1;
    let z = addDelta(1, y);
    assert(z == 0, 'z == 0');
}
#[test]
#[available_gas(2000000)]
fn test_addDelta_1_1() {
    let z = addDelta(1, 1);
    assert(z == 2, 'z == 2');
}
#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('LA', ))]
// Should panic with 'LA'.
fn test_addDelta_overflows() {
    let x: u128 = 340282366920938463463374607431768211455; // 2 ** 128 - 1
    let x = x - 14;
    addDelta(x, 15);
}
#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('LS', ))]
// Should panic with 'LS'.
fn test_addDelta_0_minus1_underflows() {
    let y = -1;
    addDelta(0, y);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('LS', ))]
// Should panic with 'LS'.
fn test_addDelta_3_minus4_underflows() {
    let y = -4;
    addDelta(3, y);
}
