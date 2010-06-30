class virt {
	case $operatingsystem {
		debian: { include virt::debian }
	}
}

class virt::debian {
	package {
		[ "linux-image-xen-686", "xen-tools", "ubuntu-virt-server", "python-vm-builder",
			"kvm", "qemu", "qemu-kvm"]:
		ensure => latest;
    	}
}
