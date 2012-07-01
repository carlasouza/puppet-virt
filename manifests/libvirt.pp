class virt::libvirt {
  case $::operatingsystem {
    debian: { include virt::libvirt::debian }
    ubuntu: { include virt::libvirt::ubuntu }
    default: { include virt::libvirt::base }
  }
}
