class virt::openvz::hn::ubuntu inherits virt::openvz::hn::base {
  Package['opnvzkernel']{
    name => 'linux-openvz',
  }
}
