/// A struct representing a fixed point number.
#[derive(Serde, Copy, Drop, starknet::Store)]
struct FixedType {
    mag: u256,
    sign: bool
}

/// A struct listing fixed point implementations.
#[derive(Serde, Copy, Drop)]
enum FixedImpl {
    FP64x96: (),
}

/// Trait
///
/// new - Constructs a new fixed point instance.
/// new_unscaled - Creates a new fixed point instance with the specified unscaled magnitude and sign.
/// from_felt - Creates a new fixed point instance from a `felt252` value.
/// from_unscaled_felt - Creates a new fixed point instance from an unscaled `felt252` value.
/// abs - Returns the absolute value of the fixed point number.
/// ceil - Returns the smallest integer greater than or equal to the fixed point number.
/// floor - Returns the largest integer less than or equal to the fixed point number.
/// exp - Returns the value of e raised to the power of the fixed point number. 
/// exp2 - Returns the value of 2 raised to the power of the fixed point number.
/// pow - Returns the result of raising the fixed point number to the power of another fixed point number
/// round - Rounds the fixed point number to the nearest whole number.
/// sqrt - Returns the square root of the fixed point number.
trait FixedTrait {
    /// # FixedTrait::new
    /// 
    /// ```rust
    /// fn new(mag: u256, sign: bool) -> FixedType;
    /// ```
    /// 
    /// Constructs a new fixed point instance.
    ///
    /// ## Args
    /// 
    /// * `mag`(`u256`) - The magnitude of the fixed point.
    /// * `sign`(`bool`) - The sign of the fixed point, where `true` represents a negative number.
    ///
    /// ## Returns
    ///
    /// A new fixed point instance.
    ///
    /// ## Examples
    /// 
    /// ```rust
    /// fn new_fp_example() -> FixedType {
    ///     // We can call `new` function as follows. 
    ///     FixedTrait::new(67108864, false)
    /// }
    /// >>> {mag: 67108864, sign: false} // = 1
    /// ```
    ///
    fn new(mag: u256, sign: bool) -> FixedType;
    /// # FixedTrait::new\_unscaled
    /// 
    /// ```rust
    /// fn new_unscaled(mag: u256, sign: bool) -> FixedType;
    /// ```
    ///
    /// Creates a new fixed point instance with the specified unscaled magnitude and sign. 
    /// This function is only useful when you want a number with only an integer part.
    /// 
    /// ## Args
    ///
    /// `mag`(`u256`) - The unscaled magnitude of the fixed point.
    /// `sign`(`bool`) - The sign of the fixed point, where `true` represents a negative number.
    ///
    /// ## Returns
    /// 
    /// A new fixed point instance.
    /// 
    /// ## Examples
    /// 
    /// ```rust
    /// fn new_unscaled_example() -> FixedType {
    ///     // We can call `new_unscaled` function as follows. 
    ///     FixedTrait::new_unscaled(1);
    /// }
    /// >>> {mag: 67108864, sign: false}
    /// ```
    ///
    fn new_unscaled(mag: u256, sign: bool) -> FixedType;
    /// # FixedTrait::from_felt
    ///
    /// 
    /// ```rust
    /// fn from_felt(val: felt252) -> FixedType;
    /// ```
    /// 
    /// Creates a new fixed point instance from a felt252 value.
    /// This function is only useful when you want a number with only an integer part.
    ///
    /// ## Args
    /// 
    /// * `val`(`felt252`) - `felt252` value to convert in FixedType
    ///
    /// ## Returns 
    ///
    /// A new fixed point instance.
    ///
    /// ## Examples
    /// 
    /// ```rust
    /// fn from_felt_example() -> FixedType {
    ///     // We can call `from_felt` function as follows . 
    ///     FixedTrait::from_felt(194615706);
    /// }
    /// >>> {mag: 194615706, sign: false} // = 2.9
    /// ```
    ///
    fn from_felt(val: felt252) -> FixedType;
    ///# FixedTrait::from\_unscaled\_felt
    ///
    ///```rust
    ///fn from_unscaled_felt(val: felt252) -> FixedType;
    ///```
    ///
    ///Creates a new fixed point instance from an unscaled felt252 value.
    /// This function is only useful when you want a number with only an integer part.
    ///
    /// ## Args
    /// 
    /// `val`(`felt252`) - `felt252` value to convert in FixedType
    ///
    /// ## Returns - A new fixed point instance.
    ///
    /// ## Examples
    ///
    ///```rust
    ///fn from_unscaled_felt_example() -> FixedType {
    ///    // We can call `from_unscaled_felt` function as follows . 
    ///    FixedTrait::from_unscaled_felt(1);
    ///}
    ///>>> {mag: 67108864, sign: false}
    ///```
    /// 
    fn from_unscaled_felt(val: felt252) -> FixedType;
    /// # fp.abs
    /// 
    /// ```rust
    /// fn abs(self: FixedType) -> FixedType;
    /// ```
    /// 
    /// Returns the absolute value of the fixed point number.
    ///
    /// ## Args
    /// 
    /// * `self`(`FixedType`) - The input fixed point
    ///
    /// ## Returns
    ///
    /// The absolute value of the input fixed point number.
    ///
    /// ## Examples
    /// 
    /// ```rust
    /// fn abs_fp_example() -> FixedType {
    ///     // We instantiate fixed point here.
    ///     let fp = FixedTrait::from_unscaled_felt(-1);
    ///     
    ///     // We can call `abs` function as follows.
    ///     fp.abs()
    /// }
    /// >>> {mag: 67108864, sign: false} // = 1
    /// ```
    /// 
    fn abs(self: FixedType) -> FixedType;
    /// # fp.ceil
    /// 
    /// ```rust
    /// fn ceil(self: FixedType) -> FixedType;
    /// ```
    /// 
    /// Returns the smallest integer greater than or equal to the fixed point number.
    ///
    /// ## Args
    ///
    /// *`self`(`FixedType`) - The input fixed point
    ///
    /// ## Returns
    ///
    /// The smallest integer greater than or equal to the input fixed point number.
    ///
    /// ## Examples
    /// 
    /// ```rust
    /// fn ceil_fp_example() -> FixedType {
    ///     // We instantiate fixed point here.
    ///     let fp = FixedTrait::from_felt(194615506); // 2.9
    ///     
    ///     // We can call `ceil` function as follows.
    ///     fp.ceil()
    /// }
    /// >>> {mag: 201326592, sign: false} // = 3
    /// ```
    ///
    fn ceil(self: FixedType) -> FixedType;
    /// # fp.floor
    /// 
    /// ```rust
    /// fn floor(self: FixedType) -> FixedType;
    /// ```
    /// 
    /// Returns the largest integer less than or equal to the fixed point number.
    ///
    /// ## Args
    /// 
    /// * `self`(`FixedType`) - The input fixed point
    ///
    /// ## Returns
    ///
    /// Returns the largest integer less than or equal to the input fixed point number.
    ///
    /// ## Examples
    /// 
    /// ```rust
    /// fn floor_fp_example() -> FixedType {
    ///     // We instantiate fixed point here.
    ///     let fp = FixedTrait::from_felt(194615506); // 2.9
    ///     
    ///     // We can call `floor` function as follows.
    ///     fp.floor()
    /// }
    /// >>> {mag: 134217728, sign: false} // = 2
    /// ```
    /// 
    fn floor(self: FixedType) -> FixedType;
    /// # fp.round
    /// 
    /// ```rust
    /// fn round(self: FixedType) -> FixedType;
    /// ```
    /// 
    /// Rounds the fixed point number to the nearest whole number.
    ///
    /// ## Args
    ///
    /// * `self`(`FixedType`) - The input fixed point
    ///
    /// ## Returns
    ///
    /// A fixed point number representing the rounded value.
    ///
    /// ## Examples
    ///
    /// 
    /// ```rust
    /// fn round_fp_example() -> FixedType {
    ///     // We instantiate FixedTrait points here.
    ///     let a = FixedTrait::from_felt(194615506); // 2.9
    ///     
    ///     // We can call `round` function as follows.
    ///     a.round(b)
    /// }
    /// >>> {mag: 201326592, sign: false} // = 3
    /// ```
    /// 
    fn round(self: FixedType) -> FixedType;
    /// # fp.sqrt
    /// 
    /// ```rust
    /// fn sqrt(self: FixedType) -> FixedType;
    /// ```
    /// 
    /// Returns the square root of the fixed point number.
    ///
    /// ## Args
    ///
    /// `self`(`FixedType`) - The input fixed point
    ///
    /// ## Panics
    ///
    /// * Panics if the input is negative.
    ///
    /// ## Returns
    /// 
    /// A fixed point number representing the square root of the input value.
    ///
    /// ## Examples
    /// 
    /// ```rust
    /// fn sqrt_fp_example() -> FixedType {
    ///     // We instantiate FixedTrait points here.
    ///     let a = FixedTrait::from_unscaled_felt(25);
    ///     
    ///     // We can call `round` function as follows.
    ///     a.sqrt()
    /// }
    /// >>> {mag: 1677721600, sign: false} // = 5
    /// ```
    ///
    fn sqrt(self: FixedType) -> FixedType;
}
