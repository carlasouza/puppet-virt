class virt::libvirt::base {
  package{ [ 'libvirt', 'python-virtinst', 'ruby-libvirt', 'qemu' ]:
    ensure => installed,
  }

  service{'libvirtd':
    ensure => running,
    enable => true,
    hasstatus => true,
    require => Package['libvirt'],
  } 

  file{
    '/usr/local/sbin/guest_starter':
      source => 'puppet:///modules/virt/libvirt/guest_starter',
      require => Package['libvirt'],
      owner => root, group => 0, mode => 0700;
    '/usr/local/sbin/generate_random_macaddress':
      source => 'puppet:///modules/virt/libvirt/random_mac_address.rb',
      owner => root, group => 0, mode => 0755;
  }
}
