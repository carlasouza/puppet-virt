class virt::xen::xen0::ubuntu inherits virt::xen::xen0::debian {
  package{'ubuntu-xen-server':
    ensure => present,
  }
}
