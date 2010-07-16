class virt {
	case $operatingsystem {
		debian: { include virt::debian }
		ubuntu: { include virt::ubuntu }
		fedora: { include virt::fedora }
	}
}

class virt::debian {
	package {
		[ "linux-image-xen-686", "xen-hypervisor", "xen-tools", "xen-utils", 
		"kvm", "qemu", "libvirt-bin", "virtinst", "libvirt-bin" ]:
		ensure => latest;
    	}
}

class virt::ubuntu {
	package {
		[ "ubuntu-virt-server", "python-vm-builder", "kvm", "qemu", "qemu-kvm",
		"ubuntu-xen-server", "libvirt-ruby" ]
		ensure => latest;
	}
}

class virt::fedora {
	package {
		[ "kvm", "qemu", "libvirt", "python-virtinst", "kernel-xen", "xen",
		"ruby-libvirt"]
		ensure => latest;
	}
}
