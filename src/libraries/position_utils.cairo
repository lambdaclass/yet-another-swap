mod PositionUtils {
    use starknet::ContractAddress; 
    use orion::numbers::signed_integer::i32::i32;
    use orion::numbers::signed_integer::integer_trait::IntegerTrait;
    use poseidon::poseidon_hash_span;
    use serde::Serde;
    use array::ArrayTrait;

    #[derive(Serde, Drop)]
    struct Position {
        owner: ContractAddress,
        tickLower: i32,
        tickUpper: i32 
    }

    // Test that there no colision between different positions, we should check how the serilzer is working and if poseidon is a valid hash function for this 
    fn _generate_id_position(          
        owner: ContractAddress,
        tickLower: i32,
        tickUpper: i32 ) -> felt252 {
        let position = Position {owner, tickLower, tickUpper};
        let mut serialized: Array<felt252> = ArrayTrait::new();
        position.serialize(ref serialized);
        poseidon_hash_span(serialized.span())
    }
}

