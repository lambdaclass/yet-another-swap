mod MathUtils {
    use traits::{Into, TryInto};
    use option::OptionTrait;

    trait BitShiftTrait<T> {
        fn shl(ref self: T, n: T) -> T;
        fn shr(ref self: T, n: T) -> T;
    }

    impl U256BitShift of BitShiftTrait<u256> {
        #[inline(always)]
        fn shl(ref self: u256, n: u256) -> u256 {
            self * pow(2, n)
        }

        #[inline(always)]
        fn shr(ref self: u256, n: u256) -> u256 {
            self / pow(2, n)
        }
    }

    impl U128BitShift of BitShiftTrait<u128> {
        #[inline(always)]
        fn shl(ref self: u128, n: u128) -> u128 {
            self * pow(2, n.into()).try_into().unwrap()
        }

        #[inline(always)]
        fn shr(ref self: u128, n: u128) -> u128 {
            self / pow(2, n.into()).try_into().unwrap()
        }
    }

    impl U32BitShift of BitShiftTrait<u32> {
        #[inline(always)]
        fn shl(ref self: u32, n: u32) -> u32 {
            self * pow(2, n.into()).try_into().unwrap()
        }

        #[inline(always)]
        fn shr(ref self: u32, n: u32) -> u32 {
            self / pow(2, n.into()).try_into().unwrap()
        }
    }

    fn pow(x: u256, n: u256) -> u256 {
        if n == 0 {
            1
        } else if n == 1 {
            x
        } else if (n & 1) == 1 {
            x * pow(x * x, n / 2)
        } else {
            pow(x * x, n / 2)
        }
    }
}
