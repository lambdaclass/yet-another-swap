mod MathUtils {
    use traits::{Into, TryInto};
    use option::OptionTrait;

    trait BitShiftTrait<T> {
        fn shl(self: T, n: T) -> T;
        fn shr(self: T, n: T) -> T;
    }

    impl U256BitShift of BitShiftTrait<u256> {
        #[inline(always)]
        fn shl(self: u256, n: u256) -> u256 {
            self * pow(2, n)
        }

        #[inline(always)]
        fn shr(self: u256, n: u256) -> u256 {
            self / pow(2, n)
        }
    }

    impl U32BitShift of BitShiftTrait<u32> {
        #[inline(always)]
        fn shl(self: u32, n: u32) -> u32 {
            self * pow(2, n.into()).try_into().unwrap()
        }

        #[inline(always)]
        fn shr(self: u32, n: u32) -> u32 {
            self / pow(2, n.into()).try_into().unwrap()
        }
    }

    fn pow(x: u256, n: u256) -> u256 {
        if n == 0 {
            1
        } else {
            x * pow(x, n - 1)
        }
    }
}
