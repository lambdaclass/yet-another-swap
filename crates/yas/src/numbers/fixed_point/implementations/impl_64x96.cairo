use debug::PrintTrait;

use yas::numbers::fixed_point::core::{FixedTrait, FixedType};
use yas::numbers::fixed_point::math::math_64x96;
use yas::numbers::signed_integer::{i8::i8, i32::i32};

const PRIME: felt252 = 3618502788666131213697322783095070105623107215331596699973092056135872020480;
const HALF_PRIME: felt252 =
    1809251394333065606848661391547535052811553607665798349986546028067936010240;
const ONE: u256 = 79228162514264337593543950336; // 2 ** 96
const ONE_u128: u128 = 79228162514264337593543950336; // 2 ** 96
const HALF: u128 = 39614081257132168796771975168; // 2 ** 95
const MAX: u256 = 1461501637330902918203684832716283019655932542975; // (2 ** 160) - 1
const Q96_RESOLUTION: u128 = 96;

/// IMPLS

impl FP64x96Impl of FixedTrait {
    fn new(mag: u256, sign: bool) -> FixedType {
        assert(mag <= MAX, 'fp overflow');
        return FixedType { mag: mag, sign: sign };
    }

    fn new_unscaled(mag: u256, sign: bool) -> FixedType {
        return FixedTrait::new(mag * ONE, sign);
    }

    fn from_felt(val: felt252) -> FixedType {
        let mag = _felt_abs(val).into();
        return FixedTrait::new(mag, _felt_sign(val));
    }

    fn from_unscaled_felt(val: felt252) -> FixedType {
        return FixedTrait::from_felt(val * ONE_u128.into());
    }

    fn abs(self: FixedType) -> FixedType {
        return math_64x96::abs(self);
    }

    fn ceil(self: FixedType) -> FixedType {
        return math_64x96::ceil(self);
    }


    fn floor(self: FixedType) -> FixedType {
        return math_64x96::floor(self);
    }

    fn round(self: FixedType) -> FixedType {
        return math_64x96::round(self);
    }

    fn sqrt(self: FixedType) -> FixedType {
        return math_64x96::sqrt(self);
    }
}

impl FP64x96Print of PrintTrait<FixedType> {
    fn print(self: FixedType) {
        self.sign.print();
        self.mag.print();
    }
}

impl FP64x96Into of Into<FixedType, felt252> {
    fn into(self: FixedType) -> felt252 {
        let mag_felt = self.mag.try_into().unwrap();

        if (self.sign == true) {
            return mag_felt * -1;
        } else {
            return mag_felt;
        }
    }
}

impl FP64x96PartialEq of PartialEq<FixedType> {
    #[inline(always)]
    fn eq(lhs: @FixedType, rhs: @FixedType) -> bool {
        return math_64x96::eq(*lhs, *rhs);
    }

    #[inline(always)]
    fn ne(lhs: @FixedType, rhs: @FixedType) -> bool {
        return math_64x96::ne(*lhs, *rhs);
    }
}

impl FP64x96Add of Add<FixedType> {
    fn add(lhs: FixedType, rhs: FixedType) -> FixedType {
        return math_64x96::add(lhs, rhs);
    }
}

impl FP64x96AddEq of AddEq<FixedType> {
    #[inline(always)]
    fn add_eq(ref self: FixedType, other: FixedType) {
        self = Add::add(self, other);
    }
}

impl FP64x96Sub of Sub<FixedType> {
    fn sub(lhs: FixedType, rhs: FixedType) -> FixedType {
        return math_64x96::sub(lhs, rhs);
    }
}

impl FP64x96SubEq of SubEq<FixedType> {
    #[inline(always)]
    fn sub_eq(ref self: FixedType, other: FixedType) {
        self = Sub::sub(self, other);
    }
}

impl FP64x96Mul of Mul<FixedType> {
    fn mul(lhs: FixedType, rhs: FixedType) -> FixedType {
        return math_64x96::mul(lhs, rhs);
    }
}

