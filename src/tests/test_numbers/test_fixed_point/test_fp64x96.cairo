use debug::PrintTrait;
use option::OptionTrait;
use traits::Into;

use fractal_swap::numbers::fixed_point::core::{FixedTrait, FixedType};
use fractal_swap::numbers::fixed_point::implementations::impl_64x96::{
    ONE_u128, ONE, _felt_abs, _felt_sign, FP64x96Impl, FP64x96Into, FP64x96Add, FP64x96AddEq, FP64x96Sub,
    FP64x96SubEq, FP64x96Mul, FP64x96MulEq, FP64x96Div, FP64x96DivEq, FP64x96PartialOrd,
    FP64x96PartialEq
};

#[test]
fn test_into() {
    let a = FixedTrait::from_unscaled_felt(5);
    assert(a.into() == 5 * ONE_u128.into(), 'invalid result');
}

#[test]
fn test_sign() {
    let min = -1809251394333065606848661391547535052811553607665798349986546028067936010240;
    let max = 1809251394333065606848661391547535052811553607665798349986546028067936010240;
    assert(_felt_sign(min) == true, 'invalid result');
    assert(_felt_sign(-1) == true, 'invalid result');
    assert(_felt_sign(0) == false, 'invalid result');
    assert(_felt_sign(1) == false, 'invalid result');
    assert(_felt_sign(max) == false, 'invalid result');
}

#[test]
fn test_abs() {
    assert(_felt_abs(5) == 5, 'abs of pos should be pos');
    assert(_felt_abs(-5) == 5, 'abs of neg should be pos');
    assert(_felt_abs(0) == 0, 'abs of 0 should be 0');
}

#[test]
fn test_ceil() {
    let a = FixedTrait::from_felt(229761671291366579021277455974); // 2.9
    assert(a.ceil().into() == 3 * ONE_u128.into(), 'invalid pos decimal');
}

#[test]
fn test_floor() {
    let a = FixedTrait::from_felt(229761671291366579021277455974); // 2.9
    assert(a.floor().into() == 2 * ONE_u128.into(), 'invalid pos decimal');
}

#[test]
fn test_round() {
    let a = FixedTrait::from_felt(229761671291366579021277455974); // 2.9
    assert(a.round().into() == 3 * ONE_u128.into(), 'invalid pos decimal');
}

#[test]
#[should_panic]
fn test_sqrt_fail() {
    let a = FixedTrait::from_unscaled_felt(-25);
    a.sqrt();
}

#[test]
fn test_sqrt() {
    let a = FixedTrait::from_unscaled_felt(0);
    assert(a.sqrt().into() == 0, 'invalid zero root');
}

#[test]
fn test_eq() {
    let a = FixedTrait::from_unscaled_felt(25);
    let b = FixedTrait::from_unscaled_felt(25);
    let c = a == b;
    assert(c == true, 'invalid result');
}

#[test]
fn test_ne_() {
    let a = FixedTrait::from_unscaled_felt(25);
    let b = FixedTrait::from_unscaled_felt(25);
    let c = a != b;
    assert(c == false, 'invalid result');

    let a = FixedTrait::from_unscaled_felt(25);
    let b = FixedTrait::from_unscaled_felt(-25);
    let c = a != b;
    assert(c == true, 'invalid result');
}

#[test]
#[available_gas(2000000)]
fn test_add() {
    let a = FixedTrait::from_unscaled_felt(1);
    let b = FixedTrait::from_unscaled_felt(2);
    assert(a + b == FixedTrait::from_unscaled_felt(3), 'invalid result');
}

#[test]
#[available_gas(2000000)]
fn test_add_eq() {
    let mut a = FixedTrait::from_unscaled_felt(1);
    let b = FixedTrait::from_unscaled_felt(2);
    a += b;
    assert(a.into() == 3 * ONE_u128.into(), 'invalid result');
}

#[test]
#[available_gas(2000000)]
fn test_sub() {
    let a = FixedTrait::from_unscaled_felt(5);
    let b = FixedTrait::from_unscaled_felt(2);
    let c = a - b;
    assert(c.into() == 3 * ONE_u128.into(), 'false result invalid');
}

#[test]
#[available_gas(2000000)]
fn test_sub_eq() {
    let mut a = FixedTrait::from_unscaled_felt(5);
    let b = FixedTrait::from_unscaled_felt(2);
    a -= b;
    assert(a.into() == 3 * ONE_u128.into(), 'invalid result');
}

#[test]
#[available_gas(2000000)]
fn test_mul_pos() {
    let a = FixedTrait::from_unscaled_felt(5);
    let b = FixedTrait::from_unscaled_felt(2);
    let c = a * b;
    assert(c.into() == 10 * ONE_u128.into(), 'invalid result');

    let a = FixedTrait::from_unscaled_felt(9);
    let b = FixedTrait::from_unscaled_felt(9);
    let c = a * b;
    assert(c.into() == 81 * ONE_u128.into(), 'invalid result');

    let a = FixedTrait::from_felt(99035203142830421991929937920); // 1.25
    let b = FixedTrait::from_felt(198070406285660843983859875840); // 2.5
    let c = a * b;
    assert(c.into() == 247588007857076054979824844800, 'invalid result'); // 3.125

    let a = FixedTrait::from_unscaled_felt(0);
    let b = FixedTrait::from_felt(198070406285660843983859875840); // 2.5
    let c = a * b;
    assert(c.into() == 0, 'invalid result 4');
}

