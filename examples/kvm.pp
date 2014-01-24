# KVM examples, using libvirt provider
class { "kvm-guests": }
class kvm-guests {

  virt { "guest-kvm1":
    memory    => 512,
    virt_path => '/tmp/disk0.qcow2',
    disk_size => '3',
    virt_disks => {"/tmp/disk1.qcow2" => 2, "/tmp/disk2.qcow2" => 3 },
    virtio_for_disks => true,
    virtio_for_net => true,
    #interfaces => ["br1"],
    cpus      => 2,
    ensure    => running,
    virt_type => 'kvm'
    
  }
}
