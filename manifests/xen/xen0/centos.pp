class virt::xen::xen0::centos inherits virt::xen::xen0::base {
  file{'xend_defaults':
    path => '/etc/sysconfig/xend',
    source => "puppet:///modules/virt/xen/${::operatingsystem}/sysconfig/xend",
    notify => Service['xend'],
    owner => root, group => 0, mode => 0644;
  }

  File['xendomains_defaults']{
    path => '/etc/sysconfig/xendomains',
    source => "puppet:///modules/virt/xen/${::operatingsystem}/sysconfig/xendomains",
  }
}
