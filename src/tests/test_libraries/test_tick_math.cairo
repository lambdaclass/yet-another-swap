use fractal_swap::libraries::tick_math::TickMath::{
    MIN_TICK, MAX_TICK, get_sqrt_ratio_at_tick, MAX_SQRT_RATIO, MIN_SQRT_RATIO,
    get_tick_at_sqrt_ratio,
};
use orion::numbers::signed_integer::integer_trait::IntegerTrait;
use orion::numbers::signed_integer::i32::i32;
use fractal_swap::numbers::fixed_point::core::{FixedTrait, FixedType};
use fractal_swap::numbers::fixed_point::implementations::impl_64x96::{
    ONE_u128, ONE, MAX, _felt_abs, _felt_sign, FP64x96Impl, FP64x96Into, FP64x96Add, FP64x96AddEq,
    FP64x96Sub, FP64x96SubEq, FP64x96Mul, FP64x96MulEq, FP64x96Div, FP64x96DivEq, FP64x96PartialOrd,
    FP64x96PartialEq
};
use debug::PrintTrait;

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('T',))]
fn test_get_sqrt_ratio_at_tick_reverts_minus1() {
    let value = MIN_TICK() - IntegerTrait::<i32>::new(1, false);
    get_sqrt_ratio_at_tick(value);
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('T',))]
fn test_get_sqrt_ratio_at_tick_reverts_plus1() {
    let value = MAX_TICK() + IntegerTrait::<i32>::new(1, false);
    get_sqrt_ratio_at_tick(value);
}

#[test]
#[available_gas(200000000)]
fn test_get_sqrt_ratio_at_tick_min_tick() {
    assert(get_sqrt_ratio_at_tick(MIN_TICK()) == FixedTrait::from_felt(4295128739), '4295128739');
}

#[test]
#[available_gas(200000000)]
fn test_get_sqrt_ratio_at_tick_min_plus_one() {
    let value = MIN_TICK() + IntegerTrait::<i32>::new(1, false);
    assert(get_sqrt_ratio_at_tick(value) == FixedTrait::from_felt(4295343490), '4295343490');
}

#[test]
#[available_gas(200000000)]
fn test_get_sqrt_ratio_at_tick_max_minus_1() {
    let value = MAX_TICK() - IntegerTrait::<i32>::new(1, false);
    assert(
        get_sqrt_ratio_at_tick(
            value
        ) == FixedTrait::from_felt(1461373636630004318706518188784493106690254656249),
        'failed'
    );
}

#[test]
#[available_gas(200000000)]
fn test_get_sqrt_ratio_at_tick_max_tick() {
    assert(
        get_sqrt_ratio_at_tick(
            MAX_TICK()
        ) == FixedTrait::from_felt(1461446703485210103287273052203988822378723970342),
        'failed'
    );
}

#[test]
#[available_gas(200000000)]
fn test_get_sqrt_ratio_at_tick_min_sqrt_ratio() {
    assert(get_sqrt_ratio_at_tick(MIN_TICK()) == FixedTrait::new(MIN_SQRT_RATIO, false), 'failed');
}

#[test]
#[available_gas(200000000)]
fn test_get_sqrt_ratio_at_tick_max_sqrt_ratio() {
    assert(get_sqrt_ratio_at_tick(MAX_TICK()) == FixedTrait::new(MAX_SQRT_RATIO, false), 'failed');
}

#[test]
#[available_gas(2000000000)]
#[should_panic(expected: ('R',))]
fn test_panics_too_low() {
    let input = FixedTrait::new(MIN_SQRT_RATIO - 1, false);
    get_tick_at_sqrt_ratio(input);
}

#[test]
#[available_gas(2000000000)]
#[should_panic(expected: ('R',))]
fn test_panics_too_high() {
    let input = FixedTrait::new(MAX_SQRT_RATIO + 1, false);
    get_tick_at_sqrt_ratio(input);
}

#[test]
#[available_gas(2000000000)]
fn test_ratio_min_tick() {
    let input = FixedTrait::new(MIN_SQRT_RATIO, false);
    let res = get_tick_at_sqrt_ratio(input);
    assert(res == MIN_TICK(), 'failed');
}
// #[test]
// #[available_gas(2000000000)]
// fn test_min_plus_one() {
//     let input = FixedTrait::new(4295343490, false);
//     let res = get_tick_at_sqrt_ratio(input);
//     assert(res == MIN_TICK() + IntegerTrait::<i32>::new(1, false), 'failed');
// }

