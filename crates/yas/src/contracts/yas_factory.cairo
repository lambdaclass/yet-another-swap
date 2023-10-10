use starknet::ContractAddress;
use yas::numbers::signed_integer::i32::i32;

/// @title The interface for the YAS Factory
/// @notice The YAS Factory facilitates creation of YAS pools and control over the protocol fees
#[starknet::interface]
trait IYASFactory<TContractState> {
    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via set_owner
    /// @return The address of the factory owner
    fn owner(self: @TContractState) -> ContractAddress;

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    fn fee_amount_tick_spacing(self: @TContractState, fee: u32) -> i32;

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev token_a and token_b may be passed in either token_0/token_1 or token_1/token_0 order
    /// @param token_a The contract address of either token0 or token1
    /// @param token_b The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    fn pool(
        self: @TContractState, token_a: ContractAddress, token_b: ContractAddress, fee: u32
    ) -> ContractAddress;

    /// @notice Creates a pool for the given two tokens and fee
    /// @param token_a One of the two tokens in the desired pool
    /// @param token_b The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev token_a and token_b may be passed in either order: token_0/token_1 or token_1/token_0. tick_spacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    fn create_pool(
        ref self: TContractState, token_a: ContractAddress, token_b: ContractAddress, fee: u32
    ) -> ContractAddress;

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param new_owner The new owner of the factory
    fn set_owner(ref self: TContractState, new_owner: ContractAddress);

    /// @notice Enables a fee amount with the given tick_spacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tick_spacing The spacing between ticks to be enforced for all pools created with the given fee amount
    fn enable_fee_amount(ref self: TContractState, fee: u32, tick_spacing: i32);
}


#[starknet::contract]
mod YASFactory {
    use super::IYASFactory;

    use poseidon::poseidon_hash_span;
    use starknet::SyscallResultTrait;
    use starknet::syscalls::deploy_syscall;
    use starknet::{ContractAddress, ClassHash, get_caller_address, get_contract_address};

