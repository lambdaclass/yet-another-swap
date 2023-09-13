use yas::numbers::fixed_point::core::{FixedTrait, FixedType};
use yas::numbers::fixed_point::implementations::impl_64x96::{
    ONE_u128, ONE, MAX, _felt_abs, _felt_sign, FP64x96Impl, FP64x96Into, FP64x96Add, FP64x96AddEq,
    FP64x96Sub, FP64x96SubEq, FP64x96Mul, FP64x96MulEq, FP64x96Div, FP64x96DivEq, FP64x96PartialOrd,
    FP64x96PartialEq
};

#[test]
fn test_new_small_decimal() {
    let a = FixedTrait::from_felt(
        (ONE_u128 / 10000000000000000000).into()
    ); // 0.00000000000000000001
    let expected = FixedTrait::from_felt(7922816251);
    assert(a == expected, 'test_new_small_decimal');
}

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
    assert(a.ceil().into() == 3 * ONE_u128.into(), 'test_ceil');
}

#[test]
fn test_floor() {
    let a = FixedTrait::from_felt(229761671291366579021277455974); // 2.9
    assert(a.floor().into() == 2 * ONE_u128.into(), 'test_floor');
}

#[test]
fn test_round_up() {
    let a = FixedTrait::from_felt(229761671291366579021277455974); // 2.9
    assert(a.round().into() == 3 * ONE_u128.into(), 'test_round_up');
}

#[test]
fn test_round_middle() {
    let a = FixedTrait::from_felt(198070406285660843983859875840); // 2.5
    assert(a.round().into() == 3 * ONE_u128.into(), 'test_round_middle');
}

#[test]
fn test_round_down() {
    let a = FixedTrait::from_felt(190147590034234410224505480806); // 2.4
    assert(a.round().into() == 2 * ONE_u128.into(), 'test_round_down');
}

#[test]
#[should_panic]
fn test_sqrt_fail() {
    let a = FixedTrait::from_unscaled_felt(-25);
    a.sqrt();
}

#[test]
fn test_sqrt_integer() {
    let a = FixedTrait::from_unscaled_felt(81);

    let actual = a.sqrt();
    let expected = FixedTrait::from_unscaled_felt(9);
    assert(actual == expected, 'test_sqrt_integer');
}

#[test]
fn test_sqrt_decimal() {
    let a = FixedTrait::from_felt(5 * ONE_u128.into());

    let actual = a.sqrt();
    // cairo output =    2.23606797749978625233 = 177159557114295437428655128576      
    // with calculator = 2.23606797749978969639 = 177159557114295710295374903243
    let expected = FixedTrait::from_felt(177159557114295437428655128576);
    assert(actual == expected, 'test_sqrt_decimal');
}

#[test]
fn test_sqrt_zero() {
    let a = FixedTrait::from_unscaled_felt(0);
    assert(a.sqrt().into() == 0, 'test_sqrt_zero');
}

#[test]
fn test_equals() {
    let a = FixedTrait::from_felt(ONE_u128.into() * 5);
    let b = FixedTrait::from_felt(ONE_u128.into() * 5);

    let actual = a == b;
    assert(actual == true, 'test_equals');
}

fn test_ne_integer() {
    let a = FixedTrait::from_unscaled_felt(25);
    let b = FixedTrait::from_unscaled_felt(25);

    let actual = a != b;
    assert(actual == false, 'test_ne_integer');
}

#[test]
fn test_ne_sign() {
    let a = FixedTrait::from_unscaled_felt(25);
    let b = FixedTrait::from_unscaled_felt(-25);

    let actual = a != b;
    assert(actual == true, 'test_ne_sign');
}

#[test]
#[available_gas(2000000)]
fn test_add_integer() {
    let a = FixedTrait::from_unscaled_felt(100);
    let b = FixedTrait::from_unscaled_felt(20);

    let actual = a + b;
    let expected = FixedTrait::from_unscaled_felt(120);
    assert(actual == expected, 'test_add_integer');
}

#[test]
#[available_gas(2000000)]
fn test_add_decimal() {
    let a = FixedTrait::from_felt((ONE_u128 / 100).into()); // 0.01
    let b = FixedTrait::from_felt((ONE_u128 / 5).into()); // 0.2

    let actual = a + b;
    //  expected = 16,637,914,127,995,510,894,644,229,570.56 = 0.21
    let expected = FixedTrait::from_felt(16637914127995510894644229570);
    assert(actual == expected, 'test_add_decimal');
}

#[test]
fn test_new_small_add_decimal() {
    let a = FixedTrait::from_felt(
        (ONE_u128 / 10000000000000000000).into()
    ); // 0.00000000000000000001
    let b = FixedTrait::from_felt((ONE_u128 / 1000000000000000000).into()); // 0.0000000000000000001

    let actual = a + b;
    // calculator = 0.00000000000000000011 = 8,715,097,876.56907713528983453696
    // cairo result = 0.00000000000000000109 = 87150978765
    let expected = FixedTrait::from_felt(87150978765);
    assert(actual == expected, 'test_new_small_add_decimal');
}

