//ClasshashとContractAddress型を追加
use starknet::class_hash::ClassHash;
use starknet::contract_address::ContractAddress;

#[starknet::interface]
trait IUpgradable<TContractState> {
    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);
}

trait OwnableTrait<TContractState> {
    fn is_owner(self: @TContractState, address: ContractAddress) -> bool;
}

#[starknet::component]
mod upgradable {
    use starknet::{ClassHash, get_caller_address};
    use starknet::syscalls::replace_class_syscall;
    use super::OwnableTrait;

    #[storage]
    struct Storage {
        current_implementation: ClassHash
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ContractUpgraded: ContractUpgraded
    }

    #[derive(Drop, starknet::Event)]
    struct ContractUpgraded {
        old_class_hash: ClassHash,
        new_class_hash: ClassHash
    }

    #[embeddable_as(UpgradableImpl)]
    impl Upgradable<
        TContractState, +HasComponent<TContractState>, +OwnableTrait<TContractState>
    > of super::IUpgradable<ComponentState<TContractState>> {
        fn upgrade(ref self: ComponentState<TContractState>, new_class_hash: ClassHash) {
            let is_owner = self.get_contract().is_owner(get_caller_address());
            if is_owner {
                replace_class_syscall(new_class_hash).unwrap();
                let old_class_hash = self.current_implementation.read();
                self.emit(ContractUpgraded { old_class_hash, new_class_hash });
                self.current_implementation.write(new_class_hash);
            }
        }
    }
}
