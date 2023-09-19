mod ContractAddressPartialOrdTest {
    use starknet::{ContractAddress, contract_address_const};
    use yas::utils::utils::ContractAddressPartialOrd;

    #[test]
    #[available_gas(2000000)]
    fn test_contract_address_gt() {
        let a = contract_address_const::<1>();
        let b = contract_address_const::<0>();
        assert(a > b, 'a should be > b');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_contract_address_lt() {
        let a = contract_address_const::<0>();
        let b = contract_address_const::<1>();
        assert(a < b, 'a should be < b');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_contract_address_le() {
        let a = contract_address_const::<5>();
        let b = contract_address_const::<5>();
        assert(a <= b, 'a should be <= b');
        assert(!(a < b), 'a should not be < b');

        let b = contract_address_const::<6>();
        assert(a <= b, 'a should be <= b');
        assert(a < b, 'a should be < b');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_contract_address_ge() {
        let a = contract_address_const::<5>();
        let b = contract_address_const::<5>();
        assert(a >= b, 'a should be >= b');
        assert(!(a > b), 'a should not be > b');

        let a = contract_address_const::<6>();
        assert(a >= b, 'a should be >= b');
        assert(a > b, 'a should be > b');
    }
}