#[test]
#[available_gas(2000000)]
fn test_mul_neg() {
    let a = FixedTrait::from_unscaled_felt(5);
    let b = FixedTrait::from_unscaled_felt(-2);
    let c = a * b;
    assert(c.into() == -10 * ONE_u128.into(), 'true result invalid');
}

#[test]
#[available_gas(2000000)]
fn test_mul_eq() {
    let mut a = FixedTrait::from_unscaled_felt(5);
    let b = FixedTrait::from_unscaled_felt(-2);
    a *= b;

    let result: felt252 = a.into();
    let expected: felt252 = -10 * ONE_u128.into();
    assert(result == expected, 'invalid result');
}

#[test]
#[available_gas(2000000)]
fn test_div_integer_division() {
    let a = FixedTrait::from_felt((10 * ONE_u128).into()); 
    let b = FixedTrait::from_unscaled_felt(2);

    let actual = a / b;
    let expected = FixedTrait::from_unscaled_felt(5);
    assert(actual == expected, 'test_div_integer_division'); 
}

#[test]
#[available_gas(2000000)]
fn test_div_integer_division_neg() {
    let a = FixedTrait::from_felt((2 * ONE_u128).into()); 
    let b = FixedTrait::from_unscaled_felt(-2);

    let actual = a / b;
    let expected = FixedTrait::from_unscaled_felt(-1);
    assert(actual == expected, 'test_div_integer_division_neg'); 
}

#[test]
#[available_gas(2000000)]
fn test_div_decimal_part_dividend() {
    let a = FixedTrait::from_felt((ONE_u128 / 2).into()); // 0.5 
    let b = FixedTrait::from_unscaled_felt(3);

    let actual = a / b;
    // expected = 0.16666666666666666666 = 13,204,693,752,377,389,598,923,991,722.66666666666666666666
    let expected = FixedTrait::from_felt(13204693752377389598923991722); 
    assert(actual == expected, 'test_div_decimal_part_dividend'); 
}

#[test]
#[available_gas(2000000)]
fn test_div_decimal_part_divisor() {
    let a = FixedTrait::from_unscaled_felt(3);
    let b = FixedTrait::from_felt((ONE_u128 / 2).into()); // 0.5 
    
    let actual = a / b;
    let expected = FixedTrait::from_unscaled_felt(6); 
    assert(actual == expected, 'test_div_decimal_part_divisor'); 
}

#[test]
#[available_gas(2000000)]
fn test_div_decimal() {
    let a = FixedTrait::from_felt(((ONE_u128 * 2) + (ONE_u128 / 4)).into()); // 2.25 
    let b = FixedTrait::from_felt((ONE_u128 / 2).into()); // 0.5 
    
    let actual = a / b;
    let expected = FixedTrait::from_felt(356526731314189519170947776512); // 4.5
    assert(actual == expected, 'test_div_decimal'); 
}

#[test]
fn test_le() {
    let a = FixedTrait::from_unscaled_felt(1);
    let b = FixedTrait::from_unscaled_felt(0);
    let c = FixedTrait::from_unscaled_felt(-1);

    assert(a <= a, 'a <= a');
    assert(a <= b == false, 'a <= b');
    assert(a <= c == false, 'a <= c');

    assert(b <= a, 'b <= a');
    assert(b <= b, 'b <= b');
    assert(b <= c == false, 'b <= c');

    assert(c <= a, 'c <= a');
    assert(c <= b, 'c <= b');
    assert(c <= c, 'c <= c');
}

#[test]
fn test_lt() {
    let a = FixedTrait::from_unscaled_felt(1);
    let b = FixedTrait::from_unscaled_felt(0);
    let c = FixedTrait::from_unscaled_felt(-1);

    assert(a < a == false, 'a < a');
    assert(a < b == false, 'a < b');
    assert(a < c == false, 'a < c');

    assert(b < a, 'b < a');
    assert(b < b == false, 'b < b');
    assert(b < c == false, 'b < c');

    assert(c < a, 'c < a');
    assert(c < b, 'c < b');
    assert(c < c == false, 'c < c');
}

#[test]
fn test_ge() {
    let a = FixedTrait::from_unscaled_felt(1);
    let b = FixedTrait::from_unscaled_felt(0);
    let c = FixedTrait::from_unscaled_felt(-1);

    assert(a >= a, 'a >= a');
    assert(a >= b, 'a >= b');
    assert(a >= c, 'a >= c');

    assert(b >= a == false, 'b >= a');
    assert(b >= b, 'b >= b');
    assert(b >= c, 'b >= c');

    assert(c >= a == false, 'c >= a');
    assert(c >= b == false, 'c >= b');
    assert(c >= c, 'c >= c');
}

#[test]
fn test_gt() {
    let a = FixedTrait::from_unscaled_felt(1);
    let b = FixedTrait::from_unscaled_felt(0);
    let c = FixedTrait::from_unscaled_felt(-1);

    assert(a > a == false, 'a > a');
    assert(a > b, 'a > b');
    assert(a > c, 'a > c');

    assert(b > a == false, 'b > a');
    assert(b > b == false, 'b > b');
    assert(b > c, 'b > c');

    assert(c > a == false, 'c > a');
    assert(c > b == false, 'c > b');
    assert(c > c == false, 'c > c');
}
