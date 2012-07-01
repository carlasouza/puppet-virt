class virt::libvirt::ubuntu inherits virt::libvirt::debian {
  Package['python-virtinst']{
    name => 'python-vm-builder',
  }
  package{'ubuntu-virt-server':
    ensure => present,
  }
}
