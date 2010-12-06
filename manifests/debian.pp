class virt::debian {
  case $virtual {
    /^(xen|kvm)/: {
	    package {
		    [ "linux-image-xen-686", "xen-hypervisor", "xen-tools", "xen-utils", 
		      "kvm", "qemu", "libvirt-bin", "virtinst", "libvirt-bin" ]:
		      ensure => latest;
      }
  	}
    openvzhn: {
	    package {
		    [ "linux-image-openvz-686", "vzctl", "vzquota", "vzdump",
          "libvirt-bin", "python-virtinst" ]:
     		  ensure => latest;
      }
  	}
  }
}