// #[test]
// #[available_gas(2000000000)]
// fn test_max_minus_one() {
//     let input = FixedTrait::new(1461373636630004318706518188784493106690254656249, false);
//     let res = get_tick_at_sqrt_ratio(input);
//     assert(res == MAX_TICK() - IntegerTrait::<i32>::new(1, false), 'failed');
// }

// #[test]
// #[available_gas(2000000000)]
// fn test_ratio_closest_to_max_tick() {
//     let input = FixedTrait::new(MAX_SQRT_RATIO - 1, false);
//     let res = get_tick_at_sqrt_ratio(input);
//     assert(res == MAX_TICK() - IntegerTrait::<i32>::new(1, false), 'failed');
// }

//     for (const ratio of [
//       MIN_SQRT_RATIO,
//       encodePriceSqrt(BigNumber.from(10).pow(12), 1),
//       encodePriceSqrt(BigNumber.from(10).pow(6), 1),
//       encodePriceSqrt(1, 64),
//       encodePriceSqrt(1, 8),
//       encodePriceSqrt(1, 2),
//       encodePriceSqrt(1, 1),
//       encodePriceSqrt(2, 1),
//       encodePriceSqrt(8, 1),
//       encodePriceSqrt(64, 1),
//       encodePriceSqrt(1, BigNumber.from(10).pow(6)),
//       encodePriceSqrt(1, BigNumber.from(10).pow(12)),
//       MAX_SQRT_RATIO.sub(1),
//     ]) {
//       describe(`ratio ${ratio}`, () => {
//         it('is at most off by 1', async () => {
//           const jsResult = new Decimal(ratio.toString()).div(new Decimal(2).pow(96)).pow(2).log(1.0001).floor()
//           const result = await tickMath.getTickAtSqrtRatio(ratio)
//           const absDiff = new Decimal(result.toString()).sub(jsResult).abs()
//           expect(absDiff.toNumber()).to.be.lte(1)
//         })
//         it('ratio is between the tick and tick+1', async () => {
//           const tick = await tickMath.getTickAtSqrtRatio(ratio)
//           const ratioOfTick = await tickMath.getSqrtRatioAtTick(tick)
//           const ratioOfTickPlusOne = await tickMath.getSqrtRatioAtTick(tick + 1)
//           expect(ratio).to.be.gte(ratioOfTick)
//           expect(ratio).to.be.lt(ratioOfTickPlusOne)
//         })
//         it('result', async () => {
//           expect(await tickMath.getTickAtSqrtRatio(ratio)).to.matchSnapshot()
//         })
//         it('gas', async () => {
//           await snapshotGasCost(tickMath.getGasCostOfGetTickAtSqrtRatio(ratio))
//         })
//       })
//     }
//   })
// })

// TODO: check this tests.
// In Orion seems like they implemented a function that check if the result is whitin a range.
//     for (const absTick of [
//       50,
//       100,
//       250,
//       500,
//       1_000,
//       2_500,
//       3_000,
//       4_000,
//       5_000,
//       50_000,
//       150_000,
//       250_000,
//       500_000,
//       738_203,
//     ]) {
//       for (const tick of [-absTick, absTick]) {
//         describe(`tick ${tick}`, () => {
//           it('is at most off by 1/100th of a bips', async () => {
//             const jsResult = new Decimal(1.0001).pow(tick).sqrt().mul(new Decimal(2).pow(96))
//             const result = await tickMath.getSqrtRatioAtTick(tick)
//             const absDiff = new Decimal(result.toString()).sub(jsResult).abs()
//             expect(absDiff.div(jsResult).toNumber()).to.be.lt(0.000001)
//           })
//           it('result', async () => {
//             expect((await tickMath.getSqrtRatioAtTick(tick)).toString()).to.matchSnapshot()
//           })
//           it('gas', async () => {
//             await snapshotGasCost(tickMath.getGasCostOfGetSqrtRatioAtTick(tick))
//           })
//         })
//       }
//     }
//   })