    use yas::contracts::yas_pool::{YASPool, IYASPool, IYASPoolDispatcher, IYASPoolDispatcherTrait};
    use yas::numbers::signed_integer::{i32::i32, integer_trait::IntegerTrait};
    use yas::utils::utils::ContractAddressPartialOrd;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnerChanged: OwnerChanged,
        PoolCreated: PoolCreated,
        FeeAmountEnabled: FeeAmountEnabled
    }

    /// @notice Emitted when the owner of the factory is changed
    /// @param old_owner The owner before the owner was changed
    /// @param new_owner The owner after the owner was changed   
    #[derive(Drop, starknet::Event)]
    struct OwnerChanged {
        old_owner: ContractAddress,
        new_owner: ContractAddress
    }

    /// @notice Emitted when a pool is created
    /// @param token_0 The first token of the pool by address sort order
    /// @param token_1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tick_spacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    #[derive(Drop, starknet::Event)]
    struct PoolCreated {
        token_0: ContractAddress,
        token_1: ContractAddress,
        fee: u32,
        tick_spacing: i32,
        pool: ContractAddress
    }

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tick_spacing The minimum number of ticks between initialized ticks for pools created with the given fee
    #[derive(Drop, starknet::Event)]
    struct FeeAmountEnabled {
        fee: u32,
        tick_spacing: i32
    }

    #[storage]
    struct Storage {
        owner: ContractAddress,
        fee_amount_tick_spacing: LegacyMap::<u32, i32>,
        pool: LegacyMap<(ContractAddress, ContractAddress, u32), ContractAddress>,
        pool_class_hash: ClassHash
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, pool_class_hash: ClassHash) {
        self.owner.write(owner);
        self.emit(OwnerChanged { old_owner: Zeroable::zero(), new_owner: owner });

        assert(pool_class_hash.is_non_zero(), 'pool class hash can not be zero');
        self.pool_class_hash.write(pool_class_hash);

        // value derived from a simple proportion. 
        // fee %0.01 -> tick_spacing 2
        self.fee_amount_tick_spacing.write(100, IntegerTrait::<i32>::new(2, false));
        self.emit(FeeAmountEnabled { fee: 100, tick_spacing: IntegerTrait::<i32>::new(2, false) });

        // fee %0.05 -> tick_spacing 10
        self.fee_amount_tick_spacing.write(500, IntegerTrait::<i32>::new(10, false));
        self.emit(FeeAmountEnabled { fee: 500, tick_spacing: IntegerTrait::<i32>::new(10, false) });

        // fee %0.3 -> tick_spacing 60
        self.fee_amount_tick_spacing.write(3000, IntegerTrait::<i32>::new(60, false));
        self
            .emit(
                FeeAmountEnabled { fee: 3000, tick_spacing: IntegerTrait::<i32>::new(60, false) }
            );

        // fee %1 -> tick_spacing 200
        self.fee_amount_tick_spacing.write(10000, IntegerTrait::<i32>::new(200, false));
        self
            .emit(
                FeeAmountEnabled { fee: 10000, tick_spacing: IntegerTrait::<i32>::new(200, false) }
            );
    }

    #[external(v0)]
    impl YASFactoryImpl of IYASFactory<ContractState> {
        fn owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn fee_amount_tick_spacing(self: @ContractState, fee: u32) -> i32 {
            self.fee_amount_tick_spacing.read(fee)
        }

        fn pool(
            self: @ContractState, token_a: ContractAddress, token_b: ContractAddress, fee: u32
        ) -> ContractAddress {
            self.pool.read((token_a, token_b, fee))
        }

        fn create_pool(
            ref self: ContractState, token_a: ContractAddress, token_b: ContractAddress, fee: u32
        ) -> ContractAddress {
            assert(token_a != token_b, 'tokens must be different');
            assert(
                token_a.is_non_zero() && token_b.is_non_zero(), 'tokens addresses cannot be zero'
            );

            let (token_0, token_1) = if token_a < token_b {
                (token_a, token_b)
            } else {
                (token_b, token_a)
            };

            let tick_spacing = self.fee_amount_tick_spacing(fee);
            assert(tick_spacing.is_non_zero(), 'tick spacing not initialized');

            assert(self.pool(token_0, token_1, fee).is_zero(), 'token pair already created');

            let contract_address_salt = generate_salt(@token_0, @token_1);
            let calldata = serialize_calldata(@token_0, @token_1, fee, @tick_spacing);

            let (pool, _) = deploy_syscall(
                self.pool_class_hash.read(), contract_address_salt, calldata.span(), false
            )
                .unwrap_syscall();

            self.pool.write((token_0, token_1, fee), pool);
            // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
            self.pool.write((token_1, token_0, fee), pool);

            self.emit(PoolCreated { token_0, token_1, fee, tick_spacing, pool });

            pool
        }

        fn enable_fee_amount(ref self: ContractState, fee: u32, tick_spacing: i32) {
            self.assert_only_owner();
            assert(fee < 1000000, 'fee cannot be gt 1000000');

            // tick spacing is capped at 16384 to prevent the situation where tick_spacing is so large that
            // TickBitmap#nextInitializedTickWithinOneWord overflows int24 container from a valid tick
            // 16384 ticks represents a >5x price change with ticks of 1 bips
            assert(
                tick_spacing > Zeroable::zero()
                    && tick_spacing < IntegerTrait::<i32>::new(16384, false),
                'wrong tick_spacing (0<ts<16384)'
            );
            assert(self.fee_amount_tick_spacing(fee).is_zero(), 'fee amount already initialized');

            self.fee_amount_tick_spacing.write(fee, tick_spacing);
            self.emit(FeeAmountEnabled { fee, tick_spacing });
        }

        fn set_owner(ref self: ContractState, new_owner: ContractAddress) {
            self.assert_only_owner();
            self.emit(OwnerChanged { old_owner: self.owner(), new_owner });
            self.owner.write(new_owner);
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn assert_only_owner(self: @ContractState) {
            assert(get_caller_address() == self.owner(), 'only owner can do this action!');
        }
    }

    fn serialize_calldata(
        token_0: @ContractAddress, token_1: @ContractAddress, fee: u32, tick_spacing: @i32
    ) -> Array<felt252> {
        let mut calldata = array![];
        calldata.append(get_contract_address().into());
        Serde::serialize(token_0, ref calldata);
        Serde::serialize(token_1, ref calldata);
        calldata.append(fee.into());
        Serde::serialize(tick_spacing, ref calldata);

        calldata
    }

    fn generate_salt(token_0: @ContractAddress, token_1: @ContractAddress) -> felt252 {
        let mut data = array![];
        Serde::serialize(token_0, ref data);
        Serde::serialize(token_1, ref data);
        poseidon_hash_span(data.span())
    }
}
