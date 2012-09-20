class xen-fullvirt-guest {
  virt { "Jun29":
    memory => 512,
    virt_path => "/home/carla/ourgrid/images/worker-carla/disk0.qcow2",
    ensure => installed,
    virt_type => "xen_fullyvirt"
  }
}

class ovz-guest {
  virt { "ovz1":
    os_template => 'ubuntu-10.10-x86_64',
    ensure     => 'running',
    virt_type  => 'openvz',
    autoboot   => 'false',
    configfile => 'basic',
    ipaddr     => ['10.0.0.1'],
    features => ["nfs:on", "sit:off"],
    resources_parameters => ["NUMPTY=20:20", "NUMSIGINFO=255:255"],
  }

  virt { "ovz2":
    ctid       => 101,
    os_template => 'ubuntu-11.04-x86_64',
    ensure     => 'stopped',
    virt_type  => 'openvz',
    ve_root => '/home/a/root/$VEID',
    ve_private => '/home/a/private/$VEID',
    user => 'user:password',
    capability => ["chown:off"],
    devices => ["b:8:19:rw", "b:8:18:rw", "cdrom:rw"]
  }

  virt { guest-openvz1:
    ensure      => 'running',
    id          => 101,
    os_template => 'ubuntu-10.10',
    virt_type   => 'openvz',
    autoboot    => 'false'
  }

# Note that some values can be specified as an array of values:
  virt { guest-openvz2:
    ensure      => 'installed',
    memory      => 512,
    os_template => 'ubuntu-10.10-x86_64',
    virt_type   => 'openvz',
    autoboot    => true,
    interfaces  => ["eth0", "eth1"]
  }

}

#KVM examples:
class kvm-guests {

  virt { guest-kvm1:
    memory    => 512,
    virt_path => '/home/user/disk0.qcow2',
    ensure    => installed,
    virt_type => 'kvm'
  }

  # clone from guest-kvm1
  virt { guest-kvm2:
    clone     => 'guest-kvm1'
    ensure    => running,
    virt_type => 'kvm'
  }

}

# lXC Examples:
class lxc-guest {

  virt { guest-lxc1:
    ensure      => running,
    os_template => 'ubuntu',
    provider    => 'lxc'
  }

  # clone from guest-lxc1
  virt { guest-lxc2:
    ensure   => running,
    clone    => 'guest-lxc1',
    snapshot => true,
    provider => 'lxc',
    require  => Virt['lxc1']
  }

}
