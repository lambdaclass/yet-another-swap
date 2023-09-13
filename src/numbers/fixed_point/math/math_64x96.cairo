use yas::numbers::fixed_point::core::{FixedTrait, FixedType};
use yas::numbers::fixed_point::implementations::impl_64x96::{ONE, ONE_u128, MAX, HALF};
use yas::numbers::fixed_point::implementations::impl_64x96::{
    FP64x96Impl, FP64x96Add, FP64x96AddEq, FP64x96Into, FP64x96Print, FP64x96PartialEq, FP64x96Sub,
    FP64x96SubEq, FP64x96Mul, FP64x96MulEq, FP64x96Div, FP64x96DivEq, FP64x96PartialOrd, FP64x96Neg
};

/// Cf: FixedTrait::abs docstring
fn abs(a: FixedType) -> FixedType {
    return FixedTrait::new(a.mag, false);
}

/// Adds two fixed point numbers and returns the result.
///
/// # Arguments
///
/// * `a` - The first fixed point number to add.
/// * `b` - The second fixed point number to add.
///
/// # Returns
///
/// * The sum of the input fixed point numbers.
fn add(a: FixedType, b: FixedType) -> FixedType {
    return FixedTrait::from_felt(a.into() + b.into());
}

/// Cf: FixedTrait::ceil docstring
fn ceil(a: FixedType) -> FixedType {
    let (div_u128, rem_u128) = _split_unsigned(a);

    if (rem_u128 == 0_u128) {
        return a;
    } else if (a.sign == false) {
        return FixedTrait::new_unscaled((div_u128 + 1_u128).into(), false);
    } else {
        return FixedTrait::from_unscaled_felt(div_u128.into() * -1);
    }
}

/// Divides the first fixed point number by the second fixed point number and returns the result.
///
/// # Arguments
///
/// * `a` - The dividend fixed point number.
/// * `b` - The divisor fixed point number.
///
/// # Returns
///
/// * The result of the division of the input fixed point numbers.
fn div(a: FixedType, b: FixedType) -> FixedType {
    let res_sign = a.sign ^ b.sign;

    // Invert b to preserve precision as much as possible
    // TODO: replace if / when there is a felt div_rem supported
    let mul_res = integer::u256_wide_mul(a.mag, ONE);
    let b_inv = MAX / b.mag;
    let res = u256 { high: mul_res.limb1, low: mul_res.limb0 } / b.mag
        + u256 { high: mul_res.limb3, low: mul_res.limb2 } * b_inv;

    // Re-apply sign
    return FixedType { mag: res, sign: res_sign };
}

/// Checks whether two fixed point numbers are equal.
///
/// # Arguments
///
/// * `a` - The first fixed point number to compare.
/// * `b` - The second fixed point number to compare.
///
/// # Returns
///
/// * A boolean value that indicates whether the input fixed point numbers are equal.
fn eq(a: FixedType, b: FixedType) -> bool {
    return a.mag == b.mag && a.sign == b.sign;
}

/// Cf: FixedTrait::floor docstring
fn floor(a: FixedType) -> FixedType {
    let (div_u128, rem_u128) = _split_unsigned(a);

    if (rem_u128 == 0_u128) {
        return a;
    } else if (a.sign == false) {
        return FixedTrait::new_unscaled(div_u128.into(), false);
    } else {
        return FixedTrait::from_unscaled_felt(-1 * div_u128.into() - 1);
    }
}

/// Checks whether the first fixed point number is greater than or equal to the second fixed point number.
///
/// # Arguments
///
/// * `a` - The first fixed point number to compare.
/// * `b` - The second fixed point number to compare.
///
/// # Returns
///
/// * A boolean value that indicates whether the first fixed point number is greater than or equal to the second fixed point number.
fn ge(a: FixedType, b: FixedType) -> bool {
    if (a.sign != b.sign) {
        return !a.sign;
    } else {
        return a.mag == b.mag || (a.mag > b.mag) ^ a.sign;
    }
}

/// Checks whether the first fixed point number is greater than the second fixed point number.
///
/// # Arguments
///
/// * `a` - The first fixed point number to compare.
/// * `b` - The second fixed point number to compare.
///
/// # Returns
///
/// * A boolean value that indicates whether the first fixed point number is greater than the second fixed point number.
fn gt(a: FixedType, b: FixedType) -> bool {
    if (a.sign != b.sign) {
        return !a.sign;
    } else {
        return a.mag != b.mag && (a.mag > b.mag) ^ a.sign;
    }
}

