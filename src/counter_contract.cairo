#[starknet::interface]
trait ICounterContract<TContractState> {
    fn increase_counter(ref self: TContractState, amount: u128);
    fn double_increase(ref self: TContractState, amount: u128);
    fn decrease_counter(ref self: TContractState, amount: u128);
    fn get_counter(self: @TContractState) -> u128;
}

#[starknet::contract]
mod counter_contract {
    use starknet::contract_address::ContractAddress;
    use starknet::{ClassHash, get_caller_address};
    use components::upgradable::upgradable as upgradable_component;
    use components::upgradable::OwnableTrait;

    component!(path: upgradable_component, storage: upgradable, event: UpgradableEvent);

    #[abi(embed_v0)]
    impl Upgradable = upgradable_component::UpgradableImpl<ContractState>;

    impl Ownable of components::upgradable::OwnableTrait<ContractState> {
        fn is_owner(self: @ContractState, address: ContractAddress) -> bool {
            let caller = get_caller_address();
            let owner = self.owner_address.read();
            caller == owner
        }
    }

    #[storage]
    struct Storage {
        counter: u128,
        owner_address: ContractAddress,
        #[substorage(v0)]
        upgradable: upgradable_component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterIncreased: CounterIncreased,
        DoubleIncreased: DoubleIncreased,
        CounterDecreased: CounterDecreased,
        UpgradableEvent: upgradable_component::Event
    }

    #[derive(Drop, starknet::Event)]
    struct CounterIncreased {
        amount: u128
    }

    #[derive(Drop, starknet::Event)]
    struct DoubleIncreased {
        amount: u128
    }

    #[derive(Drop, starknet::Event)]
    struct CounterDecreased {
        amount: u128
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_counter: u128, owner_address: ContractAddress) {
        self.counter.write(initial_counter);
        self.owner_address.write(owner_address);
    }

    #[external(v0)]
    impl CounterContract of super::ICounterContract<ContractState> {
        fn get_counter(self: @ContractState) -> u128 {
            self.counter.read()
        }

        fn increase_counter(ref self: ContractState, amount: u128) {
            let is_owner = self.is_owner(get_caller_address());
            if is_owner {
                let current = self.counter.read();
                self.counter.write(current + amount);
                self.emit(CounterIncreased { amount });
            }
        }

        fn double_increase(ref self: ContractState, amount: u128) {
            let is_owner = self.is_owner(get_caller_address());
            if is_owner {
                let current = self.counter.read();
                self.counter.write(current + 2 * amount);
                self.emit(CounterIncreased { amount });
            }
        }

        fn decrease_counter(ref self: ContractState, amount: u128) {
            let is_owner = self.is_owner(get_caller_address());
            if is_owner {
                let current = self.counter.read();
                self.counter.write(current - amount);
                self.emit(CounterDecreased { amount });
            }
        }
    }
}
