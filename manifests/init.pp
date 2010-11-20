class virt {
	case $operatingsystem {
		debian: { include virt::debian }
		ubuntu: { include virt::ubuntu }
		fedora: { include virt::fedora }
	}
}

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