#[test]
#[available_gas(2000000)]
fn test_add_eq() {
    let mut a = FixedTrait::from_unscaled_felt(1);
    let b = FixedTrait::from_unscaled_felt(2);

    a += b;
    let expected = 3 * ONE_u128.into();
    assert(a.into() == expected, 'invalid result');
}

#[test]
#[available_gas(2000000)]
fn test_sub_integer() {
    let a = FixedTrait::from_unscaled_felt(6);
    let b = FixedTrait::from_unscaled_felt(4);

    let actual = a - b;
    let expected = FixedTrait::from_unscaled_felt(2);
    assert(actual == expected, 'test_sub_integer');
}

#[test]
#[available_gas(2000000)]
fn test_sub_integer_neg() {
    let a = FixedTrait::from_unscaled_felt(6);
    let b = FixedTrait::from_unscaled_felt(9);

    let actual = a - b;
    let expected = FixedTrait::from_unscaled_felt(-3);
    assert(actual == expected, 'test_sub_integer_neg');
}

#[test]
#[available_gas(2000000)]
fn test_sub_decimal() {
    let a = FixedTrait::from_felt((ONE_u128 / 100).into()); // 0.01
    let b = FixedTrait::from_felt((ONE_u128 / 1000).into()); // 0.001

    let actual = a - b;
    let expected = FixedTrait::from_felt(713053462628379038341895553); // 0.009
    assert(actual == expected, 'test_sub_decimal');
}

#[test]
#[available_gas(2000000)]
fn test_sub_eq() {
    let mut a = FixedTrait::from_unscaled_felt(5);
    let b = FixedTrait::from_unscaled_felt(2);
    a -= b;
    assert(a.into() == 3 * ONE_u128.into(), 'test_sub_eq');
}

#[test]
#[available_gas(2000000)]
fn test_mul_integer() {
    let a = FixedTrait::from_unscaled_felt(5);
    let b = FixedTrait::from_unscaled_felt(2);

    let actual = a * b;
    let expected = FixedTrait::from_unscaled_felt(10);
    assert(actual == expected, 'test_mul_integer');
}

#[test]
#[available_gas(2000000)]
fn test_mul_integer_swap_sign() {
    let a = FixedTrait::from_unscaled_felt(100);
    let b = FixedTrait::from_unscaled_felt(-1);

    let actual = a * b;
    let expected = FixedTrait::from_unscaled_felt(-100);
    assert(actual == expected, 'test_mul_integer_swap_sign');
}

#[test]
#[available_gas(2000000)]
fn test_mul_integer_neg() {
    let a = FixedTrait::from_unscaled_felt(-5);
    let b = FixedTrait::from_unscaled_felt(10);

    let actual = a * b;
    let expected = FixedTrait::from_unscaled_felt(-50);
    assert(actual == expected, 'test_mul_integer_neg');
}

#[test]
#[available_gas(2000000)]
fn test_mul_decimal_x_integer() {
    let a = FixedTrait::from_felt(((ONE_u128 * 2) + (ONE_u128 / 4)).into()); // 2.25
    let b = FixedTrait::from_unscaled_felt(2);

    let actual = a * b;
    let expected = FixedTrait::from_felt(356526731314189519170947776512); // 4.5
    assert(actual == expected, 'test_mul_decimal_x_integer');
}

#[test]
#[available_gas(2000000)]
fn test_mul_decimal_x_decimal() {
    let a = FixedTrait::from_felt((ONE_u128 / 4).into()); // 0.25
    let b = FixedTrait::from_felt((ONE_u128 / 2).into()); // 0.50

    let actual = a * b;
    let expected = FixedTrait::from_felt(9903520314283042199192993792); // 0.125
    assert(actual == expected, 'test_mul_decimal_x_decimal');
}

#[test]
#[available_gas(2000000)]
fn test_mul_zero() {
    let a = FixedTrait::from_unscaled_felt(0);
    let b = FixedTrait::from_felt((ONE_u128 / 2).into()); // 0.5

    let actual = a * b;
    let expected = FixedTrait::from_felt(0);
    assert(actual == expected, 'test_mul_decimal_x_decimal');
}

#[test]
#[available_gas(2000000)]
fn test_div_integer() {
    let a = FixedTrait::from_felt((10 * ONE_u128).into());
    let b = FixedTrait::from_unscaled_felt(2);

    let actual = a / b;
    let expected = FixedTrait::from_unscaled_felt(5);
    assert(actual == expected, 'test_div_integer');
}

#[test]
#[available_gas(2000000)]
fn test_div_integer_neg() {
    let a = FixedTrait::from_felt((2 * ONE_u128).into());
    let b = FixedTrait::from_unscaled_felt(-2);

    let actual = a / b;
    let expected = FixedTrait::from_unscaled_felt(-1);
    assert(actual == expected, 'test_div_integer_neg');
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
