class virt::xen::xenu {
  case $::operatingsystem {
    centos: { include virt::xen::xenu::centos }
  }
}
