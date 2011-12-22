class virt {
  case $virtual {
    /^xen/: { include virt::xen }
    #/^kvm/: { include virt::kvm }
    /^openvzhn/: { include virt::openvz }
  }
}
