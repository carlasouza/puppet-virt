class virt::libvirt::debian inherits virt::libvirt::base {
  Package['python-virtinst']{
    name => 'virtinst',
  }
  Package['libvirt']{
    name => 'libvirt0',
  }
  Package['ruby-libvirt']{
    name => 'libvirt-ruby',
  }
  package{'libvirt-bin':
    ensure => present,
  }
  Service['libvirtd']{
    name => 'libvirt-bin',
    require +> Package['libvirt-bin'],
  }
}
