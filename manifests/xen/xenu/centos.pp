class virt::xen::xenu::centos {
  # Connect console to xvc0
  line{
    'xvc0_inittab':
      file => '/etc/inittab',
      line => 'co:2345:respawn:/sbin/agetty xvc0 9600 vt100-nav';
    'securetty':
      file => '/etc/securetty',
      line => 'xvc0';
  }
}
