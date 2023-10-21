mod YASFaucet {
    use starknet::{ContractAddress, ClassHash, SyscallResultTrait, contract_address_const};
    use starknet::syscalls::deploy_syscall;
    use starknet::testing::{set_contract_address, set_caller_address, set_block_timestamp};

    use yas_core::contracts::yas_erc20::{ERC20, IERC20Dispatcher, IERC20DispatcherTrait};
    use yas_faucet::yas_faucet::{YASFaucet, IYASFaucetDispatcher, IYASFaucetDispatcherTrait};
    use yas_core::tests::utils::constants::PoolConstants::{OTHER, OWNER, WALLET};

    fn setup() -> (IYASFaucetDispatcher, IERC20Dispatcher) {
        let yas_token = deploy_erc20('YAS', '$YAS', 4000000000000000000, OWNER());
        let yas_faucet = deploy_yas_faucet(OWNER(), yas_token.contract_address, 1000, 86400);
        set_contract_address(OWNER());
        yas_token.transfer(yas_faucet.contract_address, 4000000000000000000);
        (yas_faucet, yas_token)
    }

    fn deploy_yas_faucet(
        owner: ContractAddress,
        token_address: ContractAddress,
        withdrawal_amount: u256,
        wait_time: u64
    ) -> IYASFaucetDispatcher {
        let mut calldata: Array<felt252> = ArrayTrait::new();
        calldata.append(owner.into());
        calldata.append(token_address.into());
        Serde::serialize(@withdrawal_amount, ref calldata);
        calldata.append(wait_time.into());

        let (address, _) = deploy_syscall(
            YASFaucet::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), true
        )
            .unwrap_syscall();

        return IYASFaucetDispatcher { contract_address: address };
    }

    fn deploy_erc20(
        name: felt252, symbol: felt252, initial_supply: u256, recipent: ContractAddress
    ) -> IERC20Dispatcher {
        let mut calldata = array![name, symbol];
        Serde::serialize(@initial_supply, ref calldata);
        calldata.append(recipent.into());

        let (address, _) = deploy_syscall(
            ERC20::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), true
        )
            .unwrap_syscall();

        return IERC20Dispatcher { contract_address: address };
    }

    #[test]
    #[available_gas(200000000)]
    fn test_happy_path() {
        let (yas_faucet, yas_erc_20) = setup();

        assert(yas_erc_20.balanceOf(WALLET()) == 0, 'wrong balance');

        set_contract_address(WALLET());
        yas_faucet.faucet_mint();

        assert(yas_erc_20.balanceOf(WALLET()) == 1000, 'wrong balance');
    }

    #[test]
    #[available_gas(200000000)]
    fn test_double_faucet_mint() {
        let (yas_faucet, yas_erc_20) = setup();

        assert(yas_erc_20.balanceOf(WALLET()) == 0, 'wrong balance');

        set_contract_address(WALLET());
        yas_faucet.faucet_mint();
        assert(yas_erc_20.balanceOf(WALLET()) == 1000, 'wrong balance');

        set_block_timestamp(86400 + 1);

        yas_faucet.faucet_mint();
        assert(yas_erc_20.balanceOf(WALLET()) == 2000, 'wrong balance');
    }

    #[test]
    #[available_gas(200000000)]
    fn test_withdraw_all_balance() {
        let (yas_faucet, yas_erc_20) = setup();

        assert(yas_erc_20.balanceOf(OTHER()) == 0, 'wrong balance');
        assert(
            yas_erc_20.balanceOf(yas_faucet.contract_address) == 4000000000000000000,
            'wrong balance'
        );

        set_contract_address(OWNER());
        yas_faucet.withdraw_all_balance(OTHER());

        assert(yas_erc_20.balanceOf(OTHER()) == 4000000000000000000, 'wrong balance');
        assert(yas_erc_20.balanceOf(yas_faucet.contract_address) == 0, 'wrong balance');
    }

    #[test]
    #[available_gas(200000000)]
    fn test_faucet_constructor() {
        let (yas_faucet, yas_erc_20) = setup();
        assert(yas_faucet.get_amount_faucet() == 4000000000000000000, 'wrong amount_faucet');
        assert(
            yas_faucet.get_token_address() == yas_erc_20.contract_address, 'wrong token_address'
        );
        assert(yas_faucet.get_withdrawal_amount() == 1000, 'wrong withdrawal_amount');
        assert(yas_faucet.get_wait_time() == 86400, 'wrong wait_time');
    }

    #[test]
    #[available_gas(200000000)]
    #[should_panic(expected: ('Not allowed to withdraw', 'ENTRYPOINT_FAILED'))]
    fn test_withdrawal_not_allowed_panic() {
        let (yas_faucet, yas_erc_20) = setup();

        assert(yas_erc_20.balanceOf(WALLET()) == 0, 'wrong balance');

        set_contract_address(WALLET());
        yas_faucet.faucet_mint();
        assert(yas_erc_20.balanceOf(WALLET()) == 1000, 'wrong balance');

        set_block_timestamp(86400);

        yas_faucet.faucet_mint();
        assert(yas_erc_20.balanceOf(WALLET()) == 2000, 'wrong balance');
    }

    #[test]
    #[available_gas(200000000)]
    #[should_panic(expected: ('There is not enough balance', 'ENTRYPOINT_FAILED'))]
    fn test_insufficient_balance_panic() {
        let yas_token = deploy_erc20('YAS', '$YAS', 4000000000000000000, OWNER());
        let yas_faucet = deploy_yas_faucet(OWNER(), yas_token.contract_address, 1000, 86400);
        set_contract_address(WALLET());
        yas_faucet.faucet_mint();
    }

    #[test]
    #[available_gas(200000000)]
    #[should_panic(expected: ('Caller is not the owner', 'ENTRYPOINT_FAILED'))]
    fn test_owner_withdrawal_panic() {
        let (yas_faucet, yas_erc_20) = setup();

        assert(yas_erc_20.balanceOf(OTHER()) == 0, 'wrong balance');
        assert(
            yas_erc_20.balanceOf(yas_faucet.contract_address) == 4000000000000000000,
            'wrong balance'
        );

        set_contract_address(WALLET());
        yas_faucet.withdraw_all_balance(OTHER());

        assert(yas_erc_20.balanceOf(OTHER()) == 4000000000000000000, 'wrong balance');
        assert(yas_erc_20.balanceOf(yas_faucet.contract_address) == 0, 'wrong balance');
    }
}
