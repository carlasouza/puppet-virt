class virt::openvz::hn::base {
  package{
    [ 'vzctl', 'vzquota', 'ovzkernel']:
      ensure => present,
  }
}
