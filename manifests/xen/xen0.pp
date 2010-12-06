class virt::xen::xen0 {
  include ::virt::libvirt
  case $operatingsystem {
    debian: { include virt::xen::xen0::debian }
    centos: { include virt::xen::xen0::centos }
    default: { include virt::xen::xen0::base }
  }
}
