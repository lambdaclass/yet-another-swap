use fractal_swap::libraries::tick_math::TickMath::{MIN_TICK, MAX_TICK, get_sqrt_ratio_at_tick};
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
    assert(get_sqrt_ratio_at_tick(value) == FixedTrait::from_felt(1461373636630004318706518188784493106690254656249), 'failed');
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

// TODO: check this tests.
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

//   describe('#MIN_SQRT_RATIO', async () => {
//     it('equals #getSqrtRatioAtTick(MIN_TICK)', async () => {
//       const min = await tickMath.getSqrtRatioAtTick(MIN_TICK)
//       expect(min).to.eq(await tickMath.MIN_SQRT_RATIO())
//       expect(min).to.eq(MIN_SQRT_RATIO)
//     })
//   })

//   describe('#MAX_SQRT_RATIO', async () => {
//     it('equals #getSqrtRatioAtTick(MAX_TICK)', async () => {
//       const max = await tickMath.getSqrtRatioAtTick(MAX_TICK)
//       expect(max).to.eq(await tickMath.MAX_SQRT_RATIO())
//       expect(max).to.eq(MAX_SQRT_RATIO)
//     })
//   })

//   describe('#getTickAtSqrtRatio', () => {
//     it('throws for too low', async () => {
//       await expect(tickMath.getTickAtSqrtRatio(MIN_SQRT_RATIO.sub(1))).to.be.revertedWith('R')
//     })

//     it('throws for too high', async () => {
//       await expect(tickMath.getTickAtSqrtRatio(BigNumber.from(MAX_SQRT_RATIO))).to.be.revertedWith('R')
//     })

//     it('ratio of min tick', async () => {
//       expect(await tickMath.getTickAtSqrtRatio(MIN_SQRT_RATIO)).to.eq(MIN_TICK)
//     })
//     it('ratio of min tick + 1', async () => {
//       expect(await tickMath.getTickAtSqrtRatio('4295343490')).to.eq(MIN_TICK + 1)
//     })
//     it('ratio of max tick - 1', async () => {
//       expect(await tickMath.getTickAtSqrtRatio('1461373636630004318706518188784493106690254656249')).to.eq(MAX_TICK - 1)
//     })
//     it('ratio closest to max tick', async () => {
//       expect(await tickMath.getTickAtSqrtRatio(MAX_SQRT_RATIO.sub(1))).to.eq(MAX_TICK - 1)
//     })

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


