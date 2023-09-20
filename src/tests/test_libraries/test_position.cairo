mod PositionTests {
    use yas::libraries::position::Position;
    use starknet::{contract_address_const, ContractAddress};

    fn STATE() -> Position::ContractState {
        Position::contract_state_for_testing()
    }

    fn OWNER() -> ContractAddress {
        contract_address_const::<'OWNER'>()
    }

    mod Get {
        use super::{STATE, OWNER};

        use yas::libraries::position::{Info, PositionKey, Position::{PositionImpl, InternalImpl}};

        use yas::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};


        #[test]
        #[available_gas(30000000)]
        fn test_get_state() {
            let mut state = STATE();

            let position_key = PositionKey {
                owner: OWNER(),
                tick_lower: IntegerTrait::<i32>::new(0, false),
                tick_upper: IntegerTrait::<i32>::new(10, false),
            };

            let info = Info {
                liquidity: 100,
                fee_growth_inside_0_last_X128: 20,
                fee_growth_inside_1_last_X128: 20,
                tokens_owed_0: 10,
                tokens_owed_1: 10,
            };

            InternalImpl::set_position(ref state, position_key, info);

            let position = PositionImpl::get(@state, position_key);

            assert(position.liquidity == 100, 'liquidity');
            assert(position.fee_growth_inside_0_last_X128 == 20, 'fee_growth_inside_0_last_X128');
            assert(position.fee_growth_inside_1_last_X128 == 20, 'fee_growth_inside_1_last_X128');
            assert(position.tokens_owed_0 == 10, 'tokens_owed_0');
            assert(position.tokens_owed_1 == 10, 'tokens_owed_1');
        }
        #[test]
        #[available_gas(30000000)]
        fn test_get_not_init_position() {
            let mut state = STATE();

            let position_key = PositionKey {
                owner: OWNER(),
                tick_lower: IntegerTrait::<i32>::new(0, false),
                tick_upper: IntegerTrait::<i32>::new(10, false),
            };

            let position: Info = PositionImpl::get(@state, position_key);

            assert(position.liquidity == 0, 'liquidity');
            assert(position.fee_growth_inside_0_last_X128 == 0, 'fee_growth_inside_0_last_X128');
            assert(position.fee_growth_inside_1_last_X128 == 0, 'fee_growth_inside_1_last_X128');
            assert(position.tokens_owed_0 == 0, 'tokens_owed_0');
            assert(position.tokens_owed_1 == 0, 'tokens_owed_1');
        }
    }

    mod Update {
        use super::{STATE, OWNER};

        use yas::libraries::position::{Info, PositionKey, Position::{PositionImpl, InternalImpl}};

        use yas::numbers::signed_integer::{i32::i32, i128::i128, integer_trait::IntegerTrait};

        #[test]
        #[available_gas(30000000)]
        #[should_panic(expected: ('NP',))]
        fn test_liquidity_delta_eq_zero_with_position_not_init() {
            let mut state = STATE();

            let position_key = PositionKey {
                owner: OWNER(),
                tick_lower: IntegerTrait::<i32>::new(0, false),
                tick_upper: IntegerTrait::<i32>::new(10, false),
            };

            // should be zero or negative to make it panic
            let liquidity_delta = IntegerTrait::<i128>::new(0, false);

            let fee_growth_inside_0_X128 = 0;
            let fee_growth_inside_1_X128 = 0;

            let position = PositionImpl::update(
                ref state,
                position_key,
                liquidity_delta,
                fee_growth_inside_0_X128,
                fee_growth_inside_1_X128
            );
        }

        #[test]
        #[available_gas(30000000)]
        fn test_liquidity_delta_eq_zero_with_position_init() {
            let mut state = STATE();

            let position_key = PositionKey {
                owner: OWNER(),
                tick_lower: IntegerTrait::<i32>::new(0, false),
                tick_upper: IntegerTrait::<i32>::new(10, false),
            };

            let info = Info {
                liquidity: 100,
                fee_growth_inside_0_last_X128: 0,
                fee_growth_inside_1_last_X128: 0,
                tokens_owed_0: 10,
                tokens_owed_1: 10,
            };

            InternalImpl::set_position(ref state, position_key, info);

            let liquidity_delta = IntegerTrait::<i128>::new(0, false);

            let fee_growth_inside_0_X128 = 0;
            let fee_growth_inside_1_X128 = 0;

            PositionImpl::update(
                ref state,
                position_key,
                liquidity_delta,
                fee_growth_inside_0_X128,
                fee_growth_inside_1_X128
            );

            let position = PositionImpl::get(@state, position_key);

            assert(position.liquidity == 100, 'liquidity');
            assert(position.fee_growth_inside_0_last_X128 == 0, 'fee_growth_inside_0_last_X128');
            assert(position.fee_growth_inside_1_last_X128 == 0, 'fee_growth_inside_1_last_X128');
            assert(position.tokens_owed_0 == 10, 'tokens_owed_0');
            assert(position.tokens_owed_1 == 10, 'tokens_owed_1');
        }

        #[test]
        #[available_gas(30000000)]
        fn test_not_init_position() {
            let mut state = STATE();

            let position_key = PositionKey {
                owner: OWNER(),
                tick_lower: IntegerTrait::<i32>::new(0, false),
                tick_upper: IntegerTrait::<i32>::new(10, false),
            };

            let liquidity_delta = IntegerTrait::<i128>::new(100, false);

            let fee_growth_inside_0_X128 = 0;
            let fee_growth_inside_1_X128 = 0;

            PositionImpl::update(
                ref state,
                position_key,
                liquidity_delta,
                fee_growth_inside_0_X128,
                fee_growth_inside_1_X128
            );

            let position = PositionImpl::get(@state, position_key);

            assert(position.liquidity == 100, 'liquidity');
            assert(position.fee_growth_inside_0_last_X128 == 0, 'fee_growth_inside_0_last_X128');
            assert(position.fee_growth_inside_1_last_X128 == 0, 'fee_growth_inside_1_last_X128');
            assert(position.tokens_owed_0 == 0, 'tokens_owed_0');
            assert(position.tokens_owed_1 == 0, 'tokens_owed_1');
        }
    }
}
