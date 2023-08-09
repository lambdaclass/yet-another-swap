use starknet::ContractAddress;

#[starknet::interface]
trait IAMM<TContractState> {
    fn add_demo_token(ref self: TContractState, token_a_amount: u128, token_b_amount: u128);
    fn init_pool(ref self: TContractState, token_a: u128, token_b: u128);
    fn swap(ref self: TContractState, token_from: felt252, amount_from: u128);
}

#[starknet::contract]
mod AMM {
    ////////////////////////////////
    // library imports
    ////////////////////////////////
    use starknet::get_caller_address;
    use starknet::ContractAddress;

    ////////////////////////////////
    // constants
    ////////////////////////////////
    const BALANCE_UPPER_BOUND: u128 = 1073741824; // max amount of token to belong to AMM (2^30)
    const POOL_UPPER_BOUND: u128 = 1048576; // max amount to belong to pool (2^20)
    const ACCOUNT_BALANCE_BOUND: u128 =
        104857; // max amount an account can hold (POOL_UPPER_BOUND/10)

    ////////////////////////////////
    // constants - token types (we'll have just two for simplicity sake)
    ////////////////////////////////
    const TOKEN_TYPE_A: felt252 = 1;
    const TOKEN_TYPE_B: felt252 = 2;

    ////////////////////////////////
    // storage variables
    ////////////////////////////////
    #[storage]
    struct Storage {
        account_balance: LegacyMap::<(ContractAddress, felt252), u128>,
        pool_balance: LegacyMap::<felt252, u128>,
    }

    ////////////////////////////////
    // @dev function to set pool balance for a given token
    ////////////////////////////////
    fn set_pool_token_balance(ref self: ContractState, token_type: felt252, balance: u128) {
        assert((BALANCE_UPPER_BOUND - 1) > balance, 'exceeds maximum allowed tokens!');

        self.pool_balance.write(token_type, balance);
        return ();
    }

    #[external(v0)]
    fn get_account_token_balance(
        self: @ContractState, account: ContractAddress, token_type: felt252
    ) -> u128 {
        self.account_balance.read((account, token_type))
    }

    ////////////////////////////////
    // @dev function to return the pool's balance for a token type
    ////////////////////////////////
    #[external(v0)]
    fn get_pool_token_balance(self: @ContractState, token_type: felt252) -> u128 {
        self.pool_balance.read(token_type)
    }

    ////////////////////////////////
    // function to return account balance for a given token
    ////////////////////////////////
    #[external(v0)]
    impl AMM of super::IAMM<ContractState> {
        ////////////////////////////////
        // @dev function to add demo token to the given account
        ////////////////////////////////
        fn add_demo_token(ref self: ContractState, token_a_amount: u128, token_b_amount: u128) {
            let account = get_caller_address();

            modify_account_balance(ref self, account, TOKEN_TYPE_A, token_a_amount);
            modify_account_balance(ref self, account, TOKEN_TYPE_B, token_b_amount);
            return ();
        }

        ////////////////////////////////
        // @dev function to intialize AMM
        ////////////////////////////////
        fn init_pool(ref self: ContractState, token_a: u128, token_b: u128) {
            assert(
                ((POOL_UPPER_BOUND - 1) > token_a) & ((POOL_UPPER_BOUND - 1) > token_b),
                'exceeds maximum allowed tokens!'
            );

            set_pool_token_balance(ref self, TOKEN_TYPE_A, token_a);
            set_pool_token_balance(ref self, TOKEN_TYPE_B, token_b);
            return ();
        }

        ////////////////////////////////
        // @dev function to swap token between the given account and the pool
        ////////////////////////////////
        fn swap(ref self: ContractState, token_from: felt252, amount_from: u128) {
            let account = get_caller_address();

            // verify token_from is TOKEN_TYPE_A or TOKEN_TYPE_B
            assert(
                token_from - TOKEN_TYPE_A == 0 || token_from - TOKEN_TYPE_B == 0,
                'token not allowed in the pool!'
            );
            // check requested amount_from is valid
            assert((BALANCE_UPPER_BOUND - 1) > amount_from, 'exceeds maximum allowed tokens');

            // check user has enough funds
            let account_from_balance = get_account_token_balance(@self, account, token_from);
            assert(account_from_balance > amount_from, 'Insufficient balance!');

            let token_to = get_opposite_token(token_from);
            do_swap(ref self, account, token_from, token_to, amount_from);
        }
    }

    ////////////////////////////////
    // internal function that updates account balance for a given token
    ////////////////////////////////
    fn modify_account_balance(
        ref self: ContractState, account: ContractAddress, token_type: felt252, amount: u128
    ) {
        let current_balance = self.account_balance.read((account, token_type));
        let new_balance = current_balance + amount;

        assert((BALANCE_UPPER_BOUND - 1) > new_balance, 'exceeds maximum allowed tokens');

        self.account_balance.write((account, token_type), new_balance);
        return ();
    }

    ////////////////////////////////
    // internal function to get the opposite token type
    ////////////////////////////////
    fn get_opposite_token(token_type: felt252) -> felt252 {
        if (token_type == TOKEN_TYPE_A) {
            return TOKEN_TYPE_B;
        } else {
            return TOKEN_TYPE_A;
        }
    }

    ////////////////////////////////
    // internal function that swaps tokens between the given account and the pool
    ////////////////////////////////
    fn do_swap(
        ref self: ContractState,
        account: ContractAddress,
        token_from: felt252,
        token_to: felt252,
        amount_from: u128
    ) {
        // get pool balance
        let amm_from_balance = get_pool_token_balance(@self, token_from);
        let amm_to_balance = get_pool_token_balance(@self, token_to);

        // calculate swap amount
        let amount_to = (amm_to_balance * amount_from) / (amm_from_balance + amount_from);

        // update account balances
        modify_account_balance(ref self, account, token_from, (0 - amount_from));
        modify_account_balance(ref self, account, token_to, amount_to);

        // update pool balances
        set_pool_token_balance(ref self, token_from, (amm_from_balance + amount_from));
        set_pool_token_balance(ref self, token_to, (amm_to_balance - amount_to));
    }
}
