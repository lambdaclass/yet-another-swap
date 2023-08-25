mod BitMath {
    use integer::{U256BitAnd, Felt252IntoU256};
    use traits::{TryInto, DivEq};
    use option::OptionTrait;

    fn most_significant_bit(x: u256) -> u8 {
        assert(x > 0, 'most_significant_bit');
        let mut x: u256 = x;
        let mut r: u8 = 0;

        if x >= 0x100000000000000000000000000000000 {
            x /= 0x100000000000000000000000000000000;
            r += 128;
        }
        if x >= 0x10000000000000000 {
            x /= 0x10000000000000000;
            r += 64;
        }
        if x >= 0x100000000 {
            x /= 0x100000000;
            r += 32;
        }
        if x >= 0x10000 {
            x /= 0x10000;
            r += 16;
        }
        if x >= 0x100 {
            x /= 0x100;
            r += 8;
        }
        if x >= 0x10 {
            x /= 0x10;
            r += 4;
        }
        if x >= 0x4 {
            x /= 0x4;
            r += 2;
        }
        if x >= 0x2 {
            r += 1;
        }
        r
    }

    fn least_significant_bit(x: u256) -> u8 {
        assert(x > 0, 'least_significant_bit');
        let mut x = x;
        let mut r: u8 = 255;

        if (x & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) > 0 {
            r -= 128;
        } else {
            x /= 0x100000000000000000000000000000000;
        }
        if (x & 0xFFFFFFFFFFFFFFFF) > 0 {
            r -= 64;
        } else {
            x /= 0x10000000000000000;
        }
        if (x & 0xFFFFFFFF) > 0 {
            r -= 32;
        } else {
            x /= 0x100000000;
        }
        if (x & 0xFFFF) > 0 {
            r -= 16;
        } else {
            x /= 0x10000;
        }
        if (x & 0xFF) > 0 {
            r -= 8;
        } else {
            x /= 0x100;
        }
        if (x & 0xF) > 0 {
            r -= 4;
        } else {
            x /= 0x10;
        }
        if (x & 0x3) > 0 {
            r -= 2;
        } else {
            x /= 0x4;
        }
        if (x & 0x1) > 0 {
            r -= 1;
        }
        r
    }
}
