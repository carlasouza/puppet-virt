class virt::fedora {
  case $virtual {
    /^(xen|kvm)/: {
	    package {
		    [ "kvm", "qemu", "libvirt", "python-virtinst", "kernel-xen", "xen",
		      "ruby-libvirt" ]:
		      ensure => latest;
	    }
    }
    openvzhn: {
	    package {
		    [ "ovzkernel", "vzctl", "vzquota", "libvirt", "python-virtinst", "ruby-libvirt" ]:
		      ensure => latest;
      }
    }
  }
}
