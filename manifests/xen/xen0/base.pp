class virt::xen::xen0::base {
  package{ ['xen', 'xen-libs', 'kernel-xen']:
    ensure => present,
  }

  service{'xend':
    ensure => running,
    enable => true,
    hasstatus => true,
    require => Package['kernel-xen'],
  }

  file{'xendomains_defaults':
    owner => root, group => 0, mode => 0644;
  }

  service{'xendomains':
    enable => true,
    hasstatus => true,
    require => Package['kernel-xen'],
  }
  # only ensure xendomains running if we have more
  # than one domain running
  if $::virtual_guests_count and $::virtual_guests_count > 0 {
    Service['xendomains']{
      ensure => running,
    }
    File['xendomains_defaults']{
      notify => Service[xendomains]
    }
  }

  file{'/etc/xen/xend-config.sxp':
    source => [ "puppet:///modules/site_virt/xen/${::fqdn}/config/xend-config.sxp",
                "puppet:///modules/site_virt/xen/config/${::domain}/xend-config.sxp",
                "puppet:///modules/site_virt/xen/config/${::operatingsystem}.${::lsbdistcodename}/xend-config.sxp",
                "puppet:///modules/site_virt/xen/config/${::operatingsystem}/xend-config.sxp",
                "puppet:///modules/site_virt/xen/config/xend-config.sxp",
                "puppet:///modules/virt/xen/config/${::operatingsystem}/xend-config.sxp",
                "puppet:///modules/virt/xen/config/xend-config.sxp" ],
    notify => Service['xend'],
    owner => root, group => 0, mode => 0644;
  }
}
