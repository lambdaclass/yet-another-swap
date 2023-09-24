use starknet::{ContractAddress, contract_address_to_felt252};
use yas::contracts::yas_pool::YASPool::Slot0;
use yas::numbers::fixed_point::implementations::impl_64x96::{FP64x96PartialEq};
use starknet::testing;

impl ContractAddressPartialOrd of PartialOrd<ContractAddress> {
    #[inline(always)]
    fn le(lhs: ContractAddress, rhs: ContractAddress) -> bool {
        let lhs_u256: u256 = lhs.into();
        let rhs_u256: u256 = rhs.into();
        lhs_u256 <= rhs_u256
    }
    #[inline(always)]
    fn ge(lhs: ContractAddress, rhs: ContractAddress) -> bool {
        let lhs_u256: u256 = lhs.into();
        let rhs_u256: u256 = rhs.into();
        rhs_u256 <= lhs_u256
    }
    #[inline(always)]
    fn lt(lhs: ContractAddress, rhs: ContractAddress) -> bool {
        let lhs_u256: u256 = lhs.into();
        let rhs_u256: u256 = rhs.into();
        lhs_u256 < rhs_u256
    }
    #[inline(always)]
    fn gt(lhs: ContractAddress, rhs: ContractAddress) -> bool {
        let lhs_u256: u256 = lhs.into();
        let rhs_u256: u256 = rhs.into();
        rhs_u256 < lhs_u256
    }
}

impl ContractAddressIntoU256 of Into<ContractAddress, u256> {
    fn into(self: ContractAddress) -> u256 {
        contract_address_to_felt252(self).into()
    }
}

impl Slot0PartialEq of PartialEq<Slot0> {
    #[inline(always)]
    fn eq(lhs: @Slot0, rhs: @Slot0) -> bool {
        (*lhs.sqrt_price_X96) == (*rhs.sqrt_price_X96)
            && (*lhs.tick) == (*rhs.tick)
            && lhs.fee_protocol == rhs.fee_protocol
            && lhs.unlocked == rhs.unlocked
    }
    #[inline(always)]
    fn ne(lhs: @Slot0, rhs: @Slot0) -> bool {
        !(lhs == rhs)
    }
}


/// Pop the earliest unpopped logged event for the contract as the requested type
/// and checks there's no more data left on the event, preventing unaccounted params.
/// This function also removes the hashed event-name key to support indexed event
/// members.
fn pop_log_with_key<T, impl TDrop: Drop<T>, impl TEvent: starknet::Event<T>>(
    address: ContractAddress
) -> Option<T> {
    let (mut keys, mut data) = testing::pop_log_raw(address)?;

    // Remove the event ID from the keys.
    keys.pop_front();

    let ret = starknet::Event::deserialize(ref keys, ref data);
    assert(data.is_empty(), 'Event has extra data');
    ret
}