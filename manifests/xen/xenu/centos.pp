class virt::xen::xenu::centos {
  # Connect console to xvc0
  file_line{
    'xvc0_inittab':
      path => '/etc/inittab',
      line => 'co:2345:respawn:/sbin/agetty xvc0 9600 vt100-nav';
    'securetty':
      path => '/etc/securetty',
      line => 'xvc0';
  }
}
