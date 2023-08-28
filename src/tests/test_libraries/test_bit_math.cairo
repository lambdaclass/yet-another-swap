use integer::BoundedInt;

use fractal_swap::libraries::bit_math::BitMath::{most_significant_bit, least_significant_bit};

#[test]
#[available_gas(20000000)]
fn msb_happy_path() {
    // 1
    assert(most_significant_bit(1) == 0, 'msb should be 0');
}

#[test]
#[available_gas(20000000)]
fn msb_larger_number() {
    // 10000000
    assert(most_significant_bit(128) == 7, 'msb should be 7');
}

#[test]
#[available_gas(20000000)]
fn msb_bigger_number() {
    // 11110100001001000000
    assert(most_significant_bit(1000000) == 19, 'msb should be 19');
}

#[test]
#[available_gas(2000000000)]
fn msb_maximum_256() {
    assert(most_significant_bit(BoundedInt::max()) == 255, 'msb should be 255');
}

#[test]
#[available_gas(20000000)]
fn msb_random_number() {
    // 11000000111001
    assert(most_significant_bit(12345) == 13, 'msb should be 13');
}

#[test]
#[available_gas(20000000)]
fn lsb_happy_path() {
    // 1
    assert(least_significant_bit(1) == 0, 'lsb should be 0');
}

#[test]
#[available_gas(200000000)]
fn lsb_larger_number() {
    // 10000000
    assert(least_significant_bit(128) == 7, 'lsb should be 7');
}

#[test]
#[available_gas(200000000)]
fn lsb_bigger_number() {
    // 11110100001001000000
    assert(least_significant_bit(1000000) == 6, 'lsb should be 6');
}

#[test]
#[available_gas(200000000000)]
fn lsb_maximum_256() {
    // 
    assert(least_significant_bit(BoundedInt::max()) == 0, 'lsb should be 0');
}

#[test]
#[available_gas(20000000)]
fn lsb_random_number() {
    // 11000000111001
    let ret = least_significant_bit(12345);
    assert(ret == 0, 'lsb should be 0');
}
