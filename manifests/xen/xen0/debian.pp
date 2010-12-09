class virt::xen::xen0::debian inherits virt::xen::xen0::base {
  # This package is i386 only
  # See also http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=379444
  case $architecture {
    'i386': {
      package { 'libc6-xen': ensure => present }
    }
  }
  Package['kernel-xen']{
    name => "linux-image-xen-$architecture",
  }

  Package['xen']{
    name => 'xen-hypervisor',
  }

  Package['xen-libs']{
    name => 'xen-utils',
  }

  File['xendomains_defaults']{
        path => '/etc/default/xendomains',
        source => "puppet:///modules/virt/xen/${operatingsystem}/default/xendomains",
  }

  config_file {
    "/etc/ld.so.conf.d/nosegneg.conf":
      ensure => $xen_ensure,
      content => "hwcap 0 nosegneg\n",
    }
}

