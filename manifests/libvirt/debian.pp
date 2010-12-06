class virt::libvirt::debian inherits virt::libvirt::base {
  Package['python-virtinst']{
    name => 'virtinst',
  }
}
