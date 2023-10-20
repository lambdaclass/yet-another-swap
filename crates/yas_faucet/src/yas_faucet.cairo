use starknet::ContractAddress;

#[starknet::interface]
trait IYASFaucet<TContractState> {
    fn faucet_mint(ref self: TContractState);
    fn get_user_unlock_time(self: @TContractState, user: ContractAddress) -> u64;
    fn get_token_address(self: @TContractState) -> ContractAddress;
    fn get_withdrawal_amount(self: @TContractState) -> u256;
    fn get_wait_time(self: @TContractState) -> u64;
    fn set_withdrawal_amount(ref self: TContractState, amount: u256);
    fn set_wait_time(ref self: TContractState, wait_time: u64);
}

#[starknet::contract]
mod YASFaucet {
    use super::IYASFaucet;

    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};
    use openzeppelin::access::ownable::Ownable;
    use yas_core::interfaces::interface_ERC20::{IERC20DispatcherTrait, IERC20Dispatcher};

    #[storage]
    struct Storage {
        user_unlock_time: LegacyMap<ContractAddress, u64>,
        token_address: ContractAddress,
        withdrawal_amount: u256,
        wait_time: u64,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        token_address: ContractAddress,
        withdrawal_amount: u256,
        wait_time: u64
    ) {
        let mut unsafe_state = Ownable::unsafe_new_contract_state();
        Ownable::InternalImpl::initializer(ref unsafe_state, owner);
        self.token_address.write(token_address);
        self.withdrawal_amount.write(withdrawal_amount);
        self.wait_time.write(wait_time);
    }

    #[external(v0)]
    impl YASFaucetImpl of IYASFaucet<ContractState> {
        fn faucet_mint(ref self: ContractState) {
            let caller_address = get_caller_address();
            assert(self.allowed_to_withdraw(caller_address), 'Not allowed to withdraw');
            self
                .user_unlock_time
                .write(caller_address, get_block_timestamp() + self.wait_time.read());
            IERC20Dispatcher { contract_address: self.token_address.read() }
                .transfer(caller_address, self.withdrawal_amount.read());
        }

        fn get_user_unlock_time(self: @ContractState, user: ContractAddress) -> u64 {
            self.user_unlock_time.read(user)
        }

        fn get_token_address(self: @ContractState) -> ContractAddress {
            self.token_address.read()
        }

        fn get_withdrawal_amount(self: @ContractState) -> u256 {
            self.withdrawal_amount.read()
        }

        fn get_wait_time(self: @ContractState) -> u64 {
            self.wait_time.read()
        }

        fn set_withdrawal_amount(ref self: ContractState, amount: u256) {
            let unsafe_state = Ownable::unsafe_new_contract_state();
            Ownable::InternalImpl::assert_only_owner(@unsafe_state);
            self.withdrawal_amount.write(amount);
        }

        fn set_wait_time(ref self: ContractState, wait_time: u64) {
            let unsafe_state = Ownable::unsafe_new_contract_state();
            Ownable::InternalImpl::assert_only_owner(@unsafe_state);
            self.wait_time.write(wait_time);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn allowed_to_withdraw(self: @ContractState, user: ContractAddress) -> bool {
            let unlock_time = self.user_unlock_time.read(user);
            if unlock_time == 0 {
                return true;
            }
            let timestamp = get_block_timestamp();
            if unlock_time < timestamp {
                true
            } else {
                false
            }
        }
    }
}
