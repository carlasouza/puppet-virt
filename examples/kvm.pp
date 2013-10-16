# KVM examples, using libvirt provider

class kvm-guests {

  virt { "guest-kvm1":
    memory    => 512,
    virt_path => '/home/user/disk0.qcow2',
    cpus      => 2,
    ensure    => running,
    virt_type => 'kvm',
    macaddrs    => ["00:16:3e:14:1b:a1"],
  }

  # clone from guest-kvm1
  virt { guest-kvm2:
    clone     => 'guest-kvm1',
    ensure    => running,
    virt_type => 'kvm'
  }

}
