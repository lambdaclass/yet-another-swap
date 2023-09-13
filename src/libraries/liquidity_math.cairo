/// Math library for liquidity
mod LiquidityMath {
    use core::traits::PartialOrd;
    use core::integer::u128_overflowing_add;
    use yas::numbers::signed_integer::{i128::i128, integer_trait::IntegerTrait};

    /// Add a signed liquidity delta to liquidity and revert if it overflows or underflows.
    /// Parameters:
    /// - x: The liquidity before change.
    /// - y: The delta by which liquidity should be changed.
    fn add_delta(x: u128, y: i128) -> u128 {
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
