# OpenVZ Examples

class ovz-guests {

  # Simplest way to create a guest
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

  # Creates a guest from an existing xml file
  virt { "101":
    memory     => 1024,
    vcpu       => 4,
    xml_file   => "/etc/libvirt/qemu/systems/101.xml",
    tmpl_cache => "debian-5.0-x86",
    ensure     => installed,
    virt_type  => "openvz"
  }

  # Creates a guest using a template
  virt { "ovz1":
    os_template          => 'ubuntu-10.10-x86_64',
    ensure               => 'running',
    virt_type            => 'openvz',
    autoboot             => 'false',
    configfile           => 'basic',
    ipaddr               => ['10.0.0.1'],
    features             => ["nfs:on", "sit:off"],
    resources_parameters => ["NUMPTY=20:20", "NUMSIGINFO=255:255"],
  }

  # Creates a guest using a template specifying where it should be stored
  virt { "ovz2":
    ctid        => 101,
    os_template => 'ubuntu-11.04-x86_64',
    ensure      => 'stopped',
    virt_type   => 'openvz',
    ve_root     => '/home/a/root/$VEID',
    ve_private  => '/home/a/private/$VEID',
    user        => 'user:password',
    capability  => ["chown:off"],
    devices     => ["b:8:19:rw", "b:8:18:rw", "cdrom:rw"]
  }

}