/// Checks whether the first fixed point number is less than or equal to the second fixed point number.
///
/// # Arguments
///
/// * `a` - The first fixed point number to compare.
/// * `b` - The second fixed point number to compare.
///
/// # Returns
///
/// * A boolean value that indicates whether the first fixed point number is less than or equal to the second fixed point number.
fn le(a: FixedType, b: FixedType) -> bool {
    if (a.sign != b.sign) {
        return a.sign;
    } else {
        return a.mag == b.mag || (a.mag < b.mag) ^ a.sign;
    }
}

/// Checks whether the first fixed point number is less than the second fixed point number.
///
/// # Arguments
///
/// * `a` - The first fixed point number to compare.
/// * `b` - The second fixed point number to compare.
///
/// # Returns
///
/// * A boolean value that indicates whether the first fixed point number is less than the second fixed point number.
fn lt(a: FixedType, b: FixedType) -> bool {
    if (a.sign != b.sign) {
        return a.sign;
    } else {
        return a.mag != b.mag && (a.mag < b.mag) ^ a.sign;
    }
}

/// Multiplies two fixed point numbers.
///
/// # Arguments
///
/// * `a` - The first fixed point number.
/// * `b` - The second fixed point number.
///
/// # Returns
///
/// * A FixedType value representing the product of the two input numbers.
fn mul(a: FixedType, b: FixedType) -> FixedType {
    let res_sign = a.sign ^ b.sign;

    // Use u128 to multiply and shift back down
    // TODO: replace if / when there is a felt div_rem supported
    let mul_res = integer::u256_wide_mul(a.mag, b.mag);
    let res_u256 = u256 { high: mul_res.limb3, low: mul_res.limb2 }
        + (u256 { high: mul_res.limb1, low: mul_res.limb0 } / ONE);

    // Re-apply sign
    return FixedType { mag: res_u256, sign: res_sign };
}

/// Checks whether the first fixed point number is not equal to the second fixed point number.
///
/// # Arguments
///
/// * `a` - The first fixed point number to compare.
/// * `b` - The second fixed point number to compare.
///
/// # Returns
///
/// * A boolean value that indicates whether the first fixed point number is not equal to the second fixed point number.
fn ne(a: FixedType, b: FixedType) -> bool {
    return a.mag != b.mag || a.sign != b.sign;
}

/// Negates a fixed point number.
///
/// # Arguments
///
/// * `a` - The fixed point number to negate.
///
/// # Returns
///
/// * A FixedType value representing the negation of the input number.
fn neg(a: FixedType) -> FixedType {
    if (a.sign == false) {
        return FixedTrait::new(a.mag, true);
    } else {
        return FixedTrait::new(a.mag, false);
    }
}

/// Cf: FixedTrait::round docstring
fn round(a: FixedType) -> FixedType {
    let (div_u128, rem_u128) = _split_unsigned(a);

    if (HALF <= rem_u128) {
        return FixedTrait::new(ONE * (div_u128 + 1_u128).into(), a.sign);
    } else {
        return FixedTrait::new(ONE * div_u128.into(), a.sign);
    }
}

/// Important! It is advised that the current function 
/// has a precision error of at least 3 points
fn sqrt(a: FixedType) -> FixedType {
    assert(a.sign == false, 'must be positive');
    let root = integer::u256_sqrt(a.mag);
    let scale_root = integer::u256_sqrt(ONE);
    let res_u256 = root.into() * ONE / scale_root.into();
    return FixedTrait::new(res_u256, false);
}

/// Subtracts one fixed point number from another.
///
/// # Arguments
///
/// * `a` - The minuend fixed point number.
/// * `b` - The subtrahend fixed point number.
///
/// # Returns
///
/// * A fixed point number representing the result of the subtraction.
fn sub(a: FixedType, b: FixedType) -> FixedType {
    return FixedTrait::from_felt(a.into() - b.into());
}

/// INTERNAL

/// Ignores the sign and always returns false.
///
/// # Arguments
///
/// * `a` - The input fixed point number.
///
/// # Returns
///
/// * A tuple of two u128 numbers representing the division and remainder of the input number divided by `ONE`.
fn _split_unsigned(a: FixedType) -> (u128, u128) {
    let div: u256 = a.mag / ONE;
    let rem: u256 = a.mag % ONE;
    return (div.try_into().unwrap(), rem.try_into().unwrap());
}
