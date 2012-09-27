# XEN Example using libvirt provider

class xen-fullvirt-guest {
  virt { guest:
    memory    => 512,
    virt_path => "/home/user/disk0.qcow2",
    ensure    => installed,
    virt_type => "xen_fullyvirt"
  }
}
