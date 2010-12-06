class virt::ubuntu {
  case $virtual {
    /^(xen|kvm)/: {
	    package {
		    [ "ubuntu-virt-server", "python-vm-builder", "kvm", "qemu", "qemu-kvm",
		      "ubuntu-xen-server", "libvirt-ruby" ]:
		      ensure => latest;
	    }
  	}
    openvzhn: {
	    package {
		    [ "linux-openvz", "vzctl", "vzquota", "libvirt-bin", "python-virtinst" ]:
		      ensure => latest;
      }
  	}
  }
}

