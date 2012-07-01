class virt::kvm::base {
  package{ [ 'kvm', 'qemu-kvm']:
    ensure => present,
  }
}
