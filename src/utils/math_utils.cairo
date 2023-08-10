mod MathUtils {
    use traits::{Into, TryInto};

    fn shift_left(num: u256, shift_amount: u256) -> u256 {
        num * pow(2, shift_amount)
    }

    fn shift_right(num: u256, shift_amount: u256) -> u256 {
        num / pow(2, shift_amount)
    }

    fn pow(x: u256, n: u256) -> u256 {
        if n == 0 {
            1
        } else if (n & 1) == 1 {
            x * pow(x * x, n / 2)
        } else {
            pow(x * x, n / 2)
        }
    }
}
