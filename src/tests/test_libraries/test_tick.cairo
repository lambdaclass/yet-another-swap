use array::ArrayTrait;
use core::result::ResultTrait;
use core::traits::Into;
use option::OptionTrait;
use starknet::syscalls::deploy_syscall;
use traits::TryInto;

use orion::numbers::signed_integer::i64::i64;
use orion::numbers::signed_integer::i128::i128;
use orion::numbers::signed_integer::integer_trait::IntegerTrait;

use fractal_swap::libraries::tick::{Tick, ITick, ITickDispatcher, ITickDispatcherTrait};

fn deploy() -> ITickDispatcher {
    let calldata: Array<felt252> = ArrayTrait::new();
    let (address, _) = deploy_syscall(
        Tick::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), true
    )
        .expect('DEPLOY_FAILED');
    return (ITickDispatcher { contract_address: address });
}

#[test]
#[available_gas(30000000)]
fn test_save_info() {
    let tick = deploy();

    tick.set_tick();

    let result = tick.get_tick(1);
    assert(result.liquidity_gross == 1, 'liquidity_gross should be 1');
    assert(
        result.liquidity_net == IntegerTrait::<i128>::new(2, false), 'liquidity_net should be 2'
    );
    assert(result.fee_growth_outside_0X128 == 3, 'fee_growth_0X128 should be 3');
    assert(result.fee_growth_outside_1X128 == 4, 'fee_growth_1X128 should be 4');
    assert(
        result.tick_cumulative_outside == IntegerTrait::<i64>::new(5, false),
        'tick_cumulative should be 5'
    );
    assert(result.seconds_per_liquidity_outside_X128 == 6, 'sec_per_liqui_X128 should be 6');
    assert(result.seconds_outside == 7, 'seconds_outside should be 7');
    assert(result.initialized == true, 'initialized should be true');
}