impl FP64x96MulEq of MulEq<FixedType> {
    #[inline(always)]
    fn mul_eq(ref self: FixedType, other: FixedType) {
        self = Mul::mul(self, other);
    }
}

impl FP64x96Div of Div<FixedType> {
    fn div(lhs: FixedType, rhs: FixedType) -> FixedType {
        return math_64x96::div(lhs, rhs);
    }
}

impl FP64x96DivEq of DivEq<FixedType> {
    #[inline(always)]
    fn div_eq(ref self: FixedType, other: FixedType) {
        self = Div::div(self, other);
    }
}

impl FP64x96PartialOrd of PartialOrd<FixedType> {
    #[inline(always)]
    fn ge(lhs: FixedType, rhs: FixedType) -> bool {
        return math_64x96::ge(lhs, rhs);
    }

    #[inline(always)]
    fn gt(lhs: FixedType, rhs: FixedType) -> bool {
        return math_64x96::gt(lhs, rhs);
    }

    #[inline(always)]
    fn le(lhs: FixedType, rhs: FixedType) -> bool {
        return math_64x96::le(lhs, rhs);
    }

    #[inline(always)]
    fn lt(lhs: FixedType, rhs: FixedType) -> bool {
        return math_64x96::lt(lhs, rhs);
    }
}

impl FP64x96Neg of Neg<FixedType> {
    #[inline(always)]
    fn neg(a: FixedType) -> FixedType {
        return math_64x96::neg(a);
    }
}

impl FP64x96TryIntoI32 of TryInto<FixedType, i32> {
    fn try_into(self: FixedType) -> Option<i32> {
        _i32_try_from_fp(self)
    }
}

impl FP64x96TryIntoI8 of TryInto<FixedType, i8> {
    fn try_into(self: FixedType) -> Option<i8> {
        _i8_try_from_fp(self)
    }
}

impl FP64x96TryIntoU32 of TryInto<FixedType, u32> {
    fn try_into(self: FixedType) -> Option<u32> {
        _u32_try_from_fp(self)
    }
}

impl FP64x96Zeroable of Zeroable<FixedType> {
    fn zero() -> FixedType {
        FP64x96Impl::new(0, false)
    }
    #[inline(always)]
    fn is_zero(self: FixedType) -> bool {
        self.mag == Zeroable::zero()
    }
    #[inline(always)]
    fn is_non_zero(self: FixedType) -> bool {
        !self.is_zero()
    }
}

/// INTERNAL

fn _felt_sign(a: felt252) -> bool {
    return integer::u256_from_felt252(a) > integer::u256_from_felt252(HALF_PRIME);
}

fn _felt_abs(a: felt252) -> felt252 {
    let a_sign = _felt_sign(a);

    if (a_sign == true) {
        return a * -1;
    } else {
        return a;
    }
}

fn _i32_try_from_fp(x: FixedType) -> Option<i32> {
    let unscaled_mag: Option<u32> = (x.mag / ONE).try_into();

    match unscaled_mag {
        Option::Some(val) => Option::Some(i32 { mag: unscaled_mag.unwrap(), sign: x.sign }),
        Option::None(_) => Option::None(())
    }
}

fn _u32_try_from_fp(x: FixedType) -> Option<u32> {
    let unscaled: Option<u32> = (x.mag / ONE).try_into();

    match unscaled {
        Option::Some(val) => Option::Some(unscaled.unwrap()),
        Option::None(_) => Option::None(())
    }
}

fn _i8_try_from_fp(x: FixedType) -> Option<i8> {
    let unscaled_mag: Option<u8> = (x.mag / ONE).try_into();

    match unscaled_mag {
        Option::Some(val) => Option::Some(i8 { mag: unscaled_mag.unwrap(), sign: x.sign }),
        Option::None(_) => Option::None(())
    }
}
